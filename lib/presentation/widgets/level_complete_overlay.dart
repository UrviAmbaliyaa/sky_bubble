import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/models/level_config.dart';
import '../../data/services/ad_service.dart';
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final bannerH   = AdSize.banner.height.toDouble();

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

        // ── Main card (leaves room for the banner + safe area below) ─────
        Positioned(
          top: 0, left: 0, right: 0,
          bottom: bannerH + bottomPad + 10,
          child: Center(
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
        ),

        // ── Banner ad pinned above the system home indicator ─────────────
        Obx(() {
          RemoteAdConfigService? remote;
          try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
          final adsOn = remote?.adsEnabled.value ?? false;
          if (!adsOn) return const SizedBox.shrink();
          return Positioned(
            bottom: bottomPad,
            left: 0,
            right: 0,
            child: const _LevelCompleteBanner(),
          );
        }),
      ],
    );
  }
}

// ─── Level-specific color palette ────────────────────────────────────────────

class _LevelTheme {
  final Color primary;
  final Color secondary;
  final String trophy;

  const _LevelTheme({required this.primary, required this.secondary, required this.trophy});

  // 10 rotating themes — cycles every 10 levels
  static const _themes = [
    _LevelTheme(primary: Color(0xFF6C63FF), secondary: Color(0xFF48CAE4), trophy: '🏆'), // purple-cyan
    _LevelTheme(primary: Color(0xFFFF6B6B), secondary: Color(0xFFFFE66D), trophy: '🔥'), // red-yellow
    _LevelTheme(primary: Color(0xFF43E97B), secondary: Color(0xFF38F9D7), trophy: '🌿'), // green-teal
    _LevelTheme(primary: Color(0xFFFF8C00), secondary: Color(0xFFFFD700), trophy: '⭐'), // orange-gold
    _LevelTheme(primary: Color(0xFFE040FB), secondary: Color(0xFFFF80AB), trophy: '💜'), // purple-pink
    _LevelTheme(primary: Color(0xFF00B4DB), secondary: Color(0xFF0083B0), trophy: '🌊'), // ocean blue
    _LevelTheme(primary: Color(0xFFF7971E), secondary: Color(0xFFFFD200), trophy: '🌟'), // amber-gold
    _LevelTheme(primary: Color(0xFFCB2D3E), secondary: Color(0xFFEF473A), trophy: '💎'), // crimson
    _LevelTheme(primary: Color(0xFF11998E), secondary: Color(0xFF38EF7D), trophy: '🌈'), // emerald
    _LevelTheme(primary: Color(0xFF4776E6), secondary: Color(0xFF8E54E9), trophy: '🚀'), // blue-violet
  ];

