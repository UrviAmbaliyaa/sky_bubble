import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/models/bubble_model.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/bubble_painter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _Background()),
          const SafeArea(child: _HomeUI()),
          // Celebration overlay removed — the 🏆 New High Score banner now
          // appears directly on the game screen while the player is still
          // playing, making it more immediate and correctly positioned.
        ],
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/home_screen.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

// ─── Home UI ──────────────────────────────────────────────────────────────────

class _HomeUI extends GetView<HomeController> {
  const _HomeUI();

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnim,
      child: SlideTransition(
        position: controller.slideAnim,
        child: Column(
          children: [
            SizedBox(height: 1.5.h),
            Obx(() => controller.bestScore.value == 0
                ? const SizedBox.shrink()
                : _BestScorePill(controller: controller)),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlayButton(onPressed: controller.navigateToGame),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          icon: Icons.leaderboard_rounded,
                          iconColor: const Color(0xFFFFD54F),
                          label: 'PROGRESS',
                          onPressed: controller.navigateToScores,
                        ),
                      ),
                      SizedBox(width: 3.5.w),
                      const Expanded(child: _StyleButton()),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BEST SCORE PILL
// ═══════════════════════════════════════════════════════════════════════════════

class _BestScorePill extends StatelessWidget {
  final HomeController controller;
  const _BestScorePill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD740).withOpacity(0.18),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: const Color(0xFFFFD740).withOpacity(0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9100).withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 17.sp)),
              SizedBox(width: 2.5.w),
              Text(
                '${controller.bestScore.value} pts',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PLAY BUTTON  — circular, layered, 3-D glow design
// ═══════════════════════════════════════════════════════════════════════════════

class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PlayButton({required this.onPressed});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: ctrl.pulseAnim,
        builder: (_, child) => AnimatedScale(
          scale: _pressed ? 0.93 : ctrl.pulseAnim.value,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
        child: Container(
          width: 55.w,
          height: 7.5.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00D4FF), Color(0xFF007AFF)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.50), blurRadius: 20, offset: const Offset(0, 8)),
              BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                'PLAY',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SECONDARY BUTTON  (Leaderboard / Progress)
// ═══════════════════════════════════════════════════════════════════════════════

class _SecondaryButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 5.5.w),
                  SizedBox(width: 2.w),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STYLE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _StyleButton extends StatefulWidget {
  const _StyleButton();

  @override
  State<_StyleButton> createState() => _StyleButtonState();
}

