import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../controllers/ad_watch_controller.dart';
import '../widgets/glow_orb.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AD WATCH SCREEN  — pure UI, zero business logic
//
//  All logic lives in AdWatchController. This screen only builds UI from
//  reactive state (adsCompleted, isLoading, isCancelled).
// ═══════════════════════════════════════════════════════════════════════════════

class AdWatchScreen extends StatelessWidget {
  const AdWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdWatchController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ctrl.cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.screenDarkBottom,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.screenDarkTop, AppColors.screenDarkBottom],
                ),
              ),
            ),

            // Decorative orbs
            Positioned(
              top: -8.h, right: -10.w,
              child: GlowOrb(size: 45.w, color: AppColors.earnCoin),
            ),
            Positioned(
              bottom: -5.h, left: -8.w,
              child: GlowOrb(size: 35.w, color: AppColors.adBgGlow),
            ),

            SafeArea(
              child: Column(
                children: [
                  _BackButton(onTap: ctrl.cancel),
                  const Spacer(),
                  _AdProgressBody(ctrl: ctrl),
                  const Spacer(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4.w, top: 1.h),
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.glassWhite, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 4.w),
                    SizedBox(width: 1.w),
                    Text('Back',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main body (reacts to controller state) ───────────────────────────────────

class _AdProgressBody extends StatelessWidget {
  final AdWatchController ctrl;
  const _AdProgressBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completed = ctrl.adsCompleted.value;
      final loading   = ctrl.isLoading.value;
      final total     = AdWatchController.totalAds;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin image
          Image.asset('assets/images/coin.png', width: 22.w, height: 22.w),
          SizedBox(height: 3.h),

          // Title
          Text(
            'Earning Coins',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textWhite,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Watch all $total ads to earn ${AdWatchController.coinReward} coins',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 5.h),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final done   = i < completed;
              final active = i == completed;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                width:  active ? 8.w : 5.w,
                height: 1.2.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: done
                      ? AppColors.earnCoin
                      : active
                          ? AppColors.textWhite
                          : Colors.white24,
                ),
              );
            }),
          ),

          SizedBox(height: 2.5.h),

          // Status text
          Text(
            loading
                ? 'Loading ad ${completed + 1} of $total…'
                : 'Ad ${completed + 1} of $total ready',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 3.h),

          // Spinner
          if (loading)
            SizedBox(
              width: 8.w, height: 8.w,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.earnCoin,
                backgroundColor: Colors.white12,
              ),
            ),
        ],
      );
    });
  }
}
