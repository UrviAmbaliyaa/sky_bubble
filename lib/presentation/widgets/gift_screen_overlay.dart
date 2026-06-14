import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../data/services/ad_service.dart';
import '../controllers/game_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GIFT SCREEN OVERLAY  — luxurious dark theme
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

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0, end: -16).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _wobble  = Tween<double>(begin: -0.035, end: 0.035).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

    _lidCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _lidFly  = Tween<double>(begin: 0, end: -150).animate(CurvedAnimation(parent: _lidCtrl, curve: Curves.easeOut));
    _lidFade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _lidCtrl, curve: const Interval(0.30, 1.0)));

    _shatterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 430));
    _boxScale = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _shatterCtrl, curve: Curves.easeOutBack));

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _particles = List.generate(75, (_) => _Particle(_rnd));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _cardSlide = Tween<double>(begin: 80, end: 0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardScale = Tween<double>(begin: 0.75, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut));
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
    // Show ad when tapping to open the gift, then reveal the reward.
    Get.find<AdService>().loadAndShowInterstitial(
      onDismissed: _doOpen,
      onFailure:   _doOpen,
    );
  }

  void _doOpen() {
    if (!mounted) return;
    setState(() => _opened = true);
    _bounceCtrl.stop();
    _lidCtrl.forward();
    _shatterCtrl.forward();
    _confettiCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl       = Get.find<GameController>();
    final rewardType = ctrl.giftRewardType.value;
    final newBest    = ctrl.newBestScore.value;

    return FadeTransition(
      opacity: _bgFade,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A3A), Color(0xFF0D0520), Color(0xFF140830)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Floating star particles (background)
            const _StarField(),

            // Radial glow behind gift box
            Center(
              child: Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF4D4D).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

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

                  // ── Gift box ───────────────────────────────────────────────
                  if (!_opened)
                    AnimatedBuilder(
                      animation: _bounceCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounceY.value),
                        child: Transform.rotate(angle: _wobble.value, child: child),
                      ),
                      child: GestureDetector(
                        onTap: _openGift,
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (_, __) => _RealGiftBox(
                            shimmerT: _shimmerCtrl.value,
                            showLid: true,
                          ),
                        ),
                      ),
                    )
                  else
                    AnimatedBuilder(
                      animation: _shatterCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _boxScale.value,
                        child: child,
                      ),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // Body (no lid, no bow)
                          _RealGiftBox(shimmerT: 0, showLid: false, showBow: false),

                          // Flying lid
                          AnimatedBuilder(
                            animation: _lidCtrl,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _lidFly.value),
                              child: Opacity(
                                opacity: _lidFade.value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                            child: const _FlyingLid(),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 2.h),

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

// ═══════════════════════════════════════════════════════════════════════════════
//  REAL GIFT BOX  — drawn entirely via CustomPainter
// ═══════════════════════════════════════════════════════════════════════════════

class _RealGiftBox extends StatelessWidget {
  final double shimmerT;
  final bool showLid;
  final bool showBow;

  const _RealGiftBox({
    required this.shimmerT,
    this.showLid = true,
    this.showBow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62.w,
      height: 68.w,
      child: CustomPaint(
        painter: _GiftBoxPainter(
          shimmerT: shimmerT,
          showLid: showLid,
          showBow: showBow,
        ),
      ),
    );
  }
}

// Flying lid widget — only the lid portion, positioned at the correct offset
class _FlyingLid extends StatelessWidget {
  const _FlyingLid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68.w,
      height: 20.w,
      child: CustomPaint(painter: _LidOnlyPainter()),
    );
  }
}

// ─── Gift box CustomPainter ────────────────────────────────────────────────────

class _GiftBoxPainter extends CustomPainter {
  final double shimmerT;
  final bool showLid;
  final bool showBow;

  const _GiftBoxPainter({
    required this.shimmerT,
    this.showLid = true,
    this.showBow = true,
  });

