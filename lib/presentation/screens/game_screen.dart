import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/style_service.dart';
import '../controllers/game_controller.dart';
import '../widgets/bubble_painter.dart';
import '../widgets/gift_screen_overlay.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/safe_asset_background.dart';

class GameScreen extends GetView<GameController> {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back button is ALWAYS blocked by Flutter; we decide manually below.
      // This prevents the user leaving the game screen while:
      //   • a full-screen interstitial ad is visible
      //   • a level-complete overlay is showing
      //   • the gift-screen overlay is showing
      //   • the hearts-over overlay is showing
      // In all other states the back press behaves normally (saves score + pops).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return; // canPop:false → didPop is always false
        final adSvc = Get.find<AdService>();
        final blocked = adSvc.isAdShowing.value          // interstitial on screen
            || controller.showLevelComplete.value         // level-complete card
            || controller.showGiftScreen.value            // gift overlay
            || controller.isHeartsOver.value;             // hearts-over dialog
        if (blocked) return;                              // swallow the back press
        controller.persistScoreOnExit();
        Get.back();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF87CEEB),
        body: LayoutBuilder(
          builder: (context, constraints) => _GameBody(
            controller: controller,
            size: constraints.biggest,
          ),
        ),
      ),
    );
  }
}

class _GameBody extends StatefulWidget {
  final GameController controller;
  final Size size;
  const _GameBody({required this.controller, required this.size});

  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleAnimCtrl;

  @override
  void initState() {
    super.initState();
    _bubbleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _onInit();
  }

  @override
  void dispose() {
    _bubbleAnimCtrl.dispose();
    super.dispose();
  }

