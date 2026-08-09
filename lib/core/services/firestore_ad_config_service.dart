import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  FIRESTORE AD CONFIG SERVICE
//
//  Fetches all ad flags and AdMob IDs from Cloud Firestore (app_config/admob).
//  Document structure:
//    ad_visible          – bool   – master gate for ads
//    ad_more_visible     – bool   – extra ads toggle (global banner, resume)
//    ad_live_mode        – bool   – live ad mode flag
//    android_banner      – string – AdMob Banner ID for Android
//    android_interstitial – string – AdMob Interstitial ID for Android
//    ios_banner          – string – AdMob Banner ID for iOS
//    ios_interstitial    – string – AdMob Interstitial ID for iOS
// ═══════════════════════════════════════════════════════════════════════════════

class FirestoreAdConfigService extends GetxService {
  // ── Firestore field names (matches Firestore console exactly) ───────────────
  static const _kCollection          = 'app_config';
  static const _kDocAdmob            = 'admob';

  static const _kAdVisible           = 'ad_visible';
  static const _kAdMoreVisible       = 'ad_more_visible';
  static const _kAdLiveMode          = 'ad_live_mode';
  static const _kAndroidBanner       = 'android_banner';
  static const _kAndroidInterstitial = 'android_interstitial';
  static const _kIosBanner           = 'ios_banner';
  static const _kIosInterstitial     = 'ios_interstitial';

  // ── Reactive values consumed by the UI ──────────────────────────────────────
  final RxBool   adsEnabled     = false.obs;
  final RxBool   moreAdsEnabled = false.obs;
  final RxBool   adLiveMode     = false.obs;
  final RxString bannerId       = ''.obs;
  final RxString interstitialId = ''.obs;

  // Keep showAds as an alias for adsEnabled so existing call-sites compile seamlessly.
  RxBool get showAds => (adsEnabled.value && hasValidAdConfig).obs;

  /// Returns true if required AdMob IDs are non-empty (in debug mode, test IDs are used).
  bool get hasValidAdConfig {
    if (kDebugMode) return true;
    return bannerId.value.trim().isNotEmpty &&
        interstitialId.value.trim().isNotEmpty;
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  // ─────────────────────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<FirestoreAdConfigService> init() async {
    final docRef = FirebaseFirestore.instance
        .collection(_kCollection)
        .doc(_kDocAdmob);

    // Initial fetch with timeout/error catch so app startup is never blocked
    try {
      final snap = await docRef.get().timeout(const Duration(seconds: 5));
      if (snap.exists && snap.data() != null) {
        _applyData(snap.data()!);
      }
    } catch (e) {
      _logd('Initial Firestore ad_config fetch failed / offline: $e');
    }

    // Listen for real-time document updates
    _subscription = docRef.snapshots().listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          _applyData(snap.data()!);
          _logd('Real-time Firestore ad config updated');
        }
      },
      onError: (e) => _logd('Firestore snapshot listener error: $e'),
    );

    _printConfig();
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APPLY DATA — parse Firestore fields & select platform IDs
  // ─────────────────────────────────────────────────────────────────────────

  void _applyData(Map<String, dynamic> data) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    final rawAdVisible   = data[_kAdVisible] as bool? ?? false;
    moreAdsEnabled.value = data[_kAdMoreVisible] as bool? ?? false;
    adLiveMode.value     = data[_kAdLiveMode] as bool? ?? false;

    if (isAndroid) {
      bannerId.value       = data[_kAndroidBanner] as String? ?? '';
      interstitialId.value = data[_kAndroidInterstitial] as String? ?? '';
    } else {
      bannerId.value       = data[_kIosBanner] as String? ?? '';
      interstitialId.value = data[_kIosInterstitial] as String? ?? '';
    }

    // Disable ads if required platform IDs are missing in release mode
    if (!kDebugMode && !hasValidAdConfig) {
      adsEnabled.value = false;
    } else {
      adsEnabled.value = rawAdVisible;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DEBUG LOGGING & CLEANUP
  // ─────────────────────────────────────────────────────────────────────────

  void _printConfig() {
    if (!kDebugMode) return;
    final sep = '═' * 52;
    dev.log(sep, name: 'AdConfig');
    dev.log('  FIRESTORE AD CONFIG VALUES (app_config/admob)', name: 'AdConfig');
    dev.log(sep, name: 'AdConfig');
    dev.log('  ad_visible          : ${adsEnabled.value}', name: 'AdConfig');
    dev.log('  ad_more_visible     : ${moreAdsEnabled.value}', name: 'AdConfig');
    dev.log('  ad_live_mode        : ${adLiveMode.value}', name: 'AdConfig');
    dev.log('  active_banner       : ${bannerId.value}', name: 'AdConfig');
    dev.log('  active_interstitial  : ${interstitialId.value}', name: 'AdConfig');
    dev.log(sep, name: 'AdConfig');
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  static void _logd(String msg) {
    if (kDebugMode) dev.log(msg, name: 'AdConfig');
  }
}
