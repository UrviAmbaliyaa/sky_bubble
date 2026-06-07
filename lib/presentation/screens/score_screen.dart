import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/score_model.dart';
import '../controllers/score_controller.dart';

// ════════════════════════════════════════════════════════════════════════════
//  PROGRESS SCREEN
// ════════════════════════════════════════════════════════════════════════════

class ScoreScreen extends GetView<ScoreController> {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: Column(
        children: [
          _HeaderBanner(controller: controller),
          _TabStrip(controller: controller),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 0:  return _DateTab(ctrl: controller);
                  case 1:  return _WeekTab(ctrl: controller);
                  default: return _MonthTab(ctrl: controller);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HEADER BANNER  — gradient with floating bubbles + key stats
// ════════════════════════════════════════════════════════════════════════════

class _HeaderBanner extends StatefulWidget {
  final ScoreController controller;
  const _HeaderBanner({required this.controller});
  @override
  State<_HeaderBanner> createState() => _HeaderBannerState();
}

class _HeaderBannerState extends State<_HeaderBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, MediaQuery.of(context).padding.top + 1.5.h, 4.w, 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF4FC3F7), Color(0xFF9C27B0)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // floating bubble decorations
          ..._bubbleDecos(_ctrl.value),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  '🏆  My Progress',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Spacer(),
                const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 28),
              ]),
              SizedBox(height: 2.h),
              // Stats row
              Obx(() => Row(children: [
                _HeaderStat(emoji: '⭐', label: 'Best Score',
                    value: widget.controller.globalBest.value == 0
                        ? '0' : '${widget.controller.globalBest.value}'),
                const SizedBox(width: 10),
                _HeaderStat(emoji: '🎮', label: 'Total Games',
                    value: '${widget.controller.allDateSummaries.fold(0, (s, d) => s + d.gamesPlayed)}'),
                const SizedBox(width: 10),
                _HeaderStat(emoji: '📅', label: 'Days Played',
                    value: '${widget.controller.allDateSummaries.length}'),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  static List<Widget> _bubbleDecos(double t) {
    const specs = [
      [0.85, 0.15, 22.0, Color(0x33FFFFFF)],
      [0.70, 0.60, 14.0, Color(0x22FFFFFF)],
      [0.92, 0.80, 18.0, Color(0x1AFFFFFF)],
      [0.60, 0.10, 10.0, Color(0x2AFFFFFF)],
    ];
    return specs.map((s) {
      final x = s[0] as double;
      final y = s[1] as double;
      final r = s[2] as double;
      final c = s[3] as Color;
      final dy = math.sin(t * math.pi * 2 + x * 3) * 6;
      return Positioned(
        right: x * 80,
        top: y * 60 + dy,
        child: Container(
          width: r * 2, height: r * 2,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
      );
    }).toList();
  }
}

class _HeaderStat extends StatelessWidget {
  final String emoji, label, value;
  const _HeaderStat({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
              textAlign: TextAlign.center),
          Text(label,
              style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TAB STRIP
// ════════════════════════════════════════════════════════════════════════════

class _TabStrip extends StatelessWidget {
  final ScoreController controller;
  const _TabStrip({required this.controller});

  static const _tabs = [
    ('📅', 'Dates'),
    ('📆', 'Week'),
    ('🗓', 'Month'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Obx(() => Row(
        children: List.generate(_tabs.length, (i) {
          final sel = controller.selectedTab.value == i;
          final (emoji, label) = _tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.onTabChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF4FC3F7)],
                  ) : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: sel ? [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.35), blurRadius: 8)] : null,
                ),
                child: Center(
                  child: Text(
                    '$emoji  $label',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      color: sel ? Colors.white : AppColors.textMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      )),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PERIOD NAVIGATOR  (< Label >)
// ════════════════════════════════════════════════════════════════════════════

class _PeriodNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onLabelTap;
  final List<Color> gradient;

  const _PeriodNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.gradient,
    this.onLabelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev, gradient: gradient),
        Expanded(
          child: GestureDetector(
            onTap: onLabelTap,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              if (onLabelTap != null) ...[
                const SizedBox(width: 6),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(colors: gradient).createShader(b),
                  child: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                ),
              ],
            ]),
          ),
        ),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
          gradient: onNext != null ? gradient : [Colors.grey.shade300, Colors.grey.shade300],
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color> gradient;
  const _NavBtn({required this.icon, required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: onTap != null ? LinearGradient(colors: gradient) : null,
          color: onTap == null ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onTap != null ? Colors.white : Colors.grey.shade400, size: 26),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  RAINBOW BAR CHART
// ════════════════════════════════════════════════════════════════════════════

const _kBarColors = [
  Color(0xFF4FC3F7), Color(0xFF81C784), Color(0xFFFFD54F),
  Color(0xFFFF8A65), Color(0xFFCE93D8), Color(0xFFFF6B9D), Color(0xFF64B5F6),
];

class _RainbowBarChart extends StatefulWidget {
  final List<BarItem> bars;
  final int selectedIndex;
  final void Function(int) onTap;

  const _RainbowBarChart({required this.bars, required this.selectedIndex, required this.onTap});

  @override
  State<_RainbowBarChart> createState() => _RainbowBarChartState();
}

class _RainbowBarChartState extends State<_RainbowBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_RainbowBarChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars) _ctrl.forward(from: 0);
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return const SizedBox(height: 140, child: Center(child: Text('No data', style: TextStyle(color: Colors.grey))));
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(
        builder: (ctx, c) => GestureDetector(
          onTapUp: (d) {
            final bw = (c.maxWidth - 24) / widget.bars.length;
            final idx = ((d.localPosition.dx - 12) / bw).floor();
            if (idx >= 0 && idx < widget.bars.length) widget.onTap(idx);
          },
          child: SizedBox(
            width: c.maxWidth, height: 150,
            child: CustomPaint(
              painter: _RainbowBarPainter(
                bars: widget.bars,
                sel: widget.selectedIndex,
                anim: _anim.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RainbowBarPainter extends CustomPainter {
  final List<BarItem> bars;
  final int sel;
  final double anim;
  _RainbowBarPainter({required this.bars, required this.sel, required this.anim});

  @override
  void paint(Canvas canvas, Size s) {
    const pH = 18.0, pB = 28.0, pS = 12.0;
    final chartH = s.height - pH - pB;
    final bw = (s.width - pS * 2) / bars.length;
    final maxV = bars.map((b) => b.value).fold(0, math.max);

    // Grid lines
    final gp = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = pH + chartH - chartH * i / 3;
      canvas.drawLine(Offset(pS, y), Offset(s.width - pS, y), gp);
    }

    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final isSel = sel == i;
      final color = _kBarColors[i % _kBarColors.length];
      final bH = maxV > 0 ? b.value / maxV * chartH * anim : 0.0;
      final bx = pS + i * bw + bw * 0.12;
      final bW = bw * 0.76;
      final by = pH + chartH - bH;

      if (bH > 2) {
        // Shadow
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 2, by + 4, bW, bH), const Radius.circular(8)),
          Paint()..color = color.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Bar gradient
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bW, bH), const Radius.circular(8)),
          Paint()..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(isSel ? 0.95 : 0.65)],
          ).createShader(Rect.fromLTWH(bx, by, bW, bH)),
        );
        // Selected border
        if (isSel) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bW, bH), const Radius.circular(8)),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5,
          );
        }
        // Value label
        if (bH > 20) {
          final tp = TextPainter(
            text: TextSpan(
              text: '${b.value}',
              style: TextStyle(fontSize: isSel ? 11 : 9, fontWeight: FontWeight.w800, color: isSel ? color : Colors.grey.shade600),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(bx + (bW - tp.width) / 2, by - tp.height - 3));
        }
      }

      // Day label
      final lp = TextPainter(
        text: TextSpan(
          text: b.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel || b.isCurrent ? FontWeight.w900 : FontWeight.w500,
            color: isSel ? color : b.isCurrent ? AppColors.textDark : Colors.grey.shade500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(bx + (bW - lp.width) / 2, pH + chartH + 7));
    }
  }

  @override
  bool shouldRepaint(_RainbowBarPainter o) => o.anim != anim || o.sel != sel || o.bars != bars;
}