  void _onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.setScreenSize(widget.size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Premium level-based background
        _PremiumBackground(controller: widget.controller),
        // Game canvas — CustomPaint needs a child to claim its full size
        GestureDetector(
          onTapDown: widget.controller.handleTapDown,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _bubbleAnimCtrl,
            builder: (_, __) => Obx(
              () => CustomPaint(
                painter: BubblePainter(
                  bubbles: widget.controller.bubbles.toList(),
                  level: widget.controller.level.value,
                  style: Get.find<StyleService>().selectedStyle.value,
                  animTime: _bubbleAnimCtrl.value * 2 * 3.141592653589793,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        // ── Banner Ad (top of screen, edge-to-edge) ───────────────────────
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _BannerAdWidget(),
        ),
        // HUD overlay — offset below the banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _GameHUD(controller: widget.controller),
        ),
        // Level-up / speed-ramp banner
        Obx(() => widget.controller.levelUpMessage.value.isEmpty
            ? const SizedBox.shrink()
            : Positioned(
                top: MediaQuery.of(context).padding.top + 10.h,
                left: 0,
                right: 0,
                child: _LevelUpBanner(
                    message: widget.controller.levelUpMessage.value),
              )),
        // ── New High Score celebration banner ──────────────────────────────
        // Appears just below the level-up banner so both can coexist without
        // overlapping the HUD.  Tapping it dismisses it immediately.
        Obx(() => widget.controller.showNewBestBanner.value
            ? Positioned(
                top: MediaQuery.of(context).padding.top + 16.h,
                left: 6.w,
                right: 6.w,
                child: GestureDetector(
                  onTap: () => widget.controller.showNewBestBanner.value = false,
                  child: _NewBestBanner(
                      score: widget.controller.newBestScore.value),
                ),
              )
            : const SizedBox.shrink()),
        // Pause overlay
        Obx(() => widget.controller.isPaused.value
            ? Positioned.fill(
                child: _PauseOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
        // Game-over overlay
        Obx(() => widget.controller.isGameOver.value
            ? Positioned.fill(
                child: _GameOverOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
        // Hearts-over popup
        Obx(() => widget.controller.isHeartsOver.value
            ? Positioned.fill(
                child: _HeartsOverOverlay(controller: widget.controller),
              )
            : const SizedBox.shrink()),
        // Level-complete overlay — shown when the player advances to a new level
        Obx(() => widget.controller.showLevelComplete.value
            ? const Positioned.fill(
                child: LevelCompleteOverlay(),
              )
            : const SizedBox.shrink()),
        // Gift screen — shown when player breaks all-time high score
        Obx(() => widget.controller.showGiftScreen.value
            ? const Positioned.fill(
                child: GiftScreenOverlay(),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

// ─── Banner Ad Widget ─────────────────────────────────────────────────────────

class _BannerAdWidget extends StatelessWidget {
  const _BannerAdWidget();

  @override
  Widget build(BuildContext context) {
    final adSvc = Get.find<AdService>();
    return Obx(() {
      if (!adSvc.isBannerLoaded.value || adSvc.bannerAd == null) {
        return const SizedBox.shrink();
      }
      return SizedBox(
        width: double.infinity,
        height: adSvc.bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: adSvc.bannerAd!),
      );
    });
  }
}

// ─── HUD ─────────────────────────────────────────────────────────────────────

class _GameHUD extends StatelessWidget {
  final GameController controller;
  const _GameHUD({required this.controller});

  @override
  Widget build(BuildContext context) {
    final adSvc = Get.find<AdService>();
    return Obx(() {
      final bannerH = adSvc.isBannerLoaded.value && adSvc.bannerAd != null
          ? adSvc.bannerAd!.size.height.toDouble()
          : 0.0;
      return Padding(
        padding: EdgeInsets.fromLTRB(4.w, bannerH + 1.h, 4.w, 1.h),
        child: SizedBox(
          height: 10.w,   // single source of truth for all HUD element heights
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Score
              _HudCard(
                child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.scoreGold, size: 5.5.w),
                    SizedBox(width: 1.5.w),
                    Text(
                      '${controller.score.value}',
                      style: TextStyle(fontSize: 15.5.sp, fontWeight: FontWeight.w900, color: AppColors.textDark),
                    ),
                  ],
                )),
              ),
              SizedBox(width: 2.w),
              // ── Level
              _HudCard(
                child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.levelGreen, size: 5.w),
                    SizedBox(width: 1.w),
                    Text(
                      'LVL ${controller.level.value}',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppColors.levelGreen),
                    ),
                  ],
                )),
              ),
              const Spacer(),
              // ── Hearts counter pill
              _HudCard(
                child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: const Color(0xFFFF4D6D), size: 5.5.w),
                    SizedBox(width: 1.5.w),
                    Text(
                      '${controller.lives.value}',
                      style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFFF4D6D)),
                    ),
                  ],
                )),
              ),
              SizedBox(width: 2.w),
              _SoundToggleButton(),
              SizedBox(width: 2.w),
              _PauseButton(onTap: controller.togglePause),
            ],
          ),
        ),
      );
    });
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
          BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}


class _SoundToggleButton extends StatelessWidget {
  _SoundToggleButton();

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
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
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

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

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
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Icon(Icons.pause_rounded, color: AppColors.textDark, size: 6.w),
        ),
      ),
    );
  }
}

// ─── Level-up Banner ─────────────────────────────────────────────────────────

class _LevelUpBanner extends StatefulWidget {
  final String message;
  const _LevelUpBanner({required this.message});

  @override
  State<_LevelUpBanner> createState() => _LevelUpBannerState();
}

class _LevelUpBannerState extends State<_LevelUpBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _slide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
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
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43E97B).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
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

// ─── New High Score Banner ────────────────────────────────────────────────────
// Slides in from above with a golden gradient, confetti shimmer glow, and a
// spring-scale pop — visually distinct from the green level-up banner.
// Auto-dismissed by GameController after 3 s; also tap-to-dismiss.

class _NewBestBanner extends StatefulWidget {
  final int score;
  const _NewBestBanner({required this.score});

  @override
  State<_NewBestBanner> createState() => _NewBestBannerState();
}

