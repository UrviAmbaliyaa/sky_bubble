import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

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
          width: 100.w,
          height: 100.h,
        ),
        Positioned(
          bottom: 10.h,
          left: 8.w,
          right: 8.w,
          child: _LoadingBar(animation: controller.loadAnim),
        ),
      ],
    );
  }
}

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
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2.h),
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
              padding: EdgeInsets.all(0.5.h),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(1.5.h),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(1.5.h),
                        boxShadow: const [
                          BoxShadow(color: Color(0x88FFB300), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0.3.h, left: 1.5.w, right: 7.w, height: 0.6.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0.5.w, top: 0, bottom: 0,
                    child: Center(
                      child: Container(
                        width: 5.5.w, height: 5.5.w,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x660D47A1), blurRadius: 4),
                          ],
                        ),
                        child: Center(
                          child: Text('⭐', style: TextStyle(fontSize: 12.sp)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          '⭐   LOADING...   ⭐',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0D47A1),
            letterSpacing: 2.5,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 10),
              Shadow(color: Colors.white, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
