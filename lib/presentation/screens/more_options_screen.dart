import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/style_service.dart';
import '../controllers/more_options_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  MORE OPTIONS SCREEN
//
//  Fantasy background · glass pill buttons · live-reactive coin/award balance.
//  All logic lives in MoreOptionsController — this file is pure UI.
// ═══════════════════════════════════════════════════════════════════════════════

class MoreOptionsScreen extends GetView<MoreOptionsController> {
  const MoreOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fantasy background image ────────────────────────────────────
          Image.asset(
            'assets/images/home_screen.png',
            fit: BoxFit.cover,
          ),
          // Subtle dark overlay for legibility
          Container(color: Colors.black.withOpacity(0.22)),

          SafeArea(
            child: Column(
              children: [
                _Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    child: Column(
                      children: [
                        SizedBox(height: 1.h),
                        _OptionTile(
                          emoji: '🗂',
                          label: 'LEVELS',
                          gradientColors: const [Color(0xFF4776E6), Color(0xFF8E54E9)],
                          onTap: controller.navigateToLevels,
                        ),
                        SizedBox(height: 2.h),
                        _OptionTile(
                          emoji: '🌅',
                          label: 'BACKGROUND',
                          gradientColors: const [Color(0xFFf7971e), Color(0xFFffd200)],
                          onTap: controller.navigateToBackground,
                        ),
                        SizedBox(height: 2.h),
                        _OptionTile(
                          emoji: '🪙',
                          label: 'EARN COINS',
                          gradientColors: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                          onTap: controller.navigateToEarnCoins,
                        ),
                        SizedBox(height: 2.h),
                        // Earn Award — live-reactive coin affordability
                        Obx(() {
                          final svc = Get.find<StyleService>();
                          final canAfford = svc.totalCoins.value >= StyleService.awardPurchaseCost;
                          final busy = controller.isBuyingAward.value;
                          return _EarnAwardTile(
                            canAfford: canAfford,
                            busy: busy,
                            onTap: controller.buyAwardWithCoins,
                          );
                        }),
                        SizedBox(height: 2.h),
                        _OptionTile(
                          emoji: '⚙️',
                          label: 'SETTINGS',
                          gradientColors: const [Color(0xFF4776E6), Color(0xFF8360C3)],
                          onTap: controller.navigateToSettings,
                        ),
                        SizedBox(height: 2.h),
                        _OptionTile(
                          emoji: '🎧',
                          label: 'HELP & SUPPORT',
                          gradientColors: const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                          onTap: controller.navigateToHelpSupport,
                        ),
                        SizedBox(height: 2.h),
                        _OptionTile(
                          emoji: '🔒',
                          label: 'PRIVACY POLICY',
                          gradientColors: const [Color(0xFF373B44), Color(0xFF4286f4)],
                          onTap: controller.navigateToPrivacyPolicy,
                        ),
                        SizedBox(height: 3.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 5.w, 0.5.h),
      child: Row(
        children: [
          // Back button — circular glass
          GestureDetector(
            onTap: Get.back,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 10.w, height: 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.22),
                    border: Border.all(color: Colors.white.withOpacity(0.40)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 4.5.w),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MORE OPTIONS',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: const [Shadow(color: Colors.black38, blurRadius: 8)],
                  ),
                ),
                // Decorative star divider
                Row(
                  children: [
                    Container(
                      height: 1.5,
                      width: 10.w,
                      color: Colors.white.withOpacity(0.60),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                      child: Text('✦', style: TextStyle(color: AppColors.scoreGold, fontSize: 9.sp)),
                    ),
                    Container(
                      height: 1.5,
                      width: 10.w,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STANDARD OPTION TILE  — glass pill with emoji + gradient accent
// ═══════════════════════════════════════════════════════════════════════════════

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 7.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  gradientColors[0].withOpacity(0.75),
                  gradientColors[1].withOpacity(0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.30),
                  blurRadius: 14, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 5.w),
                // Emoji icon in a small white circle
                Container(
                  width: 9.w, height: 9.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: Center(child: Text(emoji, style: TextStyle(fontSize: 12.sp))),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.85), size: 4.5.w),
                SizedBox(width: 5.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EARN AWARD TILE  — same pill shape, gold gradient, live busy/afford state
// ═══════════════════════════════════════════════════════════════════════════════

class _EarnAwardTile extends StatelessWidget {
  final bool canAfford;
  final bool busy;
  final VoidCallback onTap;

  const _EarnAwardTile({
    required this.canAfford,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = canAfford
        ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
        : [const Color(0xFF9E9E9E), const Color(0xFF757575)];

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 7.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  colors[0].withOpacity(0.80),
                  colors[1].withOpacity(0.80),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
              boxShadow: canAfford
                  ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5))]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(width: 5.w),
                Container(
                  width: 9.w, height: 9.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  child: Center(child: Text('🏆', style: TextStyle(fontSize: 12.sp))),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: busy
                      ? Row(children: [
                          SizedBox(
                            width: 4.5.w, height: 4.5.w,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 2.w),
                          Text('Processing…',
                              style: TextStyle(fontSize: 11.sp,
                                  fontWeight: FontWeight.w700, color: Colors.white70)),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EARN AWARD',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                              ),
                            ),
                            Text(
                              canAfford
                                  ? '${StyleService.awardPurchaseCost} coins'
                                  : 'Need ${StyleService.awardPurchaseCost} coins',
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
                if (!busy)
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.85), size: 4.5.w),
                SizedBox(width: 5.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
