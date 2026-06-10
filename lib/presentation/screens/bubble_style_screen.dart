import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/models/level_config.dart';
import '../../data/models/bubble_model.dart';
import '../../data/services/ad_service.dart';
import '../widgets/coin_display.dart';
import '../../data/services/style_service.dart';
import '../widgets/bubble_painter.dart';

// ════════════════════════════════════════════════════════════════════════════
//  BUBBLE STYLE SCREEN  — white theme, no AppBar
//
//  • Classic is FREE, premium styles cost coins to unlock
//  • Crown badge (white bg) for premium — consistent with BackgroundStyleScreen
//  • Top bar matches BackgroundStyleScreen / LevelsScreen pattern
// ════════════════════════════════════════════════════════════════════════════

class BubbleStyleScreen extends StatelessWidget {
  const BubbleStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Column(
        children: [
          // ── Sticky hero header ────────────────────────────────────────────
          const _HeroHeader(),

          // ── Scrollable list — SafeArea for bottom home indicator ──────────
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final current = svc.selectedStyle.value;
                final coins   = svc.totalCoins.value;
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                  itemCount: BubbleStyle.values.length,
                  itemBuilder: (_, i) {
                    final style    = BubbleStyle.values[i];
                    final unlocked = svc.isUnlocked(style);
                    return _StyleRow(
                      style: style,
                      isSelected: current == style,
                      isUnlocked: unlocked,
                      userCoins: coins,
                      onTap: () {
                        if (unlocked) {
                          svc.setStyle(style);
                        } else {
                          showUnlockDialog(context, style, svc);
                        }
                      },
                    );
                  },
                );
              }),
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
              'assets/backgrounds/premium_bg_29.png',
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
              child: _Orb(size: 26.w, color: const Color(0xFF6C63FF), opacity: 0.22),
            ),
            Positioned(
              top: heroH * 0.25,
              left: -5.w,
              child: _Orb(size: 18.w, color: const Color(0xFF48CAE4), opacity: 0.18),
            ),
            Positioned(
              bottom: heroH * 0.15,
              right: 12.w,
              child: _Orb(size: 10.w, color: const Color(0xFFFFD700), opacity: 0.20),
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
              child: Obx(() {
                final svc2 = Get.find<StyleService>();
                return Row(
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
                          child: CoinDisplay(amount: svc2.totalCoins.value, imageSize: 14, fontSize: 12, gap: 4),
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
                              Text('${svc2.totalAwards.value}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
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
                          child: Icon(Icons.bubble_chart_rounded,
                              color: Colors.white, size: 6.w),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Bubble Styles',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Classic is free · earn 🪙 coins to unlock more',
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
                            child: _HeaderStatChip(
                              icon: Icons.track_changes_rounded,
                              label: 'Current',
                              value: 'Lvl $current',
                              gradStart: AppColors.levelMapCurrentStart,
                              gradEnd: AppColors.levelMapCurrentEnd,
                            ),
                          ),
                          Expanded(
                            child: _HeaderStatChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'Target',
                              value: '${LevelConfig.scoreTargetForLevel(current)} pts',
                              gradStart: AppColors.levelMapTargetStart,
                              gradEnd: AppColors.levelMapTargetEnd,
                            ),
                          ),
                          Expanded(
                            child: _HeaderStatChip(
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

class _Orb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

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

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    gradStart;
  final Color    gradEnd;

  const _HeaderStatChip({
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

// ─── Style Row (list item matching the reference image) ───────────────────────

class _StyleRow extends StatefulWidget {
  final BubbleStyle  style;
  final bool         isSelected;
  final bool         isUnlocked;
  final int          userCoins;
  final VoidCallback onTap;

  const _StyleRow({
    required this.style,
    required this.isSelected,
    required this.isUnlocked,
    required this.userCoins,
    required this.onTap,
  });

  @override
  State<_StyleRow> createState() => _StyleRowState();
}

class _StyleRowState extends State<_StyleRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _classicColors = [
    Color(0xFF4FC3F7), Color(0xFF7C4DFF), Color(0xFFFF6B9D),
    Color(0xFF43E97B), Color(0xFFFFD54F), Color(0xFF4FC3F7),
  ];

  Color get _classicColor {
    final t     = _ctrl.value.clamp(0.0, 1.0);
    final total = _classicColors.length - 1;
    final idx   = (t * total).floor().clamp(0, total - 1);
    return Color.lerp(_classicColors[idx], _classicColors[idx + 1],
        (t * total) - idx)!;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sel       = widget.isSelected;
    final locked    = !widget.isUnlocked;
    final isClassic = widget.style == BubbleStyle.classic;
    final canAfford = widget.userCoins >= widget.style.coinCost;
    final isPremium = widget.style.isPremium;
    final accent    = widget.style.gradientColors.first;

    // Card background: light tint when selected
    final cardColor = sel
        ? accent.withOpacity(0.10)
        : Colors.white;
    final borderColor = sel
        ? accent.withOpacity(0.55)
        : locked
            ? const Color(0xFFFFD740).withOpacity(0.55)
            : const Color(0xFFEEF0FF);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 1.8.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: sel ? 2.0 : 1.2),
          boxShadow: [
            BoxShadow(
              color: sel
                  ? accent.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Bubble preview circle with optional crown ──────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 17.w,
                  height: 17.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                  ),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => ClipOval(
                      child: CustomPaint(
                        painter: isClassic
                            ? _ClassicBubblePainter(
                                animValue: _ctrl.value,
                                tintColor: _classicColor,
                              )
                            : _BubblePreviewPainter(
                                style: widget.style,
                                color: AppColors.bubbleColors[
                                    widget.style.index %
                                        AppColors.bubbleColors.length],
                              ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                // Crown overlapping top of the circle
                if (isPremium)
                  Positioned(
                    top: -12,
                    left: -3,
                    child: Text('👑',
                        style: TextStyle(fontSize: 18.sp,
                            shadows: [Shadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4)])),
                  ),
              ],
            ),

            SizedBox(width: 4.w),

            // ── Name + description / cost ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row
                  Row(
                    children: [
                      if (isClassic)
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => SizedBox(
                            width: 4.5.w,
                            height: 4.5.w,
                            child: CustomPaint(
                              painter: _ClassicBubblePainter(
                                animValue: _ctrl.value,
                                tintColor: _classicColor,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(widget.style.emoji,
                            style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 1.5.w),
                      Text(
                        widget.style.label,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: sel
                              ? accent
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),

                  // Cost or description line
                  if (locked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CoinDisplay(
                          amount: widget.style.coinCost,
                          imageSize: 12,
                          fontSize: 10,
                          textColor: canAfford ? const Color(0xFF2E7D32) : const Color(0xFF9099B0),
                          gap: 3,
                        ),
                        Text(
                          '  🏅 ${widget.style.awardCost} awards',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: canAfford ? const Color(0xFF2E7D32) : const Color(0xFF9099B0),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      widget.style.description,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: const Color(0xFF9099B0),
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: 3.w),

            // ── Trailing: checkmark circle (selected) or lock circle (locked)
            if (sel)
              Container(
                width: 9.w, height: 9.w,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.white, size: 5.w),
              )
            else if (locked)
              Container(
                width: 9.w, height: 9.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFFBE6),
                  border: Border.all(
                      color: const Color(0xFFFFD740).withOpacity(0.7),
                      width: 1.5),
                ),
                child: Icon(Icons.lock_rounded,
                    color: const Color(0xFFFFB300), size: 4.5.w),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

// ─── Classic Glass-Bubble Painter ────────────────────────────────────────────
//
//  Draws a realistic soap/glass bubble matching the reference image:
//  • Translucent light-blue fill
//  • Thin circular border ring
//  • Large top-left gloss oval
//  • Small right-side specular dot
//  • Bottom diffuse glow
//
class _ClassicBubblePainter extends CustomPainter {
  final double animValue;   // 0..1 – used to gently pulse the tint
  final Color tintColor;

  const _ClassicBubblePainter({
    required this.animValue,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.44;

    // ── 1. Body fill — very translucent tinted blue ──────────────────────────
    final baseColor = Color.lerp(
      const Color(0xFFB3E5FC), // light sky-blue
      tintColor,
      0.28,
    )!;

    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 1.0,
        colors: [
          baseColor.withOpacity(0.55),
          baseColor.withOpacity(0.18),
          const Color(0xFF81D4FA).withOpacity(0.08),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // ── 2. Border ring — thin, semi-transparent ──────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF90CAF9).withOpacity(0.70),
          const Color(0xFFE3F2FD).withOpacity(0.90),
          const Color(0xFF64B5F6).withOpacity(0.55),
          const Color(0xFF90CAF9).withOpacity(0.70),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // ── 3. Top-left gloss oval ───────────────────────────────────────────────
    final glossOffset = Offset(cx - r * 0.30, cy - r * 0.30);
    final glossW = r * 0.72;
    final glossH = r * 0.48;

    final glossPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.82),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCenter(
          center: glossOffset, width: glossW * 2, height: glossH * 2));

    canvas.save();
    canvas.translate(glossOffset.dx, glossOffset.dy);
    canvas.scale(1.0, glossH / glossW);
    canvas.drawCircle(Offset.zero, glossW, glossPaint);
    canvas.restore();

    // ── 4. Small specular highlight — right side ─────────────────────────────
    final specPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.75), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(
          center: Offset(cx + r * 0.52, cy - r * 0.10),
          radius: r * 0.20));

    canvas.drawCircle(
        Offset(cx + r * 0.52, cy - r * 0.10), r * 0.20, specPaint);

    // ── 5. Bottom diffuse inner glow ─────────────────────────────────────────
    final bottomGlow = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(0.10, 0.70),
        radius: 0.65,
        colors: [
          const Color(0xFF4FC3F7).withOpacity(0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, bottomGlow);
  }

  @override
  bool shouldRepaint(_ClassicBubblePainter old) =>
      old.animValue != animValue || old.tintColor != old.tintColor;
}

// ─── Preview Painter ──────────────────────────────────────────────────────────

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.38;
    final b  = BubbleModel(
      id: 'preview',
      color: color,
      x: cx,
      y: cy,
      radius: r,
      speed: 0,
      driftAmplitude: 0,
      driftFrequency: 0,
      pointValue: 3,
    );
    BubblePainter(bubbles: [b], level: 3, style: style).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) =>
      old.style != style || old.color != color;
}

// ─── Unlock Dialog ────────────────────────────────────────────────────────────

void showUnlockDialog(
    BuildContext context, BubbleStyle style, StyleService svc) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Obx(() {
        final hasCoins  = svc.totalCoins.value  >= style.coinCost;
        final hasAwards = svc.totalAwards.value >= style.awardCost;
        final canUnlock = hasCoins && hasAwards;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon + crown ───────────────────────────────────────────────
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE0E4FF), width: 2),
                    ),
                    child: Center(
                      child: Text(style.emoji,
                          style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFE0E0E0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Center(
                      child:
                          Text('👑', style: TextStyle(fontSize: 13, height: 1.0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Unlock ${style.label}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                style.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9099B0), height: 1.4),
              ),
              const SizedBox(height: 20),

              // ── Cost: BOTH coins AND awards ────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: canUnlock
                      ? const Color(0xFFF1FDF1)
                      : const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: canUnlock
                        ? const Color(0xFF43A047).withOpacity(0.35)
                        : const Color(0xFFE53935).withOpacity(0.25),
                  ),
                ),
                child: Column(
                  children: [
                    // Label
                    Text(
                      'Required (both needed)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Coins row
                    _CostRow(
                      emoji: '🪙',
                      label: '${style.coinCost} Coins',
                      have: 'You have ${svc.totalCoins.value}',
                      ok: hasCoins,
                      isCoin: true,
                    ),
                    const SizedBox(height: 8),
                    // Awards row
                    _CostRow(
                      emoji: '🏅',
                      label: '${style.awardCost} Awards',
                      have: 'You have ${svc.totalAwards.value}',
                      ok: hasAwards,
                    ),
                  ],
                ),
              ),

              // ── Missing message ────────────────────────────────────────────
              if (!canUnlock) ...[
                const SizedBox(height: 10),
                Text(
                  !hasCoins && !hasAwards
                      ? 'Need ${style.coinCost - svc.totalCoins.value} more coins & ${style.awardCost - svc.totalAwards.value} more awards'
                      : !hasCoins
                          ? 'Need ${style.coinCost - svc.totalCoins.value} more 🪙 coins'
                          : 'Need ${style.awardCost - svc.totalAwards.value} more 🏅 awards',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Unlock button ──────────────────────────────────────────────
              if (canUnlock)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final success = svc.unlockStyle(style);
                      if (!success) {
                        Get.back();
                        return;
                      }
                      Get.find<AdService>().showInterstitial(
                        onDismissed: () {
                          Get.back();
                          svc.setStyle(style);
                          Get.snackbar(
                            '${style.emoji} Unlocked!',
                            '${style.label} style is now active.',
                            backgroundColor: const Color(0xFF6C63FF),
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 14,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unlock — ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        CoinDisplay(amount: style.coinCost, imageSize: 16, fontSize: 14, gap: 3),
                        Text(' + ${style.awardCost} 🏅', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}

// ─── Cost row (used in unlock dialog) ────────────────────────────────────────
class _CostRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String have;
  final bool   ok;
  final bool   isCoin;
  const _CostRow({
    required this.emoji,
    required this.label,
    required this.have,
    required this.ok,
    this.isCoin = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Row(
      children: [
        if (isCoin)
          Image.asset('assets/images/coin.png', width: 20, height: 20)
        else
          Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const Spacer(),
        Text(have,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
          size: 18,
        ),
      ],
    );
  }
}