class _NewBestBannerState extends State<_NewBestBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _slide = Tween<double>(begin: -70, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _shimmer = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
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
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.6.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                border: Border.all(
                  color: Colors.white.withOpacity(0.55),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.55 + _shimmer.value * 0.2),
                    blurRadius: 18 + _shimmer.value * 12,
                    spreadRadius: 1 + _shimmer.value * 3,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left trophy
                  Text('🏆', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 3.w),
                  // Text block
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.white, size: 4.w),
                          SizedBox(width: 1.w),
                          Text(
                            '${widget.score} pts',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.95),
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 3),
                              ],
                            ),
                          ),
                          SizedBox(width: 1.5.w),
                          Text('🎉', style: TextStyle(fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(width: 3.w),
                  // Right trophy
                  Text('🏆', style: TextStyle(fontSize: 18.sp)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pause overlay ──────────────────────────────────────────────────────────

class _PauseOverlay extends StatefulWidget {
  final GameController controller;
  const _PauseOverlay({required this.controller});

  @override
  State<_PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<_PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _scale = Tween<double>(begin: 0.75, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 7.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 16)),
                    BoxShadow(color: const Color(0xFF4FC3F7).withOpacity(0.20), blurRadius: 24, offset: const Offset(0, 6)),
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
                          colors: [Color(0xFF00D4FF), Color(0xFF007AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: Colors.white54, size: 5.w),
                            SizedBox(width: 1.w),
                            Icon(Icons.circle, color: Colors.white70, size: 7.w),
                            SizedBox(width: 1.w),
                            Icon(Icons.circle, color: Colors.white54, size: 5.w),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          width: 17.w, height: 17.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.22),
                            border: Border.all(color: Colors.white.withOpacity(0.60), width: 2.5),
                          ),
                          child: Icon(Icons.pause_rounded, color: Colors.white, size: 9.w),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Game Paused!',
                          style: TextStyle(
                            fontSize: 16.5.sp, fontWeight: FontWeight.w900, color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: const [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(6.w, 2.5.h, 6.w, 3.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PauseStatChip(
                                emoji: '⭐',
                                label: '${widget.controller.score.value} pts',
                                bg: const Color(0xFFFFF8E1),
                                border: const Color(0xFFFFCA28),
                                textColor: const Color(0xFF7A5300),
                              ),
                              SizedBox(width: 2.5.w),
                              _PauseStatChip(
                                emoji: '❤️',
                                label: '${widget.controller.lives.value}',
                                bg: const Color(0xFFFFEBEE),
                                border: const Color(0xFFFF8A80),
                                textColor: const Color(0xFFD32F2F),
                              ),
                            ],
                          )),
                          SizedBox(height: 2.5.h),
                          _PauseActionBtn(
                            label: '▶  Resume',
                            gradient: const [Color(0xFF43E97B), Color(0xFF11998E)],
                            glowColor: const Color(0xFF43E97B),
                            onTap: widget.controller.togglePause,
                          ),
                          SizedBox(height: 1.5.h),
                          _PauseOutlineBtn(
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

class _PauseStatChip extends StatelessWidget {
  final String emoji, label;
  final Color bg, border, textColor;
  const _PauseStatChip({
    required this.emoji, required this.label,
    required this.bg, required this.border, required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: TextStyle(fontSize: 12.5.sp)),
        SizedBox(width: 1.5.w),
        Text(label, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: textColor)),
      ]),
    );
  }
}

class _PauseActionBtn extends StatefulWidget {
  final String label;
  final List<Color> gradient;
  final Color glowColor;
  final VoidCallback onTap;
  const _PauseActionBtn({required this.label, required this.gradient, required this.glowColor, required this.onTap});

  @override
  State<_PauseActionBtn> createState() => _PauseActionBtnState();
}

class _PauseActionBtnState extends State<_PauseActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
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
            boxShadow: [BoxShadow(color: widget.glowColor.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _PauseOutlineBtn extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PauseOutlineBtn({required this.label, required this.color, required this.onTap});

  @override
  State<_PauseOutlineBtn> createState() => _PauseOutlineBtnState();
}

class _PauseOutlineBtnState extends State<_PauseOutlineBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withOpacity(0.50), width: 1.8),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: widget.color, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}

// ─── Hearts Over overlay ─────────────────────────────────────────────────────

class _HeartsOverOverlay extends StatefulWidget {
  final GameController controller;
  const _HeartsOverOverlay({required this.controller});