// ════════════════════════════════════════════════════════════════════════════
//  DATE TAB
// ════════════════════════════════════════════════════════════════════════════

class _DateTab extends StatelessWidget {
  final ScoreController ctrl;
  const _DateTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summaries = ctrl.allDateSummaries;
      final filter = ctrl.dateRangeFilter.value;
      if (summaries.isEmpty) return const _EmptyState(showPlayButton: true);

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        itemCount: summaries.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _DateFilterBar(ctrl: ctrl, filter: filter);
          }
          final idx = i - 1;
          // Rank medal: best total score day = 🥇, 2nd = 🥈, 3rd = 🥉
          final sortedByTotal = [...summaries]..sort((a, b) => b.totalScore.compareTo(a.totalScore));
          final rank = sortedByTotal.indexOf(summaries[idx]);
          return Obx(() => _DateCard(
            summary: summaries[idx],
            index: idx,
            rank: rank,
            isExpanded: ctrl.expandedDateIndex.value == idx,
            onToggle: () => ctrl.toggleDateExpanded(idx),
          ));
        },
      );
    });
  }
}

class _DateFilterBar extends StatelessWidget {
  final ScoreController ctrl;
  final DateTimeRange? filter;
  const _DateFilterBar({required this.ctrl, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const Icon(Icons.history_rounded, color: Color(0xFF1565C0), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            filter == null ? 'All Dates' : '${_fmtDate(filter!.start)} – ${_fmtDate(filter!.end)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ),
        if (filter != null) ...[
          GestureDetector(
            onTap: ctrl.clearDateFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade400)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () => _showDateCalendarPicker(context, ctrl),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF4FC3F7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateSummary summary;
  final int index;
  final int rank; // 0=gold 1=silver 2=bronze
  final bool isExpanded;
  final VoidCallback onToggle;
  const _DateCard({required this.summary, required this.index, required this.rank, required this.isExpanded, required this.onToggle});

  String get _medal => rank == 0 ? '🥇' : rank == 1 ? '🥈' : rank == 2 ? '🥉' : '🎮';
  Color get _accentColor => rank == 0
      ? const Color(0xFFFF9100)
      : rank == 1
          ? const Color(0xFF78909C)
          : rank == 2
              ? const Color(0xFFBF8040)
              : const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = summary.date.year == now.year &&
        summary.date.month == now.month &&
        summary.date.day == now.day;
    final accent = isToday ? const Color(0xFF1565C0) : _accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isToday ? accent.withOpacity(0.50) : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Date badge
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [accent, accent.withOpacity(0.70)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${summary.date.day}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                  Text(_shortMonth(summary.date.month),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(_medal, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(_fullDate(summary.date),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isToday ? accent : AppColors.textDark)),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                        child: const Text('TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    _MiniPill(label: '🎮 ${summary.gamesPlayed}', color: const Color(0xFF4FC3F7)),
                    const SizedBox(width: 6),
                    _MiniPill(label: '🏅 Best ${summary.bestScore}', color: const Color(0xFFFF9100)),
                  ]),
                ]),
              ),
              // Total score
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(colors: [accent, accent.withOpacity(0.65)]).createShader(b),
                  child: Text('${summary.totalScore}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                ),
                const Text('pts', style: TextStyle(fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (isToday)
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.game),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('▶ Play', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ]),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 22),
              ),
            ]),
          ),
        ),
        // Expanded games
        if (isExpanded) ...[
          Divider(height: 1, color: Colors.grey.shade100),
          ...summary.games.asMap().entries.map((e) {
            final gi = e.key;
            final g = e.value;
            final isBest = g.score == summary.bestScore;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: isBest ? const Color(0xFFFF9100).withOpacity(0.15) : accent.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(isBest ? '⭐' : '${gi + 1}',
                        style: TextStyle(fontSize: isBest ? 16 : 13, fontWeight: FontWeight.w800, color: isBest ? const Color(0xFFFF9100) : accent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Game ${gi + 1}  •  ${_hhmm(g.playedAt)}  •  Lvl ${g.level}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBest ? const Color(0xFFFF9100).withOpacity(0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${g.score} pts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isBest ? const Color(0xFFFF9100) : AppColors.textDark)),
                ),
              ]),
            );
          }),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }

  static String _shortMonth(int m) {
    const s = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return s[m - 1];
  }
  static String _fullDate(DateTime d) {
    const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${ms[d.month - 1]} ${d.day}, ${d.year}';
  }
  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  WEEK TAB  — 7 horizontal progress bars with dates
