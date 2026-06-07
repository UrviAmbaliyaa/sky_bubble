import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/score_model.dart';

class StorageService extends GetxService {
  static const _scoresKey         = 'scores';
  static const _coinsKey          = 'coins';
  static const _unlockedStylesKey = 'unlocked_styles';
  static const _styleKey          = 'bubble_style';

  late final GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  List<ScoreModel> readScores() {
    final raw = _box.read<List>(_scoresKey);
    if (raw == null) return [];
    return raw
        .map((e) => ScoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void writeScore(ScoreModel score) {
    final existing = readScores();
    existing.add(score);
    _box.write(_scoresKey, existing.map((s) => s.toJson()).toList());
  }

  void clearScores() => _box.remove(_scoresKey);

  // ── Coins ─────────────────────────────────────────────────────────────────

  int readCoins() => _box.read<int>(_coinsKey) ?? 0;

  void writeCoins(int coins) => _box.write(_coinsKey, coins);

  // ── Unlocked styles ───────────────────────────────────────────────────────

  List<String> readUnlockedStyles() {
    final raw = _box.read<List>(_unlockedStylesKey);
    if (raw == null) return [];
    return raw.cast<String>();
  }

  void writeUnlockedStyles(List<String> keys) =>
      _box.write(_unlockedStylesKey, keys);

  // ── Style key ─────────────────────────────────────────────────────────────

  String? readStyleKey() => _box.read<String>(_styleKey);

  void writeStyleKey(String key) => _box.write(_styleKey, key);
}
