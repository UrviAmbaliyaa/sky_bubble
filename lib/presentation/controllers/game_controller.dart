import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class GameController extends GetxController with WidgetsBindingObserver {
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

  // ── Level-complete snack (slides in first, then overlay appears) ─────────
  final RxBool showLevelSnack      = false.obs;
  final RxInt  snackCompletedLevel = 0.obs;

  // ── Level-complete overlay ────────────────────────────────────────────────
  // Shown full-screen when the player advances to a new level.
  final RxBool showLevelComplete = false.obs;
  final RxInt  completedLevel    = 0.obs;   // level the player just finished
  final RxInt  coinsThisLevel    = 0.obs;   // score earned this level (displayed as score)

  // ── Gift screen (shown when player breaks all-time high score) ────────────
  // 0 = +1 heart, 1 = +5 coins, 2 = +1 award
  final RxBool showGiftScreen  = false.obs;
  final RxInt  giftRewardType  = 0.obs;

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

  // ─── Background index ─────────────────────────────────────────────────────
  // Derived from level in a fixed queue: level 1 → bg 0, level 2 → bg 1 …
  // wraps after all 14 backgrounds. Read-only from outside; updates whenever
  // level changes.
  int get bgIndex => ((level.value - 1) % BgAssets.all.length).toInt();

  // ─── In-game background (score-driven, changes every 200 pts) ────────────
  // A random background is picked from the full pool each time the score
  // crosses a new 200-point milestone. Reactive so _PremiumBackground rebuilds.
  final RxString gameBgAsset = RxString('');
  int _lastBgMilestone = 0;   // last 200-pt boundary we changed bg at

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
    // Register for app lifecycle events so the game pauses when the app is
    // minimised/sent to background and auto-resumes on return.
    WidgetsBinding.instance.addObserver(this);
    // HomeController passes the current best score so we can detect a new high
    // during gameplay without an extra storage read.
    final args = Get.arguments;
    if (args is Map) {
      _storedBestScore = (args['bestScore'] as int?) ?? 0;
    }
  }

  // Called by Flutter whenever the app lifecycle state changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background / screen locked — pause if actively running.
        if (isGameRunning.value && !isPaused.value) {
          isPaused.value      = true;
          isGameRunning.value = false;
          _cancelTimers();
        }
        break;
      case AppLifecycleState.resumed:
        // App is back in the foreground — resume only if we auto-paused it
        // (don't resume if the player manually paused or the game is over).
        if (isPaused.value && !isGameOver.value && !isHeartsOver.value) {
          isPaused.value      = false;
          isGameRunning.value = true;
          _startGameLoop();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void setScreenSize(Size size) {
    if (size == _screenSize || size == Size.zero) return;
    _screenSize = size;
    if (!isGameRunning.value && !isGameOver.value && !isPaused.value) startGame();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
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
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  void startGame() {
    final style = Get.find<StyleService>();
    score.value = 0;
    level.value = style.currentLevel.value.clamp(1, 9999);
    lives.value = 3;
    isGameOver.value   = false;
    isHeartsOver.value = false;
    isGameRunning.value = true;
    isPaused.value = false;
    _lastSpeedRampScore = 0;
    _lastBgMilestone    = 0;
    _scoreSaved   = false; // reset so the new game's score can be saved
    _newBestShown = false;
    showNewBestBanner.value = false;
    // Initial background — free + user's unlocked premium only
    final styleSvc = Get.find<StyleService>();
    final initPool = [
      ...BgAssets.free,
      ...styleSvc.unlockedBackgrounds
          .map((bg) => bg.assetPath)
          .where((p) => p.isNotEmpty),
    ];
    gameBgAsset.value = initPool[_random.nextInt(initPool.length)];
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
    _spawnTimer?.cancel();
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    // Interval is driven purely by level (2000 ms at Lv1 → 800 ms at Lv100).
    final interval = LevelConfig.spawnIntervalForLevel(level.value);
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      // ── CRITICAL: ALWAYS reschedule first, before anything else. ──────────
      // Previously we only rescheduled inside the `if (isGameRunning)` block,
      // so if the game was briefly paused/overlaid at the exact moment this
      // timer fired, the entire spawn chain terminated permanently and bubbles
      // stopped generating for the rest of the session.
      if (isGameRunning.value) {
        _spawnWave();
      }
      // Reschedule unconditionally — the chain must never die.
      // _cancelTimers() sets _spawnTimer = null and cancels the pending timer,
      // so this call after cancel is harmless (the callback already fired).
      _scheduleNextSpawn();
    });
  }

  void _tick() {
    if (!isGameRunning.value) return;

    // ── Spawn-timer watchdog ──────────────────────────────────────────────────
    // If the spawn timer somehow died (null while game is running), restart it
    // immediately so bubbles never stop generating.
    if (_spawnTimer == null) {
      _scheduleNextSpawn();
    }

    // ── Score-driven background change (every 200 pts) ────────────────────────
    final milestone = (score.value ~/ 200) * 200;
    if (milestone > _lastBgMilestone) {
      _lastBgMilestone = milestone;
      // Build pool = all free backgrounds + any premium the user has unlocked
      final svc  = Get.find<StyleService>();
      final pool = [
        ...BgAssets.free,
        ...svc.unlockedBackgrounds
            .map((bg) => bg.assetPath)
            .where((p) => p.isNotEmpty),
      ];
      if (pool.isEmpty) return;
      // Pick a random entry different from the current one
      String next;
      do { next = pool[_random.nextInt(pool.length)]; }
      while (next == gameBgAsset.value && pool.length > 1);
      gameBgAsset.value = next;
    }

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
      // Normal bubbles: capped at height/300 so even at the fastest level the
      // crossing time stays ≥ 2 s (60 fps × 300 ticks ÷ screenHeight).
      final double tickSpeed;
      if (b.isSpecial) {
        tickSpeed = b.speed;
      } else {
        final maxPixelsPerTick = _screenSize.height / 300.0;
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
    final target = LevelConfig.scoreTargetForLevel(level.value);
    if (score.value >= target) {
      final doneLv = level.value;
      completedLevel.value = doneLv;
      coinsThisLevel.value = score.value;   // score earned this level (for display)

      // Persist the level's score before resetting it.
      _persistScore();

      // Reset per-level state.
      level.value++;
      score.value  = 0;
      _scoreSaved  = false;
      lives.value  = 3;
      // Persist the new current level so the user resumes from here.
      Get.find<StyleService>().updateCurrentLevel(level.value);

      // Pause game and immediately show the level-complete overlay.
      _cancelTimers();
      isGameRunning.value     = false;
      showLevelComplete.value = true;
    }
  }

  /// Called by the "Next Level" button on the level-complete overlay.
  void continueAfterLevelComplete() {
    showLevelComplete.value = false;
    // Clear any leftover bubbles so the new level starts with a clean screen.
    bubbles.clear();
    _lastSpeedRampScore = 0;
    levelUpMessage.value = '🚀 Level ${level.value} — ${_skinName(level.value)}';
    Future.delayed(const Duration(seconds: 2), () {
      if (levelUpMessage.value.contains('Level ${level.value}')) {
        levelUpMessage.value = '';
      }
    });
    isGameRunning.value = true;
    _spawnWave();          // seed the first wave immediately
    _startGameLoop();
    _startSpawnTimer();
  }

  String _skinName(int lv) {
    const names = ['', 'Soap', 'Vivid', 'Neon ✨', 'Gold 🌟',
        'Crystal 💎', 'Fire 🔥', 'Rainbow 🌈'];
    return lv < names.length ? names[lv] : 'Rainbow 🌈';
  }

  // Fires the Gift screen the first time the player's score surpasses their
  // stored all-time best during this session.
  void _checkNewBest() {
    if (_newBestShown) return;
    // First-timers: gift at 200+. Returning players: gift when beating previous best (min 200).
    final threshold = _storedBestScore > 200 ? _storedBestScore : 199;
    if (score.value <= threshold) return;
    _newBestShown = true;
    newBestScore.value = score.value;
    showNewBestBanner.value = true; // kept for banner — hidden by gift overlay
    // Pause and show the gift screen
    _cancelTimers();
    isGameRunning.value = false;
    giftRewardType.value = _random.nextInt(3); // 0=heart, 1=coins, 2=award
    showGiftScreen.value = true;
    // Auto-dismiss banner (gift overlay shown separately)
    Future.delayed(const Duration(seconds: 3), () {
      showNewBestBanner.value = false;
    });
  }

  /// Called when the player claims the gift reward.
  void claimGift() {
    showGiftScreen.value = false;
    final style = Get.find<StyleService>();
    switch (giftRewardType.value) {
      case 0:
        lives.value += 1;      // +1 heart
        style.recordGiftHeart();
        break;
      case 1:
        style.addCoins(5);     // +5 coins
        style.recordGiftCoins();
        break;
      case 2:
        style.addAward(1);     // +1 award
        style.recordGiftAward();
        break;
    }
    // Resume the game
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
  }

  // Speed is now purely level-driven (LevelConfig.speedMultiplierForLevel).
  // This method is kept as a no-op so call-sites don't need to change.
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 100;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 100) * 100;
      // Banner suppressed — speed changes are invisible and gradual.
      // Uncomment the lines below if you want to restore the "⚡" toast.
      if (false && levelUpMessage.value.isEmpty) {
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
    // Soft, kid-friendly haptic — light impact so it feels like a gentle "pop"
    HapticFeedback.lightImpact();
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
    // Base speed: 0.0018–0.0026 × screen height per tick at 60 fps.
    // Combined with speedMultiplierForLevel (0.30 → 1.00 over 100 levels):
    //   Level  1: ~0.00054–0.00078 × h  →  crossing ≈ 6–7 s  (very relaxed)
    //   Level 50: ~0.00104–0.00151 × h  →  crossing ≈ 3.5 s
    //   Level100: ~0.0018–0.0026  × h   →  crossing ≈ 2 s    (challenging)
    final baseSpd = _screenSize.height * (0.0018 + _random.nextDouble() * 0.0008);

    final palette = AppColors.bubbleColorsForLevel(level.value);
    _sound.playBubbleSpawn();
    bubbles.add(BubbleModel(
      id: 'b${_idCounter++}',
      color: palette[_random.nextInt(palette.length)],
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
    final fixedSpeed = _screenSize.height / (8 * 60.0); // always ~8 s crossing

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
    lives.value = 3;
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
    _gameTimer = null;
    // Cancel and null the spawn timer so the watchdog in _tick() can detect
    // a dead chain and restart it when the game resumes.
    _spawnTimer?.cancel();
    _spawnTimer = null;
  }
}
