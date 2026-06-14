import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/coin_display.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenDarkBottom,
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
            const _HomeStatsRow(),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: _PlayButton(onPressed: controller.navigateToGame),
            ),
            SizedBox(height: 3.h),
            // 2-column option grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OptionsRow(
                    left: _GridPill(
                      iconData: Icons.bar_chart_rounded,
                      label: 'PROGRESS',
                      tintColor: const Color(0xFFD0D8E0),
                      opacity: 0.32,
                      iconColor: Colors.amber,
                      onTap: controller.navigateToScores,
                    ),
                    right: _GridPill(
                      iconData: Icons.bubble_chart_rounded,
                      label: 'STYLE',
                      tintColor: const Color(0xFF7090AA),
                      opacity: 0.32,
                      onTap: controller.navigateToBubbleStyle,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _OptionsRow(
                    left: _GridPill(
                      iconData: Icons.menu_book_rounded,
                      label: 'LEVELS',
                      tintColor: const Color(0xFF2850C0),
                      opacity: 0.32,
                      onTap: controller.navigateToLevels,
                    ),
                    right: _GridPill(
                      iconData: Icons.wb_sunny_rounded,
                      label: 'BACKGROUND',
                      tintColor: const Color(0xFF904888),
                      opacity: 0.32,
                      iconColor: Colors.amber,
                      onTap: controller.navigateToBackground,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _OptionsRow(
                    left: _GridPill(
                      iconData: Icons.monetization_on_rounded,
                      label: 'EARN COINS',
                      tintColor: const Color(0xFF107858),
                      opacity: 0.32,
                      iconColor: Colors.amber,
                      onTap: controller.navigateToEarnCoins,
                    ),
                    right: Obx(() {
                      final svc       = Get.find<StyleService>();
                      final canAfford = svc.totalCoins.value >= StyleService.awardPurchaseCost;
                      final busy      = controller.isBuyingAward.value;
                      return _EarnAwardGridPill(
                        canAfford: canAfford,
                        busy:      busy,
                        onTap:     controller.buyAwardWithCoins,
                      );
                    }),
                  ),
                  SizedBox(height: 3.h),
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
//  HOME STATS ROW  — best score · coins · awards
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeStatsRow extends StatelessWidget {
  const _HomeStatsRow();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final svc  = Get.find<StyleService>();

    return Obx(() {
      final best   = ctrl.bestScore.value;
      final coins  = svc.totalCoins.value;
      final awards = svc.totalAwards.value;
      final today  = ctrl.todayTotalScore.value;

      // Hide the row if there's truly nothing to show
      if (best == 0 && coins == 0 && awards == 0) return const SizedBox.shrink();

      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 1.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Best score
                if (best > 0) ...[
                  _StatChip(
                    emoji: '🏆',
                    label: '$best',
                    sublabel: 'BEST',
                    chipColor: AppColors.gold,
                  ),
                  if (today > 0 || coins >= 0 || awards > 0)
                    _StatDivider(),
                ],
                // Today's total score
                if (today > 0) ...[
                  _StatChip(
                    emoji: '⭐',
                    label: '$today',
                    sublabel: 'TODAY',
                    chipColor: AppColors.earnAward,
                  ),
                  _StatDivider(),
                ],
                // Total coins
                _CoinStatChip(coins: coins),
                if (awards >= 0) _StatDivider(),
                // Total awards
                _StatChip(
                  emoji: '🏅',
                  label: '$awards',
                  sublabel: 'AWARDS',
                  chipColor: AppColors.pink,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color chipColor;

  const _StatChip({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 13.sp)),
            SizedBox(width: 1.2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.3.h),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 7.5.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87.withOpacity(0.85),
            letterSpacing: 0.8,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: 3.5.h,
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      color: AppColors.glassBorder,
    );
  }
}

class _CoinStatChip extends StatelessWidget {
  final int coins;
  const _CoinStatChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinDisplay(amount: coins, imageSize: 16, fontSize: 14, gap: 4),
        SizedBox(height: 0.3.h),
        Text(
          'COINS',
          style: TextStyle(
            fontSize: 7.5.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87.withOpacity(0.85),
            letterSpacing: 0.8,
            height: 1.0,
          ),
        ),
      ],
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
          height: 6.8.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.earnCoin, AppColors.primaryDeep],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.primaryDeep.withOpacity(0.50), blurRadius: 20, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.earnCoin.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2)),
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
//  2-COLUMN GRID HELPERS
//  _OptionsRow       — lays two equal-width pills side by side
//  _GridPill         — frosted glass pill for standard options
//  _EarnAwardGridPill— same shape, gold gradient, live afford/busy state
// ═══════════════════════════════════════════════════════════════════════════════

class _OptionsRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _OptionsRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 3.5.w),
        Expanded(child: right),
      ],
    );
  }
}

class _GridPill extends StatelessWidget {
  final IconData iconData;
  final String label;
  final Color tintColor;
  final double opacity;
  final Color iconColor;
  final VoidCallback onTap;

  const _GridPill({
    required this.iconData,
    required this.label,
    required this.tintColor,
    required this.onTap,
    this.opacity   = 0.28,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 6.h,
            decoration: BoxDecoration(
              color: tintColor.withOpacity(opacity),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1.2,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Icon(iconData, color: iconColor, size: 6.w,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
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

class _EarnAwardGridPill extends StatelessWidget {
  final bool canAfford;
  final bool busy;
  final VoidCallback onTap;

  const _EarnAwardGridPill({
    required this.canAfford,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 6.5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFA83050).withOpacity(0.68),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1.2,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: busy
                ? Center(
                    child: SizedBox(
                      width: 5.w, height: 5.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    ),
                  )
                : Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: Colors.amber, size: 6.w,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'EARN AWARD',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
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
    AppColors.gold,           AppColors.pink,      AppColors.earnAward,
    AppColors.primary,        AppColors.auroraPurple, Color(0xFFFF8A65),
    AppColors.textWhite,      AppColors.earnCoin,  AppColors.pinkLight,
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
          colors: [AppColors.styleHeaderTop, AppColors.indigo, AppColors.screenDarkTop],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.65),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.30),
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
              colors: [AppColors.gold, AppColors.orange],
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
                colors: [AppColors.gold, AppColors.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.50),
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
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
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

