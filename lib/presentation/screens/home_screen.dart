import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../controllers/home_controller.dart';
import '../widgets/animated_start_button.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _TopBar(controller: controller),
                const Spacer(),
                const _AppTitle(),
                const SizedBox(height: 8),
                Obx(() => _BestScoreBadge(score: controller.bestScore.value)),
                const SizedBox(height: 48),
                AnimatedStartButton(onPressed: controller.navigateToGame),
                const SizedBox(height: 36),
                _ScoresButton(onPressed: controller.navigateToScores),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final HomeController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatChip(
            icon: Icons.videogame_asset_rounded,
            label: 'Games',
            valueObs: controller.totalGamesPlayed,
            color: AppColors.primary,
          ),
          _StatChip(
            icon: Icons.emoji_events_rounded,
            label: 'Best',
            valueObs: controller.bestScore,
            color: AppColors.scoreGold,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final RxInt valueObs;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.valueObs,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${valueObs.value}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

// ─── App Title ────────────────────────────────────────────────────────────────

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    // "SKY BUBBLE" first row
    const line1 = ['S', 'K', 'Y', ' ', 'B', 'U', 'B', 'B', 'L', 'E'];
    const line1Colors = [
      Color(0xFF4FC3F7), Color(0xFFBA68C8), Color(0xFF4DB6AC),
      Colors.transparent,
      Color(0xFFFF6B9D), Color(0xFF4FC3F7), Color(0xFF81C784),
      Color(0xFFFFD54F), Color(0xFFFF8A65), Color(0xFFBA68C8),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: SKY BUBBLE
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(line1.length, (i) => Text(
            line1[i],
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: line1Colors[i],
              height: 1.0,
              shadows: line1[i] == ' ' ? null : const [
                Shadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
          )),
        ),
        // Row 2: BURST!
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'BURST!',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: AppColors.startGradientEnd,
                height: 1.0,
                shadows: [
                  Shadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text('🫧', style: TextStyle(fontSize: 44)),
          ],
        ),
      ],
    );
  }
}

// ─── Best Score Badge ─────────────────────────────────────────────────────────

class _BestScoreBadge extends StatelessWidget {
  final int score;
  const _BestScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3C8), Color(0xFFFFE57A)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.scoreGold.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFF9800), size: 22),
          const SizedBox(width: 8),
          Text(
            score == 0 ? 'Play to set a record!' : 'Best: $score pts',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A4F00),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scores Button ────────────────────────────────────────────────────────────

class _ScoresButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ScoresButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.leaderboard_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'LEADERBOARD',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  final List<_BgBubble> _bubbles = [];
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    for (int i = 0; i < 12; i++) {
      _bubbles.add(_BgBubble(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 20 + rng.nextDouble() * 50,
        speed: 0.00015 + rng.nextDouble() * 0.0002,
        color: AppColors.bubbleColors[i % AppColors.bubbleColors.length],
        phase: rng.nextDouble(),
      ));
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CustomPaint(
      painter: _BgPainter(
        bubbles: _bubbles,
        progress: _ctrl.value,
        size: size,
      ),
    );
  }
}

class _BgBubble {
  final double x;
  double y;
  final double size;
  final double speed;
  final Color color;
  final double phase;

  _BgBubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.phase,
  });
}

class _BgPainter extends CustomPainter {
  final List<_BgBubble> bubbles;
  final double progress;
  final Size size;

  _BgPainter({
    required this.bubbles,
    required this.progress,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final b in bubbles) {
      final y = ((b.y - progress * 100 * b.speed + b.phase) % 1.2) - 0.1;
      final x = b.x + math.sin((progress * math.pi * 2) + b.phase) * 0.03;
      final center = Offset(x * canvasSize.width, y * canvasSize.height);
      canvas.drawCircle(
        center,
        b.size,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [
              b.color.withOpacity(0.22),
              b.color.withOpacity(0.06),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: b.size),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.progress != progress;
}
