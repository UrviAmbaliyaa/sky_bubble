import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController loadCtrl;
  late final Animation<double> loadAnim;

  @override
  void onInit() {
    super.onInit();
    loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
    loadAnim = CurvedAnimation(parent: loadCtrl, curve: Curves.easeInOut);
  }

  @override
  void onReady() {
    super.onReady();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(milliseconds: 3400), () {
      Get.offAllNamed(AppRoutes.home);
    });
  }

  @override
  void onClose() {
    loadCtrl.dispose();
    super.onClose();
  }
}
