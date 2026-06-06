import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

// All animation logic lives in SplashController.
// No StatefulWidget, no lifecycle code, no declarations before return.

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _SplashBody(controller: controller));
  }
}

class _SplashBody extends StatelessWidget {
  final SplashController controller;
  const _SplashBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/splash_screen.png',
          fit: BoxFit.cover,
          width:  MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
        ),
        Positioned(
          bottom: MediaQuery.sizeOf(context).height * 0.10,
          left:   MediaQuery.sizeOf(context).width  * 0.08,
          right:  MediaQuery.sizeOf(context).width  * 0.08,
          child: _LoadingBar(animation: controller.loadAnim),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LOADING BAR  (animated fill + "LOADING…" label)
// ════════════════════════════════════════════════════════════

class _LoadingBar extends StatelessWidget {
  final Animation<double> animation;
  const _LoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0D47A1), width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x551565C0),
                  blurRadius: 16,
                  spreadRadius: 3,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x88FFB300), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2, left: 6, right: 30, height: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1, top: 0, bottom: 0,
                    child: Center(
                      child: Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x660D47A1), blurRadius: 4),
                          ],
                        ),
                        child: const Center(
                          child: Text('⭐', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '⭐   LOADING...   ⭐',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0D47A1),
            letterSpacing: 2.5,
            shadows: [
              Shadow(color: Colors.white, blurRadius: 10),
              Shadow(color: Colors.white, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
