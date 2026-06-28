import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Tracks the current route name reactively so widgets can conditionally
/// show/hide based on which screen is visible.
class NavigationService extends GetxService {
  final RxString currentRoute = ''.obs;
}

/// NavigatorObserver wired into GetMaterialApp.navigatorObservers.
class AppRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final name = route?.settings.name ?? '';
    try {
      Get.find<NavigationService>().currentRoute.value = name;
    } catch (_) {}
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _update(newRoute);
}