  // ── Color palette ──────────────────────────────────────────────────────────
  static const _boxRed1  = Color(0xFFE53935);
  static const _boxRed2  = Color(0xFFC62828);
  static const _boxRed3  = Color(0xFF8B0000);
  static const _lidRed1  = Color(0xFFFF5252);
  static const _lidRed2  = Color(0xFFD32F2F);
  static const _goldHi   = Color(0xFFFFE57A);
  static const _goldMid  = Color(0xFFFFB300);
  static const _goldLow  = Color(0xFFFF8F00);
  static const _goldDark = Color(0xFFE65100);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Layout ──────────────────────────────────────────────────────────────
    // From top: bow area → lid → body
    final lidTopY  = h * 0.28;
    final lidBotY  = h * 0.41;
    final bodyBotY = h * 0.96;
    final bowCY    = h * 0.24;   // bow knot center
    final bowCX    = w * 0.50;
    final bowR     = w * 0.34;   // bow loop radius

    final ribW  = w * 0.098;    // ribbon width
    final ribX  = (w - ribW) / 2;

    final boxL = w * 0.04;
    final boxR = w * 0.96;
    final lidL = -w * 0.02;
    final lidR = w * 1.02;

    final bodyRect = Rect.fromLTRB(boxL, lidBotY, boxR, bodyBotY);
    final lidRect  = Rect.fromLTRB(lidL, lidTopY, lidR, lidBotY + 3);

    // ── 1. Drop shadow under box ───────────────────────────────────────────
    _drawShadow(canvas, bodyRect);

    // ── 2. Body ───────────────────────────────────────────────────────────
    _drawBody(canvas, bodyRect, ribX, ribW);

    // ── 3. Lid ────────────────────────────────────────────────────────────
    if (showLid) {
      _drawLid(canvas, lidRect, ribX, ribW);
    }

    // ── 4. Bow ────────────────────────────────────────────────────────────
    if (showBow) {
      _drawBow(canvas, bowCX, bowCY, bowR, shimmerT);
    }

