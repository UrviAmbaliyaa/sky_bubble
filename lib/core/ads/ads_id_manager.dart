import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/remote_ad_config_service.dart';

// ── Google's official test IDs — used in DEBUG builds ─────────────────────
const _kTestAppId          = 'ca-app-pub-3940256099942544~3347511713';
const _kTestBannerId       = 'ca-app-pub-3940256099942544/6300978111';
const _kTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

// ── Hard-coded prod fallback (also stored in RemoteAdConfigService) ────────
const _kProdAppId          = 'ca-app-pub-8028748386746773~3717080813';
const _kProdBannerId       = 'ca-app-pub-8028748386746773/2020855764';
const _kProdInterstitialId = 'ca-app-pub-8028748386746773/4922231132';

class SkyBubbleBurstAdsIdManager extends AdsIdManager {
  const SkyBubbleBurstAdsIdManager();

  @override
  List<AppAdIds> get appAdIds {
    // In debug mode always use Google's test IDs.
    if (kDebugMode) {
      return [
        AppAdIds(
          adNetwork:      AdNetwork.admob,
          appId:          _kTestAppId,
          bannerId:       _kTestBannerId,
          interstitialId: _kTestInterstitialId,
        ),
      ];
    }

    // In release: prefer IDs fetched from Firebase (with local-storage fallback).
    // If the service isn't registered yet (shouldn't happen), use hard-coded prod IDs.
    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}

    final banner       = remote?.bannerId.value       ?? _kProdBannerId;
    final interstitial = remote?.interstitialId.value ?? _kProdInterstitialId;
    final app          = remote?.appId.value          ?? _kProdAppId;

    return [
      AppAdIds(
        adNetwork:      AdNetwork.admob,
        appId:          app,
        bannerId:       banner,
        interstitialId: interstitial,
      ),
    ];
  }
}
