import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GIFT SCREEN OVERLAY  — white theme
//  Phase 1: bouncing gift box + "Tap to open" hint.
//  Phase 2: lid flies off → confetti → reward card slides up.
// ═══════════════════════════════════════════════════════════════════════════════

class GiftScreenOverlay extends StatefulWidget {
  const GiftScreenOverlay({super.key});

  @override
  State<GiftScreenOverlay> createState() => _GiftScreenOverlayState();
}

class _GiftScreenOverlayState extends State<GiftScreenOverlay>
    with TickerProviderStateMixin {
  bool _opened = false;

  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceY;
  late final Animation<double> _wobble;

  late final AnimationController _shimmerCtrl;

  late final AnimationController _lidCtrl;
  late final Animation<double> _lidFly;
  late final Animation<double> _lidFade;

  late final AnimationController _shatterCtrl;
  late final Animation<double> _boxScale;

  late final AnimationController _confettiCtrl;
  late List<_Particle> _particles;

  late final AnimationController _cardCtrl;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _cardScale;

  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0, end: -14).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _wobble  = Tween<double>(begin: -0.04, end: 0.04).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

    _lidCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _lidFly  = Tween<double>(begin: 0, end: -130).animate(CurvedAnimation(parent: _lidCtrl, curve: Curves.easeOut));
    _lidFade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _lidCtrl, curve: const Interval(0.35, 1.0)));

    _shatterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _boxScale = Tween<double>(begin: 1.0, end: 1.16).animate(CurvedAnimation(parent: _shatterCtrl, curve: Curves.easeOutBack));

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _particles = List.generate(65, (_) => _Particle(_rnd));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _cardSlide = Tween<double>(begin: 70, end: 0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardScale = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _bounceCtrl.dispose();
    _shimmerCtrl.dispose();
    _lidCtrl.dispose();
    _shatterCtrl.dispose();
    _confettiCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  void _openGift() {
    if (_opened) return;
    setState(() => _opened = true);
    _bounceCtrl.stop();
    _lidCtrl.forward();
    _shatterCtrl.forward();
    _confettiCtrl.forward();
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl        = Get.find<GameController>();
    final rewardType  = ctrl.giftRewardType.value;
    final newBest     = ctrl.newBestScore.value;

    return FadeTransition(
      opacity: _bgFade,
      child: Container(
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft radial tint so it's not stark white
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [Color(0xFFEEF4FF), Color(0xFFFFFFFF)],
                ),
              ),
            ),

            // Floating circles decoration
            const _FloatingCircles(),

            // Confetti (phase 2)
            if (_opened)
              AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(particles: _particles, progress: _confettiCtrl.value),
                  child: const SizedBox.expand(),
                ),
              ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 3.h),

                  // NEW BEST badge
                  _NewBestBadge(score: newBest, shimmer: _shimmerCtrl),

                  const Spacer(),

                  // Gift box
                  if (!_opened)
                    AnimatedBuilder(
                      animation: _bounceCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounceY.value),
                        child: Transform.rotate(angle: _wobble.value, child: child),
                      ),
                      child: GestureDetector(
                        onTap: _openGift,
                        child: _GiftBoxWidget(shimmer: _shimmerCtrl),
                      ),
                    )
                  else
                    AnimatedBuilder(
                      animation: _shatterCtrl,
                      builder: (_, child) => Transform.scale(scale: _boxScale.value, child: child),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          _GiftBodyWidget(),
                          AnimatedBuilder(
                            animation: _lidCtrl,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _lidFly.value),
                              child: Opacity(opacity: _lidFade.value.clamp(0.0, 1.0), child: child),
                            ),
                            child: _GiftLidWidget(),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 3.h),

                  // Tap hint (phase 1)
                  if (!_opened) _TapHint(shimmer: _shimmerCtrl),

                  // Reward card (phase 2)
                  if (_opened)
                    AnimatedBuilder(
                      animation: _cardCtrl,
                      builder: (_, child) => FadeTransition(
                        opacity: _cardFade,
                        child: Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Transform.scale(scale: _cardScale.value, child: child),
                        ),
                      ),
                      child: _RewardCard(
                        rewardType: rewardType,
                        shimmer: _shimmerCtrl,
                        onClaim: () => ctrl.claimGift(),
                      ),
                    ),

                  const Spacer(),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating decorative circles (background) ─────────────────────────────────

