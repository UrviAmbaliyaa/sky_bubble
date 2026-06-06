import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/style_service.dart';
import '../controllers/game_controller.dart';
import '../widgets/bubble_painter.dart';
import '../widgets/safe_asset_background.dart';

class GameScreen extends GetView<GameController> {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: LayoutBuilder(
        builder: (context, constraints) => _GameBody(
          controller: controller,
          size: constraints.biggest,
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

class _GameBodyState extends State<_GameBody> {
  @override
  void initState() { super.initState(); _onInit(); }

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
          child: Obx(
            () => CustomPaint(
              painter: BubblePainter(
                bubbles: widget.controller.bubbles.toList(),
                level: widget.controller.level.value,
                style: Get.find<StyleService>().selectedStyle.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // HUD overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _GameHUD(controller: widget.controller)),
        ),
        // Level-up banner
        Obx(() => widget.controller.levelUpMessage.value.isEmpty
            ? const SizedBox.shrink()
            : Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 0,
                right: 0,
                child: _LevelUpBanner(
                    message: widget.controller.levelUpMessage.value),
              )),
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
      ],
    );
  }
}

// ─── HUD ─────────────────────────────────────────────────────────────────────

class _GameHUD extends StatelessWidget {
  final GameController controller;
  const _GameHUD({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          // ── Score
          _HudCard(
            child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.scoreGold, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${controller.score.value}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
              ],
            )),
          ),
          const SizedBox(width: 8),
          // ── Level
          _HudCard(
            child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, color: AppColors.levelGreen, size: 18),
                const SizedBox(width: 4),
                Text(
                  'LVL ${controller.level.value}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.levelGreen),
                ),
              ],
            )),
          ),
                    const Spacer(),

          // ── Hearts counter pill
          _HudCard(
            child: Obx(() => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 20),
                const SizedBox(width: 5),
                Text(
                  '+${controller.lives.value}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF4D6D),
                  ),
                ),
              ],
            )),
          ),
                    const SizedBox(width: 8),

          _SoundToggleButton(),
          const SizedBox(width: 8),
          _PauseButton(onTap: controller.togglePause),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: muted ? Colors.red.shade400 : AppColors.textDark,
            size: 22,
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
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: const Icon(Icons.pause_rounded, color: AppColors.textDark, size: 24),
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

  void _onDispose() {
    _ctrl.dispose();
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
                '🎉  ${widget.message}',
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
                margin: const EdgeInsets.symmetric(horizontal: 28),
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
                    // ── Colourful top banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF007AFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        // Bubble emoji row
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🫧', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 4),
                            Text('🫧', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 4),
                            Text('🫧', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Pause icon circle
                        Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.22),
                            border: Border.all(color: Colors.white.withOpacity(0.60), width: 2.5),
                          ),
                          child: const Icon(Icons.pause_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Game Paused!',
                          style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                          ),
                        ),
                      ]),
                    ),
                    // ── White body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Score + Hearts chips
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
                              const SizedBox(width: 10),
                              _PauseStatChip(
                                emoji: '❤️',
                                label: '+${widget.controller.lives.value}',
                                bg: const Color(0xFFFFEBEE),
                                border: const Color(0xFFFF8A80),
                                textColor: const Color(0xFFD32F2F),
                              ),
                            ],
                          )),
                          const SizedBox(height: 22),
                          // Resume button
                          _PauseActionBtn(
                            label: '▶  Resume',
                            gradient: const [Color(0xFF43E97B), Color(0xFF11998E)],
                            glowColor: const Color(0xFF43E97B),
                            onTap: widget.controller.togglePause,
                          ),
                          const SizedBox(height: 12),
                          // Home button — outlined style on white bg
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
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: widget.glowColor.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withOpacity(0.50), width: 1.8),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: widget.color, letterSpacing: 0.3),
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
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated bouncing hearts
                    const Text('💔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    const Text(
                      'Hearts Over!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF4D6D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show all empty hearts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (_) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.favorite_border, color: Color(0xFFFF4D6D), size: 20),
                      )),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'All 8 chances used up!',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    // Current score chip
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.60)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFF9800), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Score: ${widget.controller.score.value}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF7A4F00)),
                        ),
                      ]),
                    )),
                    const SizedBox(height: 28),
                    // ── Reset Hearts button
                    GestureDetector(
                      onTap: widget.controller.resetHearts,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFFF4D6D)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D6D).withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Reset Hearts',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Home button
                    GestureDetector(
                      onTap: widget.controller.navigateHome,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.50), width: 1.8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, color: Color(0xFF0288D1), size: 20),
                            SizedBox(width: 8),
                            Text(
                              '🏠  Go Home',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0288D1),
                              ),
                            ),
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
                    const Text('💥', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.liveRed,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() => _ScoreRow(
                          score: widget.controller.score.value,
                          level: widget.controller.level.value,
                        )),
                    const SizedBox(height: 28),
                    _OverlayButton(
                      label: 'PLAY AGAIN',
                      icon: Icons.replay_rounded,
                      color: AppColors.startGradientEnd,
                      onTap: widget.controller.startGame,
                    ),
                    const SizedBox(height: 12),
                    _OverlayButton(
                      label: 'LEADERBOARD',
                      icon: Icons.leaderboard_rounded,
                      color: AppColors.primary,
                      onTap: () => Get.toNamed('/score'),
                    ),
                    const SizedBox(height: 12),
                    _OverlayButton(
                      label: 'HOME',
                      icon: Icons.home_rounded,
                      color: AppColors.textMedium,
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
        Container(width: 1, height: 48, color: Colors.grey.shade200),
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.35), width: 2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
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

/// Gradient fallbacks — one per image in [BgAssets.all], shown while the
/// asset is loading or if the file is missing.
const _kFallbacks = [
  // bg_sky
  [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF64B5F6), Color(0xFFBBDEFB)],
  // bg_dark_sky
  [Color(0xFF0D1B4A), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
  // bg_gallaxy
  [Color(0xFF0A0020), Color(0xFF1A0050), Color(0xFF2D0080), Color(0xFF6A00FF)],
  // bg_garden
  [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784), Color(0xFFC8E6C9)],
  // bg_garden_gate
  [Color(0xFF33691E), Color(0xFF689F38), Color(0xFFAED581), Color(0xFFDCEDC8)],
  // bg_moonsoon
  [Color(0xFF1A2332), Color(0xFF263545), Color(0xFF37474F), Color(0xFF546E7A)],
  // bg_night
  [Color(0xFF050D2A), Color(0xFF0A1F5E), Color(0xFF0D2B6E), Color(0xFF1A237E)],
  // bg_night_star
  [Color(0xFF020A1F), Color(0xFF0D1340), Color(0xFF1A1560), Color(0xFF2E2080)],
  // beach_sky
  [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
];

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
      // One random background per game, no repeats until all 9 have been seen.
      final imgIndex = widget.controller.randomBgIndex.value;
      final assetPath = BgAssets.all[imgIndex];
      final fallbackColors = _kFallbacks[imgIndex];

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
