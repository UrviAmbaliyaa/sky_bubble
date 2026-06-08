import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD WATCH CONTROLLER
//
//  Owns ALL logic for the "watch 3 ads → earn 3 coins" flow.
//  AdWatchScreen only reads reactive state; it contains zero business logic.
// ═══════════════════════════════════════════════════════════════════════════════

class AdWatchController extends GetxController {
  static const int totalAds  = 3;
  static const int coinReward = 3;

  // ── Reactive state (screen observes these) ────────────────────────────────
  final RxInt  adsCompleted = 0.obs;   // 0 … totalAds
  final RxBool isLoading    = true.obs; // waiting for next ad to load
  final RxBool isCancelled  = false.obs;

  @override
  void onReady() {
    super.onReady();
    _showNextAd();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void cancel() {
    isCancelled.value = true;
    Get.back();
  }

  // ── Private logic ──────────────────────────────────────────────────────────

  void _showNextAd() {
    if (isCancelled.value) return;
    if (adsCompleted.value >= totalAds) {
      _finish();
      return;
    }

    isLoading.value = true;

    Get.find<AdService>().loadAndShowInterstitial(
      onDismissed: () {
        if (isCancelled.value) return;
        adsCompleted.value++;
        if (adsCompleted.value >= totalAds) {
          _finish();
        } else {
          isLoading.value = false;
          _showNextAd();
        }
      },
      onFailure: () {
        if (isCancelled.value) return;
        isLoading.value = false;
        Get.back();
        Get.snackbar(
          'Ad not available',
          'Please try again in a moment.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.grey.shade800,
          colorText: Colors.white,
          borderRadius: 16,
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }

  void _finish() {
    Get.find<StyleService>().addCoins(coinReward);
    Get.until((route) => route.settings.name == AppRoutes.home);
    Get.snackbar(
      '+$coinReward Coins Earned!',
      'Thanks for watching all $totalAds ads!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFD700),
      colorText: Colors.black87,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
