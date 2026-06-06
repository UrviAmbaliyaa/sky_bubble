import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../domain/usecases/score_usecases.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final GetScoresUseCase _getScores;
  HomeController(this._getScores);

  // ── Stats ──────────────────────────────────────────────────────────────────
  final RxInt bestScore        = 0.obs;
  final RxInt totalGamesPlayed = 0.obs;
  final RxInt todayGamesCount  = 0.obs;
  final RxInt todayTotalScore  = 0.obs;
  final RxInt weekGamesCount   = 0.obs;
  final RxInt weekTotalScore   = 0.obs;
  final RxList<int> weekDayScores = <int>[0, 0, 0, 0, 0, 0, 0].obs;

  // ── Entry animation (fade + slide) ────────────────────────────────────────
  late final AnimationController entryAnimCtrl;
  late final Animation<double>   fadeAnim;
  late final Animation<Offset>   slideAnim;

  // ── Play-button pulse ──────────────────────────────────────────────────────
  late final AnimationController pulseCtrl;
  late final Animation<double>   pulseAnim;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
  }

  @override
  void onReady() {
    super.onReady();
    _loadStats();
  }

  @override
  void onClose() {
    _disposeAnimations();
    super.onClose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _initAnimations() {
    entryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    fadeAnim  = CurvedAnimation(parent: entryAnimCtrl, curve: Curves.easeOut);
    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: entryAnimCtrl, curve: Curves.easeOutCubic));

    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    pulseAnim = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut));
  }

  void _disposeAnimations() {
    entryAnimCtrl.dispose();
    pulseCtrl.dispose();
  }

  void _loadStats() {
    final scores = _getScores();
    totalGamesPlayed.value = scores.length;
    bestScore.value =
        scores.isEmpty ? 0 : scores.map((s) => s.score).reduce(math.max);

    final now      = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd   = todayStart.add(const Duration(days: 1));

    final todayScores = scores
        .where((s) => !s.playedAt.isBefore(todayStart) && s.playedAt.isBefore(todayEnd))
        .toList();
    todayGamesCount.value = todayScores.length;
    todayTotalScore.value = todayScores.fold(0, (s, e) => s + e.score);

    final weekStart = todayStart.subtract(Duration(days: (now.weekday - 1) % 7));
    final weekEnd   = weekStart.add(const Duration(days: 7));
    final weekScores = scores
        .where((s) => !s.playedAt.isBefore(weekStart) && s.playedAt.isBefore(weekEnd))
        .toList();
    weekGamesCount.value = weekScores.length;
    weekTotalScore.value = weekScores.fold(0, (s, e) => s + e.score);

    final daySums = List.filled(7, 0);
    for (final s in weekScores) {
      final idx = s.playedAt.weekday - 1;
      if (idx >= 0 && idx < 7) daySums[idx] += s.score;
    }
    weekDayScores.value = daySums;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> navigateToGame() async {
    await Get.toNamed(AppRoutes.game);
    _loadStats();
  }

  Future<void> navigateToScores() async {
    await Get.toNamed(AppRoutes.score);
    _loadStats();
  }

  void refreshStats() => _loadStats();
}
