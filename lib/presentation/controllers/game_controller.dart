import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
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
  final RxInt lives = 0.obs;
  final RxBool isGameOver    = false.obs;
  final RxBool isGameRunning = false.obs;
  final RxBool isPaused      = false.obs;
  final RxBool isHeartsOver  = false.obs;
  final RxString levelUpMessage = ''.obs;

  final _random = math.Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;
  int _idCounter = 0;
  Size _screenSize = const Size(390, 844);

  // ─── background shuffle queue ────────────────────────────────────────────
  // Guarantees every background plays before any repeats (no-repeat shuffle).
  final RxInt randomBgIndex = 0.obs;
  final List<int> _bgQueue = [];

  void _nextBackground() {
    if (_bgQueue.isEmpty) {
      // Refill with all indices and shuffle (Fisher-Yates).
      _bgQueue.addAll(List.generate(BgAssets.all.length, (i) => i));
      for (int i = _bgQueue.length - 1; i > 0; i--) {
        final j = _random.nextInt(i + 1);
        final tmp = _bgQueue[i];
        _bgQueue[i] = _bgQueue[j];
        _bgQueue[j] = tmp;
      }
      // If the first item after reshuffle is the same as the last one shown,
      // swap it with any other position to avoid an accidental repeat.
      if (_bgQueue.length > 1 && _bgQueue.first == randomBgIndex.value) {
        final swap = 1 + _random.nextInt(_bgQueue.length - 1);
        final tmp = _bgQueue[0];
        _bgQueue[0] = _bgQueue[swap];
        _bgQueue[swap] = tmp;
      }
    }
    randomBgIndex.value = _bgQueue.removeAt(0);
  }

  // ─── speed ramp ──────────────────────────────────────────────────────────
  int _lastSpeedRampScore = 0;

  // ─── special bubble tracking ─────────────────────────────────────────────
  // The golden 100-pt bubble may only appear once every 10 minutes.
  DateTime? _lastSpecialBubbleTime;
  static const _specialMinGap = Duration(minutes: 5);
  // Approximate chance per spawn cycle when the gap has elapsed (~1 in 80).
  static const _specialSpawnChance = 80;

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
    isGameOver.value   = false;
    isHeartsOver.value = false;
    isGameRunning.value = true;
    isPaused.value = false;
    _lastSpeedRampScore = 0;
    _nextBackground();
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
    // Kids-friendly spawn rate: starts slow, gently ramps down to 700 ms min.
    final interval = (1400 - (score.value * 2)).clamp(700, 1400);
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

      // Special bubbles use their fixed speed — never scaled by level.
      // Normal bubbles: capped so traversal takes at least 6 seconds (kids pace).
      final double tickSpeed;
      if (b.isSpecial) {
        tickSpeed = b.speed;
      } else {
        final maxPixelsPerTick = _screenSize.height / 360.0;
        tickSpeed = (b.speed * speedMult).clamp(0.0, maxPixelsPerTick);
      }
      b.y -= tickSpeed;
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
    final newLevel = LevelConfig.levelForScore(score.value);
    if (newLevel > level.value) {
      level.value = newLevel;
      lives.value += 1;   // reward +1 heart on every level-up
      _nextBackground();
      levelUpMessage.value = '🚀 Level $newLevel — ${_skinName(newLevel)}';
      Future.delayed(const Duration(seconds: 2), () {
        if (levelUpMessage.value.contains('Level $newLevel')) {
          levelUpMessage.value = '';
        }
      });
    }
  }

  String _skinName(int lv) {
    const names = ['', 'Soap', 'Vivid', 'Neon ✨', 'Gold 🌟',
        'Crystal 💎', 'Fire 🔥', 'Rainbow 🌈'];
    return lv < names.length ? names[lv] : 'Rainbow 🌈';
  }

  // Every 100 score pts show a speed-bump micro-feedback (between level-ups).
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 100;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 100) * 100;
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
    final b = bubbles[idx];
    b.isPopped = true;
    b.isBursting = true;
    score.value += b.pointValue;
    if (b.isSpecial) {
      levelUpMessage.value = '🌟 Bonus Bubble!';
      Future.delayed(const Duration(seconds: 2), () {
        if (levelUpMessage.value == '🌟 Bonus Bubble!') {
          levelUpMessage.value = '';
        }
      });
    }
    _sound.playPop();
    bubbles.refresh();
  }

  /// Radius range: minR = shortestSide * 0.055, maxR = shortestSide * 0.095
  /// Score: small bubble (minR) → 5 pts, large (maxR) → 1 pt (linear mapping)
  int _scoreForRadius(double r) {
    final minR = _screenSize.shortestSide * 0.055;
    final maxR = _screenSize.shortestSide * 0.095;
    final t = ((maxR - r) / (maxR - minR)).clamp(0.0, 1.0); // 0=large, 1=small
    return (1 + (t * 4).round()).clamp(1, 5);
  }

  bool _canSpawnSpecial() {
    if (_lastSpecialBubbleTime == null) return true;
    return DateTime.now().difference(_lastSpecialBubbleTime!) >= _specialMinGap;
  }

  void _spawnBubble() {
    final config = LevelConfig.forScore(score.value);
    if (bubbles.where((b) => !b.isPopped).length >= config.maxBubbles) return;

    // ── Rare special (home-style) bubble ─────────────────────────────────
    if (_canSpawnSpecial() && _random.nextInt(_specialSpawnChance) == 0) {
      _spawnSpecialBubble();
      return;
    }

    // ── Normal bubble ─────────────────────────────────────────────────────
    final r = _screenSize.shortestSide * (0.055 + _random.nextDouble() * 0.04);
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    // Kids-friendly base speed: slow and gentle, no score-based creep.
    // maxPixelsPerTick cap (height/360) is the real speed ceiling.
    final baseSpd = _screenSize.height *
        (0.0010 + _random.nextDouble() * 0.0008);

    _sound.playBubbleSpawn();
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
      pointValue: _scoreForRadius(r),
    ));
  }

  void _spawnSpecialBubble() {
    // Large, slow, fixed-speed golden bubble worth 100 pts.
    // Radius: 1.8× the normal max so it stands out visually.
    final r = _screenSize.shortestSide * 0.17;
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    // Fixed speed: always takes ~6 seconds to cross the screen.
    final fixedSpeed = _screenSize.height / (6 * 60.0);

    _lastSpecialBubbleTime = DateTime.now();
    _sound.playBubbleSpawn();
    bubbles.add(BubbleModel(
      id: 'special_${_idCounter++}',
      color: const Color(0xFFFFD700), // gold
      x: x,
      y: _screenSize.height + r * 2,
      radius: r,
      speed: fixedSpeed,
      driftAngle: _random.nextDouble() * math.pi * 2,
      driftAmplitude: 2.0,
      driftFrequency: 0.02,
      pointValue: 10,
      isSpecial: true,
    ));
  }

  void _onBubbleEscaped() {
    lives.value -= 1;
    if (lives.value <= 0) {
      lives.value = 0;
      // Pause the game and show the hearts-over popup (don't end game yet).
      isGameRunning.value = false;
      _cancelTimers();
      isHeartsOver.value = true;
    }
  }

  /// Restore 8 hearts and resume the game from where it was.
  void resetHearts() {
    lives.value = 8;
    isHeartsOver.value = false;
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
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