  @override
  State<_HeartsOverOverlay> createState() => _HeartsOverOverlayState();
}

class _HeartsOverOverlayState extends State<_HeartsOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
      ..forward();
    _scale = Tween<double>(begin: 0.65, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withOpacity(0.60),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 9.w),
                padding: EdgeInsets.fromLTRB(7.w, 4.h, 7.w, 3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 12))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💔', style: TextStyle(fontSize: 35.5.sp)),
                    SizedBox(height: 1.5.h),
                    Text(
                      'Hearts Over!',
                      style: TextStyle(fontSize: 18.5.sp, fontWeight: FontWeight.w900, color: const Color(0xFFFF4D6D), letterSpacing: 0.5),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(1, (_) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.5.w),
                        child: Icon(Icons.favorite_border, color: const Color(0xFFFF4D6D), size: 5.w),
                      )),
                    ),
                    SizedBox(height: 1.h),
                    Text('1 chance used up!',
                        style: TextStyle(fontSize: 11.5.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    SizedBox(height: 1.h),
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.60)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.stars_rounded, color: const Color(0xFFFF9800), size: 5.w),
                        SizedBox(width: 1.5.w),
                        Text('${widget.controller.score.value} pts',
                            style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF7A4F00))),
                      ]),
                    )),
                    SizedBox(height: 2.h),
                    Text(
                      'Get a Chance',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 1.2.h),
                    Row(
                      children: [
                        // ── Option 1: Pay 5 coins ──────────────────────────────
                        Expanded(
                          child: Obx(() {
                            final canAfford = widget.controller.canAffordChance;
                            return GestureDetector(
                              onTap: canAfford ? widget.controller.getChanceWithCoins : null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: canAfford ? 1.0 : 0.45,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB300), Color(0xFFFF8C00)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8C00).withOpacity(0.40),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/coin.png',
                                        width: 6.w, height: 6.w,
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        '5 Coins',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(width: 3.w),
                        // ── Option 2: Watch Ad ─────────────────────────────────
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.controller.getChanceWithAd,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF).withOpacity(0.40),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded,
                                      color: Colors.white, size: 6.w),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'Watch Ad',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5.h),
                    GestureDetector(
                      onTap: widget.controller.navigateHome,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.50), width: 1.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, color: const Color(0xFF0288D1), size: 5.w),
                            SizedBox(width: 2.w),
                            Text('Go Home',
                                style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0288D1))),
                          ],
                        ),
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

void _closeApp() {
  // Gracefully pop to the OS home screen.
  // On Android this minimises; on iOS it does nothing (expected platform behaviour).
  SystemNavigator.pop();
}

// ─── Game Over overlay ───────────────────────────────────────────────────────

class _GameOverOverlay extends StatefulWidget {
  final GameController controller;
  const _GameOverOverlay({required this.controller});

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  void _onDispose() {
    _ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXL),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 40,
                        offset: Offset(0, 12))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💥', style: TextStyle(fontSize: 31.5.sp)),
                    SizedBox(height: 1.h),
                    Text(
                      'GAME OVER',
                      style: TextStyle(fontSize: 18.5.sp, fontWeight: FontWeight.w900, color: AppColors.liveRed, letterSpacing: 2),
                    ),
                    SizedBox(height: 3.h),
                    Obx(() => _ScoreRow(score: widget.controller.score.value, level: widget.controller.level.value)),
                    SizedBox(height: 3.h),
                    _OverlayButton(label: 'PLAY AGAIN', icon: Icons.replay_rounded, color: AppColors.startGradientEnd, onTap: widget.controller.startGame),
                    SizedBox(height: 1.5.h),
                    _OverlayButton(label: 'LEADERBOARD', icon: Icons.leaderboard_rounded, color: AppColors.primary, onTap: () => Get.toNamed('/score')),
                    SizedBox(height: 1.5.h),
                    _OverlayButton(label: 'HOME', icon: Icons.home_rounded, color: AppColors.textMedium, onTap: widget.controller.navigateHome),
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

