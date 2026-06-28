import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../core/services/navigation_service.dart';
import '../core/theme/app_theme.dart';
import '../presentation/widgets/force_update_overlay.dart';
import '../presentation/widgets/global_banner_widget.dart';
import '../presentation/widgets/no_internet_overlay.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

// White status bar icons on every screen — enforced at root level so no
// individual screen or navigation event can override it.
const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

class BubblePopApp extends StatelessWidget {
  const BubblePopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: FlutterSizer(
        builder: (context, orientation, deviceType) => GetMaterialApp(
          title: 'Sky Bubble Burst',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          debugShowCheckedModeBanner: false,
          defaultTransition: Transition.fadeIn,
          navigatorObservers: [AppRouteObserver()],
          builder: (context, child) => ForceUpdateOverlay(
            child: NoInternetOverlay(
              child: GlobalBannerWidget(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

