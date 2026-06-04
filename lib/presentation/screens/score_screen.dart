import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/score_model.dart';
import '../controllers/score_controller.dart';

// ════════════════════════════════════════════════════════════════════════════
//  SKY BUBBLE BURST — LEADERBOARD (White Theme)
// ════════════════════════════════════════════════════════════════════════════

class ScoreScreen extends GetView<ScoreController> {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: Get.back),
            Obx(() => controller.latestAwards.isEmpty
                ? const SizedBox.shrink()
                : _LatestAwardsSection(awards: controller.latestAwards)),
            _TabStrip(controller: controller),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                switch (controller.selectedTab.value) {
                  case 0:
                    return _DailyPage(entries: controller.dailyEntries);
                  default:
                    return _CalendarPage(blocks: controller.monthBlocks);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x334FC3F7), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
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
            child: Text(
              '🏆  Leaderboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Text('🫧', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}

// ─── Latest Awards ────────────────────────────────────────────────────────────

class _LatestAwardsSection extends StatelessWidget {
  final List<ScoreModel> awards;
  const _LatestAwardsSection({required this.awards});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Latest Awards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(awards.length, (i) {
              final cfgs = [
                _AwardCfg('🥇', [const Color(0xFFFFD700), const Color(0xFFFF8C00)], 'Champion'),
                _AwardCfg('🥈', [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)], '2nd Place'),
                _AwardCfg('🥉', [const Color(0xFFFFCCBC), const Color(0xFFFF7043)], '3rd Place'),
              ];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < awards.length - 1 ? 8 : 0),
                  child: _AwardCard(cfg: cfgs[i], score: awards[i], isFirst: i == 0),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AwardCfg {
  final String medal;
  final List<Color> colors;
  final String title;
  _AwardCfg(this.medal, this.colors, this.title);
}

class _AwardCard extends StatefulWidget {
  final _AwardCfg cfg;
  final ScoreModel score;
  final bool isFirst;
  const _AwardCard({required this.cfg, required this.score, required this.isFirst});

  @override
  State<_AwardCard> createState() => _AwardCardState();
}

class _AwardCardState extends State<_AwardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.cfg.colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.cfg.colors.last.withOpacity(
                  widget.isFirst ? _pulse.value * 0.5 : 0.2),
              blurRadius: widget.isFirst ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.cfg.medal, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _ago(widget.score.playedAt),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.score.score}',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
            ),
            Text(
              'pts • Lvl ${widget.score.level}',
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

// ─── Tab Strip ────────────────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final ScoreController controller;
  const _TabStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            _TabItem(label: 'Today', emoji: '📅', index: 0, ctrl: controller),
            _TabItem(label: 'Calendar', emoji: '🗓', index: 1, ctrl: controller),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final String emoji;
  final int index;
  final ScoreController ctrl;
  const _TabItem({required this.label, required this.emoji, required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sel = ctrl.selectedTab.value == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => ctrl.onTabChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: sel
                  ? const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)])
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: sel
                  ? [BoxShadow(color: const Color(0xFF4FC3F7).withOpacity(0.4), blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: Text(
                '$emoji  $label',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? Colors.white : AppColors.textMedium,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ════════════════════════════  DAILY PAGE  ════════════════════════════════════

class _DailyPage extends StatelessWidget {
  final List<DailyEntry> entries;
  const _DailyPage({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: entries.length,
      itemBuilder: (_, i) => _DailyCard(rank: i + 1, entry: entries[i]),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final int rank;
  final DailyEntry entry;
  const _DailyCard({required this.rank, required this.entry});

  static const _rankGrads = [
    [Color(0xFFFFD700), Color(0xFFFF8C00)],
    [Color(0xFFB0BEC5), Color(0xFF78909C)],
    [Color(0xFFFF8A65), Color(0xFFD84315)],
  ];

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final emoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
    final borderColor = entry.isLatestAward
        ? AppColors.scoreGold
        : isTop3
            ? _rankGrads[rank - 1][0]
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: entry.isLatestAward
                ? AppColors.scoreGold.withOpacity(0.18)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isTop3
                  ? LinearGradient(colors: _rankGrads[rank - 1])
                  : null,
              color: isTop3 ? null : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: emoji != null
                  ? Text(emoji, style: const TextStyle(fontSize: 22))
                  : Text('$rank',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textMedium)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.levelGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level ${entry.score.level}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.levelGreen),
                      ),
                    ),
                    if (entry.isLatestAward) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scoreGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✨ NEW',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w900,
                              color: AppColors.scoreGold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _hhmm(entry.score.playedAt),
                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score.score}',
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900,
                    color: AppColors.textDark, height: 1.0),
              ),
              const Text('pts',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textMedium)),
            ],
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')} : ${dt.minute.toString().padLeft(2, '0')}';
}