class _ScoreRow extends StatelessWidget {
  final int score;
  final int level;
  const _ScoreRow({required this.score, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ResultTile(
          label: 'SCORE',
          value: '$score',
          color: AppColors.scoreGold,
          icon: Icons.stars_rounded,
        ),
        Container(width: 1, height: 6.h, color: Colors.grey.shade200),
        _ResultTile(
          label: 'LEVEL',
          value: '$level',
          color: AppColors.levelGreen,
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 7.w),
        SizedBox(height: 0.5.h),
        Text(value, style: TextStyle(fontSize: 20.5.sp, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 10.5.sp, color: AppColors.textMedium, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.35), width: 2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 5.w),
            SizedBox(width: 2.5.w),
            Text(label, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  LOOPING IMAGE BACKGROUND
//  Images cycle: bg_day → bg_sunset → bg_garden → bg_garden_real → bg_rain
//  → bg_day → … (wraps back to image 1 after the last)
// ════════════════════════════════════════════════════════════════════════════

/// Generic fallback gradient used when a background asset hasn't loaded.
const _kDefaultFallback = [
  Color(0xFF0D1B4A), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB),
];

/// Gradient fallbacks keyed by asset path.
const _kFallbackMap = <String, List<Color>>{
  'assets/backgrounds/bg_sky.png':              [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF64B5F6), Color(0xFFBBDEFB)],
  'assets/backgrounds/bg_dark_sky.png':         [Color(0xFF0D1B4A), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
  'assets/backgrounds/bg_gallaxy.png':          [Color(0xFF0A0020), Color(0xFF1A0050), Color(0xFF2D0080), Color(0xFF6A00FF)],
  'assets/backgrounds/bg_garden.png':           [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784), Color(0xFFC8E6C9)],
  'assets/backgrounds/bg_garden_gate.png':      [Color(0xFF33691E), Color(0xFF689F38), Color(0xFFAED581), Color(0xFFDCEDC8)],
  'assets/backgrounds/bg_moonsoon.png':         [Color(0xFF1A2332), Color(0xFF263545), Color(0xFF37474F), Color(0xFF546E7A)],
  'assets/backgrounds/bg_night.png':            [Color(0xFF050D2A), Color(0xFF0A1F5E), Color(0xFF0D2B6E), Color(0xFF1A237E)],
  'assets/backgrounds/bg_night_star.png':       [Color(0xFF020A1F), Color(0xFF0D1340), Color(0xFF1A1560), Color(0xFF2E2080)],
  'assets/backgrounds/beach_sky.png':           [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
  'assets/backgrounds/bg_morning.png':          [Color(0xFFFF6F00), Color(0xFFFFA000), Color(0xFFFFCA28), Color(0xFFFFECB3)],
  'assets/backgrounds/bg_morning_view.png':     [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFB74D), Color(0xFFFFE0B2)],
  'assets/backgrounds/bg_morning_view_water.png':[Color(0xFF006064), Color(0xFF00838F), Color(0xFF4DD0E1), Color(0xFFB2EBF2)],
  'assets/backgrounds/bg_peacoc.png':           [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF26A69A), Color(0xFFB2DFDB)],
  'assets/backgrounds/bs_morning.png':          [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF7043), Color(0xFFFFCCBC)],
};

class _PremiumBackground extends StatefulWidget {
  final GameController controller;
  const _PremiumBackground({required this.controller});

  @override
  State<_PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<_PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _parallaxCtrl;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _parallaxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _parallaxCtrl.addListener(() => setState(() {}));
  }

  void _onDispose() {
    _parallaxCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Background changes every 200 score points (random pick, never repeats).
      // Falls back to the first asset until the game starts and sets gameBgAsset.
      final assetPath = widget.controller.gameBgAsset.value.isNotEmpty
          ? widget.controller.gameBgAsset.value
          : Get.find<StyleService>().currentBgAsset.value;
      final fallbackColors =
          _kFallbackMap[assetPath] ?? _kDefaultFallback;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: SafeAssetBackground(
          key: ValueKey(assetPath),
          assetPath: assetPath,
          progress: _parallaxCtrl.value,
          fallback: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fallbackColors,
              ),
            ),
          ),
        ),
      );
    });
  }
}
