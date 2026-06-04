import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AnimatedStartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const AnimatedStartButton({super.key, required this.onPressed});

  @override
  State<AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 12.0, end: 32.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: AppDimensions.startButtonSize,
            height: AppDimensions.startButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                radius: 0.85,
                colors: [
                  Color(0xFFFFEE88),
                  AppColors.startGradientMid,
                  AppColors.startGradientEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.startGradientMid.withOpacity(0.65),
                  blurRadius: _glow.value,
                  spreadRadius: _glow.value * 0.25,
                ),
                BoxShadow(
                  color: AppColors.startGradientEnd.withOpacity(0.3),
                  blurRadius: _glow.value * 2.2,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(-6, -6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer halo ring
                Container(
                  width: AppDimensions.startButtonSize - 10,
                  height: AppDimensions.startButtonSize - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                ),
                // Icon and label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 44,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'TAP TO PLAY',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Top-left shine
                Positioned(
                  top: 24,
                  left: 30,
                  child: Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
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
