import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/navigation_service.dart';
import '../../core/services/remote_ad_config_service.dart';

/// Persistent bottom banner shown on every screen when moreads=true,
/// except Home and Splash (excluded via NavigationService).
///
/// Uses Stack + Positioned so the banner sits on top of content without
/// fighting the Navigator's full-screen MediaQuery sizing.
/// MediaQuery.padding.bottom is increased so screens that respect SafeArea
/// automatically avoid being obscured by the banner.
class GlobalBannerWidget extends StatelessWidget {
  final Widget child;
  const GlobalBannerWidget({super.key, required this.child});

  static const double _bannerHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    final remote = Get.find<RemoteAdConfigService>();
    final navSvc = Get.find<NavigationService>();
    return Obx(() {
      final adsOn       = remote.adsEnabled.value;   // ads field — master gate
      final moreAds     = remote.moreAdsEnabled.value;
      final validConfig = remote.hasValidAdConfig;
      final route       = navSvc.currentRoute.value;

      // No bottom banner on home, splash, game screen, or before first nav.
      // Game screen has its own top banner — a second bottom banner is unwanted.
      final isExcluded = route == AppRoutes.home
          || route == AppRoutes.splash
          || route == AppRoutes.game
          || route.isEmpty;

      // Global banner: ads=true AND moreads=true AND validConfig.
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
