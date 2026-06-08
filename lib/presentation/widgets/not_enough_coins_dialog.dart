import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';

import '../../data/services/style_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  NOT ENOUGH COINS DIALOG
//
//  Beautiful primary-colored banner dialog shown when the user taps "Earn Award"
//  but has fewer coins than required.
//
//  Layout:
//    ┌──────────────────────────────────────┐
//    │  🪙  gradient header + title         │
//    │──────────────────────────────────────│
//    │  progress bar  (current / needed)    │
//    │  "X / 50 coins"  label               │
//    │──────────────────────────────────────│
//    │  [Watch Ads to Earn]   [Close]       │
//    └──────────────────────────────────────┘
// ═══════════════════════════════════════════════════════════════════════════════

class NotEnoughCoinsDialog extends StatelessWidget {
  final int currentCoins;
  final VoidCallback onWatchAds;

  const NotEnoughCoinsDialog({
    super.key,
    required this.currentCoins,
    required this.onWatchAds,
  });

  static void show({required int currentCoins, required VoidCallback onWatchAds}) {
    Get.dialog(
      NotEnoughCoinsDialog(currentCoins: currentCoins, onWatchAds: onWatchAds),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needed   = StyleService.awardPurchaseCost;
    final progress = (currentCoins / needed).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 8.w),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(5.w, 2.2.h, 5.w, 2.0.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00D4FF), // AppColors.earnCoin
                    Color(0xFF0072FF), // AppColors.primaryDeep
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 11.w, height: 11.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 10, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('🪙', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not Enough Coins',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        'You need $needed coins to earn an award',
                        style: TextStyle(
                          fontSize: 8.5.sp,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── White body ───────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 0.8.h),
              child: Column(
                children: [
                  // Coin progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your coins',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666680),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$currentCoins',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: currentCoins > 0
                                    ? const Color(0xFF0072FF)
                                    : const Color(0xFF999999),
                              ),
                            ),
                            TextSpan(
                              text: ' / $needed',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 1.2.h,
                      backgroundColor: const Color(0xFFE8ECF4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00D4FF),
                      ),
                    ),
                  ),
                  SizedBox(height: 0.6.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Need ${needed - currentCoins} more coins',
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: const Color(0xFF0072FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(5.w, 0.8.h, 5.w, 2.2.h),
              child: Row(
                children: [
                  // Close button
                  Expanded(
                    child: GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        height: 5.5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Later',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF666680),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Watch Ads CTA
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        onWatchAds();
                      },
                      child: Container(
                        height: 5.5.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF0072FF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0072FF).withOpacity(0.35),
                              blurRadius: 12, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 2.w),
                            Text(
                              'Watch Ads to Earn',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
