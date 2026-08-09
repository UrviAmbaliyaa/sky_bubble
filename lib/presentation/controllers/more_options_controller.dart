import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../widgets/not_enough_coins_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  MORE OPTIONS CONTROLLER
//
//  All navigation and business logic for the More Options screen.
//  The screen itself is pure UI — no logic lives there.
// ═══════════════════════════════════════════════════════════════════════════════

// ── Replace with your hosted privacy policy URL ────────────────────────────
const _kPrivacyPolicyUrl = 'https://sarav-dev.blogspot.com/2026/07/privacy-policy-sky-bubble-burst.html';

class MoreOptionsController extends GetxController {
  // ── Reactive state ─────────────────────────────────────────────────────────

  int get coins => Get.find<StyleService>().totalCoins.value;

  bool get canAffordAward =>
      Get.find<StyleService>().totalCoins.value >= StyleService.awardPurchaseCost;

  final RxBool isBuyingAward = false.obs;

  // ── Navigation ──────────────────────────────────────────────────────────────

  void navigateToLevels()      => Get.toNamed(AppRoutes.levels);
  void navigateToBackground()  => Get.toNamed(AppRoutes.backgroundStyle);
  void navigateToEarnCoins()   => Get.toNamed(AppRoutes.adWatch);
  void navigateToBubbleStyle() => Get.toNamed(AppRoutes.bubbleStyle);

  void navigateToSettings() {
    Get.snackbar('Settings', 'Coming soon!', snackPosition: SnackPosition.TOP);
  }

  void navigateToHelpSupport() {
    Get.snackbar('Help & Support', 'Coming soon!', snackPosition: SnackPosition.TOP);
  }

  Future<void> navigateToPrivacyPolicy() async {
    final uri = Uri.parse(_kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Privacy Policy',
        _kPrivacyPolicyUrl,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
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
    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final adsOn = remote?.adsEnabled.value ?? false;

    void complete() {
      final ok = styleSvc.purchaseAwardWithCoins();
      isBuyingAward.value = false;
      if (ok) {
        Get.snackbar(
          '+1 Award Earned! 🏆',
          '${StyleService.awardPurchaseCost} coins spent — award added!',
          snackPosition: SnackPosition.TOP,
        );
      }
    }

    if (adsOn) {
      Get.find<AdService>().showInterstitial(onDismissed: complete);
    } else {
      complete();
    }
  }
}
