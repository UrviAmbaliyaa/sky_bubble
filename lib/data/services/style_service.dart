import 'package:get/get.dart';
import '../../core/constants/bubble_styles.dart';
import 'storage_service.dart';

/// Manages selected bubble style, coin balance, and unlocked premium styles.
class StyleService extends GetxService {
  late final StorageService _storage;

  final Rx<BubbleStyle> selectedStyle = BubbleStyle.classic.obs;
  final RxInt totalCoins = 0.obs;

  // Classic is always in the set; premium styles are added on unlock.
  final RxSet<BubbleStyle> unlockedStyles =
      <BubbleStyle>{BubbleStyle.classic}.obs;

  Future<StyleService> init() async {
    _storage = Get.find<StorageService>();

    totalCoins.value = _storage.readCoins();

    // Restore previously unlocked styles (classic always included)
    final keys = _storage.readUnlockedStyles();
    for (final k in keys) {
      unlockedStyles.add(BubbleStyleInfo.fromKey(k));
    }

    // Restore last selected style (only if still unlocked)
    final savedKey = _storage.readStyleKey();
    if (savedKey != null) {
      final style = BubbleStyleInfo.fromKey(savedKey);
      if (isUnlocked(style)) selectedStyle.value = style;
    }

    return this;
  }

  bool isUnlocked(BubbleStyle style) =>
      !style.isPremium || unlockedStyles.contains(style);

  /// Deducts coins and unlocks [style]. Returns false if coins are insufficient.
  bool unlockStyle(BubbleStyle style) {
    if (isUnlocked(style)) return true;
    if (totalCoins.value < style.coinCost) return false;

    totalCoins.value -= style.coinCost;
    unlockedStyles.add(style);
    _persistCoinsAndUnlocks();
    return true;
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    totalCoins.value += amount;
    _storage.writeCoins(totalCoins.value);
  }

  void setStyle(BubbleStyle style) {
    if (!isUnlocked(style)) return;
    selectedStyle.value = style;
    _storage.writeStyleKey(style.key);
  }

  void _persistCoinsAndUnlocks() {
    _storage.writeCoins(totalCoins.value);
    _storage.writeUnlockedStyles(
      unlockedStyles.map((s) => s.key).toList(),
    );
  }
}
