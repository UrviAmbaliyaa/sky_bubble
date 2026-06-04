import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _SplashBody());
  }
}

class _SplashBody extends StatefulWidget {
  const _SplashBody();

  @override
  State<_SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<_SplashBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadCtrl;
  late Animation<double> _loadAnim;

  @override
  void initState() {
    super.initState();
    // Only the loading bar animates — fills over 3 s, nav fires at 3.4 s
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
    _loadAnim =
        CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        // ① Full-screen splash asset image — no animation
        Image.asset(
          'assets/images/splash_screen.png',
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
        ),

        // ② Loading bar pinned near the bottom — ONLY animated element
        Positioned(
          bottom: size.height * 0.10,
          left: size.width * 0.08,
          right: size.width * 0.08,
          child: _LoadingBar(animation: _loadAnim),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  LOADING BAR  (animated fill + "LOADING..." label)
// ════════════════════════════════════════════════════════════

class _LoadingBar extends StatelessWidget {
  final Animation<double> animation;
  const _LoadingBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bar container
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) => Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF0D47A1), width: 3.5),
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
              padding: const EdgeInsets.all(6),
              child: Stack(
                children: [
                  // Track
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  // Animated fill
                  FractionallySizedBox(
                    widthFactor: animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x88FFB300),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shine strip
                  Positioned(
                    top: 3,
                    left: 8,
                    right: 50,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Blue star badge on right
                  Positioned(
                    right: 2,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x660D47A1),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('⭐', style: TextStyle(fontSize: 18)),
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
        // "LOADING..." label
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
