import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import '../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GLASS BUTTON
//
//  A glassmorphic pill button that shrinks slightly on press (0.95 scale).
//  Replaces the 7+ repeated StatefulWidget press-state patterns across screens.
//
//  Usage:
//    GlassButton(
//      onTap: controller.doSomething,
//      accentColor: AppColors.earnCoin,
//      child: Text('Tap me'),
//    )
// ═══════════════════════════════════════════════════════════════════════════════

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double borderWidth;
  final bool busy;           // shows reduced opacity when busy

  const GlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.accentColor   = Colors.white,
    this.borderRadius  = AppDimensions.radiusFull,
    this.padding,
    this.blurSigma     = 12,
    this.borderWidth   = 1.5,
    this.busy          = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h);

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed || widget.busy) ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurSigma,
              sigmaY: widget.blurSigma,
            ),
            child: Container(
              padding: effectivePadding,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(
                  widget.busy ? 0.50 : 0.15,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: widget.borderWidth,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gradient variant — used for the home-screen nav pills ──────────────────

class GlassGradientButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<Color> gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double borderWidth;
  final Color borderColor;
  final bool busy;

  const GlassGradientButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.gradientColors,
    this.borderRadius = AppDimensions.radiusFull,
    this.padding,
    this.blurSigma    = 12,
    this.borderWidth  = 1.5,
    this.borderColor  = AppColors.glassBorder,
    this.busy         = false,
  });

  @override
  State<GlassGradientButton> createState() => _GlassGradientButtonState();
}

class _GlassGradientButtonState extends State<GlassGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(vertical: 2.h);

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed || widget.busy) ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurSigma,
              sigmaY: widget.blurSigma,
            ),
            child: Container(
              width: double.infinity,
              padding: effectivePadding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradientColors,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.borderColor,
                  width: widget.borderWidth,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
