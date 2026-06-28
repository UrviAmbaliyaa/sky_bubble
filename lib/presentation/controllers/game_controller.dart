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
import '../../core/services/remote_ad_config_service.dart';
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
  final RxBool isGameOver    = false.obs;
  final RxBool isGameRunning = false.obs;
  final RxBool isPaused      = false.obs;
  final RxString levelUpMessage = ''.obs;

  // ── Time remaining for current level (for HUD display) ───────────────────
  final RxString timeRemaining = ''.obs;

  // ── New-best banner ───────────────────────────────────────────────────────
  final RxBool showNewBestBanner = false.obs;
  final RxInt  newBestScore      = 0.obs;

  // ── Level-complete snack (slides in first, then overlay appears) ─────────
  final RxBool showLevelSnack      = false.obs;
  final RxInt  snackCompletedLevel = 0.obs;

  // ── Level-complete overlay ────────────────────────────────────────────────
  final RxBool showLevelComplete = false.obs;
  final RxInt  completedLevel    = 0.obs;
  final RxInt  coinsThisLevel    = 0.obs;
  final RxInt  starsEarned       = 0.obs;

  // ── Gift screen ───────────────────────────────────────────────────────────
  final RxBool     showGiftScreen  = false.obs;
  final RxInt      giftRewardType  = 0.obs;
  final RxList<int> sessionGifts   = <int>[].obs;

  final _random = math.Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _levelTimer;
  Timer? _bgChangeTimer;         // fires every 5 min to rotate background
  Timer? _hudTimer;              // fires every second to update timeRemaining
  Timer? _lockedBubbleTimer;     // fires every 2 min to spawn a locked bubble
  DateTime? _levelStartTime;
  Duration _levelElapsed = Duration.zero;
  int _idCounter = 0;
  Size _screenSize = Size.zero;

  bool _scoreSaved = false;
  int _storedBestScore = 0;
  bool _newBestShown = false;
  int? _startLevel; // set when replaying a specific level from the levels screen

  // ─── Background index ─────────────────────────────────────────────────────
  int get bgIndex => ((level.value - 1) % BgAssets.all.length).toInt();

  // ─── In-game background (changes every 5 minutes) ────────────────────────
  final RxString gameBgAsset = RxString('');
  List<String> _gameBgPool   = [];
  int _gameBgPoolIdx         = 0;

  // ─── speed ramp ──────────────────────────────────────────────────────────
  int _lastSpeedRampScore = 0;

  // ─── special bubble tracking ─────────────────────────────────────────────
  DateTime? _lastSpecialBubbleTime;
  static const _specialMinGap = Duration(minutes: 5);
  static const _specialSpawnChance = 80;

  // ─── gift bubble tracking ─────────────────────────────────────────────────
  bool _giftBubbleSpawnedThisLevel = false;
  int  _giftBubbleEligibleLevel    = -1;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    if (args is Map) {
      _storedBestScore = (args['bestScore'] as int?) ?? 0;
      _startLevel      = args['startLevel'] as int?;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (isGameRunning.value && !isPaused.value) {
          isPaused.value      = true;
          isGameRunning.value = false;
          _cancelTimers();
        }
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

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
    _persistScore();
    super.onClose();
  }

  void persistScoreOnExit() => _persistScore();

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
    level.value = (_startLevel ?? style.currentLevel.value).clamp(1, 9999);
    isGameOver.value   = false;
    isGameRunning.value = true;
    isPaused.value = false;
    _lastSpeedRampScore    = 0;
    _scoreSaved   = false;
    _newBestShown = false;
    showNewBestBanner.value = false;
    sessionGifts.clear();
    _gameBgPool    = [];
    _gameBgPoolIdx = 0;
    final styleSvc = Get.find<StyleService>();
    if (styleSvc.autoBackground.value) {
      _gameBgPool       = _buildBgPoolList(styleSvc);
      gameBgAsset.value = _gameBgPool.isNotEmpty
          ? _gameBgPool[_gameBgPoolIdx++]
          : BgAssets.free[0];
    } else {
      final fixed = styleSvc.fixedBgStyle.value;
      gameBgAsset.value = fixed != null ? fixed.assetPath : BgAssets.free[0];
    }
    bubbles.clear();
    _cancelTimers();
    _giftBubbleSpawnedThisLevel = false;
    _giftBubbleEligibleLevel    = -1;
    _spawnWave();
    _startGameLoop();
    _startSpawnTimer();
    _startLevelTimer();
    _startBgChangeTimer();
    _startHudTimer();
    _startLockedBubbleTimer();
    _trySpawnGiftBubble();
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
      _startBgChangeTimer();
      _startHudTimer();
      _startLockedBubbleTimer();
    } else {
      isPaused.value = true;
      isGameRunning.value = false;
      _cancelTimers();
    }
  }

  void navigateHome() {
    _cancelTimers();
    _persistScore();
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
    final interval = LevelConfig.spawnIntervalForLevel(level.value);
    _spawnTimer?.cancel();
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      if (isGameRunning.value) {
        _spawnWave();
      }
      _scheduleNextSpawn();
    });
  }

  // ─── HUD timer (updates time remaining every second) ─────────────────────
  void _startHudTimer() {
    _hudTimer?.cancel();
    _hudTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeRemaining());
    _updateTimeRemaining();
  }

  void _updateTimeRemaining() {
    if (_levelStartTime == null) return;
    final limit = LevelConfig.timeLimitForLevel(level.value);
    final elapsed = _levelElapsed + DateTime.now().difference(_levelStartTime!);
    final remaining = limit - elapsed;
    if (remaining <= Duration.zero) {
      timeRemaining.value = '0:00';
      return;
    }
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    timeRemaining.value = '$m:${s.toString().padLeft(2, '0')}';
  }

  // ─── Background rotation (every 5 minutes) ────────────────────────────────
  void _startBgChangeTimer() {
    _bgChangeTimer?.cancel();
    _bgChangeTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!isGameRunning.value) return;
      final svc = Get.find<StyleService>();
      if (svc.autoBackground.value) {
        if (_gameBgPoolIdx >= _gameBgPool.length) {
          _gameBgPool    = _buildBgPoolList(svc);
          _gameBgPoolIdx = 0;
        }
        if (_gameBgPool.isNotEmpty) {
          gameBgAsset.value = _gameBgPool[_gameBgPoolIdx++];
        }
      } else {
        final fixed = svc.fixedBgStyle.value;
        if (fixed != null) gameBgAsset.value = fixed.assetPath;
      }
    });
  }

  // ─── Locked bubble timer (every 2 minutes) ────────────────────────────────
  void _startLockedBubbleTimer() {
    _lockedBubbleTimer?.cancel();
    _lockedBubbleTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (isGameRunning.value) _spawnLockedBubble();
    });
  }

  void _tick() {
    if (!isGameRunning.value) return;

    if (_spawnTimer == null) {
      _scheduleNextSpawn();
    }

    final speedMult = LevelConfig.speedMultiplierForScore(score.value);
    final toRemove = <String>[];

    for (final b in bubbles) {
      if (b.isBursting) {
        b.burstProgress += 0.07;
        if (b.burstProgress >= 1.0) toRemove.add(b.id);
        continue;
      }
      if (b.isPopped) continue;

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
        // No penalty when a bubble escapes — hearts removed
      }
    }

    if (toRemove.isNotEmpty) {
      bubbles.removeWhere((b) => toRemove.contains(b.id));
    }
    bubbles.refresh();

    _checkSpeedRamp();
    _checkNewBest();
  }

  // Speed ramp is kept as a no-op for now (score still accumulates)
  void _checkSpeedRamp() {
    final rampThreshold = _lastSpeedRampScore + 100;
    if (score.value >= rampThreshold && score.value > 0) {
      _lastSpeedRampScore = (score.value ~/ 100) * 100;
    }
  }

  // Fires the Gift screen the first time the player's score surpasses their
  // stored all-time best during this session.
  void _checkNewBest() {
    if (_newBestShown) return;
    final threshold = _storedBestScore > 200 ? _storedBestScore : 199;
    if (score.value <= threshold) return;
    _newBestShown = true;
    newBestScore.value = score.value;
    showNewBestBanner.value = true;
    _cancelTimers();
    isGameRunning.value = false;
    giftRewardType.value = _random.nextInt(2) + 1; // 1=coins, 2=award (no heart)

    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final _bAdsOn = remote?.adsEnabled.value ?? false;

    if (_bAdsOn) {
      Get.find<AdService>().loadAndShowInterstitial(
        onDismissed: () => showGiftScreen.value = true,
        onFailure:   () => showGiftScreen.value = true,
      );
    } else {
      showGiftScreen.value = true;
    }

    Future.delayed(const Duration(seconds: 3), () {
      showNewBestBanner.value = false;
    });
  }

  void claimGift() {
    showGiftScreen.value = false;
    sessionGifts.add(giftRewardType.value);
    final style = Get.find<StyleService>();
    switch (giftRewardType.value) {
      case 1:
        style.addCoins(5);
        style.recordGiftCoins();
        break;
      case 2:
        style.addAward(1);
        style.recordGiftAward();
        break;
    }
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
    _resumeLevelTimer();
    _startBgChangeTimer();
    _startHudTimer();
    _startLockedBubbleTimer();
  }

  // ─── Bubble management ───────────────────────────────────────────────────

  void _popBubble(String id) {
    final idx = bubbles.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final b = bubbles[idx];
    b.isPopped = true;
    b.isBursting = true;
    score.value += b.pointValue;
    if (b.isGift) {
      _triggerGiftBubbleReward();
    } else if (b.isSpecial) {
      levelUpMessage.value = '🌟 Bonus Bubble!';
      Future.delayed(const Duration(seconds: 2), () {
        if (levelUpMessage.value == '🌟 Bonus Bubble!') {
          levelUpMessage.value = '';
        }
      });
    }
    _sound.playPop();
    HapticFeedback.selectionClick();
    bubbles.refresh();
  }

  void _triggerGiftBubbleReward() {
    _cancelTimers();
    isGameRunning.value = false;
    giftRewardType.value = _random.nextInt(2) + 1; // 1=coins, 2=award

    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final _gAdsOn = remote?.adsEnabled.value ?? false;

    if (_gAdsOn) {
      Get.find<AdService>().loadAndShowInterstitial(
        onDismissed: () => showGiftScreen.value = true,
        onFailure:   () => showGiftScreen.value = true,
      );
    } else {
      showGiftScreen.value = true;
    }
  }

  void _spawnGiftBubble() {
    final r = _screenSize.shortestSide * 0.13;
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    final fixedSpeed = _screenSize.height / (10 * 60.0);
    bubbles.add(BubbleModel(
      id: 'gift_${_idCounter++}',
      color: const Color(0xFFFF6B9D),
      x: x,
      y: _screenSize.height + r * 2,
      radius: r,
      speed: fixedSpeed,
      driftAngle: _random.nextDouble() * math.pi * 2,
      driftAmplitude: 2.5,
      driftFrequency: 0.025,
      pointValue: 0,
      isGift: true,
    ));
  }

  void _trySpawnGiftBubble() {
    final currentLvl = level.value;
    if (currentLvl != _giftBubbleEligibleLevel) {
      _giftBubbleSpawnedThisLevel = false;
      _giftBubbleEligibleLevel = currentLvl;
    }
    if (!_giftBubbleSpawnedThisLevel) {
      _giftBubbleSpawnedThisLevel = true;
      Future.delayed(const Duration(seconds: 20), () {
        if (isGameRunning.value && !isGameOver.value) {
          _spawnGiftBubble();
        }
      });
    }
  }

  // Spawns a locked-style teaser bubble to entice the user to unlock styles.
  void _spawnLockedBubble() {
    if (_screenSize == Size.zero) return;
    final r = _screenSize.shortestSide * 0.12;
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    final fixedSpeed = _screenSize.height / (12 * 60.0);
    bubbles.add(BubbleModel(
      id: 'locked_${_idCounter++}',
      color: const Color(0xFF9E9E9E),
      x: x,
      y: _screenSize.height + r * 2,
      radius: r,
      speed: fixedSpeed,
      driftAngle: _random.nextDouble() * math.pi * 2,
      driftAmplitude: 2.0,
      driftFrequency: 0.02,
      pointValue: 0,
      isLocked: true,
    ));
  }

  int _scoreForRadius(double r) {
    final minR = _screenSize.shortestSide * 0.055;
    final maxR = _screenSize.shortestSide * 0.095;
    final t = ((r - minR) / (maxR - minR)).clamp(0.0, 1.0);
    return (1 + (t * 4).round()).clamp(1, 5);
  }

  bool _canSpawnSpecial() {
    if (_lastSpecialBubbleTime == null) return true;
    return DateTime.now().difference(_lastSpecialBubbleTime!) >= _specialMinGap;
  }

  void _spawnWave() {
    if (_screenSize == Size.zero) return;

    final config = LevelConfig.forScore(score.value);
    final active = bubbles.where((b) => !b.isPopped).length;
    final capacity = config.maxBubbles - active;
    if (capacity <= 0) return;

    final (minW, maxW) = LevelConfig.waveSizeRange(level.value);
    final rawWave = minW + _random.nextInt((maxW - minW + 1).clamp(1, 99));
    final waveSize = rawWave.clamp(1, capacity);

    int spawned = 0;

    if (_canSpawnSpecial() && _random.nextInt(_specialSpawnChance) == 0) {
      _spawnSpecialBubble();
      spawned++;
    }

    while (spawned < waveSize) {
      _spawnNormalBubble();
      spawned++;
    }
  }

  void _spawnNormalBubble() {
    final r = _screenSize.shortestSide * (0.055 + _random.nextDouble() * 0.04);
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
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
    final r = _screenSize.shortestSide * 0.17;
    final x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    final fixedSpeed = _screenSize.height / (8 * 60.0);

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

  // ── Background pool helper ────────────────────────────────────────────────
  List<String> _buildBgPoolList(StyleService svc) {
    final rng      = math.Random();
    final unlocked = svc.unlockedBackgrounds.toList()..shuffle(rng);
    final free     = BackgroundStyle.values
        .where((b) => !b.isPremium)
        .toList()
      ..shuffle(rng);
    return [
      ...unlocked.map((b) => b.assetPath),
      ...free.map((b) => b.assetPath),
    ];
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _bgChangeTimer?.cancel();
    _bgChangeTimer = null;
    _hudTimer?.cancel();
    _hudTimer = null;
    _lockedBubbleTimer?.cancel();
    _lockedBubbleTimer = null;
    _pauseLevelTimer();
  }

  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelElapsed = Duration.zero;
    _levelStartTime = DateTime.now();
    _scheduleLevelTimeout();
  }

  void _pauseLevelTimer() {
    if (_levelStartTime != null) {
      _levelElapsed += DateTime.now().difference(_levelStartTime!);
      _levelStartTime = null;
    }
    _levelTimer?.cancel();
    _levelTimer = null;
  }

  void _resumeLevelTimer() {
    _levelStartTime = DateTime.now();
    _scheduleLevelTimeout();
  }

  void _scheduleLevelTimeout() {
    final limit     = LevelConfig.timeLimitForLevel(level.value);
    final remaining = limit - _levelElapsed;
    if (remaining <= Duration.zero) {
      _forceLevelComplete();
      return;
    }
    _levelTimer = Timer(remaining, () {
      if (!isGameRunning.value) return;
      _forceLevelComplete();
    });
  }

  int _calculateStars() {
    final target = LevelConfig.scoreTargetForLevel(level.value);
    if (score.value >= target) return 3;
    if (score.value >= target ~/ 2) return 2;
    return 1;
  }

  void _forceLevelComplete() {
    final doneLv = level.value;
    completedLevel.value = doneLv;
    coinsThisLevel.value = score.value;
    starsEarned.value    = _calculateStars();

    _persistScore();
    Get.find<StyleService>().addCoins(3);
    Get.find<StyleService>().saveLevelStars(doneLv, starsEarned.value);

    level.value++;
    _scoreSaved  = false;
    Get.find<StyleService>().updateCurrentLevel(level.value);

    _cancelTimers();
    isGameRunning.value = false;

    RemoteAdConfigService? remote;
    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
    final _adsOn = remote?.adsEnabled.value ?? false;

    if (_adsOn) {
      Get.find<AdService>().loadAndShowInterstitial(
        onDismissed: () => showLevelComplete.value = true,
        onFailure:   () => showLevelComplete.value = true,
      );
    } else {
      showLevelComplete.value = true;
    }
  }

  /// Called by the "Next Level" button on the level-complete overlay.
  void continueAfterLevelComplete() {
    showLevelComplete.value = false;
    sessionGifts.clear();
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
    _spawnWave();
    _startGameLoop();
    _startSpawnTimer();
    _startLevelTimer();
    _startBgChangeTimer();
    _startHudTimer();
    _startLockedBubbleTimer();
    _trySpawnGiftBubble();
  }

  String _skinName(int lv) {
    const names = ['', 'Soap', 'Vivid', 'Neon ✨', 'Gold 🌟',
        'Crystal 💎', 'Fire 🔥', 'Rainbow 🌈'];
    return lv < names.length ? names[lv] : 'Rainbow 🌈';
  }
}
