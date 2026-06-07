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
                'Classic is free. Earn coins by playing to unlock premium styles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final current = svc.selectedStyle.value;
                final coins   = svc.totalCoins.value;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: BubbleStyle.values.length,
                  itemBuilder: (_, i) {
                    final style    = BubbleStyle.values[i];
                    final unlocked = svc.isUnlocked(style);
                    return _StyleCard(
                      style: style,
                      isSelected: current == style,
                      isUnlocked: unlocked,
                      userCoins: coins,
                      onTap: () {
                        if (unlocked) {
                          svc.setStyle(style);
                        } else {
                          showUnlockDialog(context, style, svc);
                        }
                      },
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();
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
            child: Row(
              children: [
                Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text('Bubble Style',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 0.3)),
              ],
            ),
          ),
          // Coin balance chip
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD740).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD740).withOpacity(0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('�', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${svc.totalCoins.value}',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Style Card ───────────────────────────────────────────────────────────────

class _StyleCard extends StatefulWidget {
  final BubbleStyle style;
  final bool isSelected;
  final bool isUnlocked;
  final int userCoins;
  final VoidCallback onTap;
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.isUnlocked,
    required this.userCoins,
    required this.onTap,
  });

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bob;

  static const _classicColors = [
    Color(0xFF4FC3F7), Color(0xFF7C4DFF), Color(0xFFFF6B9D),
    Color(0xFF43E97B), Color(0xFFFFD54F), Color(0xFF4FC3F7),
  ];

  Color get _classicIconColor {
    final t = (_ctrl.value).clamp(0.0, 1.0);
    final total = _classicColors.length - 1;
    final idx = (t * total).floor().clamp(0, total - 1);
    final frac = (t * total) - idx;
    return Color.lerp(_classicColors[idx], _classicColors[idx + 1], frac)!;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _bob = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sel       = widget.isSelected;
    final locked    = !widget.isUnlocked;
    final isClassic = widget.style == BubbleStyle.classic;
    final canAfford = widget.userCoins >= widget.style.coinCost;
    final isPremium = widget.style.isPremium;

    // Border color: gold for locked premium, blue for selected, grey otherwise
    final borderColor = locked
        ? const Color(0xFFFFD740)
        : sel
            ? const Color(0xFF0288D1)
            : Colors.grey.shade200;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: locked ? 1.8 : sel ? 2.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: locked
                  ? const Color(0xFFFFD740).withOpacity(0.20)
                  : sel
                      ? const Color(0xFF4FC3F7).withOpacity(0.35)
                      : Colors.black.withOpacity(0.06),
              blurRadius: locked ? 12 : sel ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Bubble preview with crown overlay ──────────────────────────
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _bob.value),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Bubble image
                    isClassic
                        ? Icon(Icons.bubble_chart_rounded,
                            size: 50, color: _classicIconColor)
                        : SizedBox(
                            width: 50, height: 50,
                            child: CustomPaint(
                              painter: _BubblePreviewPainter(
                                style: widget.style,
                                color: AppColors.bubbleColors[
                                    widget.style.index % AppColors.bubbleColors.length],
                              ),
                            ),
                          ),
                    // Crown badge — shown on premium styles (locked or unlocked)
                    if (isPremium)
                      Positioned(
                        top: -14,
                        child: _CrownBadge(
                          canAfford: canAfford,
                          isUnlocked: widget.isUnlocked,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Label ───────────────────────────────────────────────────────
            isClassic
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) => Icon(
                          Icons.bubble_chart_rounded,
                          size: 15, color: _classicIconColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(widget.style.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
                            color: sel ? const Color(0xFF0288D1) : AppColors.textDark,
                          )),
                    ],
                  )
                : Text(
                    '${widget.style.emoji}  ${widget.style.label}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
                      color: sel ? const Color(0xFF0288D1) : AppColors.textDark,
                    ),
                  ),

            const SizedBox(height: 4),

            // ── Coin cost (locked) or description / selected pill (unlocked) ─
            if (locked) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('�', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.style.coinCost} coins',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: canAfford
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  widget.style.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.3),
                ),
              ),
              if (sel) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('✓  SELECTED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 1.0)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Crown Badge (grid cards) ─────────────────────────────────────────────────

class _CrownBadge extends StatelessWidget {
  final bool canAfford;
  final bool isUnlocked;
  const _CrownBadge({required this.canAfford, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final bool vivid = !isUnlocked && canAfford;
    final bool muted = !isUnlocked && !canAfford;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: muted
              ? [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]
              : vivid
                  ? [const Color(0xFFFFE566), const Color(0xFFFFAA00)]
                  : [const Color(0xFFFFD740).withOpacity(0.30),
                     const Color(0xFFFFAA00).withOpacity(0.30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: muted
              ? Colors.grey.shade400
              : vivid
                  ? Colors.white
                  : const Color(0xFFFFD740).withOpacity(0.80),
          width: 2.0,
        ),
        boxShadow: vivid
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD740).withOpacity(0.70),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          '👑',
          style: TextStyle(fontSize: muted ? 13 : 14, height: 1.0),
        ),
      ),
    );
  }
}

// ─── Preview Painter ──────────────────────────────────────────────────────────

class _BubblePreviewPainter extends CustomPainter {
  final BubbleStyle style;
  final Color color;
  const _BubblePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
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
    BubblePainter(bubbles: [b], level: 3, style: style).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BubblePreviewPainter old) =>
      old.style != style || old.color != color;
}

// ─── Unlock Dialog (shared by both style UIs) ────────────────────────────────

void showUnlockDialog(
    BuildContext context, BubbleStyle style, StyleService svc) {
  final canAfford = svc.totalCoins.value >= style.coinCost;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(style.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'Unlock ${style.label}',
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              style.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9099B0), height: 1.4),
            ),
            const SizedBox(height: 20),
            // Coin cost row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: canAfford
                    ? const Color(0xFFF1FDF1)
                    : const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canAfford
                      ? const Color(0xFF43A047).withOpacity(0.4)
                      : const Color(0xFFE53935).withOpacity(0.3),
                ),
              ),
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '${style.coinCost} coins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: canAfford
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '(you have ${svc.totalCoins.value})',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 20),
            if (canAfford) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final success = svc.unlockStyle(style);
                    Navigator.of(context).pop();
                    if (success) {
                      svc.setStyle(style);
                      Get.snackbar(
                        '${style.emoji} Unlocked!',
                        '${style.label} style is now active.',
                        backgroundColor: const Color(0xFF0288D1),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 14,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  child: Text(
                    'Unlock for ${style.coinCost} �',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]
           
          ],
        ),
      ),
    ),
  );
}
