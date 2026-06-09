import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD SERVICE
//
//  ⚠️  BEFORE RELEASE: replace every test ID below with your real AdMob IDs.
// ═══════════════════════════════════════════════════════════════════════════════

class AdService extends GetxService with WidgetsBindingObserver {
  // ── Ad Unit IDs — test in debug, real in release ───────────────────────────
  static const _bannerAdUnitId = kReleaseMode
      ? 'ca-app-pub-6979328267625068/8444566416'      // real
      : 'ca-app-pub-3940256099942544/6300978111';     // test

  static const _interstitialAdUnitId = kReleaseMode
      ? 'ca-app-pub-6979328267625068/1770512709'      // real
      : 'ca-app-pub-3940256099942544/1033173712';     // test

  // ── Banner state ───────────────────────────────────────────────────────────
  BannerAd?      _bannerAd;
  final RxBool   isBannerLoaded = false.obs;
  BannerAd? get  bannerAd       => _bannerAd;

  // ── Preloaded interstitial (used for normal one-shot calls) ────────────────
  InterstitialAd? _interstitialAd;
  final RxBool    isInterstitialLoaded = false.obs;

  // ── Full-screen ad visibility (true while any interstitial is on screen) ───
  // Used by GameScreen to block the physical back button while an ad is visible.
  final RxBool isAdShowing = false.obs;

  // ── Sequential-ad progress (reactive so UI can show "Ad X of 3") ──────────
  final RxInt  seqAdCurrent = 0.obs;
  final RxInt  seqAdTotal   = 0.obs;
  final RxBool seqRunning   = false.obs;

  // ── Safety: pending callback fired if dismiss event is never received ───────
  // Tracks a VoidCallback to fire if the app resumes while isAdShowing is true.
  // This recovers navigation if Google Mobile Ads SDK skips the dismiss event.
  VoidCallback? _pendingAdDismissed;
  Timer?        _adSafetyTimer;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<AdService> init() async {
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _loadBanner();
    _loadInterstitial();
    return this;
  }

