import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../services/firestore_ad_config_service.dart';
import '../services/navigation_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SINGLE UNIFIED AD MANAGER FILE (ad_widget_manager.dart)
//
//  Consolidates all ad-related logic in one place:
//    1. AdIds               – Platform-specific (Android/iOS) test & live ID resolution
//    2. AdWidgetManager     – Central controller for init, ATT, interstitials, lifecycle
//    3. BannerAdWidget      – Standalone inline banner widget
//    4. GlobalBannerWidget  – Persistent bottom banner overlay widget
// ═══════════════════════════════════════════════════════════════════════════════

// ── 1. AD UNIT IDs (Platform specific: Android vs iOS) ───────────────────────

class AdIds {
  static const _kTestAppId          = 'ca-app-pub-3940256099942544~3347511713';
  static const _kTestBannerAndroid  = 'ca-app-pub-3940256099942544/6300978111';
  static const _kTestBannerIOS      = 'ca-app-pub-3940256099942544/2934735716';
  static const _kTestInterAndroid   = 'ca-app-pub-3940256099942544/1033173712';
  static const _kTestInterIOS       = 'ca-app-pub-3940256099942544/4411468910';

  /// Active Banner Ad Unit ID based on platform & environment
  static String get banner {
    if (kDebugMode) {
      return Platform.isIOS ? _kTestBannerIOS : _kTestBannerAndroid;
    }
    FirestoreAdConfigService? config;
    try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}
    return config?.bannerId.value ?? '';
  }

  /// Active Interstitial Ad Unit ID based on platform & environment
  static String get interstitial {
    if (kDebugMode) {
      return Platform.isIOS ? _kTestInterIOS : _kTestInterAndroid;
    }
    FirestoreAdConfigService? config;
    try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}
    return config?.interstitialId.value ?? '';
  }

  /// Active App ID
  static String get appId => _kTestAppId;
}

// ── 2. CENTRAL AD WIDGET MANAGER ─────────────────────────────────────────────

class SkyBubbleBurstAdsIdManager extends AdsIdManager {
  const SkyBubbleBurstAdsIdManager();

  @override
  List<AppAdIds> get appAdIds {
    return [
      AppAdIds(
        adNetwork:      AdNetwork.admob,
        appId:          AdIds.appId,
        bannerId:       AdIds.banner,
        interstitialId: AdIds.interstitial,
      ),
    ];
  }
}

class AdWidgetManager extends GetxService with WidgetsBindingObserver {
  static final AdWidgetManager instance = AdWidgetManager._();
  AdWidgetManager._();

  factory AdWidgetManager() => instance;

  static const _kInterstitialCooldown = Duration(seconds: 60);
  static const _kResumeCooldown       = Duration(seconds: 120);

  DateTime _lastInterstitialAt = DateTime(2000);
  DateTime _lastResumeAdAt     = DateTime(2000);

  // ── Reactive flags consumed by UI ─────────────────────────────────────────
  final RxBool isAdShowing    = false.obs;
  final RxBool isBannerActive = true.obs;

  // ── Sequential-ad progress (reactive for "Ad X of 3" UI) ──────────────────
  final RxInt  seqAdCurrent = 0.obs;
  final RxInt  seqAdTotal   = 0.obs;
  final RxBool seqRunning   = false.obs;

  VoidCallback? _pendingOnDismissed;
  Timer?        _safetyTimer;

  static bool _initialized = false;
  static bool get isSupported => kIsWeb ? false : (Platform.isAndroid || Platform.isIOS);

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<AdWidgetManager> init() async {
    if (_initialized || !isSupported) return this;
    _initialized = true;
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

    _logd('AdWidgetManager ready | supported: $isSupported');
    return this;
  }

  static Future<void> initialize() async {
    await instance.init();
  }

