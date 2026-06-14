import 'dart:ui';
import 'package:bubble_pumping/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../data/models/level_config.dart';
import '../../data/services/style_service.dart';
import 'coin_display.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ScreenHeader — shared hero header used by all four screens:
//    • Bubble Style      (premium_bg_29, bubble_chart icon)
//    • Progress / Score  (premium_bg_32, bar_chart icon)
//    • Background Style  (premium_bg_23, wallpaper icon)
//    • Level Map         (BgAssets.levelMapHeader, map icon)
//
//  Usage:
//    ScreenHeader(
//      backgroundAsset: 'assets/backgrounds/premium_bg_29.png',
//      titleIcon: Icons.bubble_chart_rounded,
//      title: 'Bubble Styles',
//      subtitle: 'Classic is free · earn 🪙 coins to unlock more',
//    )
//
//  Or with a dynamic subtitle widget:
//    ScreenHeader(
//      backgroundAsset: '...',
//      titleIcon: Icons.bar_chart_rounded,
//      title: 'My Progress',
//      subtitleWidget: Obx(() => Text('⭐ Best ...')),
//    )
// ═══════════════════════════════════════════════════════════════════════════════

class ScreenHeader extends StatelessWidget {
  /// Asset path for the background image.
  final String backgroundAsset;

  /// Icon shown in the gradient circle next to the title.
  final IconData titleIcon;

  /// Main heading text.
  final String title;

  /// Static subtitle string. Ignored when [subtitleWidget] is provided.
  final String? subtitle;

  /// Optional dynamic subtitle widget (e.g. an Obx Text).
  /// Takes priority over [subtitle].
  final Widget? subtitleWidget;

  const ScreenHeader({
    super.key,
    required this.backgroundAsset,
    required this.titleIcon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
  }) : assert(
          subtitle != null || subtitleWidget != null,
          'Provide either subtitle or subtitleWidget',
        );

  @override
  Widget build(BuildContext context) {
    final svc    = Get.find<StyleService>();
    final heroH  = MediaQuery.of(context).size.height * 0.26;
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SizedBox(
        height: heroH + topPad,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ────────────────────────────────────────────
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A6E)),
            ),

            // ── Gradient overlay ────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x22000000),
                    Color(0xBB000000),
                    Color(0xFF0D0D1A),
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),

            // ── Decorative orbs ─────────────────────────────────────────────
            Positioned(
              top: heroH * 0.05,
              right: -6.w,
              child: _HeaderOrb(size: 26.w, color: const Color(0xFF6C63FF), opacity: 0.22),
            ),
            Positioned(
              top: heroH * 0.25,
              left: -5.w,
              child: _HeaderOrb(size: 18.w, color: const Color(0xFF48CAE4), opacity: 0.18),
            ),
            Positioned(
              bottom: heroH * 0.15,
              right: 12.w,
              child: _HeaderOrb(size: 10.w, color: const Color(0xFFFFD700), opacity: 0.20),
            ),

            // ── Back button (top-left) ───────────────────────────────────────
            Positioned(
              top: topPad + 1.5.h,
              left: 4.w,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 11.w,
                      height: 11.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.50),
                            width: 1.2),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 4.8.w),
                    ),
                  ),
                ),
              ),
            ),

            // ── Coin + Awards pills (top-right) ──────────────────────────────
            Positioned(
              top: topPad + 1.5.h,
              right: 4.w,
              child: Obx(() => _HeaderCoinPills(
                    coins: svc.totalCoins.value,
                    awards: svc.totalAwards.value,
                  )),
            ),

            // ── Bottom content: icon + title + subtitle + stat chips ─────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Obx(() {
                final current = svc.currentLevel.value;
                return Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 2.4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Gradient icon circle
                          Container(
                            width: 13.w,
                            height: 13.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.55),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(titleIcon,
                                color: Colors.white, size: 6.w),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                // Subtitle: prefer widget, fall back to string
                                if (subtitleWidget != null)
                                  subtitleWidget!
                                else
                                  Text(
                                    subtitle!,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 1.4.h),

                      // Stat chips row (same for every screen)
                      Row(
                        spacing: 2.4.w,
                        children: [
                          Expanded(
                            child: HeaderStatChip(
                              icon: Icons.track_changes_rounded,
                              label: 'Current',
                              value: 'Lvl $current',
                              gradStart: AppColors.levelMapCurrentStart,
                              gradEnd: AppColors.levelMapCurrentEnd,
                            ),
                          ),
                          Expanded(
                            child: HeaderStatChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'Target',
                              value: '${LevelConfig.scoreTargetForLevel(current)} pts',
                              gradStart: AppColors.levelMapTargetStart,
                              gradEnd: AppColors.levelMapTargetEnd,
                            ),
                          ),
                          Expanded(
                            child: HeaderStatChip(
                              icon: Icons.lock_rounded,
                              label: 'Left',
                              value: '${100 - current + 1} Lvls',
                              gradStart: AppColors.levelMapLeftStart,
                              gradEnd: AppColors.levelMapLeftEnd,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Stat chip — exported so screens can still use it if needed ───────────────

class HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    gradStart;
  final Color    gradEnd;

  const HeaderStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradStart,
    required this.gradEnd,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.30), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(1.2.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [gradStart, gradEnd]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 15.sp),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 9.5.sp,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500)),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _HeaderOrb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _HeaderOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

class _HeaderCoinPills extends StatelessWidget {
  final int coins;
  final int awards;
  const _HeaderCoinPills({required this.coins, required this.awards});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Coins
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                    width: 1.2),
              ),
              child: CoinDisplay(amount: coins, imageSize: 14, fontSize: 12, gap: 4),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        // Awards
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.80),
                    width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 13, height: 1.0)),
                  SizedBox(width: 1.w),
                  Text('$awards',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
