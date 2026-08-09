import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/remote_ad_config_service.dart';

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

    // In release: retrieve IDs fetched dynamically from Firebase Remote Config.
    // If unavailable, return empty strings (ads will remain disabled).
    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}

    final banner       = remote?.bannerId.value       ?? '';
    final interstitial = remote?.interstitialId.value ?? '';
    final app          = remote?.appId.value          ?? '';

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
