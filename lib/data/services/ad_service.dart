import 'dart:async';
import 'dart:developer' as dev;
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/ads/ads_id_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD SERVICE  —  powered by apsl_admob_ads_flutter
//
//  App ID  : ca-app-pub-8536272432230680~9983882940
//  Publisher: pub-8536272432230680
//
//  [✓] Banner ID       : ca-app-pub-8536272432230680/8012325727
//  [✓] Interstitial ID : ca-app-pub-8536272432230680/2774601057
//  [✓] App ID          : ca-app-pub-8536272432230680~9983882940  (AndroidManifest)
//
//  Safety rules:
//  1. Test IDs in debug, real IDs in release — automatic via SkyBubbleBurstAdsIdManager.
//  2. 60 s frequency cap on AUTO-triggered interstitials (level complete, new best).
//  3. User-initiated interstitials bypass the cap — user asked for the ad.
//  4. Safety timer (5 min) force-resolves if dismiss callback never fires.
//  5. Graceful degradation — never leave the user stuck.
// ═══════════════════════════════════════════════════════════════════════════════

class AdService extends GetxService with WidgetsBindingObserver {

  static const _kInterstitialCooldown = Duration(seconds: 60);
  DateTime _lastInterstitialAt = DateTime(2000);

  // ── Reactive flags consumed by UI ─────────────────────────────────────────
  final RxBool isAdShowing    = false.obs;
  final RxBool isBannerActive = true.obs;  // banner widget uses ApslBannerAd directly

  // ── Sequential-ad progress (reactive for "Ad X of 3" UI) ──────────────────
  final RxInt  seqAdCurrent = 0.obs;
  final RxInt  seqAdTotal   = 0.obs;
  final RxBool seqRunning   = false.obs;

  // ── Safety timer ───────────────────────────────────────────────────────────
  VoidCallback? _pendingOnDismissed;
  Timer?        _safetyTimer;

  // ─────────────────────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<AdService> init() async {
    WidgetsBinding.instance.addObserver(this);

    await ApslAds.instance.initialize(
      const SkyBubbleBurstAdsIdManager(),
      adMobAdRequest: const AdRequest(nonPersonalizedAds: true),
      admobConfiguration: RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      ),
      enableLogger: kDebugMode,
    );

    _logd('AdService ready | mode: ${kReleaseMode ? "RELEASE" : "DEBUG"}');
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APP LIFECYCLE — recover if dismiss callback never fires
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAdShowing.value) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isAdShowing.value) {
          _logd('Safety: force-resolving stuck ad on resume');
          _forceResolveAd();
        }
      });
    }
  }

  void _forceResolveAd() {
    isAdShowing.value = false;
    _safetyTimer?.cancel();
    _safetyTimer = null;
    final cb = _pendingOnDismissed;
    _pendingOnDismissed = null;
    cb?.call();
  }

  void _startSafetyTimer(VoidCallback onDismissed) {
    _safetyTimer?.cancel();
    _pendingOnDismissed = onDismissed;
    _safetyTimer = Timer(const Duration(minutes: 5), () {
      if (isAdShowing.value) {
        _logd('Safety timer fired — force-resolving after 5 min');
        _forceResolveAd();
      }
    });
  }

  void _cancelSafetyTimer() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    _pendingOnDismissed = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FREQUENCY CAP
  // ─────────────────────────────────────────────────────────────────────────

  bool _checkCooldown() {
    final elapsed = DateTime.now().difference(_lastInterstitialAt);
    if (elapsed < _kInterstitialCooldown) {
      _logd('Cooldown active (${elapsed.inSeconds}s) — skipping interstitial');
      return false;
    }
    _lastInterstitialAt = DateTime.now();
    return true;
  }

  void _recordShown() => _lastInterstitialAt = DateTime.now();

  // ─────────────────────────────────────────────────────────────────────────
  //  INTERNAL — show one interstitial via ApslAds, fire callbacks via stream
  // ─────────────────────────────────────────────────────────────────────────

  void _showOneInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    StreamSubscription<AdEvent>? sub;

    void cleanup() {
      sub?.cancel();
      sub = null;
      _cancelSafetyTimer();
      isAdShowing.value = false;
    }

    sub = ApslAds.instance.onEvent.listen((event) {
      if (event.adUnitType != AdUnitType.interstitial) return;
      switch (event.type) {
        case AdEventType.adDismissed:
          _logd('Interstitial dismissed');
          cleanup();
          onDismissed();
          break;
        case AdEventType.adFailedToShow:
          _logd('Interstitial failed to show: ${event.error}');
          cleanup();
          onFailure();
          break;
        case AdEventType.adFailedToLoad:
          _logd('Interstitial failed to load: ${event.error}');
          cleanup();
          onFailure();
          break;
        default:
          break;
      }
    });

    isAdShowing.value = true;
    _startSafetyTimer(() { cleanup(); onDismissed(); });

    final shown = ApslAds.instance.showAd(AdUnitType.interstitial);
    if (!shown) {
      _logd('showAd returned false — no ad ready, loading fresh');
      // No preloaded ad — load one then show
      ApslAds.instance.loadAd();
      // Give it up to 10 s then fallback
      Timer(const Duration(seconds: 10), () {
        final retryShown = ApslAds.instance.showAd(AdUnitType.interstitial);
        if (!retryShown) {
          _logd('Retry also failed — calling onFailure');
          cleanup();
          onFailure();
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — AUTO-TRIGGERED (respects 60 s frequency cap)
  //  Use for: level complete, new best score, gift bubble pop.
  // ─────────────────────────────────────────────────────────────────────────

  void loadAndShowInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    if (!_checkCooldown()) { onDismissed(); return; }
    _showOneInterstitial(onDismissed: onDismissed, onFailure: onFailure);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — USER-INITIATED (bypasses frequency cap)
  //  Use for: earn-award, unlock background/style, extra-heart second chance.
  // ─────────────────────────────────────────────────────────────────────────

  void showInterstitial({required VoidCallback onDismissed}) {
    _recordShown();
    _showOneInterstitial(onDismissed: onDismissed, onFailure: onDismissed);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — SEQUENTIAL (user-initiated earn-coins flow)
  //  Shows [count] interstitials back-to-back, calls [onAllDone] when finished.
  // ─────────────────────────────────────────────────────────────────────────

  void showSequentialInterstitials({
    required int count,
    required VoidCallback onAllDone,
    VoidCallback? onFailure,
  }) {
    seqAdTotal.value   = count;
    seqAdCurrent.value = 0;
    seqRunning.value   = true;
    _logd('Sequential ads started: $count');
    _showNextSequential(
      remaining: count,
      onAllDone: () { seqRunning.value = false; onAllDone(); },
      onFailure: () { seqRunning.value = false; (onFailure ?? onAllDone)(); },
    );
  }

  void _showNextSequential({
    required int remaining,
    required VoidCallback onAllDone,
    required VoidCallback onFailure,
  }) {
    if (remaining <= 0) { onAllDone(); return; }
    _recordShown();
    _showOneInterstitial(
      onDismissed: () {
        seqAdCurrent.value++;
        _showNextSequential(
          remaining: remaining - 1,
          onAllDone: onAllDone,
          onFailure: onFailure,
        );
      },
      onFailure: onFailure,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _safetyTimer?.cancel();
    super.onClose();
  }

  static void _logd(String msg) {
    if (kDebugMode) dev.log('[AdService] $msg', name: 'Ads');
  }
}
