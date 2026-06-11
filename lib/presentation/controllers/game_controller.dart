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
import '../../data/services/ad_service.dart';
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
  Timer? _levelTimer;          // fires after 15 min to force-complete the level
  DateTime? _levelStartTime;  // wall-clock when current level began (or resumed)
  Duration _levelElapsed = Duration.zero; // accumulated time before last pause
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
        // App going to background / screen locked — pause and show pause overlay.
        if (isGameRunning.value && !isPaused.value) {
          isPaused.value      = true;
          isGameRunning.value = false;
          _cancelTimers();
        }
        break;
      case AppLifecycleState.resumed:
        // App returns to foreground — keep the pause overlay visible so the
        // player consciously taps Resume rather than being thrown back in-game.
        // Do nothing here; the overlay stays until the player dismisses it.
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Pause the game due to a navigation gesture (back-swipe, bottom nav bar).
  /// Stops the game loop and raises the pause overlay without exiting the screen.
  void pauseForNavigation() {
    if (!isGameRunning.value || isPaused.value) return;
    isGameRunning.value = false;
    isPaused.value      = true;
    _cancelTimers();
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
    // Initial background — only truly free (isPremium == false) + user's unlocked premium.
    // Uses the isPremium rule from BackgroundStyle so it always stays in sync
    // with whatever "free" means at any given time (currently only Image 1 / sky).
    final styleSvc = Get.find<StyleService>();
    final initPool = _buildBgPool(styleSvc);
    gameBgAsset.value = initPool[_random.nextInt(initPool.length)];
    bubbles.clear();
    _cancelTimers();
    _spawnWave();   // initial wave so the screen is never empty at start
    _startGameLoop();
    _startSpawnTimer();
    _startLevelTimer();
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
      _resumeLevelTimer();
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
      // Build pool = free backgrounds (per isPremium rule) + user-unlocked premium
      final svc  = Get.find<StyleService>();
      final pool = _buildBgPool(svc);
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

      // Persist the level's score before advancing.
      _persistScore();

      // Award 3 coins for completing a level.
      Get.find<StyleService>().addCoins(3);

      // Advance level — keep score accumulating (do NOT reset to 0).
      level.value++;
      _scoreSaved  = false;
      lives.value  = 3;
      // Persist the new current level so the user resumes from here.
      Get.find<StyleService>().updateCurrentLevel(level.value);

      // Pause game then show a MANDATORY fresh interstitial → level-complete overlay.
      // loadAndShowInterstitial always attempts a real ad load so it cannot be
      // skipped due to a missing preloaded slot.
      _cancelTimers();
      isGameRunning.value = false;
      Get.find<AdService>().loadAndShowInterstitial(
        onDismissed: () => showLevelComplete.value = true,
        onFailure:   () => showLevelComplete.value = true, // graceful degradation
      );
    }
  }

  /// Called by the "Next Level" button on the level-complete overlay.
  void continueAfterLevelComplete() {
    showLevelComplete.value = false;
    // Clear any leftover bubbles and reset score so the new level starts from 0.
    bubbles.clear();
    score.value = 0;
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
    _startLevelTimer();   // fresh 15-min window for the new level
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
    showNewBestBanner.value = true;
    // Pause game, then show a full-screen ad; gift appears after ad is dismissed.
    _cancelTimers();
    isGameRunning.value = false;
    giftRewardType.value = _random.nextInt(3); // 0=heart, 1=coins, 2=award
    Get.find<AdService>().loadAndShowInterstitial(
      onDismissed: () => showGiftScreen.value = true,
      onFailure:   () => showGiftScreen.value = true,
    );
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
    _resumeLevelTimer();
  }

  // Speed is now purely level-driven (LevelConfig.speedMultiplierForLevel).
  // This method is kept as a no-op so call-sites don't need to change.
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 100;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 100) * 100;
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

  // ── Background pool helper ────────────────────────────────────────────────
  // Builds the list of asset paths eligible for in-game background rotation:
  //   • All BackgroundStyle values where isPremium == false  (currently only sky)
  //   • Plus any premium backgrounds the user has explicitly unlocked
  // Using BackgroundStyle.isPremium (not BgAssets.free) ensures this always
  // respects the current "free" definition without needing a separate update.
  List<String> _buildBgPool(StyleService svc) {
    final free = BackgroundStyle.values
        .where((b) => !b.isPremium)
        .map((b) => b.assetPath)
        .toList();

    final unlocked = svc.unlockedBackgrounds
        .map((b) => b.assetPath)
        .where((p) => p.isNotEmpty)
        .toList();

    return [...free, ...unlocked];
  }

  /// Cost in coins to buy a second chance.
  static const int chanceCoinCost = 5;

  bool get canAffordChance =>
      Get.find<StyleService>().totalCoins.value >= chanceCoinCost;

  /// Restore hearts and resume — shared implementation.
  void resetHearts() {
    lives.value = 3;
    isHeartsOver.value = false;
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
    _resumeLevelTimer();
  }

  /// Spend [chanceCoinCost] coins for a second chance.
  void getChanceWithCoins() {
    final svc = Get.find<StyleService>();
    if (svc.totalCoins.value < chanceCoinCost) return;
    svc.spendCoins(chanceCoinCost);
    resetHearts();
  }

  /// Watch a single interstitial ad for a second chance.
  void getChanceWithAd() {
    Get.find<AdService>().showInterstitial(onDismissed: resetHearts);
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    // Cancel and null the spawn timer so the watchdog in _tick() can detect
    // a dead chain and restart it when the game resumes.
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _pauseLevelTimer();
  }

  // Starts (or restarts after a fresh level) the 15-minute level time limit.
  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelElapsed = Duration.zero;
    _levelStartTime = DateTime.now();
    _scheduleLevelTimeout();
  }

  // Pauses the level timer — call when game pauses/overlays show.
  void _pauseLevelTimer() {
    if (_levelStartTime != null) {
      _levelElapsed += DateTime.now().difference(_levelStartTime!);
      _levelStartTime = null;
    }
    _levelTimer?.cancel();
    _levelTimer = null;
  }

  // Resumes the level timer after a pause — fires with the remaining time.
  void _resumeLevelTimer() {
    _levelStartTime = DateTime.now();
    _scheduleLevelTimeout();
  }

  void _scheduleLevelTimeout() {
    final remaining = LevelConfig.levelTimeLimit - _levelElapsed;
    if (remaining <= Duration.zero) {
      _forceLevelComplete();
      return;
    }
    _levelTimer = Timer(remaining, () {
      if (!isGameRunning.value) return;
      _forceLevelComplete();
    });
  }

  void _forceLevelComplete() {
    final doneLv = level.value;
    completedLevel.value = doneLv;
    coinsThisLevel.value = score.value;
    _persistScore();
    // Award 3 coins for completing the level.
    Get.find<StyleService>().addCoins(3);
    level.value++;
    _scoreSaved  = false;
    lives.value  = 3;
    Get.find<StyleService>().updateCurrentLevel(level.value);
    _cancelTimers();
    isGameRunning.value = false;
    Get.find<AdService>().loadAndShowInterstitial(
      onDismissed: () => showLevelComplete.value = true,
      onFailure:   () => showLevelComplete.value = true,
    );
  }
}
