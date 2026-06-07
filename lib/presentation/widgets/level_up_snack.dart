import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEVEL-UP SNACK
//  A beautiful bottom-slide toast that fires as soon as the level threshold is
//  hit. Sequence:
//   0 ms  → slides up from below + scale pop + sparkle burst
//   1600 ms → begins slide back down (exit)
//   2200 ms → fully off screen (controller shows full overlay next)
// ═══════════════════════════════════════════════════════════════════════════════

class LevelUpSnack extends StatefulWidget {
  final int completedLevel;
  final int nextLevel;

  const LevelUpSnack({
    super.key,
    required this.completedLevel,
    required this.nextLevel,
  });

  @override
  State<LevelUpSnack> createState() => _LevelUpSnackState();
}

class _LevelUpSnackState extends State<LevelUpSnack>
    with TickerProviderStateMixin {

  // ── Slide + fade (entry & exit share the same controller) ─────────────────
  late final AnimationController _slideCtrl;
  late final Animation<double>   _slideY;   // 0 = fully visible, 1 = off screen below
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  // ── Sparkle particles ─────────────────────────────────────────────────────
  late final AnimationController _sparkleCtrl;
  late final List<_SparkDot>     _sparks;

  // ── Shimmer loop on the badge ─────────────────────────────────────────────
  late final AnimationController _shimmerCtrl;

  // ── Level number pop-scale ────────────────────────────────────────────────
  late final AnimationController _numCtrl;
  late final Animation<double>   _numScale;

  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();

    _sparks = List.generate(18, (_) => _SparkDot(_rnd));

    // ── Entry: slide up + scale pop
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slideY = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.0, 0.6));
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.elasticOut),
    );
    _slideCtrl.forward();

    // ── Sparkle burst (runs once, 900 ms)
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // ── Shimmer loop
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // ── Level number pop
    _numCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _numScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _numCtrl, curve: Curves.elasticOut),
    );
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _numCtrl.forward();
    });

    // ── Exit: slide back down at 1600 ms
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _slideCtrl.reverse();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _sparkleCtrl.dispose();
    _shimmerCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _slideCtrl,
        builder: (_, child) {
          final offY = _slideY.value * (28.h + 80); // slide distance
          return Transform.translate(
            offset: Offset(0, offY),
            child: FadeTransition(
              opacity: _fade,
              child: Transform.scale(
                scale: _scale.value,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Sparkle burst above the card ────────────────────────────────
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _sparkleCtrl,
                builder: (_, __) => CustomPaint(
                  size: Size(double.infinity, 80),
                  painter: _SparklePainter(
                    sparks: _sparks,
                    progress: _sparkleCtrl.value,
                  ),
                ),
              ),
            ),

            // ── Snack card ───────────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Shimmer overlay
                      AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, __) {
                          final x = _shimmerCtrl.value * 2 - 0.5;
                          return Positioned.fill(
                            child: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) => LinearGradient(
                                begin: Alignment(x - 0.5, 0),
                                end:   Alignment(x + 0.5, 0),
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0),
                                ],
                              ).createShader(bounds),
                              child: Container(color: Colors.white),
                            ),
                          );
                        },
                      ),

                      // Content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.2.h),
                        child: Row(
                          children: [
                            // Trophy icon with glow
                            Container(
                              width: 14.w,
                              height: 14.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.20),
                                border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
                              ),
                              child: Center(
                                child: Text('🏆', style: TextStyle(fontSize: 18.sp)),
                              ),
                            ),

                            SizedBox(width: 4.w),

                            // Text block
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'LEVEL ${widget.completedLevel} COMPLETE!',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                  ),
                                  SizedBox(height: 0.4.h),
                                  Row(
                                    children: [
                                      Text(
                                        'Moving to  ',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _numCtrl,
                                        builder: (_, __) => Transform.scale(
                                          scale: _numScale.value,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.3.h),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              'Level ${widget.nextLevel}',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF6C63FF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 2.w),

                            // Animated arrow
                            _PulsingArrow(),
                          ],
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
    );
  }
}

// ─── Pulsing arrow ────────────────────────────────────────────────────────────

class _PulsingArrow extends StatefulWidget {
  @override
  State<_PulsingArrow> createState() => _PulsingArrowState();
}

class _PulsingArrowState extends State<_PulsingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _x;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _x = Tween<double>(begin: 0, end: 6).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(_x.value, 0),
        child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 5.w),
      ),
    );
  }
}

// ─── Sparkle painter ─────────────────────────────────────────────────────────

class _SparkDot {
  final double angle;
  final double speed;
  final double size;
  final Color  color;

  _SparkDot(math.Random rnd)
      : angle = rnd.nextDouble() * 2 * math.pi,
        speed = 30 + rnd.nextDouble() * 55,
        size  = 3 + rnd.nextDouble() * 6,
        color = _kColors[rnd.nextInt(_kColors.length)];

  static const _kColors = [
    Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFF48CAE4),
    Color(0xFFFF4D6D), Color(0xFF43E97B), Color(0xFFE040FB),
  ];
}

class _SparklePainter extends CustomPainter {
  final List<_SparkDot> sparks;
  final double progress;
  _SparklePainter({required this.sparks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cx = size.width / 2;
    final cy = size.height;

    for (final s in sparks) {
      final dist   = s.speed * progress;
      final x      = cx + math.cos(s.angle) * dist;
      final y      = cy - math.sin(s.angle.abs()) * dist * 0.6;
      final radius = s.size * (1 - progress * 0.6);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        radius.clamp(0.5, 12),
        Paint()..color = s.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