// ════════════════════════════════════════════════════════════════════════════

class _WeekTab extends StatelessWidget {
  final ScoreController ctrl;
  const _WeekTab({required this.ctrl});

  // All computations delegated to ScoreController computed getters.
  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(children: [
      _PeriodNav(
        label: ctrl.selectedWeekLabel,
        onPrev: ctrl.prevWeek,
        onNext: ctrl.canGoNextWeek ? ctrl.nextWeek : null,
        gradient: const [Color(0xFF43A047), Color(0xFF81C784)],
        onLabelTap: () => _showWeekPicker(context, ctrl),
      ),
      if (!ctrl.isCurrentWeek)
        _ResetChip(
          label: 'Reset to This Week',
          color: const Color(0xFF43A047),
          onTap: () => ctrl.setWeekForDate(DateTime.now()),
        ),
      if (ctrl.weekAllEmpty)
        Expanded(child: _EmptyState(showPlayButton: !ctrl.canGoNextWeek))
      else
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: List.generate(ctrl.weekEntries.length, (i) =>
              _DayProgressRow(
                entry: ctrl.weekEntries[i],
                index: i,
                maxScore: ctrl.weekMaxScore,
              ),
            ),
          ),
        ),
    ]));
  }
}

// ── Single day progress bar row ───────────────────────────────────────────────