// ════════════════════════════  CALENDAR PAGE  ═════════════════════════════════

class _CalendarPage extends StatelessWidget {
  final List<MonthBlock> blocks;
  const _CalendarPage({required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: blocks.length,
      itemBuilder: (_, i) => _MonthBlockCard(block: blocks[i]),
    );
  }
}

class _MonthBlockCard extends StatefulWidget {
  final MonthBlock block;
  const _MonthBlockCard({required this.block});

  @override
  State<_MonthBlockCard> createState() => _MonthBlockCardState();
}

class _MonthBlockCardState extends State<_MonthBlockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expand;
  bool _open = true;

  @override
  void initState() {
    super.initState();
    _open = widget.block.isCurrentMonth;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300),
        value: _open ? 1.0 : 0.0);
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: widget.block.isCurrentMonth
            ? Border.all(color: c, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(widget.block.isCurrentMonth ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Month header
            GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.withOpacity(0.18), c.withOpacity(0.06)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c, c.withOpacity(0.65)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 10)],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.block.month}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.block.monthLabel,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900,
                                    color: AppColors.textDark),
                              ),
                              if (widget.block.isCurrentMonth) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: c, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('NOW',
                                      style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w900,
                                          color: Colors.white, letterSpacing: 1)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              _Chip('🎮 ${widget.block.gamesPlayed}', c),
                              _Chip('⭐ Best ${widget.block.bestScore}', c),
                              _Chip('📊 ${widget.block.totalScore} total', c),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: c, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            // Week segments
            SizeTransition(
              sizeFactor: _expand,
              child: Column(
                children: widget.block.weeks
                    .map((w) => _WeekTile(week: w, accent: c,
                            maxScore: widget.block.totalScore > 0 ? widget.block.totalScore : 1))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─── Week Tile ────────────────────────────────────────────────────────────────

class _WeekTile extends StatelessWidget {
  final WeekSegment week;
  final Color accent;
  final int maxScore;
  const _WeekTile({required this.week, required this.accent, required this.maxScore});

  @override
  Widget build(BuildContext context) {
    final progress = maxScore > 0 ? (week.totalScore / maxScore).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: week.isCurrentWeek ? accent.withOpacity(0.07) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: week.isCurrentWeek ? accent.withOpacity(0.5) : Colors.grey.shade200,
          width: week.isCurrentWeek ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Week badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: week.hasData
                      ? LinearGradient(colors: [accent, accent.withOpacity(0.65)])
                      : null,
                  color: week.hasData ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'W${week.weekNum}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: week.hasData ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          week.rangeLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: week.isCurrentWeek
                                ? AppColors.textDark
                                : AppColors.textMedium,
                          ),
                        ),
                        if (week.isCurrentWeek) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: accent, borderRadius: BorderRadius.circular(6)),
                            child: const Text('THIS WEEK',
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w900,
                                    color: Colors.white, letterSpacing: 0.8)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      week.hasData
                          ? '${week.gamesPlayed} games  •  Best ${week.bestScore}'
                          : 'No games played yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: week.hasData ? AppColors.textMedium : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              if (week.hasData)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${week.totalScore}',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900,
                          color: accent, height: 1.0),
                    ),
                    const Text('total',
                        style: TextStyle(fontSize: 12, color: AppColors.textMedium,
                            fontWeight: FontWeight.w600)),
                  ],
                )
              else
                Icon(Icons.lock_clock_rounded, color: Colors.grey.shade300, size: 26),
            ],
          ),
          if (week.hasData) ...[
            const SizedBox(height: 10),
            _AnimatedBar(progress: progress, color: accent),
          ],
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final double progress;
  final Color color;
  const _AnimatedBar({required this.progress, required this.color});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 9,
          child: Stack(
            children: [
              Container(color: Colors.grey.shade100),
              FractionallySizedBox(
                widthFactor: _anim.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.6)]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 4),
                    ],
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -12, end: 12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _float.value),
              child: const Text('🫧', style: TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Scores Yet!',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          const Text(
            'Play a game to earn awards 🎉',
            style: TextStyle(fontSize: 16, color: AppColors.textMedium),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: Get.back,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.startGradientMid, AppColors.startGradientEnd]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.startGradientMid.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: const Text(
                '🚀  PLAY NOW',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
