import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/bubble_model.dart';

/// Level → Bubble skin mapping
///  Lv 1  – Classic Soap      (transparent, iridescent rim)
///  Lv 2  – Vivid Soap        (brighter iridescence, thicker rim)
///  Lv 3  – Neon Glow         (electric edges, inner light source)
///  Lv 4  – Gold Metallic     (amber/gold body, star sparkles)
///  Lv 5  – Crystal Diamond   (icy facets, sharp multi-highlight)
///  Lv 6  – Fire Burst        (flame gradient, ember glow)
///  Lv 7+ – Premium Rainbow   (full-spectrum body + prismatic rim)
class BubblePainter extends CustomPainter {
  final List<BubbleModel> bubbles;
  final int level;

  BubblePainter({required this.bubbles, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      if (b.isBursting) {
        _paintBurst(canvas, b);
      } else if (!b.isPopped) {
        switch (level.clamp(1, 7)) {
          case 1: _paintSoap(canvas, b); break;
          case 2: _paintVivid(canvas, b); break;
          case 3: _paintNeon(canvas, b); break;
          case 4: _paintGold(canvas, b); break;
          case 5: _paintCrystal(canvas, b); break;
          case 6: _paintFire(canvas, b); break;
          default: _paintRainbow(canvas, b); break;
        }
      }
    }
  }

  // ── SHARED HELPERS ────────────────────────────────────────

