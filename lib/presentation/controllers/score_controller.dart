import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/score_model.dart';
import '../../domain/usecases/score_usecases.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

/// Aggregated summary for a single calendar date (used in Date-tab list).
class DateSummary {
  final DateTime date;
  final int totalScore;
  final int bestScore;
  final int gamesPlayed;
  final List<ScoreModel> games;

  DateSummary({
    required this.date,
    required this.totalScore,
    required this.bestScore,
    required this.gamesPlayed,
    required this.games,
  });
}

/// One bar in the interactive chart.
class BarItem {
  final String label;
  final int value;
  final bool isCurrent;
  BarItem({required this.label, required this.value, this.isCurrent = false});
}

/// A week row in the week-detail list.
class WeekDayEntry {
  final String dayLabel;
  final DateTime date;
  final int totalScore;
  final int gamesPlayed;
  final int bestScore;
  final bool isToday;
  WeekDayEntry({
    required this.dayLabel,
    required this.date,
    required this.totalScore,
    required this.gamesPlayed,
    required this.bestScore,
    required this.isToday,
  });
  bool get hasData => gamesPlayed > 0;
}

/// Light per-day data for the month calendar grid.
class DayCal {
  final int totalScore;
  final int gamesCount;
  const DayCal({required this.totalScore, required this.gamesCount});
}

/// Week segment inside a month view.
class WeekSegment {
  final int weekNum;
  final String rangeLabel;
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

/// Full month data block.
class MonthBlock {
  final String monthLabel;
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

  // ── Global best
  final RxInt globalBest = 0.obs;

  // ── Tab (default: Week)
  final RxInt selectedTab = 1.obs;

  // ── Date tab – all-dates aggregated list
  final RxList<DateSummary> allDateSummaries = <DateSummary>[].obs;
  final Rx<DateTimeRange?> dateRangeFilter = Rx<DateTimeRange?>(null);
  final RxInt expandedDateIndex = (-1).obs;

  // ── Week tab
  final Rx<DateTime> selectedWeekStart = DateTime.now().obs;
  final RxList<BarItem> weekBars = <BarItem>[].obs;
  final RxList<WeekDayEntry> weekEntries = <WeekDayEntry>[].obs;
  final RxInt selectedWeekBar = (-1).obs;

  // ── Month tab
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxList<BarItem> monthBars = <BarItem>[].obs;
  final RxList<MonthBlock> monthBlocks = <MonthBlock>[].obs;
  final RxInt selectedMonthBar = (-1).obs;
  // Per-day data for the calendar grid (key = day-of-month)
  final RxMap<int, DayCal> monthDayMap = <int, DayCal>{}.obs;
  final RxInt selectedCalDay = (-1).obs; // selected day in month calendar

  List<ScoreModel> _all = [];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthShorts = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _dayShorts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _accentColors = [
    Color(0xFF4FC3F7), Color(0xFFBA68C8), Color(0xFF81C784),
    Color(0xFFFF8A65), Color(0xFFFF6B9D), Color(0xFF4DB6AC),
    Color(0xFFFFD54F), Color(0xFFE57373), Color(0xFF7986CB),
    Color(0xFF64B5F6), Color(0xFFA5D6A7), Color(0xFF90CAF9),
  ];

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedWeekStart.value =
        _dayStart(now.subtract(Duration(days: (now.weekday - 1) % 7)));
    loadScores();
  }

  void loadScores() {
    _all = _getScores();
    globalBest.value =
        _all.isEmpty ? 0 : _all.map((s) => s.score).reduce(_max);
    _rebuildAllDates();
    _rebuildWeek();
    _rebuildMonth();
  }

  void onTabChanged(int i) => selectedTab.value = i;

  // ── Date tab ───────────────────────────────────────────────────────────────

  void setDateRangeFilter(DateTimeRange? range) {
    dateRangeFilter.value = range;
    expandedDateIndex.value = -1;
    _rebuildAllDates();
  }

  void clearDateFilter() {
    dateRangeFilter.value = null;
    expandedDateIndex.value = -1;
    _rebuildAllDates();
  }

  void toggleDateExpanded(int index) {
    expandedDateIndex.value = expandedDateIndex.value == index ? -1 : index;
  }