  // ── App lifecycle observer ─────────────────────────────────────────────────
  // If the app returns to foreground while isAdShowing is true, the ad was
  // dismissed externally (e.g., system back gesture on some OEMs, or an app
  // switch) and the dismiss callback may never fire. Force-clear the flag and
  // invoke the pending callback so navigation is never permanently blocked.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAdShowing.value) {
      // Give the SDK a short grace period to deliver the callback itself.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isAdShowing.value) {
          _forceResolveAd();
        }
      });
    }
  }

  void _forceResolveAd() {
    isAdShowing.value = false;
    _adSafetyTimer?.cancel();
    _adSafetyTimer = null;
    final cb = _pendingAdDismissed;
    _pendingAdDismissed = null;
    cb?.call();
  }

  // Start a hard safety timer — even if lifecycle events don't fire (e.g. the
  // ad is shown in a way that keeps the app in foreground), the timer ensures
  // the callback fires within 5 minutes so the user is never permanently stuck.
  void _startSafetyTimer(VoidCallback onDismissed) {
    _adSafetyTimer?.cancel();
    _pendingAdDismissed = onDismissed;
    _adSafetyTimer = Timer(const Duration(minutes: 5), () {
      if (isAdShowing.value) {
        _forceResolveAd();
      }
    });
  }

  void _cancelSafetyTimer() {
    _adSafetyTimer?.cancel();
    _adSafetyTimer = null;
    _pendingAdDismissed = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BANNER
  // ─────────────────────────────────────────────────────────────────────────

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => isBannerLoaded.value = true,
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
          isBannerLoaded.value = false;
          Future.delayed(const Duration(seconds: 30), _loadBanner);
        },
      ),
    )..load();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INTERSTITIAL — single preloaded slot
  // ─────────────────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isInterstitialLoaded.value = true;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
          isInterstitialLoaded.value = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Loads a FRESH interstitial every time and shows it immediately.
  ///
  /// This is the **mandatory** path — always attempts a real load so the ad
  /// cannot be skipped due to a stale/missing preloaded slot.
  /// [onDismissed] fires after the ad closes normally.
  /// [onFailure]   fires if loading or showing fails (caller should still
  ///               proceed so the user is never permanently stuck).
  void loadAndShowInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.setImmersiveMode(true);
          isAdShowing.value = true;
          _startSafetyTimer(onDismissed);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _cancelSafetyTimer();
              isAdShowing.value = false;
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (a, _) {
              a.dispose();
              _cancelSafetyTimer();
              isAdShowing.value = false;
              onFailure();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) => onFailure(),
      ),
    );
  }

  /// Shows the preloaded interstitial.
  /// Falls back to [onDismissed] immediately when no ad is ready so callers
  /// never get stuck — but [loadAndShowInterstitial] is preferred for events
  /// where showing an ad is truly mandatory.
  void showInterstitial({required VoidCallback onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      onDismissed();
      return;
    }
    _interstitialAd = null;
    isInterstitialLoaded.value = false;
    isAdShowing.value = true;
    _startSafetyTimer(onDismissed);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _cancelSafetyTimer();
        isAdShowing.value = false;
        _loadInterstitial();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _cancelSafetyTimer();
        isAdShowing.value = false;
        _loadInterstitial();
        onDismissed();
      },
    );
    ad.show();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SEQUENTIAL INTERSTITIALS — watch N ads in a row
  //
  //  Each ad is freshly loaded so we don't depend on the preloaded slot.
  //  seqAdCurrent / seqAdTotal are reactive so a UI progress indicator can
  //  rebuild between ads ("Watching ad 2 of 3…").
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows [count] full-screen ads one after another, then calls [onAllDone].
  /// If an ad fails to load/show the sequence is aborted and [onFailure] is
  /// called (defaults to [onAllDone] so callers only need one callback).
  void showSequentialInterstitials({
    required int count,
    required VoidCallback onAllDone,
    VoidCallback? onFailure,
  }) {
    seqAdTotal.value   = count;
    seqAdCurrent.value = 0;
    seqRunning.value   = true;
    _showNextInSequence(
      remaining: count,
      onAllDone: () {
        seqRunning.value = false;
        onAllDone();
      },
      onFailure: () {
        seqRunning.value = false;
        (onFailure ?? onAllDone)();
      },
    );
  }

  // Pre-loads the next ad while the current one is playing to avoid the gap
  // between sequential ads where the app briefly shows behind an ad.
  void _showNextInSequence({
    required int remaining,
    required VoidCallback onAllDone,
    required VoidCallback onFailure,
    InterstitialAd? preloaded,
  }) {
    if (remaining <= 0) {
      preloaded?.dispose();
      onAllDone();
      return;
    }

    void showAd(InterstitialAd ad) {
      ad.setImmersiveMode(true);
      isAdShowing.value = true;

      // Safety callback: if the dismiss event never fires, resolve after timeout.
      _startSafetyTimer(() {
        seqAdCurrent.value++;
        if (remaining - 1 <= 0) {
          onAllDone();
        } else {
          onFailure();
        }
      });

      InterstitialAd? nextAd;
      bool nextLoaded = false;
      bool currentDismissed = false;

      void proceedToNext() {
        seqAdCurrent.value++;
        if (remaining - 1 <= 0) {
          nextAd?.dispose();
          onAllDone();
          return;
        }
        if (nextLoaded && nextAd != null) {
          _showNextInSequence(
            remaining: remaining - 1,
            onAllDone: onAllDone,
            onFailure: onFailure,
            preloaded: nextAd,
          );
        }
      }

      if (remaining - 1 > 0) {
        InterstitialAd.load(
          adUnitId: _interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (next) {
              nextAd = next;
              nextLoaded = true;
              if (currentDismissed) {
                proceedToNext();
              }
            },
            onAdFailedToLoad: (_) {
              nextLoaded = true;
              nextAd = null;
              if (currentDismissed) onFailure();
            },
          ),
        );
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _cancelSafetyTimer();
          isAdShowing.value = false;
          currentDismissed = true;
          if (remaining - 1 <= 0) {
            seqAdCurrent.value++;
            onAllDone();
            return;
          }
          if (nextLoaded) {
            if (nextAd != null) {
              proceedToNext();
            } else {
              onFailure();
            }
          }
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          _cancelSafetyTimer();
          isAdShowing.value = false;
          onFailure();
        },
      );
      ad.show();
    }

    if (preloaded != null) {
      showAd(preloaded);
      return;
    }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: showAd,
        onAdFailedToLoad: (_) => onFailure(),
      ),
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _adSafetyTimer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }
}
