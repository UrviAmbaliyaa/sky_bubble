import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../../domain/usecases/score_usecases.dart';

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

  /// Shows the mode-selection bottom sheet (Game vs Learning).
  /// Called from the Play button and from the Levels screen.
  void showModeSelection({int? startLevel}) {
              _navigateToGameWithLevel(startLevel: startLevel);

  }

  Future<void> navigateToGame() async => showModeSelection();

  Future<void> _navigateToGameWithLevel({int? startLevel}) async {
    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final adsOn   = remote?.adsEnabled.value     ?? false;
    final moreAds = remote?.moreAdsEnabled.value ?? false;

    Future<void> doNav() async {
      final args = <String, dynamic>{'bestScore': bestScore.value};
      if (startLevel != null) args['startLevel'] = startLevel;
      await Get.toNamed(AppRoutes.game, arguments: args);
      await Future.delayed(const Duration(milliseconds: 150));
      _loadStats();
    }

    if (adsOn && moreAds) {
      Get.find<AdService>().showInterstitial(onDismissed: doNav);
    } else {
      await doNav();
    }
  }

  Future<void> _navigateToLearning({int? startLevel}) async {
    final args = <String, dynamic>{};
    if (startLevel != null) args['startLevel'] = startLevel;
    await Get.toNamed(AppRoutes.learning, arguments: args.isEmpty ? null : args);
  }

  

  void refreshStats() => _loadStats();

  // ── Navigation ─────────────────────────────────────────────────────────────

  
  void navigateToMoreOptions()  => Get.toNamed(AppRoutes.moreOptions);
  void navigateToSettings()     => Get.toNamed(AppRoutes.settings);
  void navigateToGameHub()      => Get.toNamed(AppRoutes.gameHub);
  void navigateToLearningHub()  => Get.toNamed(AppRoutes.learningHub);
  void navigateToHelpSupport()  => Get.snackbar('Help & Support', 'Coming soon!',
      snackPosition: SnackPosition.TOP);

  // ── Earn / buy award ───────────────────────────────────────────────────────

  final RxBool isBuyingAward = false.obs;

  bool get canAffordAward =>
      Get.find<StyleService>().totalCoins.value >= StyleService.awardPurchaseCost;

  void buyAwardWithCoins() {
    if (isBuyingAward.value) return;
    final styleSvc = Get.find<StyleService>();

   

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

// ─── Mode Selection Bottom Sheet ──────────────────────────────────────────────
// Displayed when the user taps Play or a level — lets them choose Game or Learning.

// class _ModeSelectionSheet extends StatelessWidget {
//   final VoidCallback onGameSelected;
//   final VoidCallback onLearningSelected;

//   const _ModeSelectionSheet({
//     required this.onGameSelected,
//     required this.onLearningSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
//         child: Container(
//           padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 5.h),
//           decoration: BoxDecoration(
//             color: const Color(0xFF0D1B4A).withOpacity(0.88),
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.18),
//               width: 1.2,
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Handle
//               Container(
//                 width: 10.w, height: 0.6.h,
//                 margin: EdgeInsets.only(bottom: 2.5.h),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.30),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               Text(
//                 'Choose Your Mode',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w900,
//                   color: Colors.white,
//                   letterSpacing: 0.8,
//                 ),
//               ),
//               SizedBox(height: 0.6.h),
//               Text(
//                 'How would you like to play?',
//                 style: TextStyle(
//                   fontSize: 11.sp,
//                   color: Colors.white60,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               SizedBox(height: 3.h),
//               // Cards row
//               Row(
//                 children: [
//                   Expanded(
//                     child: _ModeCard(
//                       icon: Icons.bubble_chart_rounded,
//                       emoji: '🫧',
//                       title: 'GAME',
//                       subtitle: 'Pop bubbles\n& earn points',
//                       gradient: const [Color(0xFF6C63FF), Color(0xFF4A90E2)],
//                       glowColor: const Color(0xFF6C63FF),
//                       onTap: onGameSelected,
//                     ),
//                   ),
//                   SizedBox(width: 4.w),
//                   Expanded(
//                     child: _ModeCard(
//                       icon: Icons.menu_book_rounded,
//                       emoji: '📚',
//                       title: 'LEARN',
//                       subtitle: 'Spell words\nwith bubbles',
//                       gradient: const [Color(0xFF43E97B), Color(0xFF38D9A9)],
//                       glowColor: const Color(0xFF43E97B),
//                       onTap: onLearningSelected,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 3.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji,
                  style: TextStyle(fontSize: 26.sp)),
              SizedBox(height: 1.2.h),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 0.6.h),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
