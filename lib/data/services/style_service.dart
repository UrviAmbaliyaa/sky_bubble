import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';
import '../../core/constants/background_assets.dart';
import '../../core/constants/bubble_styles.dart';
import 'storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  STYLE SERVICE
//
//  Manages:
//  • Bubble style selection & unlocking
//  • Coin balance, awards, current level
//  • Background auto-rotation
//
//  Background rotation rules
//  ─────────────────────────
//  1. Build a pool = shuffle(unlockedPremium) + shuffle(free)
//     → Unlocked premium images always come first, then free images.
//  2. Advance one image every 5 minutes.
//  3. When all images in the pool are shown, rebuild (fresh shuffle) & repeat.
//  4. "Unlocked" premium images enter the pool immediately; newly unlocked
//     images are inserted at the front of the remaining queue so the user
//     sees their new image right away.
// ═══════════════════════════════════════════════════════════════════════════════

class StyleService extends GetxService {
  late final StorageService _storage;

  // ── Bubble styles ──────────────────────────────────────────────────────────
  final Rx<BubbleStyle>    selectedStyle  = BubbleStyle.classic.obs;
  final RxSet<BubbleStyle> unlockedStyles = <BubbleStyle>{BubbleStyle.classic}.obs;

  // ── Economy ────────────────────────────────────────────────────────────────
  final RxInt totalCoins  = 0.obs;
  final RxInt totalAwards = 0.obs;
  final RxInt currentLevel = 1.obs;

  // ── Lifetime gift totals (displayed on home screen) ───────────────────────
  final RxInt giftedHearts = 0.obs;
  final RxInt giftedCoins  = 0.obs;
  final RxInt giftedAwards = 0.obs;

  // ── Background unlocks ─────────────────────────────────────────────────────
  // All 14 free styles are always available; only premium ones need unlocking.
  final RxSet<BackgroundStyle> unlockedBackgrounds =
      <BackgroundStyle>{}.obs; // premium ones the user bought

  // ── Background rotation (reactive) ────────────────────────────────────────
  /// The asset path of the background currently displayed in the game.
  final RxString currentBgAsset = RxString(BgAssets.free[0]);

  // Internal rotation state
  final _bgQueue   = <BackgroundStyle>[];   // ordered play queue
  int   _bgQueueIdx = 0;                    // next-to-play index
  Timer? _bgTimer;

