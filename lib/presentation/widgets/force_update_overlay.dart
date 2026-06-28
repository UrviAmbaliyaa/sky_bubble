import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/update_service.dart';

class ForceUpdateOverlay extends StatefulWidget {
  final Widget child;
  const ForceUpdateOverlay({super.key, required this.child});

  @override
  State<ForceUpdateOverlay> createState() => _ForceUpdateOverlayState();
}

class _ForceUpdateOverlayState extends State<ForceUpdateOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _show() {
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  Future<void> _openStore() async {
    final svc = Get.find<UpdateService>();
    final uri = Uri.parse(svc.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<UpdateService>();
    return Obx(() {
      final needsUpdate = svc.updateRequired.value;
      if (needsUpdate) _show();

      // PopScope blocks the Android back button while the update overlay is shown.
      return PopScope(
        canPop: !needsUpdate,
        child: Stack(
          children: [
            widget.child,
            if (needsUpdate)
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildOverlay(context),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildOverlay(BuildContext context) {
    return AbsorbPointer(
      absorbing: false, // overlay itself is interactive (Update Now button)
      child: _buildOverlayContent(context),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(child: _buildCard(context)),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: 84.w,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D0070),
              Color(0xFF5C009E),
              Color(0xFF7B1FA2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFAB47BC).withValues(alpha: 0.5),
              blurRadius: 50,
              spreadRadius: 6,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFCE93D8).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconSection(),
            SizedBox(height: 2.h),
            _buildBadge(),
            SizedBox(height: 1.8.h),
            Text(
              'New Update\nAvailable! 🚀',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7.w,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.25,
                letterSpacing: 0.3,
                shadows: const [
                  Shadow(color: Color(0xFFCE93D8), blurRadius: 12),
                ],
              ),
            ),
            SizedBox(height: 1.2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'We\'ve added exciting features and\nimportant improvements just for you!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 3.6.w,
                  color: const Color(0xFFE1BEE7),
                  height: 1.55,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            _buildFeaturesList(),
            SizedBox(height: 2.5.h),
            _buildUpdateButton(),
            SizedBox(height: 1.h),
            Text(
              'Update required to continue playing',
              style: TextStyle(
                fontSize: 3.w,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCE93D8).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFCE93D8), Color(0xFF9C27B0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCE93D8).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.system_update_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD600), Color(0xFFFF6F00)],
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD600).withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          SizedBox(width: 1.5.w),
          Text(
            'VERSION UPDATE',
            style: TextStyle(
              fontSize: 2.8.w,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    const features = [
      '✨  Bug fixes & performance boost',
      '🎮  Better gameplay experience',
      '🔒  Security improvements',
    ];
    return Column(
      children: features.map((f) => Padding(
        padding: EdgeInsets.symmetric(vertical: 0.4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              f,
              style: TextStyle(
                fontSize: 3.3.w,
                color: const Color(0xFFCE93D8),
                height: 1.4,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildUpdateButton() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: 0.97 + (_pulseAnim.value - 1.0) * 0.5,
        child: child,
      ),
      child: GestureDetector(
        onTap: _openStore,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD600), Color(0xFFFFA000)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_rounded, color: Colors.white, size: 22),
              SizedBox(width: 2.w),
              Text(
                'Update Now',
                style: TextStyle(
                  fontSize: 5.w,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
