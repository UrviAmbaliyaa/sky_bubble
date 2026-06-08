import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD SERVICE
//
//  ⚠️  BEFORE RELEASE: replace every test ID below with your real AdMob IDs.
// ═══════════════════════════════════════════════════════════════════════════════

class AdService extends GetxService {
  // ── Test Ad Unit IDs (Android) — swap before release ──────────────────────
  static const _bannerAdUnitId       = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

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
  final RxInt  seqAdCurrent = 0.obs;   // how many ads shown so far in this sequence
  final RxInt  seqAdTotal   = 0.obs;   // total ads in the current sequence
  final RxBool seqRunning   = false.obs;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<AdService> init() async {
    await MobileAds.instance.initialize();
    _loadBanner();
    _loadInterstitial();
    return this;
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
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              isAdShowing.value = false;
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (a, _) {
              a.dispose();
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
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        isAdShowing.value = false;
        _loadInterstitial();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
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
    InterstitialAd? preloaded,   // pass already-loaded ad to show instantly
  }) {
    if (remaining <= 0) {
      preloaded?.dispose();
      onAllDone();
      return;
    }

    void showAd(InterstitialAd ad) {
      ad.setImmersiveMode(true);
      isAdShowing.value = true;

      // Start loading the NEXT ad immediately while this one is on screen.
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
        // If nextAd not ready yet, proceedToNext was called early — the
        // onAdLoaded callback below will fire and call _showNextInSequence.
      }

      // Kick off the pre-load of ad N+1.
      if (remaining - 1 > 0) {
        InterstitialAd.load(
          adUnitId: _interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (next) {
              nextAd = next;
              nextLoaded = true;
              if (currentDismissed) {
                // Current ad already dismissed — show next immediately.
                proceedToNext();
              }
            },
            onAdFailedToLoad: (_) {
              if (currentDismissed) onFailure();
              // else: set a flag and handle in dismiss callback
              nextLoaded = true; // mark as "done" so dismiss knows to fail
              nextAd = null;
            },
          ),
        );
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
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
              // Next ad failed to load
              onFailure();
            }
          }
          // If nextLoaded is false, the preload callback will call proceedToNext.
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
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

    // No preloaded ad — load fresh (first ad in sequence).
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
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }
}
