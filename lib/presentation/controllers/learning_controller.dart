import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../core/constants/word_dictionary.dart';
import '../../data/models/bubble_model.dart';
import '../../data/services/sound_service.dart';
import '../../data/services/style_service.dart';

class LearningController extends GetxController with WidgetsBindingObserver {
  // ── Word state ──────────────────────────────────────────────────────────────
  final RxString   currentWord            = ''.obs;
  final RxString   wordEmoji              = ''.obs;
  final RxSet<int> revealedIndices        = <int>{}.obs;
  final RxBool     wordCompleted          = false.obs;
  final RxInt      wordsCompleted         = 0.obs;
  final RxInt      wordsCompletedThisLevel = 0.obs;

  // ── Bubble / game state ─────────────────────────────────────────────────────
  final RxList<BubbleModel> bubbles = <BubbleModel>[].obs;
  final RxBool isGameRunning        = false.obs;
  final RxBool isPaused             = false.obs;
  final RxInt  level                = 1.obs;
  final RxString gameBgAsset        = ''.obs;

  // ── Overlays ────────────────────────────────────────────────────────────────
  final RxBool showWordComplete  = false.obs;
  final RxBool showLevelComplete = false.obs;
  final RxInt  coinsEarnedThisLevel = 0.obs;

  final _random = math.Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _bgChangeTimer;

  int _idCounter       = 0;
  Size _screenSize     = Size.zero;
  int? _startLevel;

  // Word queue — shuffled per session, no repeats until pool exhausted
  final List<WordEntry> _wordQueue  = [];
  final Set<String>     _shownWords = {};

  // Bubble letter tracking
  final List<String> _wordLetters = [];
  int _bubbleSpawnIdx = 0; // drives the 2/3 word-letter vs random ratio

  FlutterTts? _tts;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    if (args is Map) _startLevel = args['startLevel'] as int?;
    _initTts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (isGameRunning.value && !isPaused.value) _pauseInternal();
        break;
      default:
        break;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _tts?.stop();
    super.onClose();
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  void setScreenSize(Size size) {
    if (size == _screenSize || size == Size.zero) return;
    _screenSize = size;
    if (!isGameRunning.value && !isPaused.value) startLearning();
  }