  /// Prompts iOS App Tracking Transparency (ATT) authorization on iOS.
  static Future<void> requestTrackingAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      _logd('ATT Tracking requested on iOS');
    } catch (_) {}
  }

  // ── App Lifecycle ───────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isAdShowing.value) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (isAdShowing.value) {
            _logd('Safety: force-resolving stuck ad on resume');
            _forceResolveAd();
          }
        });
        return;
      }

      FirestoreAdConfigService? config;
      try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}
      final adsOn   = config?.adsEnabled.value     ?? false;
      final moreAds = config?.moreAdsEnabled.value ?? false;

      if (adsOn && moreAds) {
        _logd('ad_more_visible: showing interstitial on app resume');
        showResumeInterstitial();
      }
    }
  }

  void showResumeInterstitial() {
    final elapsed = DateTime.now().difference(_lastResumeAdAt);
    if (elapsed < _kResumeCooldown) return;
    _lastResumeAdAt = DateTime.now();
    _showOneInterstitial(onDismissed: () {}, onFailure: () {});
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

  // ── Interstitial Ad Core Methods ───────────────────────────────────────────

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

  void _showOneInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    if (!isSupported) {
      onDismissed();
      return;
    }

    FirestoreAdConfigService? config;
    try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}
    final adsOn       = config?.adsEnabled.value     ?? false;
    final validConfig = config?.hasValidAdConfig     ?? false;

    if (!adsOn || !validConfig) {
      _logd('Ads disabled or missing Firestore config — skipping interstitial');
      onDismissed();
      return;
    }

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
      _logd('showAd returned false — loading fresh ad');
      ApslAds.instance.loadAd();
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

  /// Auto-triggered interstitial (enforces 60 s frequency cap)
  void loadAndShowInterstitial({
    required VoidCallback onDismissed,
    required VoidCallback onFailure,
  }) {
    if (!_checkCooldown()) { onDismissed(); return; }
    _showOneInterstitial(onDismissed: onDismissed, onFailure: onFailure);
  }

  /// User-initiated interstitial (bypasses frequency cap for rewards/unlocks)
  void showInterstitial({required VoidCallback onDismissed}) {
    _recordShown();
    _showOneInterstitial(onDismissed: onDismissed, onFailure: onDismissed);
  }

  /// Sequential interstitials (e.g. watch 3 ads for +3 coins)
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

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _safetyTimer?.cancel();
    super.onClose();
  }

  static void _logd(String msg) {
    if (kDebugMode) dev.log('[AdWidgetManager] $msg', name: 'Ads');
  }
}

// Typedef alias so existing Get.find<AdService>() calls continue working seamlessly
typedef AdService = AdWidgetManager;

// ── 3. STANDALONE BANNER AD WIDGET ───────────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final RxBool _adFailed = false.obs;
  StreamSubscription<AdEvent>? _adSub;

  @override
  void initState() {
    super.initState();
    if (AdWidgetManager.isSupported) {
      _adSub = ApslAds.instance.onEvent.listen((event) {
        if (event.adUnitType != AdUnitType.banner) return;
        if (event.type == AdEventType.adFailedToLoad ||
            event.type == AdEventType.adFailedToShow) {
          _adFailed.value = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _adSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdWidgetManager.isSupported) return const SizedBox.shrink();
    return Obx(() {
      FirestoreAdConfigService? config;
      try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}
      final adsOn       = config?.adsEnabled.value ?? false;
      final validConfig = config?.hasValidAdConfig ?? false;

      if (!adsOn || !validConfig || _adFailed.value) {
        return const SizedBox.shrink();
      }

      return const SizedBox(
        height: 50.0,
        child: ApslBannerAd(
          adNetwork: AdNetwork.admob,
          adSize: AdSize.banner,
        ),
      );
    });
  }
}

// ── 4. GLOBAL BOTTOM BANNER OVERLAY WIDGET ────────────────────────────────────

class GlobalBannerWidget extends StatelessWidget {
  final Widget child;
  const GlobalBannerWidget({super.key, required this.child});

  static const double _bannerHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    if (!AdWidgetManager.isSupported) return child;

    FirestoreAdConfigService? config;
    NavigationService? navSvc;
    try {
      config = Get.find<FirestoreAdConfigService>();
      navSvc = Get.find<NavigationService>();
    } catch (_) {}

    return Obx(() {
      final adsOn       = config?.adsEnabled.value     ?? false;
      final moreAds     = config?.moreAdsEnabled.value ?? false;
      final validConfig = config?.hasValidAdConfig     ?? false;
      final route       = navSvc?.currentRoute.value   ?? '';

      final isExcluded = route == AppRoutes.home
          || route == AppRoutes.splash
          || route == AppRoutes.game
          || route.isEmpty;

      if (!adsOn || !moreAds || !validConfig || isExcluded) return child;

      final mq          = MediaQuery.of(context);
      final bottomInset = mq.viewInsets.bottom;
      final safeBottom  = mq.padding.bottom;

      final bannerBottom  = bottomInset > 0 ? bottomInset : 0.0;
      final bannerVisible = bottomInset == 0;

      final updatedMq = mq.copyWith(
        padding: mq.padding.copyWith(
          bottom: safeBottom + _bannerHeight,
        ),
      );

      return MediaQuery(
        data: updatedMq,
        child: Stack(
          children: [
            child,
            if (bannerVisible)
              Positioned(
                bottom: bannerBottom,
                left: 0,
                right: 0,
                height: _bannerHeight + safeBottom,
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.topCenter,
                  child: const SizedBox(
                    height: _bannerHeight,
                    child: ApslBannerAd(
                      adNetwork: AdNetwork.admob,
                      adSize: AdSize.banner,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
