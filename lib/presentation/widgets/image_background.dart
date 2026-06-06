import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a full-screen background image (from assets) with:
///   • subtle parallax drift driven by [progress] (0→1 repeating)
///   • animated birds flying across
///   • soft light-leak / vignette overlay
///   • graceful fallback gradient if the image is missing
///
/// [fallbackColors]  – gradient used when no image is found
/// [birdColor]       – colour of the animated birds
/// [numBirds]        – how many birds to draw
/// [showBirds]       – set false for scenes where birds don't fit (e.g. rain)
/// [vignetteColor]   – overlay tint (e.g. subtle warm for day, cool for night)
class ImageBackground extends StatefulWidget {
  final String assetPath;
  final List<Color> fallbackColors;
  final Color birdColor;
  final int numBirds;
  final bool showBirds;
  final Color vignetteColor;

  const ImageBackground({
    super.key,
    required this.assetPath,
    required this.fallbackColors,
    this.birdColor = const Color(0xFF0D2B55),
    this.numBirds = 7,
    this.showBirds = true,
    this.vignetteColor = Colors.transparent,
  });

  @override
  State<ImageBackground> createState() => _ImageBackgroundState();
}

class _ImageBackgroundState extends State<ImageBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _imageExists = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onImageError() {
    if (_imageExists) setState(() => _imageExists = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background image or fallback gradient ─────────────────────────
        if (_imageExists)
          _ParallaxImage(
            assetPath: widget.assetPath,
            progress: _ctrl.value,
            onError: _onImageError,
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.fallbackColors,
              ),
            ),
          ),

        // ── Soft vignette overlay ─────────────────────────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.22),
                ],
              ),
            ),
          ),
        ),

        // ── Subtle tint ───────────────────────────────────────────────────
        if (widget.vignetteColor != Colors.transparent)
          Positioned.fill(
            child: ColoredBox(
              color: widget.vignetteColor.withOpacity(0.12),
            ),
          ),

        // ── Animated birds ────────────────────────────────────────────────
        if (widget.showBirds)
          Positioned.fill(
            child: CustomPaint(
              painter: _BirdOverlayPainter(
                progress: _ctrl.value,
                numBirds: widget.numBirds,
                color: widget.birdColor,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Parallax image ───────────────────────────────────────────────────────────

class _ParallaxImage extends StatelessWidget {
  final String assetPath;
  final double progress;
  final VoidCallback onError;

  const _ParallaxImage({
    required this.assetPath,
    required this.progress,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // Very gentle horizontal + vertical drift (max ±12px)
    final dx = math.sin(progress * math.pi * 2) * 12.0;
    final dy = math.sin(progress * math.pi * 2 * 0.6 + 1.0) * 8.0;

    return ClipRect(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: 1.055, // slight over-scale so drift never shows edges
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => onError());
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Bird overlay painter ─────────────────────────────────────────────────────

class _BirdOverlayPainter extends CustomPainter {
  final double progress;
  final int numBirds;
  final Color color;

  // [xPhase, yFrac, size, speed, flapPhase]
  static const _defs = [
    [0.04, 0.10, 11.0, 1.05, 0.0],
    [0.20, 0.07, 9.0,  1.30, 1.4],
    [0.38, 0.13, 13.0, 0.85, 2.6],
    [0.55, 0.08, 10.0, 1.20, 0.8],
    [0.70, 0.15, 12.0, 0.95, 3.5],
    [0.85, 0.06, 8.0,  1.45, 1.9],
    [0.14, 0.19, 11.0, 1.10, 4.2],
    [0.48, 0.17, 9.0,  1.35, 2.1],
    [0.65, 0.21, 13.0, 0.80, 0.5],
    [0.92, 0.12, 10.0, 1.15, 3.0],
  ];

  const _BirdOverlayPainter({
    required this.progress,
    required this.numBirds,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final count = numBirds.clamp(0, _defs.length);
    for (int i = 0; i < count; i++) {
      final d = _defs[i];
      final rawX = ((d[0] as double) + progress * (d[3] as double) * 1.15) % 1.2;
      final bx = (rawX - 0.1) * s.width;
      final by = (d[1] as double) * s.height +
          math.sin(progress * math.pi * 2 * 0.75 + (d[4] as double)) *
              (d[2] as double) *
              0.50;

      final flap =
          math.sin(progress * math.pi * 2 * 4.5 + (d[4] as double)) * 0.40;
      final sz = d[2] as double;

      final p = Paint()
        ..color = color.withOpacity(0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sz * 0.14
        ..strokeCap = StrokeCap.round;

      final lw = Path()
        ..moveTo(bx - sz, by - flap * sz)
        ..quadraticBezierTo(bx - sz * 0.42, by + flap * sz * 0.32, bx, by);
      canvas.drawPath(lw, p);
      final rw = Path()
        ..moveTo(bx, by)
        ..quadraticBezierTo(
            bx + sz * 0.42, by + flap * sz * 0.32, bx + sz, by - flap * sz);
      canvas.drawPath(rw, p);
    }
  }

  @override
  bool shouldRepaint(_BirdOverlayPainter old) =>
      old.progress != progress || old.numBirds != numBirds;
}
