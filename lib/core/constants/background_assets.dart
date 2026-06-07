// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND ASSETS
//  • 14 original images  → FREE for all users
//  • 32 new images       → PREMIUM, unlock for 100 coins each
// ═══════════════════════════════════════════════════════════════════════════════

class BgAssets {
  static const _base = 'assets/backgrounds/';

  // ── Free backgrounds (14) ─────────────────────────────────────────────────
  static const List<String> free = [
    '${_base}bg_sky.png',
    '${_base}bg_dark_sky.png',
    '${_base}bg_gallaxy.png',
    '${_base}bg_garden.png',
    '${_base}bg_garden_gate.png',
    '${_base}bg_moonsoon.png',
    '${_base}bg_night.png',
    '${_base}bg_night_star.png',
    '${_base}beach_sky.png',
    '${_base}bg_morning.png',
    '${_base}bg_morning_view.png',
    '${_base}bg_morning_view_water.png',
    '${_base}bg_peacoc.png',
    '${_base}bs_morning.png',
  ];

  // ── Premium backgrounds (32) ──────────────────────────────────────────────
  static const List<String> premium = [
    '${_base}premium_bg_01.png',
    '${_base}premium_bg_02.png',
    '${_base}premium_bg_03.png',
    '${_base}premium_bg_04.png',
    '${_base}premium_bg_05.png',
    '${_base}premium_bg_06.png',
    '${_base}premium_bg_07.png',
    '${_base}premium_bg_08.png',
    '${_base}premium_bg_09.png',
    '${_base}premium_bg_10.png',
    '${_base}premium_bg_11.png',
    '${_base}premium_bg_12.png',
    '${_base}premium_bg_13.png',
    '${_base}premium_bg_14.png',
    '${_base}premium_bg_15.png',
    '${_base}premium_bg_16.png',
    '${_base}premium_bg_17.png',
    '${_base}premium_bg_18.png',
    '${_base}premium_bg_19.png',
    '${_base}premium_bg_20.png',
    '${_base}premium_bg_21.png',
    '${_base}premium_bg_22.png',
    '${_base}premium_bg_23.png',
    '${_base}premium_bg_24.png',
    '${_base}premium_bg_25.png',
    '${_base}premium_bg_26.png',
    '${_base}premium_bg_27.png',
    '${_base}premium_bg_28.png',
    '${_base}premium_bg_29.png',
    '${_base}premium_bg_30.png',
    '${_base}premium_bg_31.png',
    '${_base}premium_bg_32.png',
  ];

  /// All backgrounds combined (free first, then premium).
  static List<String> get all => [...free, ...premium];

  /// Cycles through free backgrounds based on level (used on the level map).
  static String forLevel(int level) => free[(level - 1) % free.length];

  /// Home screen uses the first free background.
  static String get home => free[0];
}

// ─── Background style enum ────────────────────────────────────────────────────
//
// 14 free entries  (index 0-13)  → coinCost = 0
// 32 premium entries (index 14-45) → coinCost = 100
//
// The key == enum .name so it round-trips cleanly through GetStorage.

enum BackgroundStyle {
  // ── Free ──────────────────────────────────────────────────────────────────
  sky,
  darkSky,
  galaxy,
  garden,
  gardenGate,
  monsoon,
  night,
  nightStar,
  beach,
  morning,
  morningView,
  morningViewWater,
  peacock,
  bsMorning,
  // ── Premium ───────────────────────────────────────────────────────────────
  premium01,
  premium02,
  premium03,
  premium04,
  premium05,
  premium06,
  premium07,
  premium08,
  premium09,
  premium10,
  premium11,
  premium12,
  premium13,
  premium14,
  premium15,
  premium16,
  premium17,
  premium18,
  premium19,
  premium20,
  premium21,
  premium22,
  premium23,
  premium24,
  premium25,
  premium26,
  premium27,
  premium28,
  premium29,
  premium30,
  premium31,
  premium32,
}

extension BackgroundStyleInfo on BackgroundStyle {
  // ── Identity ──────────────────────────────────────────────────────────────

  String get key => name;

  static BackgroundStyle fromKey(String key) => BackgroundStyle.values
      .firstWhere((s) => s.name == key, orElse: () => BackgroundStyle.sky);

  // ── Pricing ───────────────────────────────────────────────────────────────

  /// Free for the first 14 (original) backgrounds; 100 coins for the rest.
  int get coinCost  => index < 14 ? 0 : 100;
  /// Alternative: unlock with 5 awards instead of coins.
  int get awardCost => index < 14 ? 0 : 5;
  bool get isPremium => coinCost > 0;

  // ── Asset ─────────────────────────────────────────────────────────────────

  String get assetPath {
    if (index < 14) return BgAssets.free[index];
    return BgAssets.premium[index - 14];
  }

  // ── Display ───────────────────────────────────────────────────────────────

  String get label {
    switch (this) {
      case BackgroundStyle.sky:              return 'Sky';
      case BackgroundStyle.darkSky:          return 'Dark Sky';
      case BackgroundStyle.galaxy:           return 'Galaxy';
      case BackgroundStyle.garden:           return 'Garden';
      case BackgroundStyle.gardenGate:       return 'Garden Gate';
      case BackgroundStyle.monsoon:          return 'Monsoon';
      case BackgroundStyle.night:            return 'Night';
      case BackgroundStyle.nightStar:        return 'Night Stars';
      case BackgroundStyle.beach:            return 'Beach';
      case BackgroundStyle.morning:          return 'Morning';
      case BackgroundStyle.morningView:      return 'Morning View';
      case BackgroundStyle.morningViewWater: return 'Morning Water';
      case BackgroundStyle.peacock:          return 'Peacock';
      case BackgroundStyle.bsMorning:        return 'Sunrise';
      default:
        final n = index - 13; // premium01 → 1, premium02 → 2 …
        return 'Premium $n';
    }
  }

  String get emoji {
    switch (this) {
      case BackgroundStyle.sky:              return '☀️';
      case BackgroundStyle.darkSky:          return '🌙';
      case BackgroundStyle.galaxy:           return '🌌';
      case BackgroundStyle.garden:           return '🌿';
      case BackgroundStyle.gardenGate:       return '🌳';
      case BackgroundStyle.monsoon:          return '⛈️';
      case BackgroundStyle.night:            return '🌃';
      case BackgroundStyle.nightStar:        return '⭐';
      case BackgroundStyle.beach:            return '🏖️';
      case BackgroundStyle.morning:          return '🌅';
      case BackgroundStyle.morningView:      return '🌄';
      case BackgroundStyle.morningViewWater: return '💧';
      case BackgroundStyle.peacock:          return '🦚';
      case BackgroundStyle.bsMorning:        return '🔆';
      default:                               return '✨';
    }
  }
}