class _DayProgressRow extends StatefulWidget {
  final WeekDayEntry entry;
  final int index;
  final int maxScore;
  const _DayProgressRow({required this.entry, required this.index, required this.maxScore});

  @override
  State<_DayProgressRow> createState() => _DayProgressRowState();
}

class _DayProgressRowState extends State<_DayProgressRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_DayProgressRow old) {
    super.didUpdateWidget(old);
    if (old.entry.totalScore != widget.entry.totalScore) _ctrl.forward(from: 0);
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final color = _kBarColors[widget.index % _kBarColors.length];
    final ratio = widget.maxScore == 0 ? 0.0 : (e.totalScore / widget.maxScore).clamp(0.0, 1.0);
    final parts = e.dayLabel.split(' '); // ['Thu', '4']
    final dayName = parts[0];
    final dayNum = parts.length > 1 ? parts[1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: e.isToday ? color.withOpacity(0.60) : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: [BoxShadow(
          color: e.isToday ? color.withOpacity(0.18) : Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Row(children: [
        // Day label
        SizedBox(
          width: 42,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(dayName,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: e.isToday ? color : AppColors.textMedium)),
            Text(dayNum,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: e.isToday ? color : AppColors.textDark, height: 1.0)),
            if (e.isToday)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: const Text('Today', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        // Progress bar
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final fill = ratio * _anim.value;
                return Stack(children: [
                  // Track
                  Container(
                    height: 32, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Fill
                  if (fill > 0)
                    FractionallySizedBox(
                      widthFactor: fill,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.90), color],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: e.isToday
                              ? [BoxShadow(color: color.withOpacity(0.40), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                      ),
                    ),
                  // Games text inside bar
                  if (e.hasData)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${e.gamesPlayed} game${e.gamesPlayed == 1 ? "" : "s"}',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: fill > 0.3 ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ]);
              },
            ),
            if (e.hasData) ...[
              const SizedBox(height: 4),
              Text('🏅 Best ${e.bestScore} pts',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        // Score
        SizedBox(
          width: 52,
          child: e.hasData
              ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${e.totalScore}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1.0)),
                  const Text('pts', style: TextStyle(fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                ])
              : Icon(Icons.lock_clock_rounded, color: Colors.grey.shade300, size: 20),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MONTH TAB  — year nav + 12 monthly progress bars (no calendar grid)
// ════════════════════════════════════════════════════════════════════════════

class _MonthTab extends StatelessWidget {
  final ScoreController ctrl;
  const _MonthTab({required this.ctrl});

  static const _monthNames = ['Jan','Feb','Mar','Apr','May','Jun',
                               'Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _monthColors = [
    Color(0xFF4FC3F7), Color(0xFF81C784), Color(0xFFFFD54F),
    Color(0xFFFF8A65), Color(0xFFCE93D8), Color(0xFFFF6B9D),
    Color(0xFF64B5F6), Color(0xFF4DB6AC), Color(0xFFE57373),
    Color(0xFF7986CB), Color(0xFFA5D6A7), Color(0xFF90CAF9),
  ];

  // All computations delegated to ScoreController computed getters.
  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(children: [
      _YearNav(
        year: ctrl.selectedYear.value,
        canNext: ctrl.selectedYear.value < DateTime.now().year,
        onPrev: () => ctrl.setMonthYear(1, ctrl.selectedYear.value - 1),
        onNext: () => ctrl.setMonthYear(1, ctrl.selectedYear.value + 1),
        onTap: () => _showYearPicker(context, ctrl),
      ),
      if (!ctrl.isCurrentMonthPeriod)
        _ResetChip(
          label: 'Reset to This Month',
          color: const Color(0xFF9C27B0),
          onTap: () => ctrl.setMonthYear(DateTime.now().month, DateTime.now().year),
        ),
      if (!ctrl.selectedYearHasData)
        Expanded(child: _EmptyState(showPlayButton: ctrl.selectedYear.value == DateTime.now().year))
      else
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: List.generate(12, (i) {
              final month = i + 1;
              return _MonthProgressRow(
                month: month,
                monthName: _monthNames[i],
                color: _monthColors[i],
                score: ctrl.monthlyTotalsForSelectedYear[month] ?? 0,
                maxScore: ctrl.monthlyMaxScore,
                isCurrent: ctrl.selectedYear.value == DateTime.now().year && month == DateTime.now().month,
                isSelected: month == ctrl.selectedMonth.value,
                isFuture: ctrl.selectedYear.value == DateTime.now().year && month > DateTime.now().month,
                onTap: (ctrl.selectedYear.value == DateTime.now().year && month > DateTime.now().month)
                    ? null
                    : () => ctrl.setMonthYear(month, ctrl.selectedYear.value),
              );
            }),
          ),
        ),
    ]));
  }
}

// ── Year navigator bar ────────────────────────────────────────────────────────

class _YearNav extends StatelessWidget {
  final int year;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  const _YearNav({required this.year, required this.canNext, required this.onPrev,
      required this.onNext, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gradient = [Color(0xFF9C27B0), Color(0xFFCE93D8)];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev, gradient: gradient),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$year',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: gradient).createShader(b),
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.white),
              ),
            ]),
          ),
        ),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: canNext ? onNext : null,
          gradient: canNext ? gradient : [Colors.grey.shade300, Colors.grey.shade300],
        ),
      ]),
    );
  }
}

