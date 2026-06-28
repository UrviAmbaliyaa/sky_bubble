import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../../domain/usecases/score_usecases.dart';
import '../widgets/not_enough_coins_dialog.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final GetScoresUseCase _getScores;
  HomeController(this._getScores);

  // ── Stats ──────────────────────────────────────────────────────────────────
  final RxInt bestScore        = 0.obs;
  final RxInt totalGamesPlayed = 0.obs;
  final RxInt todayGamesCount  = 0.obs;
  final RxInt todayTotalScore  = 0.obs;
  final RxInt weekGamesCount   = 0.obs;
  final RxInt weekTotalScore   = 0.obs;
  final RxList<int> weekDayScores = <int>[0, 0, 0, 0, 0, 0, 0].obs;

  // ── Celebration popup ─────────────────────────────────────────────────────
  // Shown when the player achieves a new personal best.
  final RxBool showCelebration  = false.obs;
  final RxInt  celebrationScore = 0.obs;

  // ── Entry animation (fade + slide) ────────────────────────────────────────
  late final AnimationController entryAnimCtrl;
  late final Animation<double>   fadeAnim;
  late final Animation<Offset>   slideAnim;

  // ── Play-button pulse ──────────────────────────────────────────────────────
  late final AnimationController pulseCtrl;
  late final Animation<double>   pulseAnim;


  @override
  void onInit() {
    super.onInit();
    _initAnimations();
  }

  @override
  void onReady() {
    super.onReady();
    _loadStats();
    // When the screen is recreated after Get.offAllNamed (navigateHome path),
    // check the route arguments for the last game's score.
    _checkCelebrationFromArgs();
  }

  @override
  void onClose() {
    _disposeAnimations();
    super.onClose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _initAnimations() {
    entryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    fadeAnim  = CurvedAnimation(parent: entryAnimCtrl, curve: Curves.easeOut);
    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: entryAnimCtrl, curve: Curves.easeOutCubic));

    // Skip the entry animation when returning from game or earn-coins screens.
    final args = Get.arguments;
    final skipAnim = args is Map &&
        (args['fromGame'] == true || args['skipAnimation'] == true);
    if (skipAnim) {
      entryAnimCtrl.value = 1.0; // jump to full opacity — no animation
    } else {
      entryAnimCtrl.forward(); // normal 900 ms fade-in on first open
    }

    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    pulseAnim = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut));
  }

  void _disposeAnimations() {
    entryAnimCtrl.dispose();
    pulseCtrl.dispose();
  }

  void _loadStats() {
    final scores = _getScores();
    totalGamesPlayed.value = scores.length;
    bestScore.value =
        scores.isEmpty ? 0 : scores.map((s) => s.score).reduce(math.max);

    final now        = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd   = todayStart.add(const Duration(days: 1));

    final todayScores = scores
        .where((s) => !s.playedAt.isBefore(todayStart) && s.playedAt.isBefore(todayEnd))
        .toList();
    todayGamesCount.value = todayScores.length;
    todayTotalScore.value = todayScores.fold(0, (s, e) => s + e.score);

    final weekStart = todayStart.subtract(Duration(days: (now.weekday - 1) % 7));
    final weekEnd   = weekStart.add(const Duration(days: 7));
    final weekScores = scores
        .where((s) => !s.playedAt.isBefore(weekStart) && s.playedAt.isBefore(weekEnd))
        .toList();
    weekGamesCount.value = weekScores.length;
    weekTotalScore.value = weekScores.fold(0, (s, e) => s + e.score);

    final daySums = List.filled(7, 0);
    for (final s in weekScores) {
      final idx = s.playedAt.weekday - 1;
      if (idx >= 0 && idx < 7) daySums[idx] += s.score;
    }
    weekDayScores.value = daySums;
  }

  // Called when the controller is freshly created via Get.offAllNamed (the
  // "navigateHome" path from GameController).  The route argument 'lastScore'
  // tells us what score the player just achieved so we can celebrate a new best.
  void _checkCelebrationFromArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    if (args['fromGame'] != true) return;

    final lastScore = (args['lastScore'] as int?) ?? 0;
    if (lastScore <= 0) return;

    // Celebrate when the player's last score equals the all-time best,
    // meaning this game set (or tied) a new personal record.
    if (bestScore.value > 0 && lastScore >= bestScore.value) {
      _triggerCelebration(lastScore);
    }
  }

  void _triggerCelebration(int score) {
    celebrationScore.value = score;
    showCelebration.value  = true;
    // Auto-close after 4 seconds; the UI widget also allows tap-to-dismiss.
    Future.delayed(const Duration(milliseconds: 4000), dismissCelebration);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void dismissCelebration() {
    showCelebration.value = false;
  }

  Future<void> navigateToGame() async {
    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final adsOn   = remote?.adsEnabled.value     ?? false;
    final moreAds = remote?.moreAdsEnabled.value ?? false;

    if (adsOn && moreAds) {
      Get.find<AdService>().showInterstitial(onDismissed: _doNavigateToGame);
    } else {
      await _doNavigateToGame();
    }
  }

  Future<void> _doNavigateToGame() async {
    await Get.toNamed(AppRoutes.game, arguments: {'bestScore': bestScore.value});
    await Future.delayed(const Duration(milliseconds: 150));
    _loadStats();
  }

  Future<void> navigateToScores() async {
    await Get.toNamed(AppRoutes.score);
    _loadStats();
  }

  void refreshStats() => _loadStats();

  // ── Navigation ─────────────────────────────────────────────────────────────

  void navigateToBubbleStyle()  => Get.toNamed(AppRoutes.bubbleStyle);
  void navigateToLevels()       => Get.toNamed(AppRoutes.levels);
  void navigateToBackground()   => Get.toNamed(AppRoutes.backgroundStyle);
  void navigateToEarnCoins()    => Get.toNamed(AppRoutes.adWatch);
  void navigateToMoreOptions()  => Get.toNamed(AppRoutes.moreOptions);
  void navigateToSettings()     => Get.snackbar('Settings', 'Coming soon!',
      snackPosition: SnackPosition.TOP);
  void navigateToHelpSupport()  => Get.snackbar('Help & Support', 'Coming soon!',
      snackPosition: SnackPosition.TOP);

  // ── Earn / buy award ───────────────────────────────────────────────────────

  final RxBool isBuyingAward = false.obs;

  bool get canAffordAward =>
      Get.find<StyleService>().totalCoins.value >= StyleService.awardPurchaseCost;

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
          '+1 Award Earned!',
          '${StyleService.awardPurchaseCost} coins spent — award added to your balance!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.earnAward,
          colorText: AppColors.textWhite,
          margin: const EdgeInsets.all(16),
          borderRadius: AppDimensions.radiusM,
          duration: const Duration(seconds: 3),
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