class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles();

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    return Stack(children: [
      _Circle(x: 0.08, y: 0.12, r: 60, color: const Color(0xFF6C63FF), opacity: 0.08 + 0.04 * math.sin(t * 2 * math.pi)),
      _Circle(x: 0.88, y: 0.08, r: 80, color: const Color(0xFFFFD700), opacity: 0.07 + 0.03 * math.sin(t * 2 * math.pi + 1)),
      _Circle(x: 0.05, y: 0.82, r: 70, color: const Color(0xFF43E97B), opacity: 0.07 + 0.03 * math.sin(t * 2 * math.pi + 2)),
      _Circle(x: 0.92, y: 0.75, r: 55, color: const Color(0xFFFF4D6D), opacity: 0.08 + 0.04 * math.sin(t * 2 * math.pi + 3)),
      _Circle(x: 0.5, y: 0.95, r: 90, color: const Color(0xFF48CAE4), opacity: 0.06 + 0.03 * math.sin(t * 2 * math.pi + 1.5)),
    ]);
  }
}

class _Circle extends StatelessWidget {
  final double x, y, r, opacity;
  final Color color;
  const _Circle({required this.x, required this.y, required this.r, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: x * size.width - r,
      top: y * size.height - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

// ─── NEW BEST badge ───────────────────────────────────────────────────────────

class _NewBestBadge extends StatelessWidget {
  final int score;
  final AnimationController shimmer;
  const _NewBestBadge({required this.score, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        final pulse = 0.5 + 0.5 * math.sin(shimmer.value * 2 * math.pi);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.2.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.45 + 0.25 * pulse),
                blurRadius: 18 + 10 * pulse,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 2.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEW HIGH SCORE!',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
                  Text(
                    '$score pts',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 2.w),
              Text('🏆', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Gift box widgets (drawn with plain shapes, no shader-on-empty-rect) ──────

class _GiftBoxWidget extends StatelessWidget {
  final AnimationController shimmer;
  const _GiftBoxWidget({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: AnimatedBuilder(
        animation: shimmer,
        builder: (_, __) => _GiftStack(shimmerT: shimmer.value),
      ),
    );
  }
}

class _GiftBodyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: const _GiftStack(shimmerT: 0, lidVisible: false),
    );
  }
}

class _GiftLidWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      height: 17.w,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
        ),
        child: Center(
          child: Container(
            width: 6.w,
            height: double.infinity,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
    );
  }
}

// All parts composited in a Stack — no LinearGradient.createShader calls
class _GiftStack extends StatelessWidget {
  final double shimmerT;
  final bool lidVisible;
  const _GiftStack({this.shimmerT = 0, this.lidVisible = true});

  @override
  Widget build(BuildContext context) {
    final boxW = 50.w;
    final boxH = 50.w;
    final lidH = boxH * 0.30;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Body
        Positioned(
          top: lidH,
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
            ),
          ),
        ),

        // Vertical ribbon on body
        Positioned(
          top: lidH,
          bottom: 0,
          left: boxW * 0.46,
          width: boxW * 0.08,
          child: const ColoredBox(color: Color(0xFFFFD700)),
        ),

        // Horizontal ribbon on body
        Positioned(
          top: lidH + (boxH - lidH) * 0.45,
          left: 0,
          right: 0,
          height: boxW * 0.08,
          child: const ColoredBox(color: Color(0xFFFFD700)),
        ),

        // Lid
        if (lidVisible)
          Positioned(
            top: 0,
            left: -boxW * 0.04,
            right: -boxW * 0.04,
            height: lidH + 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        // Vertical ribbon on lid
        if (lidVisible)
          Positioned(
            top: 0,
            height: lidH + 4,
            left: boxW * 0.46,
            width: boxW * 0.08,
            child: const ColoredBox(color: Color(0xFFFFD700)),
          ),

        // Bow (left loop)
        Positioned(
          top: 0,
          left: boxW * 0.18,
          child: _BowLoop(flip: false, shimmerT: shimmerT),
        ),

        // Bow (right loop)
        Positioned(
          top: 0,
          right: boxW * 0.18,
          child: _BowLoop(flip: true, shimmerT: shimmerT),
        ),

        // Knot
        Positioned(
          top: lidH * -0.05,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: boxW * 0.12,
              height: boxW * 0.12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF8F00),
              ),
            ),
          ),
        ),

        // Shimmer highlight
        Positioned(
          top: lidH + 4,
          left: boxW * 0.08,
          child: AnimatedOpacity(
            opacity: (0.12 + 0.10 * shimmerT).clamp(0.0, 1.0),
            duration: Duration.zero,
            child: Container(
              width: boxW * 0.35,
              height: (boxH - lidH) * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BowLoop extends StatelessWidget {
  final bool flip;
  final double shimmerT;
  const _BowLoop({required this.flip, required this.shimmerT});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFFF176), shimmerT)!;
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: CustomPaint(
        size: Size(8.w, 8.w),
        painter: _BowPainter(color: color),
      ),
    );
  }
}

