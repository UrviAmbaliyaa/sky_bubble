import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../controllers/game_controller.dart';
import '../widgets/bubble_painter.dart';

class GameScreen extends GetView<GameController> {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) => _GameBody(
          controller: controller,
          size: constraints.biggest,
        ),
      ),
    );
  }
}

class _GameBody extends StatefulWidget {
  final GameController controller;
  final Size size;
  const _GameBody({required this.controller, required this.size});

  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  @override
  void initState() {
    super.initState();
    // Provide exact canvas size to the controller so bubbles spawn correctly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.setScreenSize(widget.size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Premium level-based background
        _PremiumBackground(controller: widget.controller),
        // Game canvas — CustomPaint needs a child to claim its full size
        GestureDetector(
          onTapDown: widget.controller.handleTapDown,
          behavior: HitTestBehavior.opaque,
          child: Obx(
            () => CustomPaint(
              painter: BubblePainter(
                bubbles: widget.controller.bubbles.toList(),
                level: widget.controller.level.value, // triggers skin change
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // HUD overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _GameHUD(controller: widget.controller)),
        ),
        // Level-up banner
        Obx(() => widget.controller.levelUpMessage.value.isEmpty
            ? const SizedBox.shrink()
            : Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 0,
                right: 0,
                child: _LevelUpBanner(
                    message: widget.controller.levelUpMessage.value),
              )),
        // Pause overlay
        Obx(() => widget.controller.isPaused.value
            ? Positioned.fill(
                child: _PauseOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
        // Game-over overlay
        Obx(() => widget.controller.isGameOver.value
            ? Positioned.fill(
                child: _GameOverOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

// ─── HUD ─────────────────────────────────────────────────────────────────────

class _GameHUD extends StatelessWidget {
  final GameController controller;
  const _GameHUD({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          _HudCard(
            child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppColors.scoreGold, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.score.value}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                )),
          ),
          const SizedBox(width: 8),
          _HudCard(
            child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppColors.levelGreen, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'LVL ${controller.level.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.levelGreen,
                      ),
                    ),
                  ],
                )),
          ),
          const Spacer(),
          _HudCard(
            child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.lives.value > 0
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color: AppColors.liveRed,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '× ${controller.lives.value}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.liveRed,
                      ),
                    ),
                  ],
                )),
          ),
          const SizedBox(width: 8),
          _PauseButton(onTap: controller.togglePause),
        ],
      ),
    );
  }
}

class _HudCard extends StatelessWidget {
  final Widget child;
  const _HudCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.pause_rounded, color: AppColors.textDark, size: 24),
      ),
    );
  }
}

// ─── Level-up Banner ─────────────────────────────────────────────────────────

class _LevelUpBanner extends StatefulWidget {
  final String message;
  const _LevelUpBanner({required this.message});

  @override
  State<_LevelUpBanner> createState() => _LevelUpBannerState();
}

class _LevelUpBannerState extends State<_LevelUpBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _slide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43E97B).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '🎉  ${widget.message}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
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

// ─── Pause overlay ──────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final GameController controller;
  const _PauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 30, offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏸', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 28),
              _OverlayButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                color: AppColors.levelGreen,
                onTap: controller.togglePause,
              ),
              const SizedBox(height: 12),
              _OverlayButton(
                label: 'HOME',
                icon: Icons.home_rounded,
                color: AppColors.primary,
                onTap: controller.navigateHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Game Over overlay ───────────────────────────────────────────────────────

class _GameOverOverlay extends StatefulWidget {
  final GameController controller;
  const _GameOverOverlay({required this.controller});

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 40,
                        offset: Offset(0, 12))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💥', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.liveRed,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() => _ScoreRow(
                          score: widget.controller.score.value,
                          level: widget.controller.level.value,
                        )),
                    const SizedBox(height: 28),
                    _OverlayButton(
                      label: 'PLAY AGAIN',
                      icon: Icons.replay_rounded,
                      color: AppColors.startGradientEnd,
                      onTap: widget.controller.startGame,
                    ),
                    const SizedBox(height: 12),
                    _OverlayButton(
                      label: 'LEADERBOARD',
                      icon: Icons.leaderboard_rounded,
                      color: AppColors.primary,
                      onTap: () => Get.toNamed('/score'),
                    ),
                    const SizedBox(height: 12),
                    _OverlayButton(
                      label: 'HOME',
                      icon: Icons.home_rounded,
                      color: AppColors.textMedium,
                      onTap: widget.controller.navigateHome,
                    ),
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

