import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GLOW ORB
//
//  A decorative blurred radial-gradient circle used as background decoration.
//  Replaces _HeroOrb (bubble_style_screen), _Orb (background_style_screen),
//  and _GlowCircle (ad_watch_screen) — all were functionally identical.
//
//  Usage:
//    GlowOrb(size: 45.w, color: AppColors.earnCoin)
// ═══════════════════════════════════════════════════════════════════════════════

class GlowOrb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;

  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}