  static _LevelTheme forLevel(int level) => _themes[(level - 1) % _themes.length];
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
      final target   = LevelConfig.scoreTargetForLevel(doneLv);
      final theme    = _LevelTheme.forLevel(doneLv);
      final nextTheme = _LevelTheme.forLevel(nextLv);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 40, offset: const Offset(0, 16)),
            BoxShadow(color: theme.primary.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient header ──────────────────────────────────────────
              _CardHeader(doneLv: doneLv, celebCtrl: celebCtrl, skinName: _skin(doneLv), theme: theme),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(5.w, 2.5.h, 5.w, 3.h),
                child: Column(
                  children: [
                    // Score counter
                    _ScoreCounter(scoreAnim: scoreAnim, target: target, theme: theme),
                    SizedBox(height: 2.5.h),

                    // Stars row
                    _StarsDisplay(stars: ctrl.starsEarned.value),
                    SizedBox(height: 2.h),

                    // Rewards pill
                    _RewardsPill(gifts: ctrl.sessionGifts.toList()),
                    SizedBox(height: 2.5.h),

                    // Next level badge
                    _NextLevelBadge(nextLv: nextLv, skinName: _skin(nextLv), theme: nextTheme),
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
                              onTap: () {
                                RemoteAdConfigService? remote;
                                try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
                                final adsOn = remote?.adsEnabled.value ?? false;
                                if (adsOn) {
                                  Get.find<AdService>().loadAndShowInterstitial(
                                    onDismissed: ctrl.continueAfterLevelComplete,
                                    onFailure:   ctrl.continueAfterLevelComplete,
                                  );
                                } else {
                                  ctrl.continueAfterLevelComplete();
                                }
                              },
                            ),
                            SizedBox(height: 1.8.h),
                            // iOS-style indicator bar
                            Center(
                              child: Container(
                                width: 38.w,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            SizedBox(height: 1.8.h),
                            _SecondaryBtn(
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
  final _LevelTheme theme;

  const _CardHeader({required this.doneLv, required this.celebCtrl, required this.skinName, required this.theme});

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
                Color.lerp(theme.primary, theme.secondary, t)!,
                Color.lerp(theme.secondary, theme.primary, t)!,
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
                  child: Text(theme.trophy, style: TextStyle(fontSize: 30.sp)),
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
  final _LevelTheme theme;
  const _ScoreCounter({required this.scoreAnim, required this.target, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.primary.withOpacity(0.22), width: 1.5),
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
                  Icon(Icons.stars_rounded, color: theme.primary, size: 6.w),
                  SizedBox(width: 1.5.w),
                  Text(
                    '${scoreAnim.value}',
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: theme.primary),
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

// ─── Stars display ────────────────────────────────────────────────────────────

class _StarsDisplay extends StatefulWidget {
  final int stars;
  const _StarsDisplay({required this.stars});

  @override
  State<_StarsDisplay> createState() => _StarsDisplayState();
}

class _StarsDisplayState extends State<_StarsDisplay> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _scales = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
      final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
      );
      _ctrls.add(ctrl);
      _scales.add(anim);
      if (i < widget.stars) {
        Future.delayed(Duration(milliseconds: 200 + i * 200), () {
          if (mounted) ctrl.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final earned = i < widget.stars;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w),
              child: AnimatedBuilder(
                animation: _scales[i],
                builder: (_, __) => Transform.scale(
                  scale: earned ? _scales[i].value : 1.0,
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_border_rounded,
                    color: earned ? const Color(0xFFFFD700) : Colors.grey.shade300,
                    size: 9.w,
                    shadows: earned
                        ? const [Shadow(color: Color(0xFFFF8F00), blurRadius: 8, offset: Offset(0, 2))]
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 0.5.h),
        Text(
          widget.stars == 3 ? 'Excellent! 🎉' : widget.stars == 2 ? 'Great job! 👍' : 'Level Complete!',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// ─── Rewards pill — shows level-completion coins + any gifts earned ───────────

class _RewardsPill extends StatelessWidget {
  /// Raw gift types claimed this level: 0=+1 heart, 1=+5 coins, 2=+1 award.
  final List<int> gifts;
  const _RewardsPill({required this.gifts});

  @override
  Widget build(BuildContext context) {
    int extraCoins = 0, extraAwards = 0;
    for (final g in gifts) {
      if (g == 1) extraCoins += 5;
      else if (g == 2) extraAwards++;
    }
    final totalCoins = 3 + extraCoins;
    final hasGifts   = gifts.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300).withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.20), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasGifts ? '🎁' : '🪙', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 0.3.h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 1.5.w,
              children: [
                _badge('🪙', '+$totalCoins'),
                if (extraAwards > 0) _badge('🏅', '+$extraAwards'),
              ],
            ),
            SizedBox(height: 0.3.h),
            Text(
              hasGifts ? 'Rewards' : 'Coins',
              style: TextStyle(fontSize: 8.5.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String emoji, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: 11.sp, height: 1.15)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFB300),
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

// ─── Next level badge ─────────────────────────────────────────────────────────

class _NextLevelBadge extends StatelessWidget {
  final int nextLv;
  final String skinName;
  final _LevelTheme theme;
  const _NextLevelBadge({required this.nextLv, required this.skinName, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.secondary, theme.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(theme.trophy, style: TextStyle(fontSize: 14.sp)),
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
  final VoidCallback onTap;
  const _SecondaryBtn({required this.onTap});

  @override
  State<_SecondaryBtn> createState() => _SecondaryBtnState();
}

class _SecondaryBtnState extends State<_SecondaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0288D1);
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
            color: blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: blue.withValues(alpha: 0.45), width: 1.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏠', style: TextStyle(fontSize: 13.sp)),
              SizedBox(width: 2.w),
              Text(
                'Go Home',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: blue,
                ),
              ),
            ],
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

// ─── Banner ad shown at the bottom of the level-complete overlay ─────────────

class _LevelCompleteBanner extends StatelessWidget {
  const _LevelCompleteBanner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 50,
      child: ApslBannerAd(
        adNetwork: AdNetwork.admob,
        adSize: AdSize.banner,
      ),
    );
  }
}

// ─── Celebration confetti ─────────────────────────────────────────────────────

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
