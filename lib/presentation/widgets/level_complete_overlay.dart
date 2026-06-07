import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../data/models/level_config.dart';
import '../controllers/game_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEVEL COMPLETE OVERLAY  — white animated theme
//  Phase-in: backdrop blur → card pop → confetti celebration → buttons appear.
// ═══════════════════════════════════════════════════════════════════════════════

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({super.key});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  // Backdrop fade
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;

  // Card pop-in
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  // Stars / celebration loop
  late final AnimationController _celebCtrl;

  // Confetti
  late final AnimationController _confettiCtrl;
  late List<_CelebParticle> _particles;

  // Buttons stagger
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade;
  late final Animation<double> _btnSlide;

  // Score counter animation
  late final AnimationController _scoreCtrl;
  late final Animation<int> _scoreAnim;

  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();

    final ctrl = Get.find<GameController>();
    final finalScore = ctrl.coinsThisLevel.value; // score earned this level

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _cardScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);

    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _particles = List.generate(70, (_) => _CelebParticle(_rnd));

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn);
    _btnSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOutCubic));

    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = IntTween(begin: 0, end: finalScore).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));

    // Stagger the sequence
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _cardCtrl.forward();
      _confettiCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _scoreCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _celebCtrl.dispose();
    _confettiCtrl.dispose();
    _btnCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<GameController>();

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Frosted white backdrop ────────────────────────────────────────
        FadeTransition(
          opacity: _bgFade,
          child: Container(color: Colors.white.withOpacity(0.88)),
        ),

        // ── Confetti ─────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, __) => CustomPaint(
            painter: _CelebConfettiPainter(
              particles: _particles,
              progress: _confettiCtrl.value,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // ── Main card ────────────────────────────────────────────────────
        Center(
          child: AnimatedBuilder(
            animation: _cardCtrl,
            builder: (_, child) => FadeTransition(
              opacity: _cardFade,
              child: Transform.scale(scale: _cardScale.value, child: child),
            ),
            child: _LevelCard(
              ctrl: ctrl,
              celebCtrl: _celebCtrl,
              scoreAnim: _scoreAnim,
              btnFade: _btnFade,
              btnSlide: _btnSlide,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Main card ────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final GameController ctrl;
  final AnimationController celebCtrl;
  final Animation<int> scoreAnim;
  final Animation<double> btnFade;
  final Animation<double> btnSlide;

  const _LevelCard({
    required this.ctrl,
    required this.celebCtrl,
    required this.scoreAnim,
    required this.btnFade,
    required this.btnSlide,
  });

  static const _skinNames = ['', 'Soap', 'Vivid', 'Neon ✨', 'Gold 🌟', 'Crystal 💎', 'Fire 🔥', 'Rainbow 🌈'];
  String _skin(int lv) => lv < _skinNames.length ? _skinNames[lv] : 'Rainbow 🌈';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final doneLv   = ctrl.completedLevel.value;
      final nextLv   = ctrl.level.value;
      final hearts   = ctrl.lives.value;
      final target   = LevelConfig.scoreTargetForLevel(doneLv);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 40, offset: const Offset(0, 16)),
            BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient header ──────────────────────────────────────────
              _CardHeader(doneLv: doneLv, celebCtrl: celebCtrl, skinName: _skin(doneLv)),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 3.h),
                child: Column(
                  children: [
                    // Score counter
                    _ScoreCounter(scoreAnim: scoreAnim, target: target),
                    SizedBox(height: 2.5.h),

                    // Stats row
                    Row(
                      children: [
                        _StatPill(emoji: '❤️', label: 'Hearts', value: '$hearts', color: const Color(0xFFFF4D6D)),
                        SizedBox(width: 3.w),
                        _StatPill(emoji: '🚀', label: 'Next Level', value: 'LVL $nextLv', color: const Color(0xFF6C63FF)),
                      ],
                    ),
                    SizedBox(height: 2.5.h),

                    // Next level badge
                    _NextLevelBadge(nextLv: nextLv, skinName: _skin(nextLv)),
                    SizedBox(height: 3.h),

                    // Action buttons
                    FadeTransition(
                      opacity: btnFade,
                      child: AnimatedBuilder(
                        animation: btnSlide,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, btnSlide.value),
                          child: child,
                        ),
                        child: Column(
                          children: [
                            _PrimaryBtn(
                              label: 'Next Level →',
                              colors: const [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                              onTap: () => ctrl.continueAfterLevelComplete(),
                            ),
                            SizedBox(height: 1.5.h),
                            _SecondaryBtn(
                              label: '🏠  Go Home',
                              onTap: () => ctrl.navigateHome(),
                            ),
                          ],
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
    });
  }
}

// ─── Card header ─────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final int doneLv;
  final AnimationController celebCtrl;
  final String skinName;

  const _CardHeader({required this.doneLv, required this.celebCtrl, required this.skinName});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebCtrl,
      builder: (_, __) {
        final t = celebCtrl.value;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 2.5.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF6C63FF), const Color(0xFF48CAE4), t)!,
                Color.lerp(const Color(0xFF48CAE4), const Color(0xFF6C63FF), t)!,
              ],
            ),
          ),
          child: Column(
            children: [
              // Spinning trophy
              Transform.rotate(
                angle: math.sin(t * 2 * math.pi) * 0.08,
                child: Transform.scale(
                  scale: 1.0 + math.sin(t * 2 * math.pi) * 0.06,
                  child: Text('🏆', style: TextStyle(fontSize: 30.sp)),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'LEVEL $doneLv COMPLETE!',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                ),
              ),
              SizedBox(height: 0.6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skinName,
                  style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Score counter ────────────────────────────────────────────────────────────

class _ScoreCounter extends StatelessWidget {
  final Animation<int> scoreAnim;
  final int target;
  const _ScoreCounter({required this.scoreAnim, required this.target});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F0FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.18), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                'Score This Level',
                style: TextStyle(fontSize: 9.5.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              SizedBox(height: 0.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_rounded, color: const Color(0xFF6C63FF), size: 6.w),
                  SizedBox(width: 1.5.w),
                  Text(
                    '${scoreAnim.value}',
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF)),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '/ $target pts',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatPill({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.20), width: 1.2),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 0.3.h),
            Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 8.5.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Next level badge ─────────────────────────────────────────────────────────

class _NextLevelBadge extends StatelessWidget {
  final int nextLv;
  final String skinName;
  const _NextLevelBadge({required this.nextLv, required this.skinName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF48CAE4), Color(0xFF6C63FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🚀', style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 2.w),
          Text(
            'Level $nextLv — $skinName',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buttons ─────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.colors, required this.onTap});

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.colors),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.colors.last.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryBtn({required this.label, required this.onTap});

  @override
  State<_SecondaryBtn> createState() => _SecondaryBtnState();
}

class _SecondaryBtnState extends State<_SecondaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Celebration confetti ─────────────────────────────────────────────────────

class _CelebParticle {
  final double x, speed, size, angle, angularSpeed, drift;
  final Color color;

  _CelebParticle(math.Random rnd)
      : x = rnd.nextDouble(),
        speed = 0.25 + rnd.nextDouble() * 0.75,
        size = 5 + rnd.nextDouble() * 9,
        angle = rnd.nextDouble() * math.pi * 2,
        angularSpeed = (rnd.nextDouble() - 0.5) * 8,
        drift = (rnd.nextDouble() - 0.5) * 0.2,
        color = _kColors[rnd.nextInt(_kColors.length)];

  static const _kColors = [
    Color(0xFF6C63FF), Color(0xFF48CAE4), Color(0xFFFFD700),
    Color(0xFFFF4D6D), Color(0xFF43E97B), Color(0xFFFF8C00),
  ];
}

class _CelebConfettiPainter extends CustomPainter {
  final List<_CelebParticle> particles;
  final double progress;
  _CelebConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (progress * p.speed * 1.3).clamp(0.0, 1.3);
      final x = p.x + p.drift * progress;
      final angle = p.angle + p.angularSpeed * progress;
      final fade = (1.0 - (progress - 0.65).clamp(0.0, 0.35) / 0.35).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
        Paint()..color = p.color.withOpacity(fade * 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebConfettiPainter old) => old.progress != progress;
}
