import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/bubble_styles.dart';
import '../../data/models/bubble_model.dart';
import '../../data/services/style_service.dart';
import '../widgets/bubble_painter.dart';

// ════════════════════════════════════════════════════════════════════════════
//  BUBBLE STYLE SELECTION SCREEN
// ════════════════════════════════════════════════════════════════════════════

class BubbleStyleScreen extends StatelessWidget {
  const BubbleStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose how your bubbles look in-game.\nTap a style to preview & select it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final current = svc.selectedStyle.value;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: BubbleStyle.values.length,
                  itemBuilder: (_, i) {
                    final style = BubbleStyle.values[i];
                    return _StyleCard(
                      style: style,
                      isSelected: current == style,
                      onTap: () => svc.setStyle(style),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.40),
                      blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Text(
                    '✅  Apply & Go Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x334FC3F7), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('💧  Bubble Style',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 0.3)),
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
  const _StyleCard({required this.style, required this.isSelected, required this.onTap});

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _bob = Tween<double>(begin: -4.0, end: 4.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: sel ? const Color(0xFF0288D1) : Colors.grey.shade200,
            width: sel ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: sel
                  ? const Color(0xFF4FC3F7).withOpacity(0.35)
                  : Colors.black.withOpacity(0.06),
              blurRadius: sel ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview canvas with animated bob
            AnimatedBuilder(
              animation: _bob,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _bob.value),
                child: SizedBox(
                  width: 40, height: 40,
                  child: CustomPaint(
                    painter: _BubblePreviewPainter(
                      style: widget.style,
                      color: AppColors.bubbleColors[
                          widget.style.index % AppColors.bubbleColors.length],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.style.emoji}  ${widget.style.label}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
                color: sel ? const Color(0xFF0288D1) : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.style.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.3),
              ),
            ),
            if (sel) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('✓  SELECTED',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 1.0)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Preview Painter (draws a single bubble in the given style) ───────────────

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Create a fake BubbleModel for the painter
    final b = BubbleModel(
      id: 'preview',
      color: color,
      x: cx, y: cy,
      radius: r,
      speed: 0,
      driftAmplitude: 0,
      driftFrequency: 0,
      pointValue: 3,
    );

    // Use BubblePainter's logic by creating a mini painter
    final painter = BubblePainter(
      bubbles: [b],
      level: 3, // mid-level skin for classic
      style: style,
    );
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) =>
      old.style != style || old.color != color;
}
