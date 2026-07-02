import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/style_service.dart';
import '../controllers/learning_controller.dart';
import '../widgets/bubble_painter.dart';
import '../widgets/safe_asset_background.dart';
import '../widgets/word_display_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEARNING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class LearningScreen extends GetView<LearningController> {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.isPaused.value) return;
        controller.togglePause();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF87CEEB),
        body: LayoutBuilder(
          builder: (context, constraints) => _LearningBody(
            controller: controller,
            size: constraints.biggest,
          ),
        ),
      ),
    );
  }
}

// ─── Learning body ────────────────────────────────────────────────────────────

class _LearningBody extends StatefulWidget {
  final LearningController controller;
  final Size size;
  const _LearningBody({required this.controller, required this.size});

  @override
  State<_LearningBody> createState() => _LearningBodyState();
}

class _LearningBodyState extends State<_LearningBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleAnimCtrl;

  @override
  void initState() {
    super.initState();
    _bubbleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.setScreenSize(widget.size);
    });
  }

  @override
  void dispose() {
    _bubbleAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _LearningBackground(controller: widget.controller),

        // Bubble canvas
        GestureDetector(
          onTapDown: widget.controller.handleTapDown,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _bubbleAnimCtrl,
            builder: (_, __) => Obx(
              () => CustomPaint(
                painter: BubblePainter(
                  bubbles: widget.controller.bubbles.toList(),
                  level:   widget.controller.level.value,
                  style:   Get.find<StyleService>().selectedStyle.value,
                  animTime: _bubbleAnimCtrl.value * 2 * 3.141592653589793,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),

        // Top HUD + word display
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Column(
              children: [
                _LearningHUD(controller: widget.controller),
                SizedBox(height: 0.6.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Obx(() => WordDisplayWidget(
                    word:            widget.controller.currentWord.value,
                    revealedIndices: widget.controller.revealedIndices.toSet(),
                  )),
                ),
              ],
            ),
          ),
        ),

        // Pause overlay
        Obx(() => widget.controller.isPaused.value
            ? Positioned.fill(
                child: _LearningPauseOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),

        // Word-complete overlay
        Obx(() => widget.controller.showWordComplete.value
            ? Positioned.fill(
                child: _WordCompleteOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),

        // Level-complete overlay
        Obx(() => widget.controller.showLevelComplete.value
            ? Positioned.fill(
                child: _LevelCompleteOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

// ─── HUD ─────────────────────────────────────────────────────────────────────

class _LearningHUD extends StatelessWidget {
  final LearningController controller;
  const _LearningHUD({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: SizedBox(
        height: 10.w,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Level chip
            IgnorePointer(
              child: _HudCard(
                child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: const Color(0xFF43E97B), size: 5.w),
                    SizedBox(width: 1.w),
                    Text(
                      'L ${controller.level.value}',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF43E97B),
                      ),
                    ),
                  ],
                )),
              ),
            ),
            SizedBox(width: 2.w),
            // Words progress chip (X / Y words)
            IgnorePointer(
              child: _HudCard(
                child: Obx(() {
                  final done   = controller.wordsCompletedThisLevel.value;
                  final target = controller.wordsNeededForCurrentLevel;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.amber, size: 5.w),
                      SizedBox(width: 1.w),
                      Text(
                        '$done/$target',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: done >= target
                              ? const Color(0xFF43E97B)
                              : Colors.amber.shade800,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'words',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const Spacer(),
            // Sound toggle
            _SoundBtn(),
            SizedBox(width: 2.w),
            // Pause button
            _PauseBtn(onTap: controller.togglePause),
          ],
        ),
      ),
    );
  }
}

class _HudCard extends StatelessWidget {
  final Widget child;
  const _HudCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SoundBtn extends StatelessWidget {
  _SoundBtn();
  final _sound = Get.find<SoundService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final muted = _sound.isMuted.value;
      return GestureDetector(
        onTap: _sound.toggleMute,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3))
              ],
            ),
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: muted ? Colors.red.shade400 : AppColors.textDark,
              size: 5.5.w,
            ),
          ),
        ),
      );
    });
  }
}

class _PauseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3))
            ],
          ),
          child: Icon(Icons.pause_rounded,
              color: AppColors.textDark, size: 6.w),
        ),
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

const _kDefaultFallback = [
  Color(0xFF0D1B4A), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB),
];

