import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/models/bubble_model.dart';

/// Level → Bubble skin mapping (10-level tiers, 10 skins total)
///  Lv  1-10  – Classic Soap    (transparent, iridescent rim)
///  Lv 11-20  – Vivid Soap      (brighter iridescence, thicker rim)
///  Lv 21-30  – Neon Glow       (electric edges, inner light source)
///  Lv 31-40  – Gold Metallic   (amber/gold body, star sparkles)
///  Lv 41-50  – Crystal Diamond (icy facets, sharp multi-highlight)
///  Lv 51-60  – Fire Burst      (flame gradient, ember glow)
///  Lv 61-70  – Rainbow         (full-spectrum body + prismatic rim)
///  Lv 71-80  – Aurora          (northern-lights green/purple/teal)
///  Lv 81-90  – Plasma          (hot magenta/pink energy burst)
///  Lv 91-100 – Cosmic          (deep-space dark with star clusters)
class BubblePainter extends CustomPainter {
  final List<BubbleModel> bubbles;
  final int level;
  final BubbleStyle style;
  // 0→2π looping animation time used for gentle per-bubble pulse/wobble.
  final double animTime;
  /// Pre-loaded gift.png image — null until loaded, renders fallback if absent.
  final ui.Image? giftImage;
  /// Pre-loaded dog images for the animal bubble style.
  final List<ui.Image> dogImages;

  BubblePainter({
    required this.bubbles,
    required this.level,
    this.style = BubbleStyle.classic,
    this.animTime = 0.0,
    this.giftImage,
    this.dogImages = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      if (b.isBursting) {
        _paintBurst(canvas, b);
      } else if (!b.isPopped) {
        if (b.isLocked) {
          _paintLockedBubble(canvas, b);
        } else if (b.isGift) {
          _paintGiftBubble(canvas, b);
        } else if (b.isSpecial) {
          _paintSpecial(canvas, b);
        } else {
          _paintWithStyle(canvas, b);
        }
        // Overlay letter on top for learning mode bubbles
        if (b.letter != null) {
          _paintLetter(canvas, b);
        }
      }
    }
  }

