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
import '../../data/services/style_service.dart';
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

  // ── New-best banner ───────────────────────────────────────────────────────
  // Shown on the game screen when the player beats their all-time high score.
  final RxBool showNewBestBanner = false.obs;
  final RxInt  newBestScore      = 0.obs;

  final _random = math.Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;
  int _idCounter = 0;
  Size _screenSize = Size.zero;

  // Guard: ensures each game session's score is written to storage exactly once,
  // regardless of whether the user exits via a button or the device back key.
  bool _scoreSaved = false;

  // The all-time best score loaded at game start (passed via route arguments
  // from HomeController so we know when a new best has been beaten).
  int _storedBestScore = 0;
  // Ensures the new-best banner is only shown once per game session.
  bool _newBestShown = false;

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
  void onReady() {
    super.onReady();
    // HomeController passes the current best score so we can detect a new high
    // during gameplay without an extra storage read.
    final args = Get.arguments;
    if (args is Map) {
      _storedBestScore = (args['bestScore'] as int?) ?? 0;
    }
  }

  void setScreenSize(Size size) {
    if (size == _screenSize || size == Size.zero) return;
    _screenSize = size;
    if (!isGameRunning.value && !isGameOver.value && !isPaused.value) startGame();
  }

  @override
  void onClose() {
    _cancelTimers();
    // Catches the device back-button path: the controller is disposed without
    // any explicit "navigateHome" call, so we save here as a safety net.
    _persistScore();
    super.onClose();
  }

  // Called by PopScope in GameScreen before the route is popped by a swipe-back
  // or system gesture.  Saves the score synchronously so that by the time
  // HomeController.navigateToGame() resumes and reads storage, the data is there.
  void persistScoreOnExit() => _persistScore();

  // ── Score persistence (idempotent) ────────────────────────────────────────
  // Writes the current score to storage at most once per game session.
  // Safe to call from multiple code paths (navigateHome, onClose, hearts-out).
  void _persistScore() {
    if (_scoreSaved || score.value <= 0) return;
    _scoreSaved = true;
    _saveScore(ScoreModel(
      score: score.value,
      level: level.value,
      playedAt: DateTime.now(),
    ));
    // Award coins: 1 coin per 5 score points earned this session.
    final coinsEarned = score.value ~/ 5;
    if (coinsEarned > 0) {
      Get.find<StyleService>().addCoins(coinsEarned);
    }
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
    _scoreSaved   = false; // reset so the new game's score can be saved
    _newBestShown = false;
    showNewBestBanner.value = false;
    _nextBackground();
    bubbles.clear();
    _cancelTimers();
    _spawnWave();   // initial wave so the screen is never empty at start
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
    _persistScore(); // idempotent — safe even if already saved
    // Pass both flags so HomeController can:
    //   • skip the fade-in animation (fromGame)
    //   • decide whether to show the celebration popup (lastScore)
    Get.offAllNamed(AppRoutes.home, arguments: {
      'fromGame': true,
      'lastScore': score.value,
    });
  }

  // ─── Game loop ───────────────────────────────────────────────────────────

  void _startGameLoop() {
    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tick(),
    );
  }

  void _startSpawnTimer() {
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    // Interval shrinks from 1 600 ms (start) down to 650 ms (high score).
    // Wave size (2–5 bubbles) drives density; interval drives rhythm/pressure.
    final interval = (1600 - (score.value * 2)).clamp(650, 1600);
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      if (isGameRunning.value) {
        _spawnWave();
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
      // Normal bubbles: cap at height/160 → medium pace, ~2.7 s crossing at 60 fps.
      final double tickSpeed;
      if (b.isSpecial) {
        tickSpeed = b.speed;
      } else {
        final maxPixelsPerTick = _screenSize.height / 160.0;
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
    _checkNewBest();
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

  // Fires the in-game "New High Score!" celebration banner the first time the
  // player's score surpasses their stored all-time best during this session.
  void _checkNewBest() {
    if (_newBestShown) return;
    if (score.value <= _storedBestScore || score.value <= 0) return;
    _newBestShown = true;
    newBestScore.value = score.value;
    showNewBestBanner.value = true;
    // Auto-dismiss after 3 s — the banner widget also lets the user tap to close.
    Future.delayed(const Duration(seconds: 3), () {
      showNewBestBanner.value = false;
    });
  }

  // Every 100 score pts show a speed-bump micro-feedback (between level-ups).
  // Always advance the ramp threshold even when a level-up banner is active.
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 100;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 100) * 100;
      // Skip showing the banner when a level-up or bonus message is on screen;
      // the threshold still advances so it triggers correctly next time.
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
  /// Score: smallest bubble (minR) → 1 pt, biggest normal bubble (maxR) → 5 pts
  /// Special (golden) bubble always awards 10 pts (set directly in _spawnSpecialBubble).
  int _scoreForRadius(double r) {
    final minR = _screenSize.shortestSide * 0.055;
    final maxR = _screenSize.shortestSide * 0.095;
    // t = 0 when r is at minimum (smallest), t = 1 when r is at maximum (biggest)
    final t = ((r - minR) / (maxR - minR)).clamp(0.0, 1.0);
    return (1 + (t * 4).round()).clamp(1, 5);
  }

  bool _canSpawnSpecial() {
    if (_lastSpecialBubbleTime == null) return true;
    return DateTime.now().difference(_lastSpecialBubbleTime!) >= _specialMinGap;
  }

  // ── Wave spawn ────────────────────────────────────────────────────────────
  // Spawns a random number of bubbles in a single wave.
  //
  // Scenarios handled:
  //  • Game paused / over         → guard at call-site via isGameRunning
  //  • Screen size not yet set    → early-return when _screenSize is zero
  //  • Screen already at capacity → capacity == 0, nothing spawned
  //  • Capacity < full wave size  → waveSize clamped to remaining capacity
  //  • Special bubble eligible    → at most 1 special per wave, rest normal
  //  • Special takes last slot    → normal loop runs 0 times (correct)
  void _spawnWave() {
    if (_screenSize == Size.zero) return;

    final config = LevelConfig.forScore(score.value);
    final active = bubbles.where((b) => !b.isPopped).length;
    final capacity = config.maxBubbles - active;
    if (capacity <= 0) return; // screen full — skip this wave entirely

    // Pick a random wave size within the level-appropriate range, then
    // clamp so we never exceed the remaining screen capacity.
    final (minW, maxW) = LevelConfig.waveSizeRange(level.value);
    final rawWave = minW + _random.nextInt((maxW - minW + 1).clamp(1, 99));
    final waveSize = rawWave.clamp(1, capacity);

    int spawned = 0;

    // One chance per wave to include the rare special bubble.
    // It counts toward the wave total so the wave size stays predictable.
    if (_canSpawnSpecial() && _random.nextInt(_specialSpawnChance) == 0) {
      _spawnSpecialBubble();
      spawned++;
    }

    // Fill the remaining wave slots with normal bubbles.
    while (spawned < waveSize) {
      _spawnNormalBubble();
      spawned++;
    }
  }

  // Spawns a single normal bubble. All capacity / special logic lives in
  // _spawnWave; this method only builds the BubbleModel.
  void _spawnNormalBubble() {
    final r = _screenSize.shortestSide * (0.055 + _random.nextDouble() * 0.04);
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    // Medium speed range: 0.0024–0.0036 × screen height per tick (≈ 60 fps).
    // At 800 px tall: 1.9–2.9 px/tick → combined with speedMult (0.65–1.6×)
    // gives a crossing time of ~3–5 s at level 1, ~2–3 s at top levels.
    final baseSpd = _screenSize.height * (0.0024 + _random.nextDouble() * 0.0012);

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
    // Large, slow, fixed-speed golden bubble — stands out visually.
    // Radius: 1.8× the normal max; speed locked to a 6-second screen crossing.
    final r = _screenSize.shortestSide * 0.17;
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    final fixedSpeed = _screenSize.height / (6 * 60.0);

    _lastSpecialBubbleTime = DateTime.now();
    _sound.playBubbleSpawn();
    bubbles.add(BubbleModel(
      id: 'special_${_idCounter++}',
      color: const Color(0xFFFFD700),
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
      isGameRunning.value = false;
      _cancelTimers();
      _persistScore(); // save the score when hearts run out
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
    _persistScore();
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
