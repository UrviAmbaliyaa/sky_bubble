import 'dart:developer' as dev;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  REMOTE AD CONFIG SERVICE
//
//  Fetches all ad flags and AdMob IDs from Firebase Remote Config.
//  Falls back to the hard-coded defaults below when offline or on first launch.
//
//  Remote Config keys (match exactly what is in the Firebase console):
//    ads            – bool  – master gate for standard ads + Earn buttons
//    moreads        – bool  – extra ads (global banner, resume, bg-tap)
//    banner_id      – string
//    interstitial_id– string
//    app_id         – string
// ═══════════════════════════════════════════════════════════════════════════════

class RemoteAdConfigService extends GetxService {
  // ── Hard-coded fallback values (used offline / before first fetch) ──────────
  static const bool   _defaultAds            = true;
  static const bool   _defaultMoreAds        = false;
  static const String _defaultBannerId       = 'ca-app-pub-8536272432230680/8012325727';
  static const String _defaultInterstitialId = 'ca-app-pub-8536272432230680/2774601057';
  static const String _defaultAppId          = 'ca-app-pub-8536272432230680~9983882940';

  // ── Remote Config key names (must match Firebase console exactly) ───────────
  static const _kAds            = 'ads';
  static const _kMoreAds        = 'moreads';
  static const _kBannerId       = 'banner_id';
  static const _kInterstitialId = 'interstitial_id';
  static const _kAppId          = 'app_id';

  // ── Reactive values consumed by the UI ──────────────────────────────────────
  final RxBool   adsEnabled     = _defaultAds.obs;
  final RxBool   moreAdsEnabled = _defaultMoreAds.obs;
  final RxString bannerId       = _defaultBannerId.obs;
  final RxString interstitialId = _defaultInterstitialId.obs;
  final RxString appId          = _defaultAppId.obs;

  // Keep showAds as an alias for adsEnabled so existing call-sites compile.
  RxBool get showAds => adsEnabled;

  late final FirebaseRemoteConfig _rc;

  // ─────────────────────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<RemoteAdConfigService> init() async {
    _rc = FirebaseRemoteConfig.instance;

    // Register in-app defaults so the app works before the first fetch.
    await _rc.setDefaults({
      _kAds:            _defaultAds,
      _kMoreAds:        _defaultMoreAds,
      _kBannerId:       _defaultBannerId,
      _kInterstitialId: _defaultInterstitialId,
      _kAppId:          _defaultAppId,
    });

    // Fetch settings: 1-hour cache in production, no cache in debug.
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout:      const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? Duration.zero
          : const Duration(hours: 1),
    ));

    // Fetch + activate (non-fatal on network error — defaults remain active).
    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      _logd('fetchAndActivate failed (offline?): $e');
    }

    _applyValues();

    // Listen for real-time Remote Config updates (Firebase RC realtime).
    _rc.onConfigUpdated.listen((event) async {
      await _rc.activate();
      _applyValues();
      _logd('Real-time config updated');
    });

    _printConfig();
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APPLY — read activated values into reactive observables
  // ─────────────────────────────────────────────────────────────────────────

  void _applyValues() {
    adsEnabled.value     = _rc.getBool(_kAds);
    moreAdsEnabled.value = _rc.getBool(_kMoreAds);
    bannerId.value       = _rc.getString(_kBannerId).isNotEmpty
        ? _rc.getString(_kBannerId)
        : _defaultBannerId;
    interstitialId.value = _rc.getString(_kInterstitialId).isNotEmpty
        ? _rc.getString(_kInterstitialId)
        : _defaultInterstitialId;
    appId.value          = _rc.getString(_kAppId).isNotEmpty
        ? _rc.getString(_kAppId)
        : _defaultAppId;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DEBUG LOGGING
  // ─────────────────────────────────────────────────────────────────────────

  void _printConfig() {
    if (!kDebugMode) return;
    final sep = '═' * 52;
    dev.log(sep, name: 'AdConfig');
    dev.log('  FIREBASE REMOTE CONFIG VALUES', name: 'AdConfig');
    dev.log(sep, name: 'AdConfig');
    dev.log('  ads          : ${adsEnabled.value}', name: 'AdConfig');
    dev.log('  moreads      : ${moreAdsEnabled.value}', name: 'AdConfig');
    dev.log('  banner_id    : ${bannerId.value}', name: 'AdConfig');
    dev.log('  interstitial : ${interstitialId.value}', name: 'AdConfig');
    dev.log('  app_id       : ${appId.value}', name: 'AdConfig');
    dev.log(sep, name: 'AdConfig');
  }

  static void _logd(String msg) {
    if (kDebugMode) dev.log(msg, name: 'AdConfig');
  }
}