  static const _rotationInterval = Duration(minutes: 5);

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<StyleService> init() async {
    _storage = Get.find<StorageService>();
    _loadAll();
    _buildQueue();                  // build initial rotation queue
    _startRotationTimer();          // kick off 5-minute cycle
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LOAD / SAVE
  // ─────────────────────────────────────────────────────────────────────────

  void _loadAll() {
    totalCoins.value   = _storage.readCoins();
    totalAwards.value  = _storage.readAwards();
    currentLevel.value = _storage.readCurrentLevel();
    giftedHearts.value = _storage.readGiftedHearts();
    giftedCoins.value  = _storage.readGiftedCoins();
    giftedAwards.value = _storage.readGiftedAwards();

    // Unlocked premium backgrounds
    unlockedBackgrounds.clear();
    for (final key in _storage.readUnlockedBgs()) {
      final bg = BackgroundStyleInfo.fromKey(key);
      if (bg.isPremium) unlockedBackgrounds.add(bg);
    }

    // Unlocked bubble styles
    unlockedStyles.clear();
    unlockedStyles.add(BubbleStyle.classic);
    for (final key in _storage.readUnlockedStyles()) {
      unlockedStyles.add(BubbleStyleInfo.fromKey(key));
    }
    final savedKey = _storage.readStyleKey();
    if (savedKey != null) {
      final style = BubbleStyleInfo.fromKey(savedKey);
      if (isUnlocked(style)) selectedStyle.value = style;
    }

    // Restore last-displayed background
    final savedBg = _storage.readSelectedBg();
    if (savedBg != null) {
      currentBgAsset.value =
          BackgroundStyleInfo.fromKey(savedBg).assetPath;
    }
  }

  void _saveAll() {
    _storage.writeCoins(totalCoins.value);
    _storage.writeAwards(totalAwards.value);
    _storage.writeCurrentLevel(currentLevel.value);
    _storage.writeGiftedHearts(giftedHearts.value);
    _storage.writeGiftedCoins(giftedCoins.value);
    _storage.writeGiftedAwards(giftedAwards.value);
    _storage.writeUnlockedStyles(
      unlockedStyles
          .where((s) => s != BubbleStyle.classic)
          .map((s) => s.key)
          .toList(),
    );
    _storage.writeStyleKey(selectedStyle.value.key);
    _storage.writeUnlockedBgs(
      unlockedBackgrounds.map((b) => b.key).toList(),
    );
    // Persist whichever background is currently showing
    final current = BackgroundStyle.values.firstWhere(
      (b) => b.assetPath == currentBgAsset.value,
      orElse: () => BackgroundStyle.sky,
    );
    _storage.writeSelectedBg(current.key);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BACKGROUND ROTATION ENGINE
  // ─────────────────────────────────────────────────────────────────────────

  /// Rebuilds the play queue:
  ///   shuffle(unlockedPremium) + shuffle(allFree)
  void _buildQueue() {
    final rng = math.Random();

    final premiumPool = unlockedBackgrounds.toList()..shuffle(rng);
    final freePool    = BackgroundStyle.values
        .where((b) => !b.isPremium)
        .toList()
      ..shuffle(rng);

    _bgQueue
      ..clear()
      ..addAll(premiumPool)
      ..addAll(freePool);

    _bgQueueIdx = 0;
  }

  /// Advance to the next background in the queue.
  void _advanceBg() {
    if (_bgQueue.isEmpty) {
      _buildQueue();
    }

    // If we've played through the whole queue, rebuild it (fresh shuffle).
    if (_bgQueueIdx >= _bgQueue.length) {
      _buildQueue();
    }

    currentBgAsset.value = _bgQueue[_bgQueueIdx].assetPath;
    _bgQueueIdx++;
    _saveAll();
  }

  void _startRotationTimer() {
    _bgTimer?.cancel();
    _bgTimer = Timer.periodic(_rotationInterval, (_) => _advanceBg());
  }

  @override
  void onClose() {
    _bgTimer?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — BACKGROUNDS
  // ─────────────────────────────────────────────────────────────────────────

  bool isBackgroundUnlocked(BackgroundStyle bg) =>
      !bg.isPremium || unlockedBackgrounds.contains(bg);

  /// Unlock [bg] by spending coins (100). Returns false if insufficient.
  bool unlockBackground(BackgroundStyle bg) {
    if (!bg.isPremium) return true;
    if (unlockedBackgrounds.contains(bg)) return true;
    if (totalCoins.value < bg.coinCost) return false;
    totalCoins.value -= bg.coinCost;
    _doUnlockBackground(bg);
    return true;
  }

  /// Unlock [bg] by spending awards (5). Returns false if insufficient.
  bool unlockBackgroundWithAwards(BackgroundStyle bg) {
    if (!bg.isPremium) return true;
    if (unlockedBackgrounds.contains(bg)) return true;
    if (totalAwards.value < bg.awardCost) return false;
    totalAwards.value -= bg.awardCost;
    _doUnlockBackground(bg);
    return true;
  }

  void _doUnlockBackground(BackgroundStyle bg) {
    unlockedBackgrounds.add(bg);
    // Insert at next-play position so user sees it immediately.
    _bgQueue.insert(_bgQueueIdx, bg);
    _saveAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — BUBBLE STYLES
  // ─────────────────────────────────────────────────────────────────────────

  bool isUnlocked(BubbleStyle style) =>
      !style.isPremium || unlockedStyles.contains(style);

  /// Unlocks a bubble style — requires BOTH coins AND awards.
  bool unlockStyle(BubbleStyle style) {
    if (isUnlocked(style)) return true;
    if (totalCoins.value  < style.coinCost)  return false;
    if (totalAwards.value < style.awardCost) return false;
    totalCoins.value  -= style.coinCost;
    totalAwards.value -= style.awardCost;
    unlockedStyles.add(style);
    _saveAll();
    return true;
  }

  void setStyle(BubbleStyle style) {
    if (!isUnlocked(style)) return;
    selectedStyle.value = style;
    _saveAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PUBLIC API — ECONOMY
  // ─────────────────────────────────────────────────────────────────────────

  void addCoins(int amount) {
    if (amount <= 0) return;
    totalCoins.value += amount;
    _saveAll();
  }

  /// Deducts [amount] coins. Returns false if insufficient balance (no change).
  bool spendCoins(int amount) {
    if (totalCoins.value < amount) return false;
    totalCoins.value -= amount;
    _saveAll();
    return true;
  }

  void addAward(int count) {
    if (count <= 0) return;
    totalAwards.value += count;
    _saveAll();
  }

  static const awardPurchaseCost = 50;

  /// Spends [awardPurchaseCost] coins to buy 1 award.
  /// Returns false if the player doesn't have enough coins.
  bool purchaseAwardWithCoins() {
    if (totalCoins.value < awardPurchaseCost) return false;
    totalCoins.value -= awardPurchaseCost;
    totalAwards.value++;
    _saveAll();
    return true;
  }

  // ── Gift tracking (called by GameController.claimGift) ────────────────────
  void recordGiftHeart()  { giftedHearts.value++; _saveAll(); }
  void recordGiftCoins()  { giftedCoins.value++;  _saveAll(); }
  void recordGiftAward()  { giftedAwards.value++; _saveAll(); }

  void updateCurrentLevel(int level) {
    if (level <= currentLevel.value) return;
    currentLevel.value = level;
    _saveAll();
  }
}