class _ScoreRow extends StatelessWidget {
  final int score;
  final int level;
  const _ScoreRow({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ResultTile(
          label: 'SCORE',
          value: '$score',
          color: AppColors.scoreGold,
          icon: Icons.stars_rounded,
        ),
        Container(width: 1, height: 48, color: Colors.grey.shade200),
        _ResultTile(
          label: 'LEVEL',
          value: '$level',
          color: AppColors.levelGreen,
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.35), width: 2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PREMIUM SKY BACKGROUND  (level-based sky themes + animated birds)
// ════════════════════════════════════════════════════════════════════════════

class _PremiumBackground extends StatefulWidget {
  final GameController controller;
  const _PremiumBackground({required this.controller});

  @override
  State<_PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<_PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // 12 birds — each has [xPhase, yFrac, sizePx, speedFactor, flapPhase]
  static const _birdDefs = [
    [0.02, 0.10, 14.0, 1.00, 0.0],
    [0.18, 0.08, 11.0, 1.25, 1.2],
    [0.32, 0.13, 16.0, 0.85, 2.5],
    [0.48, 0.07, 10.0, 1.40, 3.8],
    [0.60, 0.16, 13.0, 1.10, 0.7],
    [0.74, 0.11, 12.0, 1.30, 1.9],
    [0.88, 0.09, 15.0, 0.78, 3.1],
    [0.10, 0.21, 10.0, 1.20, 2.3],
    [0.42, 0.19, 14.0, 1.05, 4.2],
    [0.65, 0.22, 11.0, 1.35, 0.4],
    [0.80, 0.15, 13.0, 0.95, 2.8],
    [0.25, 0.25, 9.0,  1.55, 1.6],
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final level = widget.controller.level.value.clamp(1, 7);
      final cfg = _skyConfig(level);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: cfg.gradientColors,
          ),
        ),
        child: CustomPaint(
          painter: _SkyPainter(
            level: level,
            cfg: cfg,
            progress: _ctrl.value,
            birdDefs: _birdDefs,
          ),
          child: const SizedBox.expand(),
        ),
      );
    });
  }

  static _SkyConfig _skyConfig(int level) {
    const configs = [
      // Lv1 — Clear blue day
      _SkyConfig(
        gradientColors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5), Color(0xFFB3E5FC)],
        birdColor: Color(0xFF0A3464),
        cloudColor: Colors.white,
        cloudOpacity: 0.88,
        numBirds: 7,
        theme: _SkyTheme.day,
      ),
      // Lv2 — Bright midday
      _SkyConfig(
        gradientColors: [Color(0xFF01579B), Color(0xFF0288D1), Color(0xFF29B6F6), Color(0xFFE1F5FE)],
        birdColor: Color(0xFF01274D),
        cloudColor: Colors.white,
        cloudOpacity: 0.92,
        numBirds: 10,
        theme: _SkyTheme.day,
      ),
      // Lv3 — Golden hour
      _SkyConfig(
        gradientColors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFFFF8F00), Color(0xFFFFE082)],
        birdColor: Color(0xFF3E2000),
        cloudColor: Color(0xFFFFCC80),
        cloudOpacity: 0.75,
        numBirds: 8,
        theme: _SkyTheme.golden,
      ),
      // Lv4 — Sunset
      _SkyConfig(
        gradientColors: [Color(0xFF311B92), Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF6F00)],
        birdColor: Color(0xFF1A0A00),
        cloudColor: Color(0xFFFFAB91),
        cloudOpacity: 0.65,
        numBirds: 6,
        theme: _SkyTheme.sunset,
      ),
      // Lv5 — Twilight
      _SkyConfig(
        gradientColors: [Color(0xFF050A20), Color(0xFF0D1B4A), Color(0xFF1A2980), Color(0xFF26348F)],
        birdColor: Color(0xFFB0BEC5),
        cloudColor: Color(0xFF7986CB),
        cloudOpacity: 0.35,
        numBirds: 4,
        theme: _SkyTheme.twilight,
      ),
      // Lv6 — Storm
      _SkyConfig(
        gradientColors: [Color(0xFF0A0A0A), Color(0xFF1B2631), Color(0xFF212F3C), Color(0xFF2E4057)],
        birdColor: Color(0xFFECEFF1),
        cloudColor: Color(0xFF546E7A),
        cloudOpacity: 0.90,
        numBirds: 5,
        theme: _SkyTheme.storm,
      ),
      // Lv7 — Magical rainbow sky
      _SkyConfig(
        gradientColors: [Color(0xFF0D47A1), Color(0xFF1E88E5), Color(0xFF64B5F6), Color(0xFFE3F2FD)],
        birdColor: Color(0xFF0A3464),
        cloudColor: Colors.white,
        cloudOpacity: 0.90,
        numBirds: 12,
        theme: _SkyTheme.rainbow,
      ),
    ];
    return configs[(level - 1).clamp(0, configs.length - 1)];
  }
}

