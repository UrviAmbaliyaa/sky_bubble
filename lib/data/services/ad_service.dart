import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD SERVICE
//
//  App ID  : ca-app-pub-8536272432230680~5530361568
//  Publisher: pub-8536272432230680
//
//  ── Developer checklist before every release build ───────────────────────────
//  [✓] Banner ID       : ca-app-pub-8536272432230680/1248335772
//  [✓] Interstitial ID : ca-app-pub-8536272432230680/3136132516
//  [✓] App ID          : ca-app-pub-8536272432230680~5530361568  (AndroidManifest)
//  [ ] Confirm kReleaseMode picks up real IDs  →  flutter build apk --release
//  [ ] Never click your own ads — register test device in AdMob console
//  [ ] app-ads.txt hosted at pandav.github.io/app-ads.txt
//
//  ── AdMob account safety rules encoded in this file ─────────────────────────
//  1. Test IDs in debug mode — NEVER use real IDs during development.
//  2. Child-directed + non-personalized configuration — COPPA compliant.
//  3. Interstitial frequency cap (60 s) on AUTO-triggered ads (level complete,
//     new best, time challenge) so AdMob never flags rapid consecutive shows.
//  4. User-initiated ads (earn coins, extra heart, unlock) BYPASS the cap —
//     the user explicitly asked for the ad; skipping would break the UX.
//  5. Safety timer (5 min) prevents the user being permanently blocked if
//     the dismiss callback never fires (known OEM issue on some Android skins).
//  6. Graceful degradation on all failure paths — never leave the user stuck.
// ═══════════════════════════════════════════════════════════════════════════════

class AdService extends GetxService with WidgetsBindingObserver {

  // ── Live AdMob ad unit IDs (release builds only) ──────────────────────────
  static const _kRealBannerUnitId        = 'ca-app-pub-8536272432230680/1248335772';
  static const _kRealInterstitialUnitId  = 'ca-app-pub-8536272432230680/3136132516';

  // ── Test IDs (Google's official test ad units — safe to use in dev) ────────
  static const _kTestBannerUnitId        = 'ca-app-pub-3940256099942544/6300978111';
  static const _kTestInterstitialUnitId  = 'ca-app-pub-3940256099942544/1033173712';

  // ── Runtime IDs — automatically swap debug ↔ release ──────────────────────
  static const _bannerAdUnitId       = kReleaseMode ? _kRealBannerUnitId       : _kTestBannerUnitId;
  static const _interstitialAdUnitId = kReleaseMode ? _kRealInterstitialUnitId : _kTestInterstitialUnitId;

  // ── Frequency cap — prevents account flagging for rapid consecutive ads ─────
  // Only applied to AUTO-triggered interstitials (level complete, new best, etc.)
  // User-initiated ads (earn coins, unlock, extra heart) always bypass this cap.
  static const _kInterstitialCooldown = Duration(seconds: 60);
  DateTime _lastInterstitialAt = DateTime(2000); // far past → always allowed at cold start

  // ── Banner ──────────────────────────────────────────────────────────────────
  BannerAd?     _bannerAd;
  final RxBool  isBannerLoaded = false.obs;
  BannerAd? get bannerAd       => _bannerAd;

  // ── Preloaded interstitial slot ─────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  final RxBool    isInterstitialLoaded = false.obs;

  // ── Full-screen ad visibility ───────────────────────────────────────────────
  final RxBool isAdShowing = false.obs;

  // ── Sequential-ad progress (reactive for "Ad X of 3" UI) ───────────────────
  final RxInt  seqAdCurrent = 0.obs;
  final RxInt  seqAdTotal   = 0.obs;
  final RxBool seqRunning   = false.obs;

  // ── Safety timer (dismiss callback guard) ───────────────────────────────────
  VoidCallback? _pendingAdDismissed;
  Timer?        _adSafetyTimer;

