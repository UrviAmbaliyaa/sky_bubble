import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/services/connectivity_service.dart';

class NoInternetOverlay extends StatefulWidget {
  final Widget child;
  const NoInternetOverlay({super.key, required this.child});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _handleVisibility(bool offline) {
    if (offline) {
      _fadeCtrl.forward();
    } else {
      _fadeCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();
    return Obx(() {
      final offline = !connectivity.isOnline.value;
      _handleVisibility(offline);

      return Stack(
        children: [
          widget.child,
          FadeTransition(
            opacity: _fadeAnim,
            child: offline ? _buildOverlay(context) : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  Widget _buildOverlay(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(child: _buildCard(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounceAnim.value * 0.4),
        child: child,
      ),
      child: Container(
        width: 80.w,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1D4ED8),
              Color(0xFF3B82F6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(59, 130, 246, 0.5),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Color.fromRGBO(255, 255, 255, 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: 2.h),
            Text(
              'No Internet',
              style: TextStyle(
                fontSize: 7.w,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Oops! It looks like you\'re\noffline right now. 🌐',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 4.w,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(255, 255, 255, 0.8),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Waiting for connection...',
                    style: TextStyle(
                      fontSize: 3.5.w,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(255, 255, 255, 0.12),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(
            Icons.wifi_off_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