// ── Single month progress bar row ─────────────────────────────────────────────

class _MonthProgressRow extends StatefulWidget {
  final int month;
  final String monthName;
  final Color color;
  final int score;
  final int maxScore;
  final bool isCurrent;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback? onTap;
  const _MonthProgressRow({
    required this.month, required this.monthName, required this.color,
    required this.score, required this.maxScore, required this.isCurrent,
    required this.isSelected, required this.isFuture, required this.onTap,
  });

  @override
  State<_MonthProgressRow> createState() => _MonthProgressRowState();
}

class _MonthProgressRowState extends State<_MonthProgressRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_MonthProgressRow old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) _ctrl.forward(from: 0);
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    final ratio = widget.maxScore == 0 ? 0.0 : (widget.score / widget.maxScore).clamp(0.0, 1.0);
    final color = widget.isFuture ? Colors.grey.shade300 : widget.color;
    final isHighlighted = widget.isCurrent || widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted ? color.withOpacity(0.65) : Colors.transparent,
            width: isHighlighted ? 2.0 : 0,
          ),
          boxShadow: [BoxShadow(
            color: isHighlighted ? color.withOpacity(0.20) : Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Row(children: [
          // Month name badge
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: widget.isFuture || widget.score == 0
                  ? null
                  : LinearGradient(colors: [color, color.withOpacity(0.70)]),
              color: widget.isFuture || widget.score == 0 ? Colors.grey.shade100 : null,
              borderRadius: BorderRadius.circular(13),
              boxShadow: !widget.isFuture && widget.score > 0
                  ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Center(
              child: Text(widget.monthName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                      color: widget.score > 0 && !widget.isFuture ? Colors.white : Colors.grey.shade400)),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.monthName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: widget.isFuture ? Colors.grey.shade400 : AppColors.textDark)),
                const SizedBox(width: 6),
                if (widget.isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    child: const Text('NOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                  ),
                if (widget.isSelected && !widget.isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.40)),
                    ),
                    child: Text('Selected', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
                  ),
              ]),
              const SizedBox(height: 5),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) {
                  final fill = ratio * _anim.value;
                  return Stack(children: [
                    Container(
                      height: 28, width: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.isFuture ? Colors.grey.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    if (fill > 0)
                      FractionallySizedBox(
                        widthFactor: fill,
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withOpacity(0.85), color]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isHighlighted
                                ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                        ),
                      ),
                    if (widget.score > 0)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${widget.score} pts',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: fill > 0.35 ? Colors.white : color)),
                          ),
                        ),
                      ),
                  ]);
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Year picker dialog ────────────────────────────────────────────────────────

void _showYearPicker(BuildContext context, ScoreController ctrl) {
  final now = DateTime.now();
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select Year',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
            children: List.generate(now.year - 2019, (i) {
              final year = 2020 + i;
              final isSel = year == ctrl.selectedYear.value;
              return GestureDetector(
                onTap: () {
                  ctrl.setMonthYear(
                    year == now.year ? now.month : ctrl.selectedMonth.value,
                    year,
                  );
                  Navigator.of(context).pop();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72, height: 48,
                  decoration: BoxDecoration(
                    gradient: isSel
                        ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFCE93D8)])
                        : null,
                    color: isSel ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSel
                        ? [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.35), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: Text('$year',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : AppColors.textDark)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          ),
        ]),
      ),
    ),
  );
}

// ── Shared: Day detail header + game tile (used in month tap-through) ─────────