class _LearningBackground extends StatelessWidget {
  final LearningController controller;
  const _LearningBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final asset = controller.gameBgAsset.value.isNotEmpty
          ? controller.gameBgAsset.value
          : 'assets/backgrounds/bg_sky.png';
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: SafeAssetBackground(
          key: ValueKey(asset),
          assetPath: asset,
          progress: 0,
          fallback: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _kDefaultFallback,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Pause overlay ────────────────────────────────────────────────────────────

class _LearningPauseOverlay extends StatefulWidget {
  final LearningController controller;
  const _LearningPauseOverlay({required this.controller});

  @override
  State<_LearningPauseOverlay> createState() => _LearningPauseOverlayState();
}

class _LearningPauseOverlayState extends State<_LearningPauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
    _scale = Tween<double>(begin: 0.78, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
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
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withOpacity(0.50),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 16)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 2.5.h),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        Text('📚', style: TextStyle(fontSize: 22.sp)),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Learning Paused',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(6.w, 2.5.h, 6.w, 3.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => Text(
                            'Words found: ${widget.controller.wordsCompleted.value}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF43E97B),
                            ),
                          )),
                          SizedBox(height: 2.h),
                          _ActionBtn(
                            label: '▶  Resume',
                            gradient: const [
                              Color(0xFF43E97B), Color(0xFF11998E)
                            ],
                            onTap: widget.controller.togglePause,
                          ),
                          SizedBox(height: 1.5.h),
                          _OutlineBtn(
                            label: '🏠  Go Home',
                            color: const Color(0xFF0288D1),
                            onTap: widget.controller.navigateHome,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Word-complete overlay ────────────────────────────────────────────────────

class _WordCompleteOverlay extends StatefulWidget {
  final LearningController controller;
  const _WordCompleteOverlay({required this.controller});

  @override
  State<_WordCompleteOverlay> createState() => _WordCompleteOverlayState();
}

class _WordCompleteOverlayState extends State<_WordCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _popCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _popCtrl, curve: Curves.easeIn);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    // Auto-dismiss after 2 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) widget.controller.continueAfterWordComplete();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _popCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    widget.controller.continueAfterWordComplete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _popCtrl,
        builder: (_, __) => FadeTransition(
          opacity: _fade,
          child: Container(
            color: Colors.black.withOpacity(0.60),
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  padding: EdgeInsets.fromLTRB(6.w, 3.h, 6.w, 3.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: [Color(0xFF1A3A6A), Color(0xFF0D2048), Color(0xFF162840)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF43E97B).withOpacity(0.70),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:       const Color(0xFF43E97B).withOpacity(0.28),
                        blurRadius:  32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Object emoji — big, pulsing
                      // No color/shadow on emoji Text so system emoji font renders correctly
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: 1.0 + _pulseCtrl.value * 0.10,
                          child: Obx(() => Text(
                            widget.controller.wordEmoji.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize:        64,
                              fontFamily:      '',   // use system emoji font
                              decoration:      TextDecoration.none,
                              fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
                            ),
                          )),
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      // "AMAZING!" title
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFAA00)],
                        ).createShader(b),
                        child: Text(
                          'AMAZING!',
                          style: TextStyle(
                            fontSize:      20.sp,
                            fontWeight:    FontWeight.w900,
                            color:         Colors.white,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.6.h),
                      // The spelled word
                      Obx(() => ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                        ).createShader(b),
                        child: Text(
                          widget.controller.currentWord.value,
                          style: TextStyle(
                            fontSize:      22.sp,
                            fontWeight:    FontWeight.w900,
                            color:         Colors.white,
                            letterSpacing: 6.0,
                            shadows: const [
                              Shadow(color: Color(0x9943E97B), blurRadius: 14),
                            ],
                          ),
                        ),
                      )),
                      SizedBox(height: 2.5.h),
                      // Tap-anywhere hint
                      Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          fontSize:      8.sp,
                          color:         Colors.white.withOpacity(0.45),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Level-complete overlay ───────────────────────────────────────────────────

class _LevelCompleteOverlay extends StatefulWidget {
  final LearningController controller;
  const _LevelCompleteOverlay({required this.controller});

  @override
  State<_LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<_LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _popCtrl;
  late AnimationController _shineCtrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _popCtrl, curve: Curves.easeIn);

    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _popCtrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withOpacity(0.70),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                padding: EdgeInsets.fromLTRB(5.w, 3.5.h, 5.w, 3.5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [Color(0xFF1A1A4A), Color(0xFF0D0D30), Color(0xFF1A2A4A)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.80),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:        const Color(0xFFFFD700).withOpacity(0.35),
                      blurRadius:   40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy + stars
                    AnimatedBuilder(
                      animation: _shineCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: 1.0 + _shineCtrl.value * 0.08,
                        child: const Text('🏆', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                    SizedBox(height: 0.8.h),

                    // "LEVEL COMPLETE!" title
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                      ).createShader(b),
                      child: Text(
                        'LEVEL COMPLETE!',
                        style: TextStyle(
                          fontSize:      22.sp,
                          fontWeight:    FontWeight.w900,
                          color:         Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.5.h),

                    // Level badge
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.50), width: 1.5),
                      ),
                      child: Text(
                        'Level ${widget.controller.level.value} Cleared',
                        style: TextStyle(
                          fontSize:   12.sp,
                          fontWeight: FontWeight.w700,
                          color:      const Color(0xFFFFD700),
                        ),
                      ),
                    )),
                    SizedBox(height: 1.6.h),

                    // Stars row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1.w),
                        child: AnimatedBuilder(
                          animation: _shineCtrl,
                          builder: (_, __) {
                            final delay = i * 0.3;
                            final v = (((_shineCtrl.value + delay) % 1.0));
                            return Transform.scale(
                              scale: 0.85 + v * 0.30,
                              child: const Text('⭐', style: TextStyle(fontSize: 28)),
                            );
                          },
                        ),
                      )),
                    ),
                    SizedBox(height: 1.6.h),

                    // Coins earned
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/coin.png',
                          width: 6.w, height: 6.w,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.amber, size: 6.w,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '+${widget.controller.coinsEarnedThisLevel.value} Coins Earned!',
                          style: TextStyle(
                            fontSize:   13.sp,
                            fontWeight: FontWeight.w800,
                            color:      Colors.amber,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(height: 2.5.h),

                    // Next level button
                    _ActionBtn(
                      label: '🚀  Next Level',
                      gradient: const [Color(0xFFFFD700), Color(0xFFFFA500)],
                      onTap:    widget.controller.confirmNextLevel,
                    ),
                    SizedBox(height: 1.5.h),
                    _OutlineBtn(
                      label: '🏠  Go Home',
                      color: Colors.white60,
                      onTap: widget.controller.navigateHome,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared button widgets ────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.gradient, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: widget.gradient.first.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.color.withOpacity(0.45), width: 1.8),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: widget.color,
                letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}