    // ── 5. Body shimmer ────────────────────────────────────────────────────
    _drawBodyShimmer(canvas, bodyRect, shimmerT);
  }

  // ── Shadow ─────────────────────────────────────────────────────────────────
  void _drawShadow(Canvas canvas, Rect body) {
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        body.shift(const Offset(0, 14)).inflate(4),
        bottomLeft: const Radius.circular(18),
        bottomRight: const Radius.circular(18),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  // ── Box body ────────────────────────────────────────────────────────────────
  void _drawBody(Canvas canvas, Rect r, double ribX, double ribW) {
    final rr = RRect.fromRectAndCorners(r,
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );

    // Base gradient (top-left bright → bottom-right dark)
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [_boxRed1, _boxRed2, _boxRed3],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(r));

    // Right-edge depth shadow for 3D
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.black.withOpacity(0.22)],
      ).createShader(r));

    // Bottom-edge depth shadow for 3D
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.18)],
      ).createShader(r));

    // ── Ribbons ──────────────────────────────────────────────────────────
    // Vertical ribbon
    final vRib = Rect.fromLTRB(ribX, r.top, ribX + ribW, r.bottom);
    canvas.drawRect(vRib, _satingPaint(vRib, vertical: true));
    // Ribbon edge shadow
    canvas.drawRect(vRib, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.black.withOpacity(0.10), Colors.transparent, Colors.black.withOpacity(0.10)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(vRib));

    // Horizontal ribbon
    final hRibY = r.top + r.height * 0.44;
    final hRib = Rect.fromLTRB(r.left, hRibY, r.right, hRibY + ribW);
    canvas.drawRect(hRib, _satingPaint(hRib, vertical: false));
    canvas.drawRect(hRib, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(0.10), Colors.transparent, Colors.black.withOpacity(0.10)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(hRib));

    // ── Top-edge highlight line ───────────────────────────────────────────
    canvas.drawLine(
      Offset(r.left + 16, r.top + 1.5),
      Offset(r.right - 16, r.top + 1.5),
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Shimmer / gloss on body face ────────────────────────────────────────────
  void _drawBodyShimmer(Canvas canvas, Rect r, double t) {
    final opc = (0.10 + 0.10 * math.sin(t * 2 * math.pi)).clamp(0.0, 1.0);
    // Left gloss stripe
    final sr1 = Rect.fromLTWH(r.left + 8, r.top + r.height * 0.07, r.width * 0.14, r.height * 0.55);
    canvas.drawRRect(RRect.fromRectAndRadius(sr1, const Radius.circular(24)),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(opc), Colors.transparent],
      ).createShader(sr1));
  }

  // ── Lid ─────────────────────────────────────────────────────────────────────
  void _drawLid(Canvas canvas, Rect r, double ribX, double ribW) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));

    // Lid shadow (slightly darker than body top)
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Lid base gradient
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [_lidRed1, _lidRed2],
      ).createShader(r));

    // Lid right-edge depth
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.black.withOpacity(0.20)],
      ).createShader(r));

    // Lid vertical ribbon
    final vRib = Rect.fromLTRB(ribX, r.top, ribX + ribW, r.bottom);
    canvas.drawRect(vRib, _satingPaint(vRib, vertical: true));

    // Lid top highlight (glossy band)
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.24), Colors.transparent],
        stops: const [0.0, 0.65],
      ).createShader(r));

    // Lid bottom separator shadow
    canvas.drawRect(
      Rect.fromLTWH(r.left + 4, r.bottom - 3, r.width - 8, 5),
      Paint()..color = Colors.black.withOpacity(0.20),
    );
  }

  // ── Satin ribbon paint ──────────────────────────────────────────────────────
  Paint _satingPaint(Rect rect, {required bool vertical}) => Paint()
    ..shader = LinearGradient(
      begin: vertical ? Alignment.centerLeft : Alignment.topCenter,
      end:   vertical ? Alignment.centerRight : Alignment.bottomCenter,
      colors: const [_goldLow, _goldHi, _goldMid, _goldLow],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(rect);

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOW  — 4 petal loops + ribbon tails + knot
  // ═══════════════════════════════════════════════════════════════════════════

  void _drawBow(Canvas canvas, double cx, double cy, double r, double t) {
    final shimGold = Color.lerp(const Color(0xFFFFE082), Colors.white, t * 0.25)!;

    // Ribbon tails (drawn first so loops sit on top)
    _drawTails(canvas, cx, cy, r);

    // 4 loops: back pair first (smaller), then front pair (larger)
    _drawLoop(canvas, cx, cy, r * 0.70, angle: -1.10, flipX: false, shimGold: shimGold); // back-left
    _drawLoop(canvas, cx, cy, r * 0.70, angle:  1.10, flipX: true,  shimGold: shimGold); // back-right
    _drawLoop(canvas, cx, cy, r,        angle: -0.55, flipX: false, shimGold: shimGold); // front-left
    _drawLoop(canvas, cx, cy, r,        angle:  0.55, flipX: true,  shimGold: shimGold); // front-right

    // Center knot
    _drawKnot(canvas, cx, cy, r * 0.13, t);
  }

  // One bow petal loop — an ellipse rotated + offset from center
  void _drawLoop(Canvas canvas, double cx, double cy, double r,
      {required double angle, required bool flipX, required Color shimGold}) {
    canvas.save();
    canvas.translate(cx, cy);
    if (flipX) canvas.scale(-1.0, 1.0);
    canvas.rotate(angle);

    // Ellipse offset from the rotation center
    final loopCX = -r * 0.30;
    final loopCY = -r * 0.32;
    final loopW  = r * 0.90;
    final loopH  = r * 0.58;
    final oval   = Rect.fromCenter(center: Offset(loopCX, loopCY), width: loopW, height: loopH);

    // Fill with radial gradient for depth
    canvas.drawOval(oval, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.30, -0.35),
        radius: 0.80,
        colors: [shimGold, _goldMid, _goldLow, _goldDark],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(oval));

    // Inner crease line (simulate ribbon fold)
    final creasePath = Path()
      ..moveTo(loopCX + loopW * 0.05, loopCY + loopH * 0.35)
      ..quadraticBezierTo(loopCX + loopW * 0.10, loopCY - loopH * 0.10, loopCX + loopW * 0.12, loopCY - loopH * 0.45);
    canvas.drawPath(creasePath, Paint()
      ..color = _goldDark.withOpacity(0.40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Specular highlight on loop surface
    final hlOval = Rect.fromCenter(
      center: Offset(loopCX - loopW * 0.14, loopCY - loopH * 0.18),
      width: loopW * 0.42,
      height: loopH * 0.32,
    );
    canvas.drawOval(hlOval, Paint()
      ..color = Colors.white.withOpacity(0.32));

    // Outline for crisp edge
    canvas.drawOval(oval, Paint()
      ..color = _goldDark.withOpacity(0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke);

    canvas.restore();
  }

  // Ribbon tails curving downward from the knot
  void _drawTails(Canvas canvas, double cx, double cy, double r) {
    final tailBounds = Rect.fromLTWH(cx - r * 0.40, cy, r * 0.80, r * 0.62);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [_goldMid, _goldLow, _goldDark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(tailBounds);

    // Left tail
    final lp = Path()
      ..moveTo(cx - r * 0.05, cy + r * 0.06)
      ..cubicTo(cx - r * 0.24, cy + r * 0.30, cx - r * 0.40, cy + r * 0.42, cx - r * 0.30, cy + r * 0.62)
      ..lineTo(cx - r * 0.17, cy + r * 0.62)
      ..cubicTo(cx - r * 0.16, cy + r * 0.42, cx - r * 0.06, cy + r * 0.30, cx + r * 0.01, cy + r * 0.06)
      ..close();
    canvas.drawPath(lp, paint);

    // Right tail
    final rp = Path()
      ..moveTo(cx + r * 0.05, cy + r * 0.06)
      ..cubicTo(cx + r * 0.24, cy + r * 0.30, cx + r * 0.40, cy + r * 0.42, cx + r * 0.30, cy + r * 0.62)
      ..lineTo(cx + r * 0.17, cy + r * 0.62)
      ..cubicTo(cx + r * 0.16, cy + r * 0.42, cx + r * 0.06, cy + r * 0.30, cx - r * 0.01, cy + r * 0.06)
      ..close();
    canvas.drawPath(rp, paint);

    // Tail gloss highlight
    final hlPaint = Paint()..color = Colors.white.withOpacity(0.20);
    final hlL = Path()
      ..moveTo(cx - r * 0.02, cy + r * 0.06)
      ..cubicTo(cx - r * 0.10, cy + r * 0.24, cx - r * 0.12, cy + r * 0.40, cx - r * 0.08, cy + r * 0.60)
      ..lineTo(cx - r * 0.12, cy + r * 0.60)
      ..cubicTo(cx - r * 0.16, cy + r * 0.40, cx - r * 0.14, cy + r * 0.24, cx - r * 0.06, cy + r * 0.06)
      ..close();
    canvas.drawPath(hlL, hlPaint);
  }

  // Center knot (small circle, slightly raised)
  void _drawKnot(Canvas canvas, double cx, double cy, double r, double t) {
    final pulse = 0.90 + 0.10 * math.sin(t * 2 * math.pi);
    final kr = r * pulse;
    final kRect = Rect.fromCircle(center: Offset(cx, cy), radius: kr);

    // Knot shadow
    canvas.drawCircle(Offset(cx, cy + kr * 0.5), kr, Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Knot fill
    canvas.drawCircle(Offset(cx, cy), kr, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 0.85,
        colors: const [Color(0xFFFFE082), _goldMid, _goldDark],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(kRect));

    // Knot specular
    canvas.drawCircle(
      Offset(cx - kr * 0.35, cy - kr * 0.35),
      kr * 0.40,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(_GiftBoxPainter old) =>
      old.shimmerT != shimmerT || old.showLid != showLid || old.showBow != showBow;
}

// ─── Lid-only painter (used for the flying lid animation) ─────────────────────

class _LidOnlyPainter extends CustomPainter {
  static const _lidRed1  = Color(0xFFFF5252);
  static const _lidRed2  = Color(0xFFD32F2F);
  static const _goldHi   = Color(0xFFFFE57A);
  static const _goldMid  = Color(0xFFFFB300);
  static const _goldLow  = Color(0xFFFF8F00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ribW = w * 0.09;
    final ribX = (w - ribW) / 2;
    final r = Rect.fromLTRB(0, h * 0.20, w, h * 0.92);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));

    // Shadow
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Lid body
    canvas.drawRRect(rr, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lidRed1, _lidRed2],
      ).createShader(r));

    // Right-edge depth
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.black.withOpacity(0.20)],
      ).createShader(r));

    // Vertical ribbon
    final vRib = Rect.fromLTRB(ribX, r.top, ribX + ribW, r.bottom);
    canvas.drawRect(vRib, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [_goldLow, _goldHi, _goldMid, _goldLow],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(vRib));

    // Gloss highlight
    canvas.drawRRect(rr, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.22), Colors.transparent],
        stops: const [0.0, 0.65],
      ).createShader(r));
  }

  @override
  bool shouldRepaint(_LidOnlyPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STAR FIELD  — floating sparkle dots (background decoration)
// ═══════════════════════════════════════════════════════════════════════════════

class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _stars = List.generate(55, (_) => _Star(_rnd));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
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
    return CustomPaint(
      painter: _StarPainter(stars: _stars, t: _ctrl.value),
      child: const SizedBox.expand(),
    );
  }
}