class _BowPainter extends CustomPainter {
  final Color color;
  const _BowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.9, size.height * 0.9)
      ..quadraticBezierTo(0, 0, size.width * 0.5, size.height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BowPainter old) => old.color != color;
}

// ─── Tap hint ─────────────────────────────────────────────────────────────────

class _TapHint extends StatelessWidget {
  final AnimationController shimmer;
  const _TapHint({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) => Opacity(
        opacity: (0.5 + 0.5 * shimmer.value).clamp(0.0, 1.0),
        child: Column(
          children: [
            Icon(Icons.touch_app_rounded, color: const Color(0xFF6C63FF), size: 7.w),
            SizedBox(height: 0.5.h),
            Text(
              'Tap the gift to open!',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reward card ─────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final int rewardType;
  final AnimationController shimmer;
  final VoidCallback onClaim;
  const _RewardCard({required this.rewardType, required this.shimmer, required this.onClaim});

  static const _rewards = [
    _RewardData(emoji: '❤️', title: '+1 Heart',  subtitle: 'Extra life added!',        colors: [Color(0xFFFF4D6D), Color(0xFFE91E63)]),
    _RewardData(emoji: '🪙', title: '+5 Coins',  subtitle: 'Coins added to wallet!',   colors: [Color(0xFFFFD700), Color(0xFFFF8F00)]),
    _RewardData(emoji: '🏅', title: '+1 Award',  subtitle: 'Achievement unlocked!',    colors: [Color(0xFF43E97B), Color(0xFF11998E)]),
  ];

  @override
  Widget build(BuildContext context) {
    final reward = _rewards[rewardType.clamp(0, 2)];

    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        final pulse = 0.4 + 0.6 * shimmer.value;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 7.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: reward.colors.first.withOpacity(0.30 * pulse), blurRadius: 28 + 10 * pulse, spreadRadius: 2),
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 5.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reward.colors.first.withOpacity(0.12),
                    border: Border.all(color: reward.colors.first.withOpacity(0.30), width: 2),
                  ),
                  child: Center(child: Text(reward.emoji, style: TextStyle(fontSize: 24.sp))),
                ),
                SizedBox(height: 2.h),

                Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: reward.colors.first,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  reward.subtitle,
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 3.h),

                // Claim button
                GestureDetector(
                  onTap: onClaim,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    decoration: BoxDecoration(
                      color: reward.colors.first,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: reward.colors.first.withOpacity(0.40), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(reward.emoji, style: TextStyle(fontSize: 13.sp)),
                        SizedBox(width: 2.w),
                        Text(
                          'Claim & Continue',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RewardData {
  final String emoji, title, subtitle;
  final List<Color> colors;
  const _RewardData({required this.emoji, required this.title, required this.subtitle, required this.colors});
}

// ─── Confetti painter ─────────────────────────────────────────────────────────

class _Particle {
  final double x, speed, size, angle, angularSpeed, drift;
  final Color color;

  _Particle(math.Random rnd)
      : x            = rnd.nextDouble(),
        speed        = 0.28 + rnd.nextDouble() * 0.72,
        size         = 5 + rnd.nextDouble() * 9,
        angle        = rnd.nextDouble() * math.pi * 2,
        angularSpeed = (rnd.nextDouble() - 0.5) * 7,
        drift        = (rnd.nextDouble() - 0.5) * 0.22,
        color        = _colors[rnd.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFF6C63FF), Color(0xFF48CAE4), Color(0xFFFFD700),
    Color(0xFFFF4D6D), Color(0xFF43E97B), Color(0xFFFF8C00),
    Color(0xFFE040FB), Color(0xFF76FF03),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (final p in particles) {
      final y     = (progress * p.speed * 1.35).clamp(0.0, 1.35);
      final x     = (p.x + p.drift * progress).clamp(-0.1, 1.1);
      final angle = p.angle + p.angularSpeed * progress;
      final fade  = (1.0 - ((progress - 0.65) / 0.35).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
        Paint()..color = p.color.withOpacity(fade.clamp(0.0, 0.9)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
