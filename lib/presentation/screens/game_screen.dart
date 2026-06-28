import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'package:apsl_admob_ads_flutter/apsl_admob_ads_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../core/services/remote_ad_config_service.dart';
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
      // Back / swipe-back is ALWAYS intercepted so we can pause first.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final adSvc = Get.find<AdService>();
        // Hard-block while overlays that have their own exit paths are visible.
        final blocked = adSvc.isAdShowing.value
            || controller.showLevelComplete.value
            || controller.showGiftScreen.value
            || controller.isGameOver.value;
        if (blocked) return;
        // If already showing pause overlay the user used the back gesture again
        // while paused — treat it as a no-op (they must tap Go Home instead).
        if (controller.isPaused.value) return;
        // Pause the game and show the pause overlay instead of exiting.
        controller.pauseForNavigation();
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
  ui.Image? _giftImage;
  List<ui.Image> _dogImages = [];

  @override
  void initState() {
    super.initState();
    _bubbleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _onInit();
    _loadGiftImage();
    _loadDogImages();
  }

  Future<void> _loadGiftImage() async {
    final data = await rootBundle.load('assets/images/gift.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _giftImage = frame.image);
  }

  Future<void> _loadDogImages() async {
    final paths = ['assets/dog/dog.png', 'assets/dog/dog_2.png', 'assets/dog/dog_3.png'];
    final images = <ui.Image>[];
    for (final path in paths) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      images.add(frame.image);
    }
    if (mounted) setState(() => _dogImages = images);
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
                  giftImage: _giftImage,
                  dogImages: _dogImages,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        // ── Banner Ad (bottom of screen, edge-to-edge) ──────────────────
         Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: Column(
            children: [
              _BannerAdWidget(),
              _GameHUD(controller: widget.controller)
            ],
          )),
        ),
       Obx(() {
          RemoteAdConfigService? remote;
          try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
          final adsOn   = remote?.adsEnabled.value     ?? false;
          final moreAds = remote?.moreAdsEnabled.value ?? false;
          if (!adsOn || !moreAds) return const SizedBox.shrink();
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _BannerAdWidget()),
          );
        }),
        // HUD overlay
        
        // Level-up / speed-ramp banner
        Obx(() => widget.controller.levelUpMessage.value.isEmpty
            ? const SizedBox.shrink()
            : Positioned(
                top: MediaQuery.of(context).padding.top + 6.h,
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
// Top-of-screen banner. Space collapses entirely if the ad fails to load.
// Hidden when: premium background active, ads=false, or show_ads=false.

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  static const _bannerH = 50.0;
  // True only when the banner is actually rendered — HUD reads this to offset itself.
  static final isVisible = false.obs;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {

  // Reactive so Obx rebuilds automatically when the ad load state changes.
  final _adFailed = false.obs;

  StreamSubscription<AdEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ApslAds.instance.onEvent.listen((event) {
      if (event.adUnitType != AdUnitType.banner) return;
      if (event.type == AdEventType.adFailedToLoad) {
        _adFailed.value = true;
      } else if (event.type == AdEventType.adLoaded) {
        _adFailed.value = false;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleSvc  = Get.find<StyleService>();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      bool shouldShow = false;

      final currentBg   = styleSvc.currentBgAsset.value;
      final isPremiumBg = BackgroundStyle.values.any(
        (bg) => bg.assetPath == currentBg && bg.isPremium,
      );

      if (!isPremiumBg && !_adFailed.value) {
        try {
          // Game banner: show whenever ads=true. Only hidden when ads=false.
          shouldShow = Get.find<RemoteAdConfigService>().adsEnabled.value;
        } catch (_) {}
      }

      // Keep HUD offset in sync — schedule after build to avoid setState-during-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _BannerAdWidget.isVisible.value = shouldShow;
      });

      if (!shouldShow) return const SizedBox.shrink();

      return SizedBox(
        height: _BannerAdWidget._bannerH + bottomPad,
        child: Column(
          children: [
            const SizedBox(
              height: _BannerAdWidget._bannerH,
              child: ApslBannerAd(
                adNetwork: AdNetwork.admob,
                adSize: AdSize.banner,
              ),
            ),
            SizedBox(height: bottomPad),
          ],
        ),
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
    return Padding(
        padding: EdgeInsets.fromLTRB(4.w,  1.h, 4.w, 1.h),
        child: SizedBox(
          height: 10.w,   // single source of truth for all HUD element heights
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Score (IgnorePointer so taps pass through to the game canvas)
              IgnorePointer(
                child: _HudCard(
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
              ),
              SizedBox(width: 2.w),
              // ── Level
              IgnorePointer(
                child: _HudCard(
                  child: Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up_rounded, color: AppColors.levelGreen, size: 5.w),
                      SizedBox(width: 1.w),
                      Text(
                        'L ${controller.level.value}',
                        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: AppColors.levelGreen),
                      ),
                    ],
                  )),
                ),
              ),
              const Spacer(),
              // ── Time remaining pill
              IgnorePointer(
                child: _HudCard(
                  child: Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_rounded, color: const Color(0xFF6C63FF), size: 5.5.w),
                      SizedBox(width: 1.5.w),
                      Text(
                        controller.timeRemaining.value.isEmpty ? '--:--' : controller.timeRemaining.value,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF)),
                      ),
                    ],
                  )),
                ),
              ),
              SizedBox(width: 2.w),
              _SoundToggleButton(),
              SizedBox(width: 2.w),
              _PauseButton(onTap: controller.togglePause),
            ],
          ),
        ),
      );;
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
                                emoji: '⏱',
                                label: widget.controller.timeRemaining.value.isEmpty ? '--:--' : widget.controller.timeRemaining.value,
                                bg: const Color(0xFFEDE7F6),
                                border: const Color(0xFF9575CD),
                                textColor: const Color(0xFF4A148C),
                              ),
                            ],
                          )),
                          SizedBox(height: 2.5.h),
                          _PauseActionBtn(
                            label: '▶  Resume',
                            gradient: const [Color(0xFF43E97B), Color(0xFF11998E)],
                            glowColor: const Color(0xFF43E97B),
                            onTap: () {
                              RemoteAdConfigService? remote;
                              try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
                              final adsOn   = remote?.adsEnabled.value     ?? false;
                              final moreAds = remote?.moreAdsEnabled.value ?? false;
                              if (adsOn && moreAds) {
                                Get.find<AdService>().showInterstitial(
                                  onDismissed: widget.controller.togglePause,
                                );
                              } else {
                                widget.controller.togglePause();
                              }
                            },
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

class _PremiumBackground extends StatelessWidget {
  final GameController controller;
  const _PremiumBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Background changes every 200 score points (random pick, never repeats).
      // Falls back to the first asset until the game starts and sets gameBgAsset.
      final styleSvc = Get.find<StyleService>();
      final String assetPath;
      if (!styleSvc.autoBackground.value && styleSvc.fixedBgStyle.value != null) {
        // Fixed mode: always show the pinned background, live-updates immediately
        assetPath = styleSvc.fixedBgStyle.value!.assetPath;
      } else if (controller.gameBgAsset.value.isNotEmpty) {
        assetPath = controller.gameBgAsset.value;
      } else {
        assetPath = styleSvc.currentBgAsset.value;
      }
      final fallbackColors = _kFallbackMap[assetPath] ?? _kDefaultFallback;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: SafeAssetBackground(
          key: ValueKey(assetPath),
          assetPath: assetPath,
          progress: 0,
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
