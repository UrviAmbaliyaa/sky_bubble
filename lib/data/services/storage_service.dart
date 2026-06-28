import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/score_model.dart';

class StorageService extends GetxService {
  static const _scoresKey         = 'scores';
  static const _coinsKey          = 'coins';
  static const _unlockedStylesKey = 'unlocked_styles';
  static const _styleKey          = 'bubble_style';
  static const _awardsKey         = 'awards';
  static const _currentLevelKey    = 'current_level';
  static const _selectedBgKey      = 'selected_bg';
  static const _unlockedBgsKey     = 'unlocked_bgs';

  // ── Gifted totals (lifetime cumulative from gift screen) ──────────────────
  static const _giftedHeartsKey = 'gifted_hearts';
  static const _giftedCoinsKey  = 'gifted_coins';
  static const _giftedAwardsKey = 'gifted_awards';

  late final GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  List<ScoreModel> readScores() {
    try {
      final raw = _box.read<List>(_scoresKey);
      if (raw == null) return [];
      return raw
          .map((e) => ScoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void writeScore(ScoreModel score) {
    final existing = readScores();
    existing.add(score);
    _box.write(_scoresKey, existing.map((s) => s.toJson()).toList());
  }

  void clearScores() => _box.remove(_scoresKey);

  // ── Coins ─────────────────────────────────────────────────────────────────

  int readCoins() {
    try { return (_box.read(_coinsKey) as num?)?.toInt() ?? 0; } catch (_) { return 0; }
  }

  void writeCoins(int coins) => _box.write(_coinsKey, coins);

  // ── Current level ─────────────────────────────────────────────────────────

  int readCurrentLevel() {
    try { return (_box.read(_currentLevelKey) as num?)?.toInt() ?? 1; } catch (_) { return 1; }
  }

  void writeCurrentLevel(int level) => _box.write(_currentLevelKey, level);

  // ── Selected background ───────────────────────────────────────────────────

  String? readSelectedBg() {
    try { return _box.read<String>(_selectedBgKey); } catch (_) { return null; }
  }

  void writeSelectedBg(String? key) {
    if (key == null) { _box.remove(_selectedBgKey); } else { _box.write(_selectedBgKey, key); }
  }

  List<String> readUnlockedBgs() {
    try {
      final raw = _box.read<List>(_unlockedBgsKey);
      if (raw == null) return [];
      return raw.map((e) => e.toString()).toList();
    } catch (_) { return []; }
  }

  void writeUnlockedBgs(List<String> keys) => _box.write(_unlockedBgsKey, keys);

  // ── Awards ────────────────────────────────────────────────────────────────

  int readAwards() {
    try { return (_box.read(_awardsKey) as num?)?.toInt() ?? 0; } catch (_) { return 0; }
  }

  void writeAwards(int awards) => _box.write(_awardsKey, awards);

  // ── Unlocked styles ───────────────────────────────────────────────────────

  List<String> readUnlockedStyles() {
    try {
      final raw = _box.read<List>(_unlockedStylesKey);
      if (raw == null) return [];
      return raw.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  void writeUnlockedStyles(List<String> keys) =>
      _box.write(_unlockedStylesKey, keys);

  // ── Selected style key ────────────────────────────────────────────────────

  String? readStyleKey() {
    try { return _box.read<String>(_styleKey); } catch (_) { return null; }
  }

  void writeStyleKey(String key) => _box.write(_styleKey, key);

  // ── Gifted hearts ─────────────────────────────────────────────────────────
  int  readGiftedHearts()      { try { return (_box.read(_giftedHeartsKey) as num?)?.toInt() ?? 0; } catch (_) { return 0; } }
  void writeGiftedHearts(int v) => _box.write(_giftedHeartsKey, v);

  // ── Gifted coins ──────────────────────────────────────────────────────────
  int  readGiftedCoins()       { try { return (_box.read(_giftedCoinsKey) as num?)?.toInt() ?? 0; } catch (_) { return 0; } }
  void writeGiftedCoins(int v)  => _box.write(_giftedCoinsKey, v);

  // ── Gifted awards ─────────────────────────────────────────────────────────
  int  readGiftedAwards()      { try { return (_box.read(_giftedAwardsKey) as num?)?.toInt() ?? 0; } catch (_) { return 0; } }
  void writeGiftedAwards(int v) => _box.write(_giftedAwardsKey, v);

  // ── Level stars (per-level 1-3 star rating) ──────────────────────────────
  static const _levelStarsKey = 'level_stars';

  Map<int, int> readLevelStars() {
    try {
      final raw = _box.read<Map>(_levelStarsKey);
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
    } catch (_) { return {}; }
  }

  void writeLevelStars(Map<int, int> stars) {
    _box.write(_levelStarsKey, stars.map((k, v) => MapEntry(k.toString(), v)));
  }

  // ── Auto / fixed background preference ───────────────────────────────────
  static const _autoBgKey  = 'auto_bg';
  static const _fixedBgKey = 'fixed_bg';

  bool readAutoBg() {
    try { return _box.read<bool>(_autoBgKey) ?? true; } catch (_) { return true; }
  }
  void writeAutoBg(bool v) => _box.write(_autoBgKey, v);

  String? readFixedBgKey() {
    try { return _box.read<String>(_fixedBgKey); } catch (_) { return null; }
  }
  void writeFixedBgKey(String? key) {
    if (key == null) { _box.remove(_fixedBgKey); } else { _box.write(_fixedBgKey, key); }
  }
}
