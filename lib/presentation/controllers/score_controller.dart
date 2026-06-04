import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/score_model.dart';
import '../../domain/usecases/score_usecases.dart';

// ─── View-models ──────────────────────────────────────────────────────────────

class DailyEntry {
  final ScoreModel score;
  final bool isLatestAward;
  DailyEntry({required this.score, required this.isLatestAward});
}

/// A week range inside a month (e.g. May 1–7)
class WeekSegment {
  final int weekNum;       // 1-5
  final String rangeLabel; // "May 1 – 7"
  final DateTime start;
  final DateTime end;
  final int totalScore;
  final int bestScore;
  final int gamesPlayed;
  final bool isCurrentWeek;

  WeekSegment({
    required this.weekNum,
    required this.rangeLabel,
    required this.start,
    required this.end,
    required this.totalScore,
    required this.bestScore,
    required this.gamesPlayed,
    required this.isCurrentWeek,
  });

  bool get hasData => gamesPlayed > 0;
}

/// A calendar month that has at least one week to show
class MonthBlock {
  final String monthLabel;   // "May 2025"
  final int year;
  final int month;
  final int totalScore;
  final int bestScore;
  final int gamesPlayed;
  final List<WeekSegment> weeks;
  final Color accentColor;
  final bool isCurrentMonth;

  MonthBlock({
    required this.monthLabel,
    required this.year,
    required this.month,
    required this.totalScore,
    required this.bestScore,
    required this.gamesPlayed,
    required this.weeks,
    required this.accentColor,
    required this.isCurrentMonth,
  });
}

// ─── Controller ───────────────────────────────────────────────────────────────

class ScoreController extends GetxController {
  final GetScoresUseCase _getScores;
  ScoreController(this._getScores);

  final RxList<DailyEntry> dailyEntries = <DailyEntry>[].obs;
  final RxList<WeekSegment> currentWeekDays = <WeekSegment>[].obs;
  final RxList<MonthBlock> monthBlocks = <MonthBlock>[].obs;
  final RxList<ScoreModel> latestAwards = <ScoreModel>[].obs;
  final RxInt selectedTab = 0.obs;

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  static const _monthShorts = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  static const _accentColors = [
    Color(0xFF4FC3F7), Color(0xFFBA68C8), Color(0xFF81C784), Color(0xFFFF8A65),
    Color(0xFFFF6B9D), Color(0xFF4DB6AC), Color(0xFFFFD54F), Color(0xFFE57373),
    Color(0xFF7986CB), Color(0xFF64B5F6), Color(0xFFA5D6A7), Color(0xFF90CAF9),
  ];

  @override
  void onReady() {
    super.onReady();
    loadScores();
  }

  void loadScores() {
    final all = _getScores();
    _buildLatestAwards(all);
    _buildDaily(all);
    _buildMonthBlocks(all);   // used for "Weekly" tab (calendar grouping)
  }

  void onTabChanged(int index) => selectedTab.value = index;

  // ── Latest 3 most recent games ──────────────────────────────────────────

  void _buildLatestAwards(List<ScoreModel> all) {
    final sorted = [...all]..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    latestAwards.value = sorted.take(3).toList();
  }

  // ── Today's individual scores ───────────────────────────────────────────

  void _buildDaily(List<ScoreModel> all) {
    final todayStart = _dayStart(DateTime.now());
    final latestTimes = latestAwards.map((s) => s.playedAt).toSet();

    final today = all.where((s) => s.playedAt.isAfter(todayStart)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    dailyEntries.value = today
        .map((s) => DailyEntry(
              score: s,
              isLatestAward: latestTimes.contains(s.playedAt),
            ))
        .toList();
  }

  // ── Calendar weeks grouped by month ────────────────────────────────────
  // Logic:
  //  • Group all scores by calendar month.
  //  • For each month split into week ranges: 1-7, 8-14, 15-21, 22-28, 29-end.
  //  • Show a week segment if:  has data  OR  it is the current week.
  //  • Sort months newest-first.

  void _buildMonthBlocks(List<ScoreModel> all) {
    final now = DateTime.now();
    final grouped = <String, List<ScoreModel>>{};

    for (final s in all) {
      final key =
          '${s.playedAt.year}-${s.playedAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    // Always include current month even if no scores yet
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(currentKey, () => []);

    final blocks = <MonthBlock>[];

    for (final entry in grouped.entries) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final scores = entry.value;

      final weeks = _buildWeekSegments(year, month, scores, now);
      if (weeks.isEmpty) continue;

      final isCurrentMonth = year == now.year && month == now.month;
      final accent = _accentColors[(month - 1) % _accentColors.length];

      blocks.add(MonthBlock(
        monthLabel: '${_monthNames[month - 1]} $year',
        year: year,
        month: month,
        totalScore: scores.fold(0, (s, e) => s + e.score),
        bestScore: scores.isEmpty ? 0 : scores.map((s) => s.score).reduce(_max),
        gamesPlayed: scores.length,
        weeks: weeks,
        accentColor: accent,
        isCurrentMonth: isCurrentMonth,
      ));
    }

    blocks.sort((a, b) {
      final y = b.year.compareTo(a.year);
      return y != 0 ? y : b.month.compareTo(a.month);
    });

    monthBlocks.value = blocks;
  }

  List<WeekSegment> _buildWeekSegments(
    int year,
    int month,
    List<ScoreModel> scores,
    DateTime now,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final short = _monthShorts[month - 1];

    // Fixed week ranges within a month
    final ranges = <List<int>>[
      [1, 7],
      [8, 14],
      [15, 21],
      [22, 28],
      if (daysInMonth > 28) [29, daysInMonth],
    ];

    final segments = <WeekSegment>[];

    for (int i = 0; i < ranges.length; i++) {
      final startDay = ranges[i][0];
      final endDay = ranges[i][1].clamp(1, daysInMonth);
      if (startDay > daysInMonth) continue;

      final startDate = DateTime(year, month, startDay);
      final endDate = DateTime(year, month, endDay, 23, 59, 59);

      final isCurrentWeek =
          now.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              now.isBefore(endDate.add(const Duration(seconds: 1)));

      final weekScores = scores
          .where((s) =>
              !s.playedAt.isBefore(startDate) &&
              !s.playedAt.isAfter(endDate))
          .toList();

      // Only include if has data OR it's the current week
      if (weekScores.isEmpty && !isCurrentWeek) continue;

      segments.add(WeekSegment(
        weekNum: i + 1,
        rangeLabel: '$short $startDay – $endDay',
        start: startDate,
        end: endDate,
        totalScore: weekScores.fold(0, (s, e) => s + e.score),
        bestScore: weekScores.isEmpty
            ? 0
            : weekScores.map((s) => s.score).reduce(_max),
        gamesPlayed: weekScores.length,
        isCurrentWeek: isCurrentWeek,
      ));
    }

    return segments;
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  int _max(int a, int b) => a > b ? a : b;
}
