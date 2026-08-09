import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/firestore_ad_config_service.dart';

// ── Google's official test IDs — used in DEBUG builds ─────────────────────
const _kTestAppId          = 'ca-app-pub-3940256099942544~3347511713';
const _kTestBannerId       = 'ca-app-pub-3940256099942544/6300978111';
const _kTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

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

    // In release: retrieve IDs fetched dynamically from Cloud Firestore (app_config/admob).
    // If unavailable, return empty strings (ads will remain disabled).
    FirestoreAdConfigService? config;
    try { config = Get.find<FirestoreAdConfigService>(); } catch (_) {}

    final banner       = config?.bannerId.value       ?? '';
    final interstitial = config?.interstitialId.value ?? '';
    final app          = _kTestAppId;

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