  void _rebuildAllDates() {
    // Group all scores by calendar date
    final map = <String, List<ScoreModel>>{};
    for (final s in _all) {
      final key =
          '${s.playedAt.year}-${s.playedAt.month.toString().padLeft(2, '0')}-${s.playedAt.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(s);
    }

    var summaries = map.entries.map((e) {
      final games = e.value
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt)); // newest first
      final date = DateTime(
          games.first.playedAt.year,
          games.first.playedAt.month,
          games.first.playedAt.day);
      return DateSummary(
        date: date,
        totalScore: games.fold(0, (s, g) => s + g.score),
        bestScore: games.map((g) => g.score).reduce(_max),
        gamesPlayed: games.length,
        games: games,
      );
    }).toList();

    // Apply date range filter
    final filter = dateRangeFilter.value;
    if (filter != null) {
      final fStart = _dayStart(filter.start);
      final fEnd = _dayStart(filter.end).add(const Duration(days: 1));
      summaries = summaries
          .where((s) =>
              !s.date.isBefore(fStart) && s.date.isBefore(fEnd))
          .toList();
    }

    // Newest first
    summaries.sort((a, b) => b.date.compareTo(a.date));
    allDateSummaries.value = summaries;
  }

  // ── Week navigation ────────────────────────────────────────────────────────

  void prevWeek() {
    selectedWeekStart.value =
        selectedWeekStart.value.subtract(const Duration(days: 7));
    selectedWeekBar.value = -1;
    _rebuildWeek();
  }

  void nextWeek() {
    final next = selectedWeekStart.value.add(const Duration(days: 7));
    if (next.isAfter(DateTime.now())) return;
    selectedWeekStart.value = next;
    selectedWeekBar.value = -1;
    _rebuildWeek();
  }

  // Jump to the week that contains [date]
  void setWeekForDate(DateTime date) {
    final d = _dayStart(date);
    selectedWeekStart.value =
        d.subtract(Duration(days: (d.weekday - 1) % 7));
    selectedWeekBar.value = -1;
    _rebuildWeek();
  }

  void _rebuildWeek() {
    final now = DateTime.now();
    final wStart = selectedWeekStart.value;
    final entries = <WeekDayEntry>[];
    final bars = <BarItem>[];

    for (int i = 0; i < 7; i++) {
      final day = wStart.add(Duration(days: i));
      final dayStart = _dayStart(day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final isToday = _sameDay(day, now);

      final dayScores = _all.where((s) {
        final p = s.playedAt;
        return !p.isBefore(dayStart) && p.isBefore(dayEnd);
      }).toList();

      final total = dayScores.fold(0, (s, e) => s + e.score);
      final best =
          dayScores.isEmpty ? 0 : dayScores.map((s) => s.score).reduce(_max);

      entries.add(WeekDayEntry(
        dayLabel: '${_dayShorts[i]} ${day.day}',
        date: day,
        totalScore: total,
        gamesPlayed: dayScores.length,
        bestScore: best,
        isToday: isToday,
      ));

      bars.add(BarItem(
        label: _dayShorts[i].substring(0, 1),
        value: total,
        isCurrent: isToday,
      ));
    }

    weekEntries.value = entries;
    weekBars.value = bars;
  }

  List<WeekDayEntry> get filteredWeekEntries {
    if (selectedWeekBar.value < 0) return weekEntries;
    final i = selectedWeekBar.value;
    if (i < weekEntries.length) return [weekEntries[i]];
    return weekEntries;
  }

  // ── Month navigation ───────────────────────────────────────────────────────

  void prevMonth() {
    int m = selectedMonth.value - 1;
    int y = selectedYear.value;
    if (m < 1) { m = 12; y--; }
    selectedMonth.value = m;
    selectedYear.value = y;
    selectedMonthBar.value = -1;
    selectedCalDay.value = -1;
    _rebuildMonth();
  }

  void nextMonth() {
    final now = DateTime.now();
    int m = selectedMonth.value + 1;
    int y = selectedYear.value;
    if (m > 12) { m = 1; y++; }
    if (y > now.year || (y == now.year && m > now.month)) return;
    selectedMonth.value = m;
    selectedYear.value = y;
    selectedMonthBar.value = -1;
    selectedCalDay.value = -1;
    _rebuildMonth();
  }

  void setMonthYear(int month, int year) {
    selectedMonth.value = month;
    selectedYear.value = year;
    selectedMonthBar.value = -1;
    selectedCalDay.value = -1;
    _rebuildMonth();
  }

  void tapCalDay(int day) {
    selectedCalDay.value = selectedCalDay.value == day ? -1 : day;
  }

  /// Returns the DateSummary for the selected calendar day (or null).
  DateSummary? get selectedCalDaySummary {
    final day = selectedCalDay.value;
    if (day < 1) return null;
    final m = selectedMonth.value;
    final y = selectedYear.value;
    final date = DateTime(y, m, day);
    final dayEnd = date.add(const Duration(days: 1));
    final games = _all
        .where((s) =>
            !s.playedAt.isBefore(date) && s.playedAt.isBefore(dayEnd))
        .toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt)); // newest first
    if (games.isEmpty) return null;
    return DateSummary(
      date: date,
      totalScore: games.fold(0, (s, g) => s + g.score),
      bestScore: games.map((g) => g.score).reduce(_max),
      gamesPlayed: games.length,
      games: games,
    );
  }

  void _rebuildMonth() {
    final now = DateTime.now();
    final month = selectedMonth.value;
    final year = selectedYear.value;
    final scores = _all
        .where((s) => s.playedAt.month == month && s.playedAt.year == year)
        .toList();

    // Per-day calendar grid data
    final dayMap = <int, DayCal>{};
    for (final s in scores) {
      final d = s.playedAt.day;
      final existing = dayMap[d];
      dayMap[d] = DayCal(
        totalScore: (existing?.totalScore ?? 0) + s.score,
        gamesCount: (existing?.gamesCount ?? 0) + 1,
      );
    }
    monthDayMap.value = dayMap;

    final isCurrentMonth = year == now.year && month == now.month;
    final accent = _accentColors[(month - 1) % _accentColors.length];
    final weeks = _buildWeekSegments(year, month, scores, now);

    if (weeks.isEmpty && !isCurrentMonth) {
      monthBlocks.value = [];
      monthBars.value = [];
      return;
    }

    final block = MonthBlock(
      monthLabel: '${_monthNames[month - 1]} $year',
      year: year,
      month: month,
      totalScore: scores.fold(0, (s, e) => s + e.score),
      bestScore: scores.isEmpty ? 0 : scores.map((s) => s.score).reduce(_max),
      gamesPlayed: scores.length,
      weeks: weeks,
      accentColor: accent,
      isCurrentMonth: isCurrentMonth,
    );

    monthBlocks.value = [block];
    monthBars.value = weeks
        .map((w) => BarItem(
              label: 'W${w.weekNum}',
              value: w.totalScore,
              isCurrent: w.isCurrentWeek,
            ))
        .toList();
  }

  List<WeekSegment> _buildWeekSegments(
      int year, int month, List<ScoreModel> scores, DateTime now) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final short = _monthShorts[month - 1];
    final ranges = [
      [1, 7], [8, 14], [15, 21], [22, 28],
      if (daysInMonth > 28) [29, daysInMonth],
    ];
    final segments = <WeekSegment>[];
    for (int i = 0; i < ranges.length; i++) {
      final startDay = ranges[i][0];
      final endDay = ranges[i][1].clamp(1, daysInMonth);
      if (startDay > daysInMonth) continue;
      final start = DateTime(year, month, startDay);
      final end = DateTime(year, month, endDay, 23, 59, 59);
      final isCW =
          now.isAfter(start.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end.add(const Duration(seconds: 1)));
      final ws = scores
          .where((s) => !s.playedAt.isBefore(start) && !s.playedAt.isAfter(end))
          .toList();
      if (ws.isEmpty && !isCW) continue;
      segments.add(WeekSegment(
        weekNum: i + 1,
        rangeLabel: '$short $startDay – $endDay',
        start: start,
        end: end,
        totalScore: ws.fold(0, (s, e) => s + e.score),
        bestScore: ws.isEmpty ? 0 : ws.map((s) => s.score).reduce(_max),
        gamesPlayed: ws.length,
        isCurrentWeek: isCW,
      ));
    }
    return segments;
  }

  // ── Computed view-properties (used directly in build methods) ────────────

  /// True when the displayed week is the current Mon–Sun week.
  bool get isCurrentWeek {
    final now = DateTime.now();
    final current = _dayStart(now.subtract(Duration(days: (now.weekday - 1) % 7)));
    return _sameDay(selectedWeekStart.value, current);
  }

  /// True when displayed year+month is the current calendar month.
  bool get isCurrentMonthPeriod {
    final now = DateTime.now();
    return selectedYear.value == now.year && selectedMonth.value == now.month;
  }

  /// Max total score across all 7 week-day entries (for progress-bar scaling).
  int get weekMaxScore =>
      weekEntries.map((e) => e.totalScore).fold(0, _max);

  /// True when every day in the selected week has zero games.
  bool get weekAllEmpty => weekEntries.every((e) => !e.hasData);

  /// Total score per month (1–12) for the selected year.
  Map<int, int> get monthlyTotalsForSelectedYear {
    final map = <int, int>{};
    final year = selectedYear.value;
    for (final s in allDateSummaries) {
      if (s.date.year == year) {
        map[s.date.month] = (map[s.date.month] ?? 0) + s.totalScore;
      }
    }
    return map;
  }

  /// Max monthly score for the selected year (for progress-bar scaling).
  int get monthlyMaxScore =>
      monthlyTotalsForSelectedYear.values.fold(0, _max);

  /// True when the selected year has any recorded games.
  bool get selectedYearHasData => monthlyTotalsForSelectedYear.isNotEmpty;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get selectedWeekLabel {
    final s = selectedWeekStart.value;
    final e = s.add(const Duration(days: 6));
    return '${s.day} ${_monthShorts[s.month - 1]} – ${e.day} ${_monthShorts[e.month - 1]}';
  }

  String get selectedMonthLabel =>
      '${_monthNames[selectedMonth.value - 1]} ${selectedYear.value}';

  bool get canGoNextWeek {
    final next = selectedWeekStart.value.add(const Duration(days: 7));
    return next.isBefore(DateTime.now()) || _sameDay(next, DateTime.now());
  }

  bool get canGoNextMonth {
    final now = DateTime.now();
    return !(selectedYear.value == now.year &&
        selectedMonth.value == now.month);
  }

  String monthName(int m) => _monthNames[m - 1];
  String monthShort(int m) => _monthShorts[m - 1];

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  int _max(int a, int b) => a > b ? a : b;
}
