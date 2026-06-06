import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/models/bubble_model.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/bubble_painter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _Background()),
          const SafeArea(child: _HomeUI()),
        ],
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/home_screen.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

// ─── Home UI ──────────────────────────────────────────────────────────────────

class _HomeUI extends GetView<HomeController> {
  const _HomeUI();

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnim,
      child: SlideTransition(
        position: controller.slideAnim,
        child: Column(
          children: [
            SizedBox(height: 1.5.h),
            Obx(() => controller.bestScore.value == 0
                ? const SizedBox.shrink()
                : _BestScorePill(controller: controller)),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlayButton(onPressed: controller.navigateToGame),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          icon: Icons.leaderboard_rounded,
                          iconColor: const Color(0xFFFFD54F),
                          label: 'PROGRESS',
                          onPressed: controller.navigateToScores,
                        ),
                      ),
                      SizedBox(width: 3.5.w),
                      const Expanded(child: _StyleButton()),
                    ],
                  ),
                  SizedBox(height: 12.h),
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
//  BEST SCORE PILL
// ═══════════════════════════════════════════════════════════════════════════════

class _BestScorePill extends StatelessWidget {
  final HomeController controller;
  const _BestScorePill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD740).withOpacity(0.18),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: const Color(0xFFFFD740).withOpacity(0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9100).withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 17.sp)),
              SizedBox(width: 2.5.w),
              Text(
                '${controller.bestScore.value} pts',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PLAY BUTTON  — circular, layered, 3-D glow design
// ═══════════════════════════════════════════════════════════════════════════════

class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PlayButton({required this.onPressed});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: ctrl.pulseAnim,
        builder: (_, child) => AnimatedScale(
          scale: _pressed ? 0.93 : ctrl.pulseAnim.value,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
        child: Container(
          width: 55.w,
          height: 7.5.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00D4FF), Color(0xFF007AFF)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.50), blurRadius: 20, offset: const Offset(0, 8)),
              BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                'PLAY',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SECONDARY BUTTON  (Leaderboard / Progress)
// ═══════════════════════════════════════════════════════════════════════════════

class _SecondaryButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 5.5.w),
                  SizedBox(width: 2.w),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STYLE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _StyleButton extends StatefulWidget {
  const _StyleButton();

  @override
  State<_StyleButton> createState() => _StyleButtonState();
}

class _StyleButtonState extends State<_StyleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showBubbleStyleSheet(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Obx(() {
          final style = Get.find<StyleService>().selectedStyle.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(style.emoji, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 2.w),
                    Text(
                      'STYLE',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUBBLE STYLE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

void _showBubbleStyleSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _BubbleStyleSheet(),
  );
}

class _BubbleStyleSheet extends StatelessWidget {
  const _BubbleStyleSheet();

  @override
  Widget build(BuildContext context) {
    final svc        = Get.find<StyleService>();
    final bottomPad  = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 1.5.h),
          // drag handle
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // header banner
          _StyleSheetHeader(onClose: () => Navigator.of(context).pop()),
          SizedBox(height: 1.5.h),
          // style list
          Flexible(
            child: Obx(() {
              final current = svc.selectedStyle.value;
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: BubbleStyle.values.length,
                itemBuilder: (_, i) {
                  final style = BubbleStyle.values[i];
                  return _StyleCard(
                    style: style,
                    isSelected: current == style,
                    onTap: () {
                      svc.setStyle(style);
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            }),
          ),
          SizedBox(height: bottomPad + 2.h),
        ],
      ),
    );
  }
}

// ─── Style Sheet Header ───────────────────────────────────────────────────────

class _StyleSheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _StyleSheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF4FC3F7), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text('💧', style: TextStyle(fontSize: 19.sp)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bubble Style',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.4.h),
                Text(
                  'Tap a style to play with it',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 9.w,
              height: 9.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 4.5.w),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Style Card ───────────────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  final BubbleStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  late final Animation<double>   _bobAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -3.0, end: 3.0)
        .animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.style.gradientColors.first;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(bottom: 1.2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: widget.isSelected ? accent.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? accent : const Color(0xFFE8EDF5),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [BoxShadow(color: accent.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // bubble preview
              _BubblePreviewCircle(style: widget.style, bobAnim: _bobAnim),
              SizedBox(width: 3.5.w),
              // label + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(widget.style.emoji, style: TextStyle(fontSize: 15.sp)),
                      SizedBox(width: 1.5.w),
                      Text(
                        widget.style.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.isSelected ? accent : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ]),
                    SizedBox(height: 0.5.h),
                    Text(
                      widget.style.description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF9099B0),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // checkmark
              SizedBox(
                width: 7.w,
                height: 7.w,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isSelected
                      ? Container(
                          key: const ValueKey('check'),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.style.gradientColors,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 4.5.w),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bubble Preview Circle ─────────────────────────────────────────────────────

class _BubblePreviewCircle extends StatelessWidget {
  final BubbleStyle style;
  final Animation<double> bobAnim;
  const _BubblePreviewCircle({required this.style, required this.bobAnim});

  @override
  Widget build(BuildContext context) {
    final accent = style.gradientColors.first;
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.22), width: 1.2),
      ),
      child: AnimatedBuilder(
        animation: bobAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, bobAnim.value),
          child: ClipOval(
            child: CustomPaint(
              painter: _BubblePreviewPainter(
                style: style,
                color: AppColors.bubbleColors[style.index % AppColors.bubbleColors.length],
              ),
              // SizedBox.expand ensures CustomPaint always fills its parent
              // on older Android versions (API 29/30) where size can be zero.
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bubble Preview Painter ────────────────────────────────────────────────────

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.44;
    final b  = BubbleModel(
      id: 'preview',
      color: color,
      x: cx, y: cy,
      radius: r,
      speed: 0,
      driftAmplitude: 0,
      driftFrequency: 0,
      pointValue: 3,
    );
    BubblePainter(bubbles: [b], level: 5, style: style).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) =>
      old.style != style || old.color != color;
}