// ─── Sky config data class ────────────────────────────────────────────────────

enum _SkyTheme { day, golden, sunset, twilight, storm, rainbow }

class _SkyConfig {
  final List<Color> gradientColors;
  final Color birdColor;
  final Color cloudColor;
  final double cloudOpacity;
  final int numBirds;
  final _SkyTheme theme;

  const _SkyConfig({
    required this.gradientColors,
    required this.birdColor,
    required this.cloudColor,
    required this.cloudOpacity,
    required this.numBirds,
    required this.theme,
  });
}

// ─── Sky painter ──────────────────────────────────────────────────────────────

class _SkyPainter extends CustomPainter {
  final int level;
  final _SkyConfig cfg;
  final double progress;
  final List<List<num>> birdDefs;

  const _SkyPainter({
    required this.level,
    required this.cfg,
    required this.progress,
    required this.birdDefs,
  });

  @override
  void paint(Canvas canvas, Size s) {
    _drawSkyElements(canvas, s);
    _drawBirds(canvas, s);
  }

  // ── Level-specific sky elements ───────────────────────────────────────────

  void _drawSkyElements(Canvas canvas, Size s) {
    switch (cfg.theme) {
      case _SkyTheme.day:
        _drawSunRays(canvas, s, Colors.white.withOpacity(0.08));
        _drawClouds(canvas, s);
        break;
      case _SkyTheme.golden:
        _drawSunRays(canvas, s, const Color(0xFFFFCC02).withOpacity(0.12));
        _drawClouds(canvas, s);
        _drawSunOrb(canvas, s, const Color(0xFFFFD600), 0.88, 0.95);
        break;
      case _SkyTheme.sunset:
        _drawSunRays(canvas, s, const Color(0xFFFF6D00).withOpacity(0.14));
        _drawClouds(canvas, s);
        _drawSunOrb(canvas, s, const Color(0xFFFF6F00), 0.50, 0.96);
        break;
      case _SkyTheme.twilight:
        _drawClouds(canvas, s);
        _drawMoon(canvas, s);
        _drawStars(canvas, s);
        break;
      case _SkyTheme.storm:
        _drawStormClouds(canvas, s);
        _drawLightning(canvas, s);
        _drawRainStreaks(canvas, s);
        break;
      case _SkyTheme.rainbow:
        _drawSunRays(canvas, s, Colors.white.withOpacity(0.10));
        _drawRainbow(canvas, s);
        _drawClouds(canvas, s);
        break;
    }
  }

  // ── Sun rays ──────────────────────────────────────────────────────────────