class _StyleButtonState extends State<_StyleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showBubbleStyleSheet(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Obx(() {
          final style = Get.find<StyleService>().selectedStyle.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Classic uses the bubble icon (🫧 renders as water-drop on
                    // older Android); all other styles keep their safe emojis.
                    if (style == BubbleStyle.classic)
                      Icon(Icons.bubble_chart_rounded,
                          color: Colors.white, size: 14.sp)
                    else
                      Text(style.emoji, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 2.w),
                    Text(
                      'STYLE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUBBLE STYLE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

void _showBubbleStyleSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _BubbleStyleSheet(),
  );
}

class _BubbleStyleSheet extends StatelessWidget {
  const _BubbleStyleSheet();

  @override
  Widget build(BuildContext context) {
    final svc        = Get.find<StyleService>();
    final bottomPad  = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 1.5.h),
          // drag handle
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // header banner
          _StyleSheetHeader(onClose: () => Navigator.of(context).pop()),
          SizedBox(height: 1.5.h),
          // style list
          Flexible(
            child: Obx(() {
              final current = svc.selectedStyle.value;
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: BubbleStyle.values.length,
                itemBuilder: (_, i) {
                  final style = BubbleStyle.values[i];
                  return _StyleCard(
                    style: style,
                    isSelected: current == style,
                    onTap: () {
                      svc.setStyle(style);
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            }),
          ),
          SizedBox(height: bottomPad + 2.h),
        ],
      ),
    );
  }
}

// ─── Style Sheet Header ───────────────────────────────────────────────────────

class _StyleSheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _StyleSheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF4FC3F7), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 22.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bubble Style',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  'Tap a style to play with it',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 9.w,
              height: 9.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 4.5.w),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Style Card ───────────────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  final BubbleStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  late final Animation<double>   _bobAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -3.0, end: 3.0)
        .animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.style.gradientColors.first;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(bottom: 1.2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: widget.isSelected ? accent.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? accent : const Color(0xFFE8EDF5),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [BoxShadow(color: accent.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // bubble preview
              _BubblePreviewCircle(style: widget.style, bobAnim: _bobAnim),
              SizedBox(width: 3.5.w),
              // label + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // Classic: use the vector bubble icon so it renders on
                      // all Android versions (🫧 is Unicode 14, fails below A12).
                      if (widget.style == BubbleStyle.classic)
                        Icon(Icons.bubble_chart_rounded,
                            color: accent, size: 15.sp)
                      else
                        Text(widget.style.emoji,
                            style: TextStyle(fontSize: 15.sp)),
                      SizedBox(width: 1.5.w),
                      Text(
                        widget.style.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.isSelected ? accent : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(
                      widget.style.description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF9099B0),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // checkmark
              SizedBox(
                width: 7.w,
                height: 7.w,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isSelected
                      ? Container(
                          key: const ValueKey('check'),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.style.gradientColors,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 4.5.w),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bubble Preview Circle ─────────────────────────────────────────────────────

class _BubblePreviewCircle extends StatelessWidget {
  final BubbleStyle style;
  final Animation<double> bobAnim;
  const _BubblePreviewCircle({required this.style, required this.bobAnim});

  @override
  Widget build(BuildContext context) {
    final accent = style.gradientColors.first;
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.22), width: 1.2),
      ),
      child: AnimatedBuilder(
        animation: bobAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, bobAnim.value),
          child: ClipOval(
            child: CustomPaint(
              painter: _BubblePreviewPainter(
                style: style,
                color: AppColors.bubbleColors[style.index % AppColors.bubbleColors.length],
              ),
              // SizedBox.expand ensures CustomPaint always fills its parent
              // on older Android versions (API 29/30) where size can be zero.
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bubble Preview Painter ────────────────────────────────────────────────────

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.44;
    final b  = BubbleModel(
      id: 'preview',
      color: color,
      x: cx, y: cy,
      radius: r,
      speed: 0,
      driftAmplitude: 0,
      driftFrequency: 0,
      pointValue: 3,
    );
    BubblePainter(bubbles: [b], level: 5, style: style).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) =>
      old.style != style || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CELEBRATION OVERLAY  — shown when player achieves a new personal best
// ═══════════════════════════════════════════════════════════════════════════════

// ── Confetti particle data ────────────────────────────────────────────────────

class _Particle {
  final double startX;   // 0–1 fraction of screen width
  final double startY;   // slightly above screen top (negative fraction)
  final double speed;    // fall speed multiplier
  final double radius;   // confetti piece size
  final double driftX;   // horizontal sway magnitude
  final double rotSpeed; // rotation speed
  final Color  color;

  _Particle(math.Random r)
      : startX   = r.nextDouble(),
        startY   = -0.05 - r.nextDouble() * 0.25,
        speed     = 0.25 + r.nextDouble() * 0.75,
        radius    = 4.0 + r.nextDouble() * 7.0,
        driftX    = (r.nextDouble() - 0.5) * 0.25,
        rotSpeed  = (r.nextDouble() - 0.5) * 8.0,
        color     = _kConfettiColors[r.nextInt(_kConfettiColors.length)];

  static const _kConfettiColors = [
    Color(0xFFFFD700), Color(0xFFFF6B9D), Color(0xFF43E97B),
    Color(0xFF4FC3F7), Color(0xFFCE93D8), Color(0xFFFF8A65),
    Color(0xFFFFFFFF), Color(0xFF00D4FF), Color(0xFFFF4081),
  ];
}

// ── Confetti painter ──────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0.0 → 1.0 over the overlay lifetime

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Each particle has its own phase so they don't all move in sync.
      final t = ((progress * (1.0 / p.speed)) % 1.0);
      final x = (p.startX + p.driftX * t) * size.width;
      final y = (p.startY + t * 1.3) * size.height;

      // Fade in at top, fade out near bottom
      final opacity = (t < 0.1
          ? t / 0.1
          : t > 0.75
              ? (1.0 - t) / 0.25
              : 1.0).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      paint.color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotSpeed * progress * math.pi * 2);
      // Draw a small rounded rectangle (confetti ticket shape)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.radius * 1.6,
            height: p.radius * 0.7,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── Celebration card ──────────────────────────────────────────────────────────

class _CelebrationCard extends StatelessWidget {
  final int score;
  final Animation<double> countdown; // 0→1 over the auto-close duration
  final VoidCallback onDismiss;

  const _CelebrationCard({
    required this.score,
    required this.countdown,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 3.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A6E), Color(0xFF2D0082), Color(0xFF0D1B4A)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.65),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.30),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy
          Text('🏆', style: TextStyle(fontSize: 48.sp)),
          SizedBox(height: 1.h),
          // Title
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ).createShader(b),
            child: Text(
              'NEW BEST SCORE!',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.8,
              ),
            ),
          ),
          SizedBox(height: 2.5.h),
          // Score badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 1.8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.50),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
              ),
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            'pts',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.5.h),
          // Countdown progress bar
          AnimatedBuilder(
            animation: countdown,
            builder: (_, __) => Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 1.0 - countdown.value, // shrinks left as time passes
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                    minHeight: 5,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Tap anywhere to close',
                  style: TextStyle(fontSize: 9.5.sp, color: Colors.white30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Celebration overlay (full-screen) ─────────────────────────────────────────

class _CelebrationOverlay extends StatefulWidget {
  final int score;
  final VoidCallback onDismiss;

  const _CelebrationOverlay({required this.score, required this.onDismiss});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  // Controls confetti falling + particle lifecycle
  late final AnimationController _confettiCtrl;
  // Controls the card pop-in (scale + fade)
  late final AnimationController _popCtrl;
  // Controls the auto-close countdown bar
  late final AnimationController _countdownCtrl;

  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  late final List<_Particle> _particles;

  static const _autoClose = Duration(milliseconds: 4000);

  @override
  void initState() {
    super.initState();

    // Generate confetti particles once
    final rng = math.Random();
    _particles = List.generate(70, (_) => _Particle(rng));

    // Confetti loops: particles cycle through the screen continuously
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _confettiCtrl.addListener(() => setState(() {}));

    // Card pops in with a spring effect
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _cardScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut),
    );
    _cardFade = CurvedAnimation(parent: _popCtrl, curve: Curves.easeIn);

    // Countdown runs for the full auto-close duration
    _countdownCtrl = AnimationController(vsync: this, duration: _autoClose)
      ..forward();
    _countdownCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _popCtrl.dispose();
    _countdownCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _popCtrl,
        builder: (_, __) => FadeTransition(
          opacity: _cardFade,
          child: Container(
            color: Colors.black.withOpacity(0.68),
            child: Stack(
              children: [
                // Falling confetti layer (repaints on every frame)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiCtrl.value,
                    ),
                  ),
                ),
                // Centred card with spring pop-in
                Center(
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: _CelebrationCard(
                      score: widget.score,
                      countdown: _countdownCtrl,
                      onDismiss: widget.onDismiss,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