class _Star {
  final double x, y, size, phase, speed;
  _Star(math.Random rnd)
      : x     = rnd.nextDouble(),
        y     = rnd.nextDouble(),
        size  = 1.0 + rnd.nextDouble() * 2.5,
        phase = rnd.nextDouble() * math.pi * 2,
        speed = 0.5 + rnd.nextDouble() * 1.5;
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter({required this.stars, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final opacity = (0.30 + 0.70 * math.sin(s.phase + t * s.speed * 2 * math.pi)).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(opacity * 0.80);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  NEW BEST BADGE
// ═══════════════════════════════════════════════════════════════════════════════

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
                color: const Color(0xFFFFD700).withOpacity(0.40 + 0.25 * pulse),
                blurRadius: 18 + 12 * pulse,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              SizedBox(width: 2.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('NEW HIGH SCORE!',
                      style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 1.5,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                      )),
                  Text('$score pts',
                      style: TextStyle(
                        fontSize: 10.sp, fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.92),
                      )),
                ],
              ),
              SizedBox(width: 2.w),
              const Text('🏆', style: TextStyle(fontSize: 20)),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TAP HINT
// ═══════════════════════════════════════════════════════════════════════════════

class _TapHint extends StatelessWidget {
  final AnimationController shimmer;
  const _TapHint({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) => Opacity(
        opacity: (0.45 + 0.55 * shimmer.value).clamp(0.0, 1.0),
        child: Column(
          children: [
            Icon(Icons.touch_app_rounded, color: Colors.amber.shade300, size: 7.w,
                shadows: [Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 12)]),
            SizedBox(height: 0.5.h),
            Text(
              'Tap the gift to open!',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REWARD CARD
// ═══════════════════════════════════════════════════════════════════════════════

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
            color: const Color(0xFF1E1040),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: reward.colors.first.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(color: reward.colors.first.withOpacity(0.35 * pulse), blurRadius: 30 + 12 * pulse, spreadRadius: 2),
              const BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 5.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon circle ──────────────────────────────────────────────
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        reward.colors.first.withOpacity(0.30),
                        reward.colors.first.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(color: reward.colors.first.withOpacity(0.50), width: 2),
                    boxShadow: [
                      BoxShadow(color: reward.colors.first.withOpacity(0.40 * pulse), blurRadius: 16 + 8 * pulse),
                    ],
                  ),
                  child: Center(child: Text(reward.emoji, style: TextStyle(fontSize: 24.sp))),
                ),
                SizedBox(height: 2.h),

                Text(
                  reward.title,
                  style: TextStyle(
                    fontSize: 22.sp, fontWeight: FontWeight.w900,
                    color: reward.colors.first, letterSpacing: 0.5,
                    shadows: [Shadow(color: reward.colors.first.withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
                SizedBox(height: 0.6.h),
                Text(
                  reward.subtitle,
                  style: TextStyle(fontSize: 10.5.sp, color: Colors.white60, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 3.h),

                // ── Claim button ──────────────────────────────────────────────
                GestureDetector(
                  onTap: onClaim,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [reward.colors.first, reward.colors.last]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: reward.colors.first.withOpacity(0.50), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(reward.emoji, style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 2.w),
                        Text('Claim & Continue',
                            style: TextStyle(
                              fontSize: 13.sp, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 0.4,
                            )),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  CONFETTI
// ═══════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x, speed, size, angle, angularSpeed, drift;
  final Color color;

  _Particle(math.Random rnd)
      : x            = rnd.nextDouble(),
        speed        = 0.28 + rnd.nextDouble() * 0.72,
        size         = 5 + rnd.nextDouble() * 10,
        angle        = rnd.nextDouble() * math.pi * 2,
        angularSpeed = (rnd.nextDouble() - 0.5) * 8,
        drift        = (rnd.nextDouble() - 0.5) * 0.22,
        color        = _colors[rnd.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFF6C63FF), Color(0xFF48CAE4), Color(0xFFFFD700),
    Color(0xFFFF4D6D), Color(0xFF43E97B), Color(0xFFFF8C00),
    Color(0xFFE040FB), Color(0xFF76FF03), Color(0xFFFFE082),
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
      final fade  = (1.0 - ((progress - 0.62) / 0.38).clamp(0.0, 1.0));

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