  void _drawSunRays(Canvas canvas, Size s, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.05
      ..strokeCap = StrokeCap.round;
    final cx = s.width * 0.5, cy = -s.height * 0.05;
    for (int i = 0; i < 14; i++) {
      final a = (i / 14) * math.pi * 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(a) * s.width * 1.0, cy + math.sin(a) * s.width * 1.0),
        p,
      );
    }
  }

  // ── Clouds ────────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Size s) {
    final cloudDefs = [
      [0.12, 0.14, 0.24], [0.55, 0.09, 0.28],
      [0.80, 0.20, 0.18], [0.30, 0.22, 0.20],
      [0.70, 0.30, 0.15],
    ];
    for (final d in cloudDefs) {
      _cloud(canvas,
        s.width * (d[0] as double),
        s.height * (d[1] as double),
        s.width * (d[2] as double));
    }
  }

  void _cloud(Canvas canvas, double cx, double cy, double w) {
    final h = w * 0.42;
    final p = Paint()..color = cfg.cloudColor.withOpacity(cfg.cloudOpacity);
    canvas.drawCircle(Offset(cx - w * 0.22, cy), h * 0.55, p);
    canvas.drawCircle(Offset(cx, cy - h * 0.22), h * 0.68, p);
    canvas.drawCircle(Offset(cx + w * 0.22, cy), h * 0.52, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + h * 0.2), width: w, height: h),
        Radius.circular(h * 0.5),
      ),
      p,
    );
  }

  // ── Sun orb ───────────────────────────────────────────────────────────────

  void _drawSunOrb(Canvas canvas, Size s, Color color, double xFrac, double yFrac) {
    final c = Offset(s.width * xFrac, s.height * yFrac);
    final r = s.width * 0.08;
    canvas.drawCircle(c, r * 2.5,
      Paint()
        ..color = color.withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 2));
    canvas.drawCircle(c, r, Paint()..color = color.withOpacity(0.85));
  }

  // ── Moon ──────────────────────────────────────────────────────────────────

  void _drawMoon(Canvas canvas, Size s) {
    final cx = s.width * 0.78, cy = s.height * 0.10;
    final r = s.width * 0.06;
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFFE8F0FE).withOpacity(0.90));
    canvas.drawCircle(Offset(cx + r * 0.38, cy - r * 0.10), r * 0.82,
        Paint()..color = const Color(0xFF1A2980));
  }

  // ── Stars ─────────────────────────────────────────────────────────────────

  void _drawStars(Canvas canvas, Size s) {
    final rng = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * s.width;
      final y = rng.nextDouble() * s.height * 0.55;
      final tw = 0.4 + 0.6 * math.sin(progress * math.pi * 2 * 1.5 + i * 0.7);
      // Clamp the opacity value between 0.0 and 1.0
      final opacity = (tw * 0.80).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), 1.5 + rng.nextDouble() * 1.5,
          Paint()..color = Colors.white.withOpacity(opacity));
    }
  }

  // ── Rainbow ───────────────────────────────────────────────────────────────

  void _drawRainbow(Canvas canvas, Size s) {
    final cx = s.width * 0.5, cy = s.height * 0.85;
    final base = s.width * 0.58;
    final cols = [
      const Color(0xFFFF1744), const Color(0xFFFF6D00),
      const Color(0xFFFFEA00), const Color(0xFF00E676),
      const Color(0xFF2979FF), const Color(0xFFD500F9),
    ];
    for (int i = 0; i < cols.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: base - i * s.width * 0.022),
        math.pi, math.pi, false,
        Paint()
          ..color = cols[i].withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.020,
      );
    }
  }

  // ── Storm clouds ──────────────────────────────────────────────────────────

  void _drawStormClouds(Canvas canvas, Size s) {
    final cloudDefs = [
      [0.05, 0.08, 0.38, 0.80], [0.50, 0.04, 0.42, 0.88],
      [0.82, 0.12, 0.32, 0.75], [0.28, 0.18, 0.30, 0.72],
    ];
    for (final d in cloudDefs) {
      final opacity = cfg.cloudOpacity * (d[3] as double);
      final p = Paint()..color = cfg.cloudColor.withOpacity(opacity);
      final cx = s.width * (d[0] as double);
      final cy = s.height * (d[1] as double);
      final w  = s.width * (d[2] as double);
      final h  = w * 0.50;
      canvas.drawCircle(Offset(cx - w * 0.24, cy), h * 0.60, p);
      canvas.drawCircle(Offset(cx, cy - h * 0.22), h * 0.72, p);
      canvas.drawCircle(Offset(cx + w * 0.24, cy), h * 0.55, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + h * 0.22), width: w, height: h),
          Radius.circular(h * 0.5),
        ),
        p,
      );
    }
  }

  // ── Lightning ─────────────────────────────────────────────────────────────

  void _drawLightning(Canvas canvas, Size s) {
    // Subtle periodic flashes
    final flash = math.sin(progress * math.pi * 4);
    if (flash > 0.85) {
      final lp = Paint()
        ..color = const Color(0xFFFFF9C4).withOpacity((flash - 0.85) * 6)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final lx = s.width * 0.38;
      canvas.drawLine(Offset(lx, s.height * 0.08), Offset(lx - 14, s.height * 0.22), lp);
      canvas.drawLine(Offset(lx - 14, s.height * 0.22), Offset(lx + 6, s.height * 0.30), lp);
      canvas.drawLine(Offset(lx + 6, s.height * 0.30), Offset(lx - 8, s.height * 0.42), lp);
    }
    final flash2 = math.sin(progress * math.pi * 3 + 2.0);
    if (flash2 > 0.88) {
      final lp = Paint()
        ..color = const Color(0xFFFFF9C4).withOpacity((flash2 - 0.88) * 8)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final lx = s.width * 0.72;
      canvas.drawLine(Offset(lx, s.height * 0.06), Offset(lx - 10, s.height * 0.18), lp);
      canvas.drawLine(Offset(lx - 10, s.height * 0.18), Offset(lx + 5, s.height * 0.28), lp);
    }
  }

  // ── Rain streaks ──────────────────────────────────────────────────────────

  void _drawRainStreaks(Canvas canvas, Size s) {
    final rng = math.Random(77);
    final rp = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 55; i++) {
      final x = rng.nextDouble() * s.width;
      final baseY = (rng.nextDouble() + progress * 2.5) % 1.2 * s.height;
      canvas.drawLine(Offset(x + 4, baseY), Offset(x, baseY + 22), rp);
    }
  }

  // ── Birds ──────────────────────────────────────────────────────────────────

  void _drawBirds(Canvas canvas, Size s) {
    for (int i = 0; i < cfg.numBirds; i++) {
      final def = birdDefs[i % birdDefs.length];
      final xPhase = def[0] as double;
      final yFrac  = def[1] as double;
      final size   = def[2] as double;
      final speed  = def[3] as double;
      final fPhase = def[4] as double;

      // x wraps from -10% to 110% of screen width
      final rawX = (xPhase + progress * speed * 1.3) % 1.2;
      final bx = (rawX - 0.1) * s.width;
      final by = yFrac * s.height;

      // Wing flap angle
      final flap = math.sin(progress * math.pi * 2 * 5 + fPhase) * 0.36;

      _drawBirdShape(canvas, Offset(bx, by), size, cfg.birdColor, flap);
    }
  }

  void _drawBirdShape(Canvas canvas, Offset pos, double size, Color color, double flap) {
    final p = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.16
      ..strokeCap = StrokeCap.round;

    // Left wing
    final path = Path()
      ..moveTo(pos.dx - size, pos.dy - flap * size)
      ..quadraticBezierTo(
        pos.dx - size * 0.5, pos.dy + flap * size * 0.4,
        pos.dx, pos.dy,
      );
    canvas.drawPath(path, p);

    // Right wing
    final path2 = Path()
      ..moveTo(pos.dx, pos.dy)
      ..quadraticBezierTo(
        pos.dx + size * 0.5, pos.dy + flap * size * 0.4,
        pos.dx + size, pos.dy - flap * size,
      );
    canvas.drawPath(path2, p);
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.progress != progress || old.level != level;
}