  void _paintLetter(Canvas canvas, BubbleModel b) {
    final fontSize = b.radius * 1.10;
    // Constraint width = bubble diameter so textAlign: center is truly centered.
    final constraintW = b.radius * 2.0;
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: ui.FontWeight.w900,
      shadows: const [
        ui.Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    );
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    )
      ..pushStyle(textStyle)
      ..addText(b.letter!);
    final para = builder.build()
      ..layout(ui.ParagraphConstraints(width: constraintW));
    // Draw so the paragraph rect is centred exactly on (b.x, b.y).
    canvas.drawParagraph(
      para,
      Offset(b.x - constraintW / 2, b.y - para.height / 2),
    );
  }

  void _paintWithStyle(Canvas canvas, BubbleModel b) {
    switch (style) {
      case BubbleStyle.blur:
        _paintBlur(canvas, b);
        break;
      case BubbleStyle.heart:
        _paintHeart(canvas, b);
        break;
      case BubbleStyle.star:
        _paintStar(canvas, b);
        break;
      case BubbleStyle.diamond:
        _paintDiamond(canvas, b);
        break;
      case BubbleStyle.dog1:
        _paintDogBubble(canvas, b, 0);
        break;
      case BubbleStyle.dog2:
        _paintDogBubble(canvas, b, 1);
        break;
      case BubbleStyle.dog3:
        _paintDogBubble(canvas, b, 2);
        break;
      case BubbleStyle.classic:
        // Map level → tier index 0-9 (every 10 levels = one skin)
        final tier = ((level - 1) ~/ 10).clamp(0, 9);
        switch (tier) {
          case 0: _paintSoap(canvas, b); break;
          case 1: _paintVivid(canvas, b); break;
          case 2: _paintNeon(canvas, b); break;
          case 3: _paintGold(canvas, b); break;
          case 4: _paintCrystal(canvas, b); break;
          case 5: _paintFire(canvas, b); break;
          case 6: _paintRainbow(canvas, b); break;
          case 7: _paintAurora(canvas, b); break;
          case 8: _paintPlasma(canvas, b); break;
          case 9:
          default:
            _paintCosmic(canvas, b); break;
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
    final r = _pulseRadius(b);
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

  void _sparkle(Canvas canvas, double cx, double cy, double r, {Color? color}) {
    canvas.drawCircle(
        Offset(cx, cy), r, Paint()..color = (color ?? Colors.white).withOpacity(0.88));
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);

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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
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
  //  STAR – Golden glowing 5-point star bubble
  // ══════════════════════════════════════════════════════════

  Path _starPath(double cx, double cy, double outer, double inner) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final rad = i.isEven ? outer : inner;
      final x = cx + math.cos(angle) * rad;
      final y = cy + math.sin(angle) * rad;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  void _paintStar(Canvas canvas, BubbleModel b) {
    final cx = b.x; final cy = b.y; final r = _pulseRadius(b);
    final outer = r * 0.95;
    final inner = r * 0.42;
    final starBounds = Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.0);
    final path = _starPath(cx, cy, outer, inner);

    // Outer golden glow
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.60));

    // Golden body gradient
    canvas.drawPath(path, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35), radius: 0.88,
        colors: [
          const Color(0xFFFFF9C4).withOpacity(0.85),
          const Color(0xFFFFD54F).withOpacity(0.65),
          const Color(0xFFFF8F00).withOpacity(0.35),
          Colors.transparent,
        ],
      ).createShader(starBounds));

    // Rainbow iridescent sweep
    canvas.drawPath(path, Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.yellow.withOpacity(0.30),
          Colors.orange.withOpacity(0.25),
          Colors.pink.withOpacity(0.20),
          Colors.purple.withOpacity(0.18),
          Colors.cyan.withOpacity(0.22),
          Colors.yellow.withOpacity(0.30),
        ],
      ).createShader(starBounds));

    // Golden iridescent rim
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.3,
        endAngle:    math.pi * 1.7,
        colors: [
          Colors.white,
          const Color(0xFFFFEE58).withOpacity(0.95),
          const Color(0xFFFF9100).withOpacity(0.90),
          Colors.pinkAccent.withOpacity(0.80),
          Colors.cyanAccent.withOpacity(0.85),
          const Color(0xFFFFEE58).withOpacity(0.92),
          Colors.white,
        ],
      ).createShader(starBounds));

    // Inner bright ring
    canvas.drawPath(_starPath(cx, cy, outer * 0.84, inner * 0.84), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03
      ..color = Colors.white.withOpacity(0.45));

    // Large top-left highlight
    final hlRect = Rect.fromCenter(center: Offset(cx - r * 0.22, cy - r * 0.28), width: r * 0.80, height: r * 0.50);
    canvas.drawOval(hlRect, Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.90), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ).createShader(hlRect));

    // Corner sparkles
    _drawStar(canvas, cx + r * 0.72, cy - r * 0.68, r * 0.13, const Color(0xFFFFEE58).withOpacity(0.95));
    _drawStar(canvas, cx - r * 0.75, cy + r * 0.60, r * 0.09, Colors.white.withOpacity(0.85));
    _sparkle(canvas, cx + r * 0.18, cy - r * 0.58, r * 0.09);
  }

  // ══════════════════════════════════════════════════════════
  //  HEART – Rainbow iridescent heart bubble (matches photo)
  // ══════════════════════════════════════════════════════════

  /// Perfect heart using the parametric equation:
  ///   x(t) = 16·sin³(t)
  ///   y(t) = 13·cos(t) − 5·cos(2t) − 2·cos(3t) − cos(4t)
  /// 120 segments → smooth curve, visually identical to a real heart.
  Path _heartPath(double cx, double cy, double r) {
    final path = Path();
    // Scale so the heart fits neatly inside radius r.
    // Formula x∈[-16,16] → width=32; scale = r/16 → width = 2r.
    // Formula y center ≈ -2.5 (midpoint of [-17, 12]); we shift to truly centre it.
    final scale = r / 16.0;
    const vCenter = -2.5; // vertical midpoint of the formula's y-range

    for (int i = 0; i <= 120; i++) {
      final t = (i / 120) * 2 * math.pi;
      final hx = 16.0 * math.pow(math.sin(t), 3).toDouble();
      final hy = 13.0 * math.cos(t)
               - 5.0  * math.cos(2.0 * t)
               - 2.0  * math.cos(3.0 * t)
               -        math.cos(4.0 * t);

      // Flutter y-axis is inverted relative to the formula.
      final px = cx + hx * scale;
      final py = cy - (hy - vCenter) * scale;

      if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
    }
    path.close();
    return path;
  }

  void _paintHeart(Canvas canvas, BubbleModel b) {
    final cx = b.x;
    final cy = b.y;
    // Use full bubble radius — the parametric path already fits inside 2r × 1.8r.
    final r  = b.radius * 0.78;
    // Bounding rect that covers the heart (width = 2r, height ≈ 1.82r).
    final heartBounds = Rect.fromCenter(
        center: Offset(cx, cy), width: r * 2.0, height: r * 1.85);
    final path = _heartPath(cx, cy, r);

    // ── Outer bokeh glow (matches the background haze in the photo)
    canvas.drawPath(
      path,
      Paint()
        ..color = b.color.withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.70),
    );

    // ── Translucent glass body — very slight colour tint
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.20, -0.35),
          radius: 0.85,
          colors: [
            Colors.white.withOpacity(0.22),
            b.color.withOpacity(0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(heartBounds),
    );

    // ── Rainbow iridescent sweep body (the colourful interior from the photo)
    canvas.drawPath(
      path,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.5,
          endAngle:    math.pi * 1.5,
          colors: [
            Colors.pink.withOpacity(0.28),
            Colors.purple.withOpacity(0.24),
            Colors.cyan.withOpacity(0.26),
            Colors.blue.withOpacity(0.22),
            Colors.teal.withOpacity(0.24),
            Colors.yellow.withOpacity(0.20),
            Colors.orange.withOpacity(0.22),
            Colors.pink.withOpacity(0.28),
          ],
        ).createShader(heartBounds),
    );

    // ── Iridescent rim stroke (thick rainbow outline — key feature in photo)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.4,
          endAngle:    math.pi * 1.6,
          colors: [
            Colors.white,
            Colors.pink.withOpacity(0.95),
            Colors.purple.withOpacity(0.92),
            Colors.cyanAccent.withOpacity(0.95),
            Colors.blue.withOpacity(0.90),
            Colors.teal.withOpacity(0.92),
            Colors.yellow.withOpacity(0.90),
            Colors.orange.withOpacity(0.88),
            Colors.pink.withOpacity(0.92),
            Colors.white,
          ],
        ).createShader(heartBounds),
    );

    // ── Inner bright rim line (secondary halo visible in the photo)
    canvas.drawPath(
      _heartPath(cx, cy, r * 0.84),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = Colors.white.withOpacity(0.42),
    );

    // ── Large top-left specular highlight (the big white glare spot)
    final hlRect = Rect.fromCenter(
      center: Offset(cx - r * 0.28, cy - r * 0.32),
      width: r * 0.90, height: r * 0.58,
    );
    canvas.drawOval(
      hlRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.92),
            Colors.white.withOpacity(0.45),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(hlRect),
    );

    // ── Small secondary sparkle (top-right)
    _sparkle(canvas, cx + r * 0.22, cy - r * 0.58, r * 0.10);

    // ── Tiny caustic reflection at bottom
    final causticRect = Rect.fromCenter(
      center: Offset(cx + r * 0.06, cy + r * 0.60),
      width: r * 0.42, height: r * 0.18,
    );
    canvas.drawOval(
      causticRect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.30), Colors.transparent],
        ).createShader(causticRect),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DIAMOND – Proper 4-point gem diamond (rhombus)
  // ══════════════════════════════════════════════════════════

  /// Classic gem diamond: narrow top/bottom points, wide left/right equator.
  /// Upper half is shorter (crown), lower half is taller (pavilion).
  Path _diamondPath(double cx, double cy, double r) {
    final path = Path();
    final hw = r * 0.78;      // half-width at equator
    final top   = cy - r * 0.55; // top point (crown tip)
    final bot   = cy + r * 1.00; // bottom point (pavilion tip)
    final mid   = cy - r * 0.08; // equator (widest)
    // Top girdle corners (shoulders)
    final gL    = cx - hw;
    final gR    = cx + hw;

    path.moveTo(cx, top);           // top tip
    path.lineTo(gR, mid);           // top-right shoulder
    path.lineTo(cx, bot);           // bottom tip
    path.lineTo(gL, mid);           // top-left shoulder
    path.close();
    return path;
  }

  void _paintDiamond(Canvas canvas, BubbleModel b) {
    final cx = b.x; final cy = b.y; final r = b.radius * 0.90;
    final bounds = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.8);
    final path = _diamondPath(cx, cy, r);

    // Outer icy glow
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF80DEEA).withOpacity(0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.60));

    // Glass body — icy blue-white gradient
    canvas.drawPath(path, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.20, -0.35), radius: 0.90,
        colors: [
          Colors.white.withOpacity(0.55),
          const Color(0xFFB3E5FC).withOpacity(0.35),
          const Color(0xFF81D4FA).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(bounds));

    // Iridescent sweep
    canvas.drawPath(path, Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.cyan.withOpacity(0.30),
          Colors.blue.withOpacity(0.25),
          Colors.purple.withOpacity(0.20),
          Colors.pink.withOpacity(0.18),
          Colors.cyan.withOpacity(0.30),
        ],
      ).createShader(bounds));

    // Facet lines from top tip to equator corners
    final facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(cx, cy - r * 0.55), Offset(cx - r * 0.78 * 0.5, cy - r * 0.08), facetPaint);
    canvas.drawLine(Offset(cx, cy - r * 0.55), Offset(cx + r * 0.78 * 0.5, cy - r * 0.08), facetPaint);
    canvas.drawLine(Offset(cx - r * 0.78, cy - r * 0.08), Offset(cx, cy - r * 0.08), facetPaint);
    canvas.drawLine(Offset(cx + r * 0.78, cy - r * 0.08), Offset(cx, cy - r * 0.08), facetPaint);

    // Rainbow iridescent rim stroke
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.10
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.3,
        endAngle:    math.pi * 1.7,
        colors: [
          Colors.white,
          const Color(0xFF80DEEA).withOpacity(0.95),
          const Color(0xFF4DD0E1).withOpacity(0.90),
          Colors.white.withOpacity(0.88),
          const Color(0xFF80CBC4).withOpacity(0.85),
          Colors.purpleAccent.withOpacity(0.80),
          Colors.cyanAccent.withOpacity(0.88),
          Colors.white,
        ],
      ).createShader(bounds));

    // Large specular highlight (top-left)
    final hlRect = Rect.fromCenter(
      center: Offset(cx - r * 0.20, cy - r * 0.25),
      width: r * 0.75, height: r * 0.48,
    );
    canvas.drawOval(hlRect, Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.92), Colors.white.withOpacity(0.0)],
        stops: const [0.0, 1.0],
      ).createShader(hlRect));

    // Small sparkles at corners
    _sparkle(canvas, cx + r * 0.62, cy - r * 0.12, r * 0.08);
    _sparkle(canvas, cx - r * 0.62, cy - r * 0.12, r * 0.06);
    _sparkle(canvas, cx, cy - r * 0.50, r * 0.07);
  }

  // ══════════════════════════════════════════════════════════
  //  BLUR – Frosted / soft glass
  // ══════════════════════════════════════════════════════════

  void _paintBlur(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = _pulseRadius(b);

    // Soft outer halo
    canvas.drawCircle(c, r * 1.25,
        Paint()
          ..color = b.color.withOpacity(0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55));
    // Frosted body
    canvas.drawCircle(c, r,
        Paint()
          ..color = b.color.withOpacity(0.38)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.30));
    canvas.drawCircle(c, r,
        Paint()..color = b.color.withOpacity(0.28));
    // Soft white overlay
    canvas.drawCircle(c, r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.3),
            colors: [Colors.white.withOpacity(0.55), Colors.transparent],
            stops: const [0.0, 0.8],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    // Thin rim
    canvas.drawCircle(c, r,
        Paint()
          ..color = Colors.white.withOpacity(0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06);
    // Highlight
    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.60, r * 0.38);
  }

  // ══════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════
  //  DOG BUBBLE – cute dog image inside a glass bubble
  //  index 0 = dog.png  (warm orange)
  //  index 1 = dog_2.png (mint green)
  //  index 2 = dog_3.png (soft purple)
  // ══════════════════════════════════════════════════════════

  static const _dogBodyColors = [
    // dog1 — warm peach/orange
    [Color(0xFFFFF3E0), Color(0xFFFFCC80), Color(0xFFFF8A65)],
    // dog2 — mint green
    [Color(0xFFF1F8E9), Color(0xFFA5D6A7), Color(0xFF43A047)],
    // dog3 — soft purple/lavender
    [Color(0xFFF3E5F5), Color(0xFFCE93D8), Color(0xFF8E24AA)],
  ];

  static const _dogGlowColors = [
    Color(0xFFFFCC80), Color(0xFFA5D6A7), Color(0xFFCE93D8),
  ];

  static const _dogRimPalettes = [
    // dog1 — warm iridescent
    [Colors.white, Color(0xFFFFCC80), Color(0xFFFFB74D), Color(0xFFFF8A65), Colors.white, Color(0xFFFFCC80), Colors.white],
    // dog2 — cool mint iridescent
    [Colors.white, Color(0xFFA5D6A7), Color(0xFF66BB6A), Color(0xFF43A047), Colors.white, Color(0xFFA5D6A7), Colors.white],
    // dog3 — purple iridescent
    [Colors.white, Color(0xFFCE93D8), Color(0xFFAB47BC), Color(0xFF8E24AA), Colors.white, Color(0xFFCE93D8), Colors.white],
  ];

  static const _dogSparkleColors = [
    Color(0xFFFF6B9D), Color(0xFF66BB6A), Color(0xFFBA68C8),
  ];

  // Returns true for ~50% of bubbles — stable per bubble id so it never flickers.
  // Out of every 5 bubbles, roughly 2-3 will show the animal image.
  bool _shouldShowAnimal(BubbleModel b) => b.id.hashCode.abs() % 5 < 3;

  void _paintDogBubble(Canvas canvas, BubbleModel b, int index) {
    final c    = Offset(b.x, b.y);
    final r    = _pulseRadius(b);
    final rect = Rect.fromCircle(center: c, radius: r);
    final glowColor = _dogGlowColors[index];
    final body      = _dogBodyColors[index];

    // Soft outer glow (colour-tinted per style)
    canvas.drawCircle(c, r * 1.28,
        Paint()
          ..color = glowColor.withOpacity(0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));

    // Transparent glass body — nearly invisible like a real soap bubble
    canvas.drawCircle(c, r, Paint()..color = body[0].withOpacity(0.07));
    // Iridescent film layer
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.42),
        radius: 0.78,
        colors: [
          Colors.cyan.withOpacity(0.18),
          body[1].withOpacity(0.14),
          Colors.purple.withOpacity(0.10),
          Colors.pink.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.52, 0.72, 1.0],
      ).createShader(rect));

    // ── Animal image — only on ~50% of bubbles ──────────────────────────────
    if (_shouldShowAnimal(b) && index < dogImages.length) {
      final img     = dogImages[index];
      final imgSize = r * 1.45;
      final dst = Rect.fromCenter(center: c, width: imgSize, height: imgSize);
      final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.72)));
      canvas.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    }

    // ── Rainbow iridescent rim — uses dedicated dog rim palette ───
    _rimStroke(canvas, b, _dogRimPalettes[index]);

    // Top-left specular highlight (soap-bubble style oval)
    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.72, r * 0.46);

    // Small sparkle with custom dog sparkle color
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.54, r * 0.09, color: _dogSparkleColors[index]);
  }

  // ══════════════════════════════════════════════════════════
  //  GIFT BUBBLE – once-per-level, shows gift.png inside
  // ══════════════════════════════════════════════════════════

  void _paintLockedBubble(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = b.radius;

    // Dark translucent body
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = const Color(0xFF37474F).withOpacity(0.80)
        ..style = PaintingStyle.fill,
    );

    // Subtle rim
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Lock icon drawn with primitives
    final lockW = r * 0.55;
    final lockH = r * 0.65;
    final lx = c.dx - lockW / 2;
    final ly = c.dy - lockH * 0.25;

    // Lock body (rounded rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(lx, ly, lockW, lockH * 0.6),
      Radius.circular(lockW * 0.18),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // Lock shackle (arc)
    final shacklePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lockW * 0.18
      ..strokeCap = StrokeCap.round;
    final shackleRect = Rect.fromCenter(
      center: Offset(c.dx, ly),
      width: lockW * 0.55,
      height: lockH * 0.5,
    );
    canvas.drawArc(shackleRect, math.pi, math.pi, false, shacklePaint);

    // Keyhole
    canvas.drawCircle(
      Offset(c.dx, ly + lockH * 0.3),
      lockW * 0.10,
      Paint()..color = const Color(0xFF37474F).withOpacity(0.70),
    );
  }

  void _paintGiftBubble(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = _pulseRadius(b);

    // Outer pulsing pink/magenta aura
    canvas.drawCircle(c, r * 1.45,
        Paint()
          ..color = const Color(0xFFFF6B9D).withOpacity(0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6));
    canvas.drawCircle(c, r * 1.25,
        Paint()
          ..color = const Color(0xFFFF4081).withOpacity(0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));

    // Glass bubble body — pink-to-purple gradient
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.30),
        colors: [
          const Color(0xFFFFB3D1).withOpacity(0.65),
          const Color(0xFFFF6B9D).withOpacity(0.45),
          const Color(0xFFCE93D8).withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(rect));

    // Rainbow iridescent rim
    _rimStroke(canvas, b, [
      Colors.white,
      Colors.pink.withOpacity(0.95),
      Colors.purple.withOpacity(0.90),
      Colors.cyan.withOpacity(0.85),
      Colors.yellow.withOpacity(0.88),
      Colors.pink.withOpacity(0.92),
      Colors.white,
    ], widthFactor: 0.09);

    // Draw gift.png centred inside the bubble (60% of diameter)
    if (giftImage != null) {
      final imgSize = r * 1.2;
      final dst = Rect.fromCenter(center: c, width: imgSize, height: imgSize);
      final src = Rect.fromLTWH(0, 0,
          giftImage!.width.toDouble(), giftImage!.height.toDouble());
      canvas.save();
      // Clip to circle so the image doesn't bleed outside the bubble
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.9)));
      canvas.drawImageRect(giftImage!, src, dst, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    } else {
      // Fallback: gift emoji rendered as text if image not yet loaded
      final tp = TextPainter(
        text: const TextSpan(text: '🎁', style: TextStyle(fontSize: 28)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }

    // Top-left specular highlight
    final hcx = b.x - r * 0.28;
    final hcy = b.y - r * 0.32;
    canvas.drawCircle(Offset(hcx, hcy), r * 0.22,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withOpacity(0.85), Colors.transparent],
          ).createShader(
              Rect.fromCircle(center: Offset(hcx, hcy), radius: r * 0.22)));

    // Sparkle stars around the bubble
    _drawStar(canvas, b.x + r * 0.80, b.y - r * 0.70, r * 0.12,
        const Color(0xFFFFD700).withOpacity(0.95));
    _drawStar(canvas, b.x - r * 0.82, b.y + r * 0.60, r * 0.09,
        Colors.white.withOpacity(0.90));
    _drawStar(canvas, b.x + r * 0.55, b.y + r * 0.78, r * 0.11,
        const Color(0xFFFF80AB).withOpacity(0.95));
    _drawStar(canvas, b.x - r * 0.70, b.y - r * 0.60, r * 0.10,
        const Color(0xFFCE93D8).withOpacity(0.90));
  }

  // ══════════════════════════════════════════════════════════
  //  SPECIAL – Golden home-style 10-pt bubble
  // ══════════════════════════════════════════════════════════

  void _paintSpecial(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = _pulseRadius(b);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Pulsing outer aura
    canvas.drawCircle(c, r * 1.35,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55));
    canvas.drawCircle(c, r * 1.18,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.28));

    // Glass body — semi-transparent gold fill
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.35),
        colors: [
          const Color(0xFFFFF9C4).withOpacity(0.55),
          const Color(0xFFFFD700).withOpacity(0.30),
          const Color(0xFFFF8F00).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(rect));

    // Full-spectrum rainbow rim (makes it look like the home screen bubbles)
    _rimStroke(canvas, b, [
      Colors.white,
      Colors.yellow.withOpacity(0.95),
      Colors.orange.withOpacity(0.90),
      Colors.red.withOpacity(0.85),
      Colors.pink.withOpacity(0.88),
      Colors.purple.withOpacity(0.85),
      Colors.cyan.withOpacity(0.90),
      Colors.white.withOpacity(0.92),
      Colors.yellow.withOpacity(0.95),
      Colors.white,
    ], widthFactor: 0.10);

    // Top-left specular highlight
    final hcx = b.x - r * 0.28;
    final hcy = b.y - r * 0.30;
    canvas.drawCircle(Offset(hcx, hcy), r * 0.26,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withOpacity(0.90), Colors.transparent],
          ).createShader(
              Rect.fromCircle(center: Offset(hcx, hcy), radius: r * 0.26)));

    // Stars around the bubble
    _drawStar(canvas, b.x + r * 0.75, b.y - r * 0.65, r * 0.14,
        const Color(0xFFFFEE58).withOpacity(0.95));
    _drawStar(canvas, b.x - r * 0.78, b.y + r * 0.55, r * 0.10,
        Colors.white.withOpacity(0.85));
    _drawStar(canvas, b.x + r * 0.60, b.y + r * 0.72, r * 0.12,
        const Color(0xFFFFD700).withOpacity(0.90));
  }

  // ══════════════════════════════════════════════════════════
  //  LV 71-80 – AURORA BUBBLE  (northern lights)
  // ══════════════════════════════════════════════════════════

  void _paintAurora(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Soft outer aurora glow — green + purple haze
    canvas.drawCircle(c, r + r * 0.28,
      Paint()
        ..color = const Color(0xFF00E676).withOpacity(0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7));
    canvas.drawCircle(c, r + r * 0.15,
      Paint()
        ..color = const Color(0xFFCE93D8).withOpacity(0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));

    // Translucent body with aurora sweep
    canvas.drawCircle(c, r, Paint()..color = Colors.black.withOpacity(0.08));
    canvas.drawCircle(c, r, Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.6,
        endAngle: math.pi * 1.4,
        colors: [
          const Color(0xFF00E676).withOpacity(0.22),
          const Color(0xFF00BCD4).withOpacity(0.20),
          const Color(0xFF7C4DFF).withOpacity(0.22),
          const Color(0xFFCE93D8).withOpacity(0.20),
          const Color(0xFF00E676).withOpacity(0.22),
        ],
      ).createShader(rect));

    // Vertical aurora band overlay
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.50), radius: 0.75,
        colors: [
          const Color(0xFF00E676).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(rect));

    // Aurora rim — green → teal → purple
    _rimStroke(canvas, b, [
      Colors.white,
      const Color(0xFF00E676).withOpacity(0.95),
      const Color(0xFF00BCD4).withOpacity(0.90),
      const Color(0xFF7C4DFF).withOpacity(0.88),
      const Color(0xFFCE93D8).withOpacity(0.92),
      const Color(0xFF00E676).withOpacity(0.90),
      Colors.white,
    ], widthFactor: 0.17);

    // Inner bright aurora line
    canvas.drawCircle(c, r - r * 0.17 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = const Color(0xFF00E676).withOpacity(0.40));

    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.72, r * 0.46);
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.54, r * 0.10);
    _sparkle(canvas, b.x - r * 0.48, b.y + r * 0.42, r * 0.07);
    _caustic(canvas, b);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 81-90 – PLASMA BUBBLE  (hot magenta/pink energy)
  // ══════════════════════════════════════════════════════════

  void _paintPlasma(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Hot outer plasma corona
    canvas.drawCircle(c, r + r * 0.30,
      Paint()
        ..color = const Color(0xFFE040FB).withOpacity(0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8));
    canvas.drawCircle(c, r + r * 0.14,
      Paint()
        ..color = const Color(0xFFFF4081).withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));

    // Semi-dark body
    canvas.drawCircle(c, r, Paint()..color = Colors.black.withOpacity(0.12));

    // Plasma body gradient — core hot white fading to magenta
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2), radius: 0.80,
        colors: [
          Colors.white.withOpacity(0.22),
          const Color(0xFFE040FB).withOpacity(0.28),
          const Color(0xFFFF4081).withOpacity(0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect));

    // Plasma sweep
    canvas.drawCircle(c, r, Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFE040FB).withOpacity(0.25),
          const Color(0xFFFF4081).withOpacity(0.22),
          const Color(0xFFFFAB40).withOpacity(0.18),
          const Color(0xFFE040FB).withOpacity(0.25),
        ],
      ).createShader(rect));

    // Plasma rim — magenta/pink/orange
    _rimStroke(canvas, b, [
      Colors.white,
      const Color(0xFFE040FB).withOpacity(0.95),
      const Color(0xFFFF4081).withOpacity(0.92),
      const Color(0xFFFFAB40).withOpacity(0.88),
      const Color(0xFFE040FB).withOpacity(0.90),
      const Color(0xFFFF4081).withOpacity(0.95),
      Colors.white,
    ], widthFactor: 0.17);

    // Inner plasma ring
    canvas.drawCircle(c, r - r * 0.17 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = const Color(0xFFE040FB).withOpacity(0.45));

    // Energy burst sparks around equator
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + animTime * 0.5;
      final dist = r * 0.72;
      canvas.drawCircle(
        Offset(c.dx + math.cos(angle) * dist, c.dy + math.sin(angle) * dist),
        r * 0.055,
        Paint()..color = const Color(0xFFFFAB40).withOpacity(0.80));
    }

    _highlight(canvas, b.x - r * 0.22, b.y - r * 0.28, r * 0.70, r * 0.44);
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.54, r * 0.11);
  }

  // ══════════════════════════════════════════════════════════
  //  LV 91-100 – COSMIC BUBBLE  (deep space, star clusters)
  // ══════════════════════════════════════════════════════════

  void _paintCosmic(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y); final r = _pulseRadius(b);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Deep space outer glow — indigo + gold
    canvas.drawCircle(c, r + r * 0.35,
      Paint()
        ..color = const Color(0xFF3D1A78).withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9));
    canvas.drawCircle(c, r + r * 0.15,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4));

    // Dark nebula body
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0A0020).withOpacity(0.55));

    // Nebula colour sweep
    canvas.drawCircle(c, r, Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF7C4DFF).withOpacity(0.30),
          const Color(0xFF00BCD4).withOpacity(0.22),
          const Color(0xFF3D1A78).withOpacity(0.28),
          const Color(0xFFE040FB).withOpacity(0.20),
          const Color(0xFF7C4DFF).withOpacity(0.30),
        ],
      ).createShader(rect));

    // Radial core glow
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.25), radius: 0.70,
        colors: [
          Colors.white.withOpacity(0.18),
          const Color(0xFF7C4DFF).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(rect));

    // Cosmic rim — gold/purple/cyan
    _rimStroke(canvas, b, [
      Colors.white,
      const Color(0xFFFFD700).withOpacity(0.95),
      const Color(0xFF7C4DFF).withOpacity(0.90),
      const Color(0xFF00BCD4).withOpacity(0.92),
      const Color(0xFFE040FB).withOpacity(0.88),
      const Color(0xFFFFD700).withOpacity(0.92),
      Colors.white,
    ], widthFactor: 0.18);

    // Inner bright ring
    canvas.drawCircle(c, r - r * 0.18 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = Colors.white.withOpacity(0.30));

    // Star cluster — 8 stars scattered inside bubble
    final rng = math.Random(b.x.toInt() ^ b.y.toInt());
    for (int i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist  = rng.nextDouble() * r * 0.65;
      final size  = r * (0.03 + rng.nextDouble() * 0.04);
      canvas.drawCircle(
        Offset(c.dx + math.cos(angle) * dist, c.dy + math.sin(angle) * dist),
        size,
        Paint()..color = Colors.white.withOpacity(0.60 + rng.nextDouble() * 0.30));
    }

    // Large specular highlight
    _highlight(canvas, b.x - r * 0.24, b.y - r * 0.30, r * 0.76, r * 0.50);
    // Gold star badge
    _drawStar(canvas, b.x + r * 0.60, b.y - r * 0.54, r * 0.16,
        const Color(0xFFFFD700).withOpacity(0.95));
    _sparkle(canvas, b.x + r * 0.14, b.y - r * 0.56, r * 0.12);
    _caustic(canvas, b);
  }

  // ══════════════════════════════════════════════════════════
  //  BURST (level-tinted pop)
  // ══════════════════════════════════════════════════════════

  void _paintBurst(Canvas canvas, BubbleModel b) {
    final c = Offset(b.x, b.y);
    final r = _pulseRadius(b);
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

  /// Returns the visually-animated radius for bubble [b].
  /// Each bubble gets a unique phase from its position so they pulse in/out
  /// independently, giving a natural floating feel.
  double _pulseRadius(BubbleModel b) {
    final phase = (b.x * 0.031 + b.y * 0.017) % (2 * math.pi);
    return b.radius * (1.0 + 0.045 * math.sin(animTime + phase));
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
      old.animTime != animTime || old.level != level || old.style != style || true;
}
