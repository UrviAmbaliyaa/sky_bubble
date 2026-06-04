import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/bubble_model.dart';
import '../../data/models/level_config.dart';
import '../../data/models/score_model.dart';
import '../../data/services/sound_service.dart';
import '../../domain/usecases/score_usecases.dart';

class GameController extends GetxController {
  final SaveScoreUseCase _saveScore;
  GameController(this._saveScore);

  SoundService get _sound => Get.find<SoundService>();

  final RxList<BubbleModel> bubbles = <BubbleModel>[].obs;
  final RxInt score = 0.obs;
  final RxInt level = 1.obs;
  final RxInt lives = 3.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isGameRunning = false.obs;
  final RxBool isPaused = false.obs;
  final RxString levelUpMessage = ''.obs;

  final _random = math.Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;
  int _idCounter = 0;
  Size _screenSize = const Size(390, 844);

  // ─── speed ramp: every 5 score pts we nudge existing bubbles faster ──────
  int _lastSpeedRampScore = 0;

  @override
  void onReady() => super.onReady();

  void setScreenSize(Size size) {
    if (size == _screenSize) return;
    _screenSize = size;
    if (!isGameRunning.value && !isGameOver.value) startGame();
  }

  @override
  void onClose() {
    _cancelTimers();
    super.onClose();
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  void startGame() {
    score.value = 0;
    level.value = 1;
    lives.value = 8;
    isGameOver.value = false;
    isGameRunning.value = true;
    isPaused.value = false;
    _lastSpeedRampScore = 0;
    bubbles.clear();
    _cancelTimers();
    _spawnBubble();
    _startGameLoop();
    _startSpawnTimer();
  }

  void handleTapDown(TapDownDetails details) {
    if (!isGameRunning.value) return;
    final tap = details.localPosition;
    for (int i = bubbles.length - 1; i >= 0; i--) {
      final b = bubbles[i];
      if (!b.canPop) continue;
      if ((tap - Offset(b.x, b.y)).distance <= b.radius * 1.3) {
        _popBubble(b.id);
        return;
      }
    }
  }

  void togglePause() {
    if (isPaused.value) {
      isPaused.value = false;
      isGameRunning.value = true;
      _startGameLoop();
      _startSpawnTimer();
    } else {
      isPaused.value = true;
      isGameRunning.value = false;
      _cancelTimers();
    }
  }

  void navigateHome() {
    _cancelTimers();
    Get.offAllNamed(AppRoutes.home);
  }

  // ─── Game loop ───────────────────────────────────────────────────────────

  void _startGameLoop() {
    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(),
    );
  }

  void _startSpawnTimer() {
    // Spawn interval shrinks as score grows: 900ms → min 400ms
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    final interval = (900 - (score.value * 3)).clamp(400, 900);
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      if (isGameRunning.value) {
        _spawnBubble();
        _scheduleNextSpawn();
      }
    });
  }

  void _tick() {
    if (!isGameRunning.value) return;

    // Continuous speed multiplier: +0.15× every 5 score points
    final speedMult = LevelConfig.speedMultiplierForScore(score.value);
    final toRemove = <String>[];

    for (final b in bubbles) {
      if (b.isBursting) {
        b.burstProgress += 0.07;
        if (b.burstProgress >= 1.0) toRemove.add(b.id);
        continue;
      }
      if (b.isPopped) continue;

      b.y -= b.speed * speedMult;
      b.driftAngle += b.driftFrequency;
      b.x = (b.x + math.sin(b.driftAngle) * b.driftAmplitude)
          .clamp(b.radius, _screenSize.width - b.radius);

      if (b.y < -b.radius * 2) {
        toRemove.add(b.id);
        _onBubbleEscaped();
      }
    }

    if (toRemove.isNotEmpty) {
      bubbles.removeWhere((b) => toRemove.contains(b.id));
    }
    bubbles.refresh();

    _checkLevelUp();
    _checkSpeedRamp();
  }

  void _checkLevelUp() {
    final newLevel = LevelConfig.forScore(score.value).level;
    if (newLevel > level.value) {
      level.value = newLevel;
      const styleNames = [
        '', 'Soap', 'Vivid', 'Neon ✨', 'Gold 🌟', 'Crystal 💎', 'Fire 🔥', 'Rainbow 🌈'
      ];
      final styleName = styleNames[newLevel.clamp(1, 7)];
      levelUpMessage.value = '🚀 Level $newLevel — $styleName Bubbles!';
      Future.delayed(const Duration(seconds: 2), () {
        if (levelUpMessage.value.contains('Level $newLevel')) {
          levelUpMessage.value = '';
        }
      });
    }
  }

  // Every 5 score pts show a speed-bump micro-feedback
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 5;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 5) * 5;
      if (levelUpMessage.value.isEmpty) {
        levelUpMessage.value = '⚡ Speed up!';
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (levelUpMessage.value == '⚡ Speed up!') {
            levelUpMessage.value = '';
          }
        });
      }
    }
  }

  // ─── Bubble management ───────────────────────────────────────────────────

  void _popBubble(String id) {
    final idx = bubbles.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    bubbles[idx].isPopped = true;
    bubbles[idx].isBursting = true;
    score.value += level.value;
    _sound.playPop();          // 🔊 bubble_pop.mp3
    bubbles.refresh();
  }

  void _spawnBubble() {
    final config = LevelConfig.forScore(score.value);
    if (bubbles.where((b) => !b.isPopped).length >= config.maxBubbles) return;

    final r = _screenSize.shortestSide * (0.055 + _random.nextDouble() * 0.04);
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);

    // Very gentle base speed at start; score adds a tiny increment each bubble
    final baseSpd = _screenSize.height *
        (0.0018 + _random.nextDouble() * 0.0012 + score.value * 0.000025);

    _sound.playBubbleSpawn();  // 🔊 bubble.mp3 (throttled)
    bubbles.add(BubbleModel(
      id: 'b${_idCounter++}',
      color: AppColors.bubbleColors[_random.nextInt(AppColors.bubbleColors.length)],
      x: x,
      y: _screenSize.height + r * 2,
      radius: r,
      speed: baseSpd,
      driftAngle: _random.nextDouble() * math.pi * 2,
      driftAmplitude: 1.5 + _random.nextDouble() * 1.5,
      driftFrequency: 0.03 + _random.nextDouble() * 0.04,
    ));
  }

  void _onBubbleEscaped() {
    if (kTestingMode) return; // no heart loss during testing
    lives.value = (lives.value - 1).clamp(0, 8);
    if (lives.value == 0) _endGame();
  }

  void _endGame() {
    isGameRunning.value = false;
    _cancelTimers();
    _saveScore(ScoreModel(
      score: score.value,
      level: level.value,
      playedAt: DateTime.now(),
    ));
    Future.delayed(const Duration(milliseconds: 400), () {
      isGameOver.value = true;
    });
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _gameTimer = null;
    _spawnTimer = null;
  }
}
