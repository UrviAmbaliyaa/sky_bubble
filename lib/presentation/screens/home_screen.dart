import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/bubble_painter.dart';
import '../../data/models/bubble_model.dart';

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
          const RepaintBoundary(child: _AnimatedBackground()),
          const SafeArea(child: _HomeUI()),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND — static image, no bubble/cloud animation
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

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

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME UI  — highest score · play · leaderboard · style
// ═══════════════════════════════════════════════════════════════════════════════

// _HomeUI is a pure GetView — all animation state lives in HomeController.
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
            const SizedBox(height: 16),
            _HighestScorePill(controller: controller),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlayButton(onPressed: controller.navigateToGame),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: _LeaderboardButton(onPressed: controller.navigateToScores)),
                      const SizedBox(width: 14),
                      const Expanded(child: _StyleButton()),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Highest Score Pill ───────────────────────────────────────────────────────

class _HighestScorePill extends StatelessWidget {
  final HomeController controller;
  const _HighestScorePill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD740).withOpacity(0.18),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: const Color(0xFFFFD740).withOpacity(0.55), width: 1.4),
            boxShadow: [BoxShadow(color: const Color(0xFFFF9100).withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 4))],
          ),
          child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                controller.bestScore.value == 0 ? 'No record yet' : '${controller.bestScore.value} pts',
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ─── Play Button — pulse animation owned by HomeController ───────────────────

class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PlayButton({required this.onPressed});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

// Only local UI state (_pressed) stays in the widget; animation is in HomeController.
class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: Get.find<HomeController>().pulseAnim,
        builder: (_, child) => AnimatedScale(
          scale: _pressed ? 0.93 : Get.find<HomeController>().pulseAnim.value,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
        child: SizedBox(
          width: 220,
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 62,
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    SizedBox(width: 8),
                    Text('PLAY', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3.0)),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Leaderboard Button ───────────────────────────────────────────────────────

class _LeaderboardButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LeaderboardButton({required this.onPressed});

  @override
  State<_LeaderboardButton> createState() => _LeaderboardButtonState();
}

class _LeaderboardButtonState extends State<_LeaderboardButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPressed(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD54F), size: 20),
                  SizedBox(width: 8),
                  Text('PROGRESS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Style Button ─────────────────────────────────────────────────────────────

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
      onTapUp: (_) { setState(() => _pressed = false); _showBubbleStyleDialog(context); },
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(style.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text('STYLE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
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

void _showBubbleStyleDialog(BuildContext context) {
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
    final svc = Get.find<StyleService>();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 42, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF4FC3F7), Color(0xFF9C27B0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Text('🫧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bubble Style',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Tap a style to play with it',
                      style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                ]),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          // ── Style cards list
          Flexible(
            child: Obx(() {
              final current = svc.selectedStyle.value;
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}

// ─── Horizontal style card ─────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  final BubbleStyle style;
  final bool isSelected;
  final VoidCallback onTap;
  const _StyleCard({required this.style, required this.isSelected, required this.onTap});

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard> with SingleTickerProviderStateMixin {
  late AnimationController _bob;
  late Animation<double> _bobAnim;
  bool _pressed = false;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -3.0, end: 3.0)
        .animate(CurvedAnimation(parent: _bob, curve: Curves.easeInOut));
  }

  void _onDispose() => _bob.dispose();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.style.gradientColors.first.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? widget.style.gradientColors.first : const Color(0xFFE8EDF5),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [BoxShadow(color: widget.style.gradientColors.first.withOpacity(0.20), blurRadius: 14, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 86, height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.style.gradientColors.first.withOpacity(0.12),
                border: Border.all(color: widget.style.gradientColors.first.withOpacity(0.22), width: 1.2),
              ),
              child: AnimatedBuilder(
                animation: _bobAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _bobAnim.value),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _BubblePreviewPainter(
                        style: widget.style,
                        color: AppColors.bubbleColors[widget.style.index % AppColors.bubbleColors.length],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(widget.style.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 7),
                  Text(widget.style.label,
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900,
                        color: widget.isSelected ? widget.style.gradientColors.first : const Color(0xFF1A1A2E),
                      )),
                ]),
                const SizedBox(height: 4),
                Text(widget.style.description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9099B0), height: 1.4)),
              ]),
            ),
            SizedBox(
              width: 30, height: 30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isSelected
                    ? Container(
                        key: const ValueKey('check'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.style.gradientColors),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: widget.style.gradientColors.first.withOpacity(0.35), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

}

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Use 44% of canvas width so the shape fills the circle nicely.
    final r = size.width * 0.44;
    final b = BubbleModel(
      id: 'preview', color: color, x: cx, y: cy, radius: r,
      speed: 0, driftAmplitude: 0, driftFrequency: 0, pointValue: 3,
    );
    BubblePainter(bubbles: [b], level: 5, style: style).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) => old.style != style || old.color != color;
}