class _DayDetailHeader extends StatelessWidget {
  final DateSummary summary;
  final VoidCallback onBack;
  final Color accent;
  const _DayDetailHeader({required this.summary, required this.onBack, required this.accent});

  @override
  Widget build(BuildContext context) {
    const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
          child: Text(
            '${ms[summary.date.month-1]} ${summary.date.day} — ${summary.totalScore} pts',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ),
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Text('← Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
          ),
        ),
      ]),
    );
  }
}

class _GameTile extends StatelessWidget {
  final ScoreModel game;
  final int index;
  final bool isBest;
  final Color accent;
  const _GameTile({required this.game, required this.index, required this.isBest, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isBest ? const Color(0xFFFF9100).withOpacity(0.40) : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isBest ? const Color(0xFFFF9100).withOpacity(0.12) : accent.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(isBest ? '⭐' : '$index',
                style: TextStyle(fontSize: isBest ? 18 : 13, fontWeight: FontWeight.w800,
                    color: isBest ? const Color(0xFFFF9100) : accent)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Game $index  •  ${_hhmm(game.playedAt)}  •  Lvl ${game.level}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isBest ? const Color(0xFFFF9100).withOpacity(0.12) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${game.score} pts',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: isBest ? const Color(0xFFFF9100) : AppColors.textDark)),
        ),
      ]),
    );
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ════════════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════

// Draws a simple soap bubble — works on all Android versions (no emoji needed).
class _EmptyBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;
    final c  = Offset(cx, cy);
    final rect = Rect.fromCircle(center: c, radius: r);

    // Soft shadow
    canvas.drawCircle(
      Offset(cx + r * 0.06, cy + r * 0.10), r,
      Paint()
        ..color = const Color(0xFF4FC3F7).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Translucent body
    canvas.drawCircle(c, r,
        Paint()..color = const Color(0xFFB3E5FC).withOpacity(0.28));

    // Iridescent fill
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.20, -0.40), radius: 0.80,
        colors: [
          Colors.cyanAccent.withOpacity(0.22),
          Colors.blue.withOpacity(0.14),
          Colors.purple.withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect));

    // Coloured rim
    canvas.drawCircle(c, r - r * 0.06,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..shader = SweepGradient(
          colors: [
            Colors.white.withOpacity(0.90),
            const Color(0xFF4FC3F7).withOpacity(0.85),
            Colors.cyanAccent.withOpacity(0.80),
            Colors.purpleAccent.withOpacity(0.75),
            Colors.pinkAccent.withOpacity(0.70),
            Colors.white.withOpacity(0.90),
          ],
        ).createShader(rect));

    // Top-left highlight
    final hlRect = Rect.fromCenter(
      center: Offset(cx - r * 0.22, cy - r * 0.28),
      width: r * 0.70, height: r * 0.44,
    );
    canvas.drawOval(hlRect, Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.90), Colors.transparent],
      ).createShader(hlRect));

    // Small sparkle
    canvas.drawCircle(
      Offset(cx + r * 0.14, cy - r * 0.52), r * 0.09,
      Paint()..color = Colors.white.withOpacity(0.88),
    );
  }

  @override
  bool shouldRepaint(_EmptyBubblePainter _) => false;
}

class _EmptyState extends StatefulWidget {
  final bool showPlayButton;
  const _EmptyState({this.showPlayButton = false});
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  static const _bubbleColors = [
    Color(0xFF4FC3F7), Color(0xFF7C4DFF), Color(0xFFFF6B9D),
    Color(0xFF43E97B), Color(0xFFFFD54F), Color(0xFF4FC3F7),
  ];

  Color get _iconColor {
    final t = _ctrl.value;
    final total = _bubbleColors.length - 1;
    final idx = (t * total).floor().clamp(0, total - 1);
    final frac = (t * total) - idx;
    return Color.lerp(_bubbleColors[idx], _bubbleColors[idx + 1], frac)!;
  }

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _float = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );
  }

  void _onDispose() => _ctrl.dispose();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _float.value),
                child: Icon(
                  Icons.bubble_chart_rounded,
                  size: 84,
                  color: _iconColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('No Scores Yet!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Play a game to see your progress 🎉',
                style: TextStyle(fontSize: 15, color: AppColors.textMedium)),
            if (widget.showPlayButton) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.game),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: const Color(0xFF43E97B).withOpacity(0.40), blurRadius: 16, offset: const Offset(0, 5))],
                  ),
                  child: const Text('🚀  PLAY NOW',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  CALENDAR SHEET (date picker)
// ════════════════════════════════════════════════════════════════════════════

// ── Reset chip ────────────────────────────────────────────────────────────────

class _ResetChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ResetChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      ),
    );
  }
}

