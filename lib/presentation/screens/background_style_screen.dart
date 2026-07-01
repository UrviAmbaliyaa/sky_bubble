import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/background_assets.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../widgets/coin_display.dart';
import '../widgets/screen_header.dart';

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
          const ScreenHeader(
            backgroundAsset: 'assets/backgrounds/premium_bg_23.png',
            titleIcon: Icons.wallpaper_rounded,
            title: 'Backgrounds',
            subtitle: 'Auto-rotate every 5 min · unlock to add',
          ),
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

class _BgGrid extends StatelessWidget {
  const _BgGrid();

  @override
  Widget build(BuildContext context) {
    // +1 for the Auto card at index 0
    final totalItems = BackgroundStyle.values.length + 1;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.70,
      ),
      itemCount: totalItems,
      itemBuilder: (_, i) {
        if (i == 0) return const _AutoCard();
        return _BgCard(bg: BackgroundStyle.values[i - 1]);
      },
    );
  }
}

// ─── Auto card ────────────────────────────────────────────────────────────────

class _AutoCard extends StatefulWidget {
  const _AutoCard();

  @override
  State<_AutoCard> createState() => _AutoCardState();
}

class _AutoCardState extends State<_AutoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();
    return Obx(() {
      final isAuto = svc.autoBackground.value;
      return GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); svc.setAutoBackground(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: isAuto
                  ? const Color(0xFF6C63FF).withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isAuto ? const Color(0xFF6C63FF) : const Color(0xFFE8ECF5),
                width: isAuto ? 2.5 : 1.2,
              ),
              boxShadow: isAuto
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.25),
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
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Gradient preview area ──────────────────────────────────
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 14.w),
                              SizedBox(height: 1.h),
                              Text(
                                'Auto',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAuto)
                          Positioned(
                            top: 1.h, left: 2.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.4.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: const Color(0xFF6C63FF),
                                      size: 3.2.w),
                                  SizedBox(width: 0.8.w),
                                  Text(
                                    'Playing',
                                    style: TextStyle(
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF6C63FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ── Label row ──────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(2.5.w, 1.h, 2.5.w, 1.2.h),
                    child: Row(
                      children: [
                        Text('🔄', style: TextStyle(fontSize: 11.sp)),
                        SizedBox(width: 1.5.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Auto Rotate',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              _StatusText(
                                isAuto ? 'Playing' : 'Tap to enable',
                                isAuto
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF9099B0),
                              ),
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
    if (widget.bg.isPremium && !svc.isBackgroundUnlocked(widget.bg)) {
      _showPremiumDialog(svc);
      return;
    }
    // Already pinned — tapping again does nothing
    if (!svc.autoBackground.value && svc.fixedBgStyle.value == widget.bg) return;

    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final useMoreAds = (remote?.adsEnabled.value     ?? false)
        && (remote?.moreAdsEnabled.value ?? false);

    if (useMoreAds) {
      Get.find<AdService>().showInterstitial(
        onDismissed: () => svc.setFixedBackground(widget.bg),
      );
    } else {
      svc.setFixedBackground(widget.bg);
    }
  }

  void _showPremiumDialog(StyleService svc) {
    void openDialog() {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 5.w),
          child: _UnlockSheet(bg: widget.bg, svc: svc),
        ),
        barrierColor: Colors.black54,
      );
    }

    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final adsOn   = remote?.adsEnabled.value     ?? false;
    final moreAds = remote?.moreAdsEnabled.value ?? false;

    // moreads interstitial: ads=true AND moreads=true.
    if (adsOn && moreAds) {
      Get.find<AdService>().showInterstitial(onDismissed: openDialog);
    } else {
      openDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();
    return Obx(() {
      final isUnlocked = svc.isBackgroundUnlocked(widget.bg);
      final isPremium  = widget.bg.isPremium;
      final isAuto     = svc.autoBackground.value;
      // A bg card is "selected" only in fixed mode when it is the pinned choice.
      // In auto mode, no individual bg card is highlighted — the Auto card owns that.
      final isPinned   = !isAuto && svc.fixedBgStyle.value == widget.bg;

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
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isPinned
                    ? const Color(0xFF6C63FF)
                    : isUnlocked && isPremium
                        ? const Color(0xFF43E97B).withOpacity(0.60)
                        : const Color(0xFFE8ECF5),
                width: isPinned ? 2.5 : 1.2,
              ),
              boxShadow: isPinned
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.28),
                        blurRadius: 22,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 22,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image area ─────────────────────────────────────────────
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          widget.bg.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEEF0FF),
                            child: Icon(Icons.image_not_supported_outlined,
                                color: const Color(0xFFCDD0E3), size: 8.w),
                          ),
                        ),

                        // ── Playing badge top-left (only when pinned) ─────
                        if (isPinned)
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

                        // ── Free badge top-right (free backgrounds only) ───
                        if (!isPremium)
                          Positioned(
                            top: 1.h, right: 2.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF43A047).withOpacity(0.45),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_open_rounded,
                                      color: Colors.white, size: 3.2.w),
                                  SizedBox(width: 0.8.w),
                                  Text(
                                    'Free',
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

                        // ── Crown badge top-right (locked premium only) ────
                        if (isPremium && !isUnlocked)
                          Positioned(
                            top: 0.8.h, right: 2.w,
                            child: _CrownBadge(isUnlocked: isUnlocked),
                          ),
                      ],
                    ),
                  ),

                  // ── Label row ─────────────────────────────────────────────
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
                              if (isPinned)
                                _StatusText('Playing', const Color(0xFF6C63FF))
                              else if (!isPremium)
                                _StatusText('Free', const Color(0xFF43A047))
                              else if (isUnlocked)
                                _StatusText('Unlocked', const Color(0xFF43A047))
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