  void _shadow(Canvas canvas, BubbleModel b, Color c, double blur) {
    canvas.drawCircle(
      Offset(b.x + b.radius * 0.06, b.y + b.radius * 0.10),
      b.radius,
      Paint()
        ..color = c
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _rimStroke(Canvas canvas, BubbleModel b, List<Color> colors,
      {double widthFactor = 0.13, List<double>? stops}) {
    final r = b.radius;
    final w = r * widthFactor;
    final rect = Rect.fromCircle(center: Offset(b.x, b.y), radius: r);
    canvas.drawCircle(
      Offset(b.x, b.y), r - w / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.3,
          endAngle: math.pi * 1.7,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _highlight(Canvas canvas, double cx, double cy, double w, double h) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.50),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(rect),
    );
  }

  void _sparkle(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(
        Offset(cx, cy), r, Paint()..color = Colors.white.withOpacity(0.88));
  }

  void _caustic(Canvas canvas, BubbleModel b) {
    final rect = Rect.fromCenter(
      center: Offset(b.x + b.radius * 0.08, b.y + b.radius * 0.56),
      width: b.radius * 0.44, height: b.radius * 0.20,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.28), Colors.transparent],
        ).createShader(rect),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  LV 1 – CLASSIC SOAP BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintSoap(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    _shadow(canvas, b, b.color.withOpacity(0.10), r * 0.55);
    canvas.drawCircle(c, r, Paint()..color = b.color.withOpacity(0.06));
    // Iridescent film
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.42), radius: 0.78,
        colors: [
          Colors.cyan.withOpacity(0.20), Colors.blue.withOpacity(0.14),
          Colors.purple.withOpacity(0.11), Colors.pink.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.52, 0.72, 1.0],
      ).createShader(rect));
    _rimStroke(canvas, b, [
      Colors.white.withOpacity(0.95), b.color.withOpacity(0.80),
      Colors.cyanAccent.withOpacity(0.80), Colors.purpleAccent.withOpacity(0.75),
      Colors.pinkAccent.withOpacity(0.70), Colors.white.withOpacity(0.85),
      Colors.lightBlueAccent.withOpacity(0.78), Colors.white.withOpacity(0.95),
    ]);
    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.72, r * 0.46);
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.54, r * 0.09);
    _caustic(canvas, b);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 2 – VIVID SOAP BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintVivid(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    _shadow(canvas, b, b.color.withOpacity(0.18), r * 0.6);
    canvas.drawCircle(c, r, Paint()..color = b.color.withOpacity(0.12));
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.45), radius: 0.82,
        colors: [
          Colors.cyanAccent.withOpacity(0.30), Colors.blueAccent.withOpacity(0.22),
          Colors.purpleAccent.withOpacity(0.18), Colors.pinkAccent.withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.50, 0.72, 1.0],
      ).createShader(rect));
    // Extra outer glow ring
    canvas.drawCircle(c, r + 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = b.color.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4));
    _rimStroke(canvas, b, [
      Colors.white, b.color.withOpacity(0.90),
      Colors.cyanAccent.withOpacity(0.90), Colors.purpleAccent.withOpacity(0.85),
      Colors.pinkAccent.withOpacity(0.88), Colors.greenAccent.withOpacity(0.80),
      Colors.white.withOpacity(0.95), Colors.white,
    ], widthFactor: 0.16);
    _highlight(canvas, b.x - r * 0.24, b.y - r * 0.30, r * 0.78, r * 0.50);
    _sparkle(canvas, b.x + r * 0.18, b.y - r * 0.56, r * 0.11);
    _sparkle(canvas, b.x - r * 0.50, b.y - r * 0.48, r * 0.06);
    _caustic(canvas, b);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 3 – NEON GLOW BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintNeon(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;

    // Outer neon glow halo
    canvas.drawCircle(c, r + r * 0.18,
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
    canvas.drawCircle(c, r + r * 0.08,
      Paint()
        ..color = b.color.withOpacity(0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));
    // Dark semi-transparent body
    canvas.drawCircle(c, r, Paint()..color = Colors.black.withOpacity(0.10));
    canvas.drawCircle(c, r, Paint()..color = b.color.withOpacity(0.08));
    // Inner light source
    canvas.drawCircle(c, r * 0.5,
      Paint()..shader = RadialGradient(
        colors: [
          Colors.cyanAccent.withOpacity(0.18), Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.5)));
    // Neon rim
    _rimStroke(canvas, b, [
      Colors.cyanAccent, b.color.withOpacity(0.95),
      Colors.greenAccent.withOpacity(0.95), Colors.white.withOpacity(0.90),
      Colors.cyanAccent.withOpacity(0.95), Colors.blueAccent,
      Colors.cyanAccent,
    ], widthFactor: 0.15);
    // Inner bright rim line
    canvas.drawCircle(c, r - r * 0.14 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = Colors.cyanAccent.withOpacity(0.45));
    _highlight(canvas, b.x - r * 0.20, b.y - r * 0.26, r * 0.65, r * 0.40);
    _sparkle(canvas, b.x + r * 0.15, b.y - r * 0.52, r * 0.10);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 4 – GOLD METALLIC BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintGold(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    _shadow(canvas, b, const Color(0xFFFFB300).withOpacity(0.30), r * 0.6);
    // Golden body
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.38), radius: 0.88,
        colors: [
          const Color(0xFFFFEE58).withOpacity(0.40),
          const Color(0xFFFFB300).withOpacity(0.28),
          const Color(0xFFFF8F00).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(rect));
    // Gold rim
    _rimStroke(canvas, b, [
      Colors.white, const Color(0xFFFFEE58).withOpacity(0.95),
      const Color(0xFFFFB300).withOpacity(0.95), const Color(0xFFFF8F00).withOpacity(0.90),
      const Color(0xFFFFD54F).withOpacity(0.88), Colors.white.withOpacity(0.92),
      const Color(0xFFFFEE58).withOpacity(0.90), Colors.white,
    ], widthFactor: 0.16);
    // Outer gold glow
    canvas.drawCircle(c, r + 4,
      Paint()
        ..color = const Color(0xFFFFB300).withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8));
    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.72, r * 0.46);
    // Star sparkles
    _drawStar(canvas, b.x + r * 0.55, b.y - r * 0.50, r * 0.14,
        const Color(0xFFFFEE58).withOpacity(0.90));
    _drawStar(canvas, b.x - r * 0.58, b.y + r * 0.45, r * 0.10,
        Colors.white.withOpacity(0.80));
    _sparkle(canvas, b.x + r * 0.12, b.y - r * 0.55, r * 0.09);
    _caustic(canvas, b);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = (i / 8) * math.pi * 2 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.45;
      if (i == 0) {
        path.moveTo(cx + math.cos(a) * rad, cy + math.sin(a) * rad);
      } else {
        path.lineTo(cx + math.cos(a) * rad, cy + math.sin(a) * rad);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 5 – CRYSTAL DIAMOND BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintCrystal(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    _shadow(canvas, b, Colors.cyan.withOpacity(0.20), r * 0.55);
    // Icy transparent body
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.35), radius: 0.85,
        colors: [
          Colors.white.withOpacity(0.22),
          const Color(0xFFB3E5FC).withOpacity(0.16),
          const Color(0xFF81D4FA).withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(rect));
    // Facet lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      canvas.drawLine(
        c,
        Offset(c.dx + math.cos(angle) * r * 0.72,
               c.dy + math.sin(angle) * r * 0.72),
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..strokeWidth = 0.8,
      );
    }
    // Crystal rim
    _rimStroke(canvas, b, [
      Colors.white, const Color(0xFF80DEEA).withOpacity(0.95),
      const Color(0xFF4DD0E1).withOpacity(0.90), Colors.white.withOpacity(0.88),
      const Color(0xFF80CBC4).withOpacity(0.85), Colors.white.withOpacity(0.92),
      const Color(0xFF80DEEA).withOpacity(0.90), Colors.white,
    ], widthFactor: 0.14);
    // Cold blue outer glow
    canvas.drawCircle(c, r + 5,
      Paint()
        ..color = const Color(0xFF80DEEA).withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10));
    // Multiple sharp highlights
    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.72, r * 0.46);
    _highlight(canvas, b.x + r * 0.30, b.y - r * 0.20, r * 0.30, r * 0.20);
    _sparkle(canvas, b.x + r * 0.12, b.y - r * 0.55, r * 0.11);
    _sparkle(canvas, b.x - r * 0.48, b.y + r * 0.40, r * 0.07);
    _sparkle(canvas, b.x + r * 0.50, b.y + r * 0.38, r * 0.06);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 6 – FIRE BURST BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintFire(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Outer ember glow
    canvas.drawCircle(c, r + r * 0.22,
      Paint()
        ..color = Colors.deepOrange.withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6));
    // Fire body gradient
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.30), radius: 0.85,
        colors: [
          Colors.yellow.withOpacity(0.40),
          Colors.orange.withOpacity(0.30),
          Colors.deepOrange.withOpacity(0.20),
          Colors.red.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(rect));
    // Fire rim
    _rimStroke(canvas, b, [
      Colors.white, Colors.yellow.withOpacity(0.95),
      Colors.orange.withOpacity(0.95), Colors.deepOrange.withOpacity(0.90),
      Colors.red.withOpacity(0.88), Colors.orange.withOpacity(0.90),
      Colors.yellow.withOpacity(0.92), Colors.white,
    ], widthFactor: 0.16);
    // Ember sparks
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2;
      final dist = r * 0.68;
      canvas.drawCircle(
        Offset(c.dx + math.cos(angle) * dist, c.dy + math.sin(angle) * dist),
        r * 0.055,
        Paint()..color = Colors.orange.withOpacity(0.75));
    }
    _highlight(canvas, b.x - r * 0.20, b.y - r * 0.26, r * 0.68, r * 0.42);
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.54, r * 0.10);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 7 – PREMIUM RAINBOW BUBBLE
  // ══════════════════════════════════════════════════════════

  void _paintRainbow(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = b.radius;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Double outer rainbow glow
    canvas.drawCircle(c, r + r * 0.25,
      Paint()
        ..color = Colors.purpleAccent.withOpacity(0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7));
    canvas.drawCircle(c, r + r * 0.12,
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));
    // Rainbow body (sweep over filled circle)
    canvas.drawCircle(c, r, Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.red.withOpacity(0.18), Colors.orange.withOpacity(0.16),
          Colors.yellow.withOpacity(0.16), Colors.green.withOpacity(0.16),
          Colors.cyan.withOpacity(0.18), Colors.blue.withOpacity(0.18),
          Colors.purple.withOpacity(0.18), Colors.red.withOpacity(0.18),
        ],
      ).createShader(rect));
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.3), radius: 0.7,
        colors: [Colors.white.withOpacity(0.20), Colors.transparent],
      ).createShader(rect));
    // Rainbow rim (thick, fully saturated)
    _rimStroke(canvas, b, [
      Colors.white, Colors.red.withOpacity(0.95),
      Colors.orange.withOpacity(0.92), Colors.yellow.withOpacity(0.95),
      Colors.green.withOpacity(0.92), Colors.cyan.withOpacity(0.95),
      Colors.blue.withOpacity(0.92), Colors.purple.withOpacity(0.90),
      Colors.white.withOpacity(0.95), Colors.white,
    ], widthFactor: 0.18);
    // Inner bright ring
    canvas.drawCircle(c, r - r * 0.18 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.white.withOpacity(0.35));
    // 4 shine spots
    _highlight(canvas, b.x - r * 0.24, b.y - r * 0.30, r * 0.76, r * 0.50);
    _highlight(canvas, b.x + r * 0.28, b.y - r * 0.18, r * 0.32, r * 0.22);
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.56, r * 0.12);
    _sparkle(canvas, b.x - r * 0.50, b.y + r * 0.45, r * 0.07);
    // Premium star badge (top-right)
    _drawStar(canvas, b.x + r * 0.58, b.y - r * 0.52, r * 0.16,
        Colors.yellow.withOpacity(0.92));
    _caustic(canvas, b);
  }

  // ══════════════════════════════════════════════════════════
  //  BURST (level-tinted pop)
  // ══════════════════════════════════════════════════════════

  void _paintBurst(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = b.radius;
    final p = b.burstProgress.clamp(0.0, 1.0);
    final fade = (1.0 - p).clamp(0.0, 1.0);

    // White flash
    if (p < 0.20) {
      final f = ((0.20 - p) / 0.20).clamp(0.0, 1.0);
      canvas.drawCircle(c, r * (1.0 - p * 3.5),
          Paint()..color = Colors.white.withOpacity(f * 0.85));
    }

    // Level-tinted expanding ring
    final ringR = r * (1.0 + p * 2.4);
    canvas.drawCircle(c, ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.18 * fade).clamp(0.0, r)
        ..shader = SweepGradient(
          colors: [
            Colors.cyanAccent.withOpacity(fade * 0.85),
            b.color.withOpacity(fade * 0.90),
            Colors.purpleAccent.withOpacity(fade * 0.80),
            Colors.white.withOpacity(fade * 0.75),
            Colors.cyanAccent.withOpacity(fade * 0.85),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: ringR)));

    // Thin secondary ring
    if (p < 0.75) {
      canvas.drawCircle(c, r * (1.0 + p * 1.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * 0.06 * fade).clamp(0.0, r)
          ..color = Colors.white.withOpacity(fade * 0.45));
    }

    // Droplets
    const n = 12;
    final dp = Paint();
    for (int i = 0; i < n; i++) {
      final a = (i / n) * math.pi * 2 + p * 0.6;
      final dist = r * (1.8 + (i % 3) * 0.4) * p;
      final dc = Offset(c.dx + math.cos(a) * dist, c.dy + math.sin(a) * dist);
      final dr = (r * 0.16 * (1 - p * 0.8)).clamp(0.0, r);
      dp.color = [
        b.color.withOpacity(fade * 0.9),
        Colors.cyanAccent.withOpacity(fade * 0.8),
        Colors.white.withOpacity(fade * 0.85),
        Colors.purpleAccent.withOpacity(fade * 0.75),
      ][i % 4];
      canvas.drawCircle(dc, dr, dp);
      canvas.drawCircle(
        Offset(dc.dx - dr * 0.3, dc.dy - dr * 0.3), dr * 0.3,
        Paint()..color = Colors.white.withOpacity(fade * 0.7));
    }
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
      old.level != level || true; // always repaint for animation
}