// ── Week picker — always snaps to Mon–Sun, max 7 days ────────────────────────

void _showWeekPicker(BuildContext context, ScoreController ctrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WeekPickerSheet(
      initialWeekStart: ctrl.selectedWeekStart.value,
      onPicked: (monday) => ctrl.setWeekForDate(monday),
    ),
  );
}

class _WeekPickerSheet extends StatefulWidget {
  final DateTime initialWeekStart;
  final void Function(DateTime monday) onPicked;
  const _WeekPickerSheet({required this.initialWeekStart, required this.onPicked});

  @override
  State<_WeekPickerSheet> createState() => _WeekPickerSheetState();
}

class _WeekPickerSheetState extends State<_WeekPickerSheet> {
  static const _primary = Color(0xFF43A047);
  static const _primaryLight = Color(0xFFDCEDC8);
  static const _ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  late DateRangePickerController _ctrl;
  late DateTime _monday;   // always Monday
  late DateTime _sunday;   // always Sunday = monday + 6

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _monday = widget.initialWeekStart;
    _sunday = _monday.add(const Duration(days: 6));
    _ctrl = DateRangePickerController();
    _ctrl.selectedRange = PickerDateRange(_monday, _sunday);
    _ctrl.displayDate = _monday;
  }

  void _onDispose() => _ctrl.dispose();

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  // Snap any tapped date to its Monday–Sunday week.
  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    DateTime? tapped;
    final val = args.value;
    if (val is DateTime) {
      tapped = _norm(val);
    } else if (val is PickerDateRange && val.startDate != null) {
      tapped = _norm(val.startDate!);
    }
    if (tapped == null) return;

    // Compute Monday of the tapped date's week.
    final mon = tapped.subtract(Duration(days: (tapped.weekday - 1) % 7));
    final sun = mon.add(const Duration(days: 6));
    // Clamp sunday to today if it would be in the future.
    final today = _norm(DateTime.now());
    final clampedSun = sun.isAfter(today) ? today : sun;

    setState(() {
      _monday = mon;
      _sunday = clampedSun;
    });
    // Update the picker to show the full week highlighted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.selectedRange = PickerDateRange(_monday, _sunday);
    });
  }

  String _fmt(DateTime d) => '${_ms[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            // Header
            Row(children: [
              const Text('Select Week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(8)),
                child: const Text('Max 7 days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600)),
              ),
            ]),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft,
                child: Text('Tap any day — its full Mon–Sun week is selected',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            const SizedBox(height: 14),
            // Calendar
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SfDateRangePicker(
                controller: _ctrl,
                selectionMode: DateRangePickerSelectionMode.range,
                minDate: DateTime(2020),
                maxDate: DateTime.now(),
                allowViewNavigation: true,
                showNavigationArrow: true,
                navigationDirection: DateRangePickerNavigationDirection.horizontal,
                navigationMode: DateRangePickerNavigationMode.snap,
                backgroundColor: Colors.white,
                headerStyle: const DateRangePickerHeaderStyle(
                  textAlign: TextAlign.center,
                  backgroundColor: _primary,
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                monthViewSettings: DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1,
                  viewHeaderHeight: 36,
                  viewHeaderStyle: const DateRangePickerViewHeaderStyle(
                    backgroundColor: Color(0xFFF1F8E9),
                    textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                ),
                selectionColor: _primary,
                startRangeSelectionColor: _primary,
                endRangeSelectionColor: _primary,
                rangeSelectionColor: _primaryLight,
                rangeTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
                selectionTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                todayHighlightColor: _primary,
                monthCellStyle: DateRangePickerMonthCellStyle(
                  todayTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
                  disabledDatesTextStyle: TextStyle(color: Colors.grey.shade300),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
                  leadingDatesTextStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
                onSelectionChanged: _onSelectionChanged,
              ),
            ),
            const SizedBox(height: 10),
            // Selected range preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withOpacity(0.35)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.date_range_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text(
                  '${_fmt(_monday)}  →  ${_fmt(_sunday)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Apply button
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _primary.withOpacity(0.40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onPicked(_monday);
                },
                child: const Text('Apply Week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

void _showCalendarSheet(BuildContext context, {
  DateTime? initialStart, DateTime? initialEnd,
  required void Function(DateTime start, DateTime? end) onPicked,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CalendarSheet(initialStart: initialStart, initialEnd: initialEnd, onPicked: onPicked),
  );
}

void _showDateCalendarPicker(BuildContext context, ScoreController ctrl) {
  final filter = ctrl.dateRangeFilter.value;
  _showCalendarSheet(context, initialStart: filter?.start, initialEnd: filter?.end,
      onPicked: (start, end) => ctrl.setDateRangeFilter(DateTimeRange(start: start, end: end ?? start)));
}

Future<void> _pickWeekByDate(BuildContext context, ScoreController ctrl) async {
  _showCalendarSheet(context, initialStart: ctrl.selectedWeekStart.value,
      onPicked: (start, _) => ctrl.setWeekForDate(start));
}

void _pickMonth(BuildContext context, ScoreController ctrl) {
  _showCalendarSheet(context,
      initialStart: DateTime(ctrl.selectedYear.value, ctrl.selectedMonth.value, 1),
      onPicked: (start, _) => ctrl.setMonthYear(start.month, start.year));
}

class _CalendarSheet extends StatelessWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime? end) onPicked;
  const _CalendarSheet({this.initialStart, this.initialEnd, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft,
                child: Text('Tap once to pick · Tap twice for a range', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            const SizedBox(height: 16),
            _AppCalendar(
              initialStart: initialStart,
              initialEnd: initialEnd,
              onApply: (start, end) { Navigator.of(context).pop(); onPicked(start, end); },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _AppCalendar extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime? end) onApply;
  const _AppCalendar({this.initialStart, this.initialEnd, required this.onApply});
  @override
  State<_AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<_AppCalendar> {
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFDEF0FB);
  static const _monthShorts = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  late DateRangePickerController _ctrl;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() { super.initState(); _onInit(); }

  @override
  void dispose() { _onDispose(); super.dispose(); }

  void _onInit() {
    _ctrl = DateRangePickerController();
    _start = widget.initialStart != null ? _norm(widget.initialStart!) : null;
    _end = widget.initialEnd != null ? _norm(widget.initialEnd!) : null;
    if (_start != null && _end != null && _same(_start!, _end!)) _end = null;
    if (_start != null && _end != null) _ctrl.selectedRange = PickerDateRange(_start, _end);
    else if (_start != null) _ctrl.selectedDate = _start;
    _ctrl.displayDate = _start ?? DateTime.now();
  }

  void _onDispose() => _ctrl.dispose();

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      final val = args.value;
      if (val is DateTime) { _start = _norm(val); _end = null; }
      else if (val is PickerDateRange) {
        _start = val.startDate != null ? _norm(val.startDate!) : null;
        _end = val.endDate != null ? _norm(val.endDate!) : null;
        if (_start != null && _end != null && _same(_start!, _end!)) _end = null;
      }
    });
  }

  String _fmt(DateTime d) => '${_monthShorts[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDateRangePicker(
          controller: _ctrl,
          selectionMode: DateRangePickerSelectionMode.extendableRange,
          minDate: DateTime(2020),
          maxDate: DateTime.now(),
          allowViewNavigation: true,
          showNavigationArrow: true,
          navigationDirection: DateRangePickerNavigationDirection.horizontal,
          navigationMode: DateRangePickerNavigationMode.snap,
          backgroundColor: Colors.white,
          headerStyle: const DateRangePickerHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: _primary,
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          monthViewSettings: DateRangePickerMonthViewSettings(
            firstDayOfWeek: 1,
            viewHeaderHeight: 36,
            viewHeaderStyle: const DateRangePickerViewHeaderStyle(
              backgroundColor: Color(0xFFF0F4FF),
              textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
          ),
          selectionColor: _primary,
          startRangeSelectionColor: _primary,
          endRangeSelectionColor: _primary,
          rangeSelectionColor: _primaryLight,
          rangeTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
          selectionTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          todayHighlightColor: _primary,
          monthCellStyle: DateRangePickerMonthCellStyle(
            todayTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
            disabledDatesTextStyle: TextStyle(color: Colors.grey.shade300),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
            leadingDatesTextStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          onSelectionChanged: _onSelectionChanged,
        ),
      ),
      const SizedBox(height: 8),
      // Preview chip
      _start == null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.touch_app_rounded, size: 15, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text('Tap a date to select', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              ]),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _primary.withOpacity(0.30))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.event_rounded, size: 15, color: _primary),
                const SizedBox(width: 8),
                Text(
                  _end == null ? _fmt(_start!) : '${_fmt(_start!)}  →  ${_fmt(_end!)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary),
                ),
              ]),
            ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _start != null ? _primary : Colors.grey.shade300,
            foregroundColor: Colors.white,
            elevation: _start != null ? 2 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _start != null ? () => widget.onApply(_start!, _end) : null,
          child: const Text('Apply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDate(DateTime d) {
  const s = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${s[d.month - 1]} ${d.day}';
}
