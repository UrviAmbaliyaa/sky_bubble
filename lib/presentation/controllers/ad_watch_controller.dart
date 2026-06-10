import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD WATCH CONTROLLER
//
//  Flow:
//    onReady → showSequentialInterstitials(3)
//      Ad 1 shows → (next ad pre-loads in background while Ad 1 plays)
//      Ad 1 dismissed → Ad 2 shows instantly (already loaded)
//      Ad 2 dismissed → Ad 3 shows instantly (already loaded)
//      Ad 3 dismissed → _finish() → navigate home + reward coins
//
//  The background screen is intentionally minimal (black + spinner) so the
//  user's full attention stays on the ad itself.  No timer, text or progress
//  is shown on the screen — AdMob renders its own skip/close timer on the ad.
// ═══════════════════════════════════════════════════════════════════════════════

class AdWatchController extends GetxController {
  static const int totalAds   = 3;
  static const int coinReward = 3;

  // Only one flag needed: is the controller still waiting / running?
  // True from onReady until all ads complete or user cancels.
  final RxBool isRunning = true.obs;

  @override
  void onReady() {
    super.onReady();
    _startSequence();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// User pressed back — abort the sequence and pop.
  void cancel() {
    isRunning.value = false;
    Get.back();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _startSequence() {
    Get.find<AdService>().showSequentialInterstitials(
      count:      totalAds,
      onAllDone:  _finish,
      // On any ad failure abort silently and go back — don't leave user stuck.
      onFailure: () {
        if (!isRunning.value) return;
        isRunning.value = false;
        Get.back();
        Get.snackbar(
          'Ad unavailable',
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
    if (!isRunning.value) return;
    isRunning.value = false;
    Get.find<StyleService>().addCoins(coinReward);
    // Navigate to home, clearing the entire back stack so the user is never
    // stranded. Get.until() can silently pop everything if the home route
    // isn't found; Get.offAllNamed() always lands on home unconditionally.
    Get.offAllNamed(AppRoutes.home, arguments: {'skipAnimation': true});
    Get.snackbar(
      '+$coinReward Coins Earned! 🪙',
      'Thanks for watching — enjoy your coins!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFD700),
      colorText: Colors.black87,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