  void startLearning() {
    final style = Get.find<StyleService>();
    level.value                  = (_startLevel ?? style.currentLevel.value).clamp(1, 9999);
    wordsCompletedThisLevel.value = 0;
    isPaused.value               = false;
    _shownWords.clear();
    _buildWordQueue();
    _pickNewWord();
    _setupBackground();
    bubbles.clear();
    _cancelTimers();
    isGameRunning.value = true;
    _buildWordLetters();
    _startGameLoop();
    _startSpawnTimer();
    _startBgChangeTimer();
    // Seed with a few bubbles immediately (spread over 1.5s)
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 320), () {
        if (isGameRunning.value) _spawnOneBubble();
      });
    }
  }

  void handleTapDown(TapDownDetails details) {
    if (!isGameRunning.value || wordCompleted.value) return;
    final tap = details.localPosition;
    for (int i = bubbles.length - 1; i >= 0; i--) {
      final b = bubbles[i];
      if (!b.canPop) continue;
      if ((tap - Offset(b.x, b.y)).distance <= b.radius * 1.35) {
        _handleLetterTap(b);
        return;
      }
    }
  }

  void togglePause() {
    if (isPaused.value) {
      isPaused.value      = false;
      isGameRunning.value = true;
      _startGameLoop();
      _startSpawnTimer();
      _startBgChangeTimer();
    } else {
      _pauseInternal();
    }
  }

  void navigateHome() {
    _cancelTimers();
    _tts?.stop();
    Get.offAllNamed(AppRoutes.home, arguments: {'skipAnimation': true});
  }

  void continueAfterWordComplete() {
    showWordComplete.value  = false;
    wordCompleted.value     = false;

    // Check if level is complete — show popup instead of auto-advancing
    if (wordsCompletedThisLevel.value >= _wordsNeededForLevel(level.value)) {
      const coins = 3;
      coinsEarnedThisLevel.value = coins;
      Get.find<StyleService>().addCoins(coins);
      showLevelComplete.value = true;
      return; // do NOT pick next word yet
    }

    _pickNewWord();
    _buildWordLetters();
    bubbles.removeWhere((b) => !b.isBursting);
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
    _startBgChangeTimer();
    // Seed a few bubbles quickly for the new word
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (isGameRunning.value) _spawnOneBubble();
      });
    }
  }

  /// Called when the user taps "Next Level" on the level-complete popup.
  void confirmNextLevel() {
    showLevelComplete.value       = false;
    wordsCompletedThisLevel.value = 0;
    level.value++;
    Get.find<StyleService>().saveLearningProgress(
      level:      level.value,
      totalWords: wordsCompleted.value,
    );
    _shownWords.clear();
    _buildWordQueue();
    _pickNewWord();
    _buildWordLetters();
    bubbles.removeWhere((b) => !b.isBursting);
    isGameRunning.value = true;
    _startGameLoop();
    _startSpawnTimer();
    _startBgChangeTimer();
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (isGameRunning.value) _spawnOneBubble();
      });
    }
  }

  // ── Words-per-level formula ──────────────────────────────────────────────────

  int _wordsNeededForLevel(int lvl) => 5 + (lvl - 1) * 3;

  /// Exposed for the HUD.
  int get wordsNeededForCurrentLevel => _wordsNeededForLevel(level.value);

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _pauseInternal() {
    isPaused.value      = true;
    isGameRunning.value = false;
    _cancelTimers();
  }

  // ── Word queue helpers ───────────────────────────────────────────────────────

  void _buildWordQueue() {
    _wordQueue
      ..clear()
      ..addAll(WordDictionary.poolForLevel(level.value))
      ..shuffle(_random);
  }

  void _pickNewWord() {
    final pool = WordDictionary.poolForLevel(level.value);

    // If every word in the pool has been shown, reset history and reshuffle
    if (_shownWords.length >= pool.length) {
      _shownWords.clear();
      _buildWordQueue();
    }

    // Find the next queued word not yet shown this session
    WordEntry? entry;
    for (int i = 0; i < _wordQueue.length; i++) {
      if (!_shownWords.contains(_wordQueue[i].word)) {
        entry = _wordQueue[i];
        // Move used word to the back so ordering stays varied
        _wordQueue.removeAt(i);
        _wordQueue.add(entry);
        break;
      }
    }

    // Fallback (should never happen, but be safe)
    entry ??= pool[_random.nextInt(pool.length)];

    _shownWords.add(entry.word);
    currentWord.value = entry.word.toUpperCase();
    wordEmoji.value   = entry.emoji;
    revealedIndices.clear();
  }

  void _buildWordLetters() {
    // Store unique characters so the spawn logic can track coverage
    _wordLetters
      ..clear()
      ..addAll(currentWord.value.split(''));
    _bubbleSpawnIdx = 0;
  }

  void _handleLetterTap(BubbleModel b) {
    final letter = b.letter;
    if (letter == null) return;

    final word    = currentWord.value;
    final tapChar = letter.toUpperCase();

    final newIndices = <int>[];
    for (int i = 0; i < word.length; i++) {
      if (word[i] == tapChar && !revealedIndices.contains(i)) {
        newIndices.add(i);
      }
    }

    b.isPopped   = true;
    b.isBursting = true;
    Get.find<SoundService>().playPop();
    HapticFeedback.selectionClick();

    if (newIndices.isNotEmpty) {
      for (final idx in newIndices) {
        revealedIndices.add(idx);
      }
      revealedIndices.refresh();

      if (revealedIndices.length >= word.length) {
        _onWordCompleted();
      }
    }

    bubbles.refresh();
  }

  void _onWordCompleted() {
    wordCompleted.value           = true;
    isGameRunning.value           = false;
    wordsCompleted.value++;
    wordsCompletedThisLevel.value++;
    _cancelTimers();
    // Persist total words learned so Progress screen can show it
    Get.find<StyleService>().saveLearningProgress(
      level:      level.value,
      totalWords: wordsCompleted.value,
    );
    _speakWord(currentWord.value);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!isClosed) showWordComplete.value = true;
    });
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.45);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.1);
    } catch (_) {
      _tts = null;
    }
  }

  Future<void> _speakWord(String word) async {
    try {
      await _tts?.stop();
      await _tts?.speak(word.toLowerCase());
    } catch (_) {}
  }

  // ── Bubble spawning ──────────────────────────────────────────────────────────

  void _spawnOneBubble() {
    if (_screenSize == Size.zero || _wordLetters.isEmpty) return;

    final active = bubbles.where((b) => !b.isPopped && !b.isBursting).length;
    if (active >= 14) return;

    // 2 out of every 3 bubbles carry a word letter; the 3rd is a random filler.
    // For word-letter slots: always pick the unrevealed character that has the
    // FEWEST active bubbles on screen — this guarantees every letter the player
    // still needs will always be visible.
    final String letter;
    if (_bubbleSpawnIdx % 3 != 2) {
      letter = _leastRepresentedUnrevealedLetter();
    } else {
      letter = String.fromCharCode(65 + _random.nextInt(26));
    }
    _bubbleSpawnIdx++;

    _spawnLetterBubble(letter);
  }

  /// Returns the unrevealed word character that currently has the fewest
  /// active (non-popped) bubbles on screen, ensuring all needed letters
  /// are always available for the player to tap.
  String _leastRepresentedUnrevealedLetter() {
    final word = currentWord.value;

    // Collect unique unrevealed characters
    final needed = <String>{};
    for (int i = 0; i < word.length; i++) {
      if (!revealedIndices.contains(i)) needed.add(word[i]);
    }

    if (needed.isEmpty) {
      // Fallback: word is complete, just cycle through all letters
      return _wordLetters[_random.nextInt(_wordLetters.length)];
    }

    // Count how many active bubbles already show each needed character
    final counts = <String, int>{for (final c in needed) c: 0};
    for (final b in bubbles) {
      if (b.isPopped || b.isBursting || b.letter == null) continue;
      final l = b.letter!;
      if (counts.containsKey(l)) counts[l] = counts[l]! + 1;
    }

    // Pick the character with the lowest count
    String best = counts.keys.first;
    int bestCount = counts[best]!;
    for (final entry in counts.entries) {
      if (entry.value < bestCount) {
        best      = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  void _spawnLetterBubble(String letter) {
    final r = _screenSize.shortestSide * (0.065 + _random.nextDouble() * 0.025);

    // Try to find an x that does not overlap existing bubbles
    double x = r + _random.nextDouble() * (_screenSize.width - 2 * r);
    for (int attempt = 0; attempt < 15; attempt++) {
      final candidate = r + _random.nextDouble() * (_screenSize.width - 2 * r);
      bool tooClose = false;
      for (final b in bubbles) {
        if (b.isPopped || b.isBursting) continue;
        final dx = (b.x - candidate).abs();
        // Enforce minimum gap = combined radii × 1.8
        if (dx < (b.radius + r) * 1.8) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) {
        x = candidate;
        break;
      }
    }

    final speed   = _screenSize.height * (0.0009 + _random.nextDouble() * 0.0006);
    final palette = AppColors.bubbleColorsForLevel(level.value);
    bubbles.add(BubbleModel(
      id:             'lb${_idCounter++}',
      color:          palette[_random.nextInt(palette.length)],
      x:              x,
      y:              _screenSize.height + r * 2,
      radius:         r,
      speed:          speed,
      driftAngle:     _random.nextDouble() * math.pi * 2,
      driftAmplitude: 1.5 + _random.nextDouble() * 1.0,
      driftFrequency: 0.02 + _random.nextDouble() * 0.03,
      pointValue:     0,
      letter:         letter,
    ));
  }

  // ── Game loop ────────────────────────────────────────────────────────────────

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    _spawnTimer?.cancel();
    // Spawn one bubble every 500–900 ms for a steady, non-clustered stream
    final interval = 500 + _random.nextInt(400);
    _spawnTimer = Timer(Duration(milliseconds: interval), () {
      if (isGameRunning.value) _spawnOneBubble();
      _scheduleNextSpawn();
    });
  }

  void _startBgChangeTimer() {
    _bgChangeTimer?.cancel();
    _bgChangeTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (isGameRunning.value) _setupBackground();
    });
  }

  void _cancelTimers() {
    _gameTimer?.cancel();    _gameTimer    = null;
    _spawnTimer?.cancel();   _spawnTimer   = null;
    _bgChangeTimer?.cancel(); _bgChangeTimer = null;
  }

  void _tick() {
    if (!isGameRunning.value) return;

    final toRemove = <String>[];
    for (final b in bubbles) {
      if (b.isBursting) {
        b.burstProgress += 0.07;
        if (b.burstProgress >= 1.0) toRemove.add(b.id);
        continue;
      }
      if (b.isPopped) continue;

      final max = _screenSize.height / 300.0;
      b.y -= (b.speed * 0.65).clamp(0.0, max);
      b.driftAngle += b.driftFrequency;
      b.x = (b.x + math.sin(b.driftAngle) * b.driftAmplitude)
          .clamp(b.radius, _screenSize.width - b.radius);

      if (b.y < -b.radius * 2) toRemove.add(b.id);
    }

    if (toRemove.isNotEmpty) {
      bubbles.removeWhere((b) => toRemove.contains(b.id));
    }
    bubbles.refresh();
  }

  // ── Background ───────────────────────────────────────────────────────────────

  void _setupBackground() {
    final svc = Get.find<StyleService>();
    if (svc.autoBackground.value) {
      final all = BgAssets.all;
      gameBgAsset.value = all[_random.nextInt(all.length)];
    } else {
      final fixed = svc.fixedBgStyle.value;
      gameBgAsset.value = fixed != null ? fixed.assetPath : BgAssets.free[0];
    }
  }
}