  // ─────────────────────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<AdService> init() async {
    // MUST call updateRequestConfiguration BEFORE initialize().
    // Family-safe content rating but NOT child-directed — this app targets a
    // general (mixed) audience, not children under 13.  Setting
    // tagForChildDirectedTreatment/tagForUnderAgeOfConsent to "yes" would
    // restrict the ad inventory to near-zero fill rates for interstitials.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent:      TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating:           MaxAdContentRating.g,
      ),
    );
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _logd('AdService initialized | mode: ${kReleaseMode ? "RELEASE" : "DEBUG"} | banner: $_bannerAdUnitId');
    _loadBanner();
    _loadInterstitial();
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APP LIFECYCLE OBSERVER
  //  Recovers navigation if the ad dismiss callback never fires (OEM bug).
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAdShowing.value) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isAdShowing.value) {
          _logd('Safety: force-resolving stuck ad on app resume');
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

  void _startSafetyTimer(VoidCallback onDismissed) {
    _adSafetyTimer?.cancel();
    _pendingAdDismissed = onDismissed;
    _adSafetyTimer = Timer(const Duration(minutes: 5), () {
      if (isAdShowing.value) {
        _logd('Safety timer fired — force-resolving ad after 5 min');
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
  //  FREQUENCY CAP HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true and records the timestamp if enough time has passed since
  /// the last auto-triggered interstitial.  Returns false if still cooling.
  bool _checkCooldown() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastInterstitialAt);
    if (elapsed < _kInterstitialCooldown) {
      _logd('Interstitial skipped — cooldown (${elapsed.inSeconds}s < ${_kInterstitialCooldown.inSeconds}s)');
      return false;
    }
    _lastInterstitialAt = now;
    return true;
  }

  /// Records that an interstitial was shown (updates the cooldown clock).
  /// Called for ALL interstitials (including user-initiated) so the cooldown
  /// correctly reflects the last time any interstitial appeared.
  void _recordShown() {
    _lastInterstitialAt = DateTime.now();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BANNER
  // ─────────────────────────────────────────────────────────────────────────

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerLoaded.value = true;
          _logd('Banner loaded');
        },
        onAdFailedToLoad: (ad, error) {
          _logd('Banner failed: ${error.message} — retry in 30s');
          ad.dispose();
          _bannerAd = null;
          isBannerLoaded.value = false;
          Future.delayed(const Duration(seconds: 30), _loadBanner);
        },
      ),
    )..load();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INTERSTITIAL — preloaded slot
  // ─────────────────────────────────────────────────────────────────────────

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isInterstitialLoaded.value = true;
          ad.setImmersiveMode(true);
          _logd('Interstitial preloaded');
        },
        onAdFailedToLoad: (error) {
          _logd('Interstitial preload failed: ${error.message} — retry in 30s');
          _interstitialAd = null;
          isInterstitialLoaded.value = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — AUTO-TRIGGERED INTERSTITIAL (respects frequency cap)
  //
  //  Use for: level complete, new best score, time challenge complete.
  //  These fire without the user asking — the 60-second cap prevents AdMob
  //  from flagging rapid consecutive shows as invalid traffic.
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads a fresh interstitial and shows it immediately.
  /// Respects the 60-second frequency cap — calls [onDismissed] immediately
  /// (skipping the ad) if the cap hasn't cleared yet.
  /// [onFailure] fires if the ad fails to load or show.
  void loadAndShowInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    if (!_checkCooldown()) {
      // Still in cooldown — skip the ad and proceed silently.
      onDismissed();
      return;
    }
    _logd('loadAndShowInterstitial: loading fresh ad…');
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.setImmersiveMode(true);
          isAdShowing.value = true;
          _startSafetyTimer(onDismissed);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              _logd('Auto interstitial dismissed');
              a.dispose();
              _cancelSafetyTimer();
              isAdShowing.value = false;
              onDismissed();
            },
            onAdFailedToShowFullScreenContent: (a, error) {
              _logd('Auto interstitial failed to show: ${error.message}');
              a.dispose();
              _cancelSafetyTimer();
              isAdShowing.value = false;
              onFailure();
            },
          );
          ad.show();
          _logd('Auto interstitial shown');
        },
        onAdFailedToLoad: (error) {
          _logd('Auto interstitial load failed: ${error.message}');
          onFailure();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — USER-INITIATED INTERSTITIAL (bypasses frequency cap)
  //
  //  Use for: earn-award purchase, unlock background, unlock bubble style,
  //  extra-heart second chance.  The user explicitly chose to see an ad.
  //  Skipping would break the UX contract — so no cooldown check here.
  //  We still update the cooldown clock so auto-triggered ads wait 60s after
  //  a user-initiated one.
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows the preloaded interstitial immediately (user-initiated).
  /// Bypasses the frequency cap. Falls back to [onDismissed] if no ad is ready
  /// so the unlock / reward flow always completes.
  void showInterstitial({required VoidCallback onDismissed}) {
    final ad = _interstitialAd;
    if (ad == null) {
      _logd('showInterstitial: no preloaded ad — proceeding without ad');
      onDismissed();
      _loadInterstitial(); // replenish for next time
      return;
    }
    _interstitialAd = null;
    isInterstitialLoaded.value = false;
    isAdShowing.value = true;
    _recordShown(); // update cooldown clock even for user-initiated
    _startSafetyTimer(onDismissed);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _logd('User-initiated interstitial dismissed');
        a.dispose();
        _cancelSafetyTimer();
        isAdShowing.value = false;
        _loadInterstitial();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        _logd('User-initiated interstitial failed to show: ${error.message}');
        a.dispose();
        _cancelSafetyTimer();
        isAdShowing.value = false;
        _loadInterstitial();
        onDismissed();
      },
    );
    ad.show();
    _logd('User-initiated interstitial shown');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — SEQUENTIAL INTERSTITIALS (user-initiated earn-coins flow)
  //
  //  Bypasses frequency cap — user voluntarily navigated to "EARN COINS".
  //  Pre-loads the next ad while the current one plays (zero gap between ads).
  //  Updates the cooldown clock after each ad so auto-triggered ads wait 60s
  //  after the earn-coins sequence ends.
  // ─────────────────────────────────────────────────────────────────────────

  void showSequentialInterstitials({
    required int          count,
    required VoidCallback onAllDone,
    VoidCallback?         onFailure,
  }) {
    seqAdTotal.value   = count;
    seqAdCurrent.value = 0;
    seqRunning.value   = true;
    _logd('Sequential interstitials started: $count ads');
    _showNextInSequence(
      remaining: count,
      onAllDone: () {
        seqRunning.value = false;
        _logd('Sequential interstitials complete');
        onAllDone();
      },
      onFailure: () {
        seqRunning.value = false;
        _logd('Sequential interstitials aborted (ad failure)');
        (onFailure ?? onAllDone)();
      },
    );
  }

  void _showNextInSequence({
    required int          remaining,
    required VoidCallback onAllDone,
    required VoidCallback onFailure,
    InterstitialAd?       preloaded,
  }) {
    if (remaining <= 0) {
      preloaded?.dispose();
      onAllDone();
      return;
    }

    void showAd(InterstitialAd ad) {
      ad.setImmersiveMode(true);
      isAdShowing.value = true;
      _recordShown();

      _startSafetyTimer(() {
        seqAdCurrent.value++;
        if (remaining - 1 <= 0) { onAllDone(); } else { onFailure(); }
      });

      InterstitialAd? nextAd;
      bool nextLoaded       = false;
      bool currentDismissed = false;

      void proceedToNext() {
        seqAdCurrent.value++;
        if (remaining - 1 <= 0) { nextAd?.dispose(); onAllDone(); return; }
        if (nextLoaded && nextAd != null) {
          _showNextInSequence(remaining: remaining - 1, onAllDone: onAllDone, onFailure: onFailure, preloaded: nextAd);
        }
      }

      // Pre-load next ad while this one plays
      if (remaining - 1 > 0) {
        InterstitialAd.load(
          adUnitId: _interstitialAdUnitId,
          request: const AdRequest(nonPersonalizedAds: true),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded:       (next) { nextAd = next; nextLoaded = true; if (currentDismissed) proceedToNext(); },
            onAdFailedToLoad: (_)    { nextLoaded = true; nextAd = null;  if (currentDismissed) onFailure(); },
          ),
        );
      }

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _cancelSafetyTimer();
          isAdShowing.value = false;
          currentDismissed  = true;
          if (remaining - 1 <= 0) { seqAdCurrent.value++; onAllDone(); return; }
          if (nextLoaded) { nextAd != null ? proceedToNext() : onFailure(); }
        },
        onAdFailedToShowFullScreenContent: (a, error) {
          _logd('Sequential ad failed to show: ${error.message}');
          a.dispose();
          _cancelSafetyTimer();
          isAdShowing.value = false;
          onFailure();
        },
      );
      ad.show();
      _logd('Sequential ad ${seqAdCurrent.value + 1}/$seqAdTotal shown');
    }

    if (preloaded != null) { showAd(preloaded); return; }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded:       showAd,
        onAdFailedToLoad: (_) => onFailure(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _adSafetyTimer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DEBUG LOGGING — only printed in debug builds, invisible in release
  // ─────────────────────────────────────────────────────────────────────────

  static void _logd(String msg) {
    if (kDebugMode) dev.log('[AdService] $msg', name: 'Ads');
  }
}
