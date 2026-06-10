import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/background_assets.dart';
import '../../data/models/level_config.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../widgets/coin_display.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND STYLE SCREEN  — white theme
//
//  • 14 original images → FREE  (always in rotation pool)
//  • 32 new images      → PREMIUM  (100 coins to add to pool)
//  • Images are displayed at full clarity — crown badge only for premium
//  • Currently-playing card gets a vivid purple border + ▶ badge
//  • No dark overlay, no centre lock — crown in corner is the only indicator
// ═══════════════════════════════════════════════════════════════════════════════

class BackgroundStyleScreen extends StatelessWidget {
  const BackgroundStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Column(
        children: [
          const _HeroHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  const Expanded(child: _BgGrid()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────
// Full-bleed background image with rounded bottom corners, matching LevelsScreen.

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

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
              'assets/backgrounds/premium_bg_23.png',
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

            // ── Decorative glowing orbs ─────────────────────────────────────
            Positioned(
              top: heroH * 0.05,
              right: -6.w,
              child: _HeroOrb(size: 26.w, color: const Color(0xFF6C63FF), opacity: 0.22),
            ),
            Positioned(
              top: heroH * 0.25,
              left: -5.w,
              child: _HeroOrb(size: 18.w, color: const Color(0xFF48CAE4), opacity: 0.18),
            ),
            Positioned(
              bottom: heroH * 0.15,
              right: 12.w,
              child: _HeroOrb(size: 10.w, color: const Color(0xFFFFD700), opacity: 0.20),
            ),

            // ── Floating back button ────────────────────────────────────────
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
                      width: 11.w, height: 11.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.50), width: 1.2),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 4.8.w),
                    ),
                  ),
                ),
              ),
            ),

            // ── Coin + Awards pill (top-right) ────────────────────────────────
            Positioned(
              top: topPad + 1.5.h,
              right: 4.w,
              child: Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.65), width: 1.2),
                        ),
                        child: CoinDisplay(amount: svc.totalCoins.value, imageSize: 14, fontSize: 12, gap: 4),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.80), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏅', style: TextStyle(fontSize: 13, height: 1.0)),
                            SizedBox(width: 1.w),
                            Text('${svc.totalAwards.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ),

            // ── Bottom content: icon + title/subtitle + coin pill + progress ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 2.4.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Icon circle
                        Container(
                          width: 13.w, height: 13.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.55),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.wallpaper_rounded,
                              color: Colors.white, size: 6.w),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Backgrounds',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Auto-rotate every 5 min · unlock to add',
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  color: Colors.white.withOpacity(0.75),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.4.h),
                    // ── Stat chips ──────────────────────────────────────────
                    Obx(() {
                      final current = svc.currentLevel.value;
                      return Row(
                        spacing: 2.4.w,
                        children: [
                          Expanded(
                            child: _BgStatChip(
                              icon: Icons.track_changes_rounded,
                              label: 'Current',
                              value: 'Lvl $current',
                              gradStart: AppColors.levelMapCurrentStart,
                              gradEnd: AppColors.levelMapCurrentEnd,
                            ),
                          ),
                          Expanded(
                            child: _BgStatChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'Target',
                              value: '${LevelConfig.scoreTargetForLevel(current)} pts',
                              gradStart: AppColors.levelMapTargetStart,
                              gradEnd: AppColors.levelMapTargetEnd,
                            ),
                          ),
                          Expanded(
                            child: _BgStatChip(
                              icon: Icons.lock_rounded,
                              label: 'Left',
                              value: '${100 - current + 1} Lvls',
                              gradStart: AppColors.levelMapLeftStart,
                              gradEnd: AppColors.levelMapLeftEnd,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Orb helper ───────────────────────────────────────────────────────────────

class _HeroOrb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _HeroOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}


// ─── Stat chip (matches Level Map design) ────────────────────────────────────

class _BgStatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    gradStart;
  final Color    gradEnd;

  const _BgStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradStart,
    required this.gradEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: AppColors.levelMapChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.levelMapChipBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w, height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [gradStart, gradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10.sp, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w500, height: 1.2)),
                Text(value,
                    style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w800, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _BgGrid extends StatelessWidget {
  const _BgGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.70,
      ),
      itemCount: BackgroundStyle.values.length,
      itemBuilder: (_, i) => _BgCard(bg: BackgroundStyle.values[i]),
    );
  }
}

// ─── Single background card ───────────────────────────────────────────────────

class _BgCard extends StatefulWidget {
  final BackgroundStyle bg;
  const _BgCard({required this.bg});

  @override
  State<_BgCard> createState() => _BgCardState();
}

class _BgCardState extends State<_BgCard> {
  bool _pressed = false;

  void _onTap(StyleService svc) {
    if (!widget.bg.isPremium) return;
    if (svc.isBackgroundUnlocked(widget.bg)) return;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 5.w),
        child: _UnlockSheet(bg: widget.bg, svc: svc),
      ),
      barrierColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();
    return Obx(() {
      final isUnlocked = svc.isBackgroundUnlocked(widget.bg);
      final isPlaying  = svc.currentBgAsset.value == widget.bg.assetPath;
      final isPremium  = widget.bg.isPremium;
      final isLocked   = isPremium && !isUnlocked;

      return GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); _onTap(svc); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isPlaying
                    ? const Color(0xFF6C63FF)
                    : isUnlocked && isPremium
                        ? const Color(0xFF43E97B).withOpacity(0.60)
                        : const Color(0xFFE8ECF5),
                width: isPlaying ? 2.5 : 1.2,
              ),
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.28),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image area ─────────────────────────────────────────────
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Full-clarity image — NO dark overlay
                        Image.asset(
                          widget.bg.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEF0FF),
                            child: Icon(Icons.image_not_supported_outlined,
                                color: const Color(0xFFCDD0E3), size: 8.w),
                          ),
                        ),

                        // ── Playing badge (top-left) ───────────────────────
                        if (isPlaying)
                          Positioned(
                            top: 1.h, left: 2.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF).withOpacity(0.45),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 3.2.w),
                                  SizedBox(width: 0.8.w),
                                  Text(
                                    'Playing',
                                    style: TextStyle(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Crown badge for premium (top-right) ────────────
                        // Only a crown — image stays fully visible
                        if (isPremium && !isUnlocked)
                          Positioned(
                            top: 0.8.h, right: 2.w,
                            child: _CrownBadge(isUnlocked: isUnlocked),
                          ),
                      ],
                    ),
                  ),

                  // ── Label row (white card below image) ────────────────────
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(2.5.w, 1.h, 2.5.w, 1.2.h),
                    child: Row(
                      children: [
                        Text(widget.bg.emoji, style: TextStyle(fontSize: 11.sp)),
                        SizedBox(width: 1.5.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.bg.label,
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Status line
                              if (isPlaying)
                                _StatusText('Now playing', const Color(0xFF6C63FF))
                              else if (!isPremium)
                                _StatusText('Free', const Color(0xFF43A047))
                              else if (isUnlocked)
                                _StatusText('In rotation', const Color(0xFF43A047))
                              else
                                _CostLine(cost: widget.bg.coinCost),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Crown badge ──────────────────────────────────────────────────────────────

class _CrownBadge extends StatelessWidget {
  final bool isUnlocked;
  const _CrownBadge({required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        // Unlocked → green tick; locked premium → white background for crown
        color: isUnlocked
            ? const Color(0xFF43E97B)
            : Colors.white,
            shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isUnlocked
          ? Icon(Icons.check_rounded, color: Colors.white, size: 3.5.w)
          : Text('👑', style: TextStyle(fontSize: 12.sp)),
    );
  }
}

// ─── Tiny helpers ─────────────────────────────────────────────────────────────

class _StatusText extends StatelessWidget {
  final String text;
  final Color  color;
  const _StatusText(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8.sp,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  final int cost;
  const _CostLine({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('\$', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: Color(0xFFB8860B))),
        SizedBox(width: 0.8.w),
        Text(
          '$cost coins',
          style: TextStyle(
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB8860B),
          ),
        ),
      ],
    );
  }
}

// ─── Unlock bottom-sheet style dialog ────────────────────────────────────────

class _UnlockSheet extends StatefulWidget {
  final BackgroundStyle bg;
  final StyleService    svc;
  const _UnlockSheet({required this.bg, required this.svc});

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  // 0 = pay with coins, 1 = pay with awards
  int _tab = 0;

  void _snackUnlocked() {
    Get.snackbar(
      '✅ Unlocked!',
      '${widget.bg.emoji} ${widget.bg.label} added to your rotation!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF43E97B),
      colorText: Colors.white,
      margin: EdgeInsets.all(4.w),
      borderRadius: 16,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg  = widget.bg;
    final svc = widget.svc;
    return Obx(() {
      final canAffordCoins  = svc.totalCoins.value  >= bg.coinCost;
      final canAffordAwards = svc.totalAwards.value >= bg.awardCost;
      final canAfford       = _tab == 0 ? canAffordCoins : canAffordAwards;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Preview image ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: SizedBox(
                height: 24.h,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      bg.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFEEF0FF)),
                    ),
                    // Subtle bottom gradient for label readability
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 1.5.h, left: 4.w,
                      child: Row(children: [
                        Text(bg.emoji, style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 2.w),
                        Text(
                          bg.label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                    // Crown top-right
                    Positioned(
                      top: 1.5.h, right: 3.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 9.sp)),
                            SizedBox(width: 1.w),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 3.h),
              child: Column(
                children: [
                  // ── OR tabs: Coins | Awards ────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _TabBtn(
                          label: 'Coins',
                          coinPrefix: true,
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        _TabBtn(
                          label: '🏅  Awards',
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // ── Balance row ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BalancePill(
                        label: _tab == 0 ? 'Your coins' : 'Your awards',
                        value: _tab == 0
                            ? '${svc.totalCoins.value}'
                            : '${svc.totalAwards.value}',
                        color: canAfford
                            ? const Color(0xFF43A047)
                            : Colors.redAccent,
                        isCoin: _tab == 0,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: const Color(0xFFCDD0E3), size: 4.w),
                      ),
                      _BalancePill(
                        label: 'Cost',
                        value: _tab == 0
                            ? '${bg.coinCost}'
                            : '${bg.awardCost}',
                        color: const Color(0xFFB8860B),
                        isCoin: _tab == 0,
                      ),
                    ],
                  ),

                  if (!canAfford) ...[
                    SizedBox(height: 1.h),
                    Text(
                      _tab == 0
                          ? 'You need ${bg.coinCost  - svc.totalCoins.value} more coins — keep playing!'
                          : 'You need ${bg.awardCost - svc.totalAwards.value} more awards — break your high score!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.redAccent,
                        height: 1.4,
                      ),
                    ),
                  ],

                  SizedBox(height: 2.h),

                  // ── Unlock button ──────────────────────────────────────────
                  if (canAfford)
                    _PrimaryBtn(
                      label: _tab == 0
                          ? ''
                          : 'Unlock for ${bg.awardCost} 🏅 Awards',
                      icon: _tab == 0 ? '' : '🏅',
                      labelChild: _tab == 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Unlock — ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                CoinDisplay(amount: bg.coinCost, imageSize: 16, fontSize: 14, gap: 3),
                                const Text(' Coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            )
                          : null,
                      colors: _tab == 0
                          ? const [Color(0xFFFFD700), Color(0xFFFF8C00)]
                          : const [Color(0xFF43E97B), Color(0xFF38F9D7)],
                      shadowColor: _tab == 0
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF43E97B),
                      onTap: () {
                        final ok = _tab == 0
                            ? svc.unlockBackground(bg)
                            : svc.unlockBackgroundWithAwards(bg);
                        if (!ok) return; // insufficient funds — stay open
                        Get.find<AdService>().showInterstitial(
                          onDismissed: () {
                            Get.back();
                            _snackUnlocked();
                          },
                        );
                      },
                    ),

                  SizedBox(height: 1.2.h),

                  // ── Cancel ─────────────────────────────────────────────────
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 1.6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE8ECF5), width: 1.2),
                      ),
                      child: Text(
                        'Maybe later',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9099B0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Balance pill ─────────────────────────────────────────────────────────────

class _BalancePill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   isCoin;
  const _BalancePill({
    required this.label,
    required this.value,
    required this.color,
    this.isCoin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 8.sp, color: const Color(0xFF9099B0))),
        SizedBox(height: 0.3.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: isCoin
              ? CoinDisplay(
                  amount: int.tryParse(value) ?? 0,
                  imageSize: 14,
                  fontSize: 13,
                  textColor: color,
                  gap: 4,
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final String icon;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback onTap;
  final Widget? labelChild;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
    this.labelChild,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon.isNotEmpty) ...[
              Text(icon, style: TextStyle(fontSize: 13.sp)),
              SizedBox(width: 2.w),
            ],
            if (labelChild != null)
              labelChild!
            else
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab toggle button ────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String   label;
  final bool     selected;
  final bool     coinPrefix;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.coinPrefix = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? const Color(0xFF1A1A2E) : const Color(0xFF9099B0);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coinPrefix) ...[
                Image.asset('assets/images/coin.png', width: 14, height: 14),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
