import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/foundation.dart';

// ── Real AdMob IDs ──────────────────────────────────────────────────────────
// const _kAppId          = 'ca-app-pub-8536272432230680~9983882940';
// const _kBannerId       = 'ca-app-pub-8536272432230680/8012325727';
// const _kInterstitialId = 'ca-app-pub-8536272432230680/2774601057';

// ── Google's official test IDs — safe during development ──────────────────
const _kTestAppId          = 'ca-app-pub-3940256099942544~3347511713';
const _kTestBannerId       = 'ca-app-pub-3940256099942544/6300978111';
const _kTestInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

class SkyBubbleBurstAdsIdManager extends AdsIdManager {
  const SkyBubbleBurstAdsIdManager();

  @override
  List<AppAdIds> get appAdIds => [
        AppAdIds(
          adNetwork: AdNetwork.admob,
          appId:           _kTestAppId,
          bannerId:       _kTestBannerId,
          interstitialId:  _kTestInterstitialId,
        ),
      ];
}
