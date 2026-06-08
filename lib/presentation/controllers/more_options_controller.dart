import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../widgets/not_enough_coins_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  MORE OPTIONS CONTROLLER
//
//  All navigation and business logic for the More Options screen.
//  The screen itself is pure UI — no logic lives there.
// ═══════════════════════════════════════════════════════════════════════════════

class MoreOptionsController extends GetxController {
  // ── Reactive state ─────────────────────────────────────────────────────────

  /// Coins balance — kept reactive so the Earn Award row live-updates.
  int get coins => Get.find<StyleService>().totalCoins.value;

  bool get canAffordAward =>
      Get.find<StyleService>().totalCoins.value >= StyleService.awardPurchaseCost;

  final RxBool isBuyingAward = false.obs;

  // ── Navigation ──────────────────────────────────────────────────────────────

  void navigateToLevels()     => Get.toNamed(AppRoutes.levels);
  void navigateToBackground() => Get.toNamed(AppRoutes.backgroundStyle);
  void navigateToEarnCoins()  => Get.toNamed(AppRoutes.adWatch);
  void navigateToBubbleStyle()=> Get.toNamed(AppRoutes.bubbleStyle);

  void navigateToSettings() {
    // Settings screen placeholder — wire to real route when ready.
    Get.snackbar(
      'Settings',
      'Coming soon!',
      snackPosition: SnackPosition.TOP,
    );
  }

  void navigateToHelpSupport() {
    Get.snackbar(
      'Help & Support',
      'Coming soon!',
      snackPosition: SnackPosition.TOP,
    );
  }

  // ── Earn Award ──────────────────────────────────────────────────────────────

  void buyAwardWithCoins() {
    if (isBuyingAward.value) return;
    final styleSvc = Get.find<StyleService>();

    if (styleSvc.totalCoins.value < StyleService.awardPurchaseCost) {
      NotEnoughCoinsDialog.show(
        currentCoins: styleSvc.totalCoins.value,
        onWatchAds:   navigateToEarnCoins,
      );
      return;
    }

    isBuyingAward.value = true;
    Get.find<AdService>().showInterstitial(onDismissed: () {
      final ok = styleSvc.purchaseAwardWithCoins();
      isBuyingAward.value = false;
      if (ok) {
        Get.snackbar(
          '+1 Award Earned! 🏆',
          '${StyleService.awardPurchaseCost} coins spent — award added!',
          snackPosition: SnackPosition.TOP,
        );
      }
    });
  }
}
