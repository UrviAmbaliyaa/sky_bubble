// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND ASSETS
//  • 14 original images  → FREE for all users
//  • 32 new images       → PREMIUM, unlock for 100 coins each
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

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

  // ── Premium backgrounds (36) ──────────────────────────────────────────────
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
    '${_base}premium_bg_33.png',
    '${_base}premium_bg_34.png',
    '${_base}premium_bg_35.png',
    '${_base}premium_bg_36.png',
  ];

  /// All backgrounds combined (free first, then premium).
  static List<String> get all => [...free, ...premium];

  /// Dedicated constant for the Level Map header background.
  static const String levelMapHeader = '${_base}premium_bg_08.png';

  /// Cycles through free backgrounds based on level (used on the level map).
  static String forLevel(int level) => free[(level - 1) % free.length];

  /// Home screen uses the first free background.
  static String get home => free[0];
}

// ─── Background style enum ────────────────────────────────────────────────────
//
// Indices 0-3  (sky, darkSky, galaxy, garden) → FREE, no unlock required
// Indices 4-13 (gardenGate … bsMorning)       → 100 coins to unlock
// Indices 14-49 (premium01 … premium36)        → 100 coins to unlock
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
  premium33,
  premium34,
  premium35,
  premium36,
}

extension BackgroundStyleInfo on BackgroundStyle {
  // ── Identity ──────────────────────────────────────────────────────────────

  String get key => name;

  static BackgroundStyle fromKey(String key) => BackgroundStyle.values
      .firstWhere((s) => s.name == key, orElse: () => BackgroundStyle.sky);

  // ── Pricing ───────────────────────────────────────────────────────────────

  /// Free backgrounds cost 0. Debug: premium costs 1 coin. Release: 100 coins.
  int get coinCost  => index < 4 ? 0 : (kDebugMode ? 1 : 100);
  /// Debug: 0 awards needed (1 coin is enough). Release: 5 awards.
  int get awardCost => index < 4 ? 0 : (kDebugMode ? 0 : 5);
  bool get isPremium => index >= 4;

  // ── Asset ─────────────────────────────────────────────────────────────────

  String get assetPath {
    if (index < 14) return BgAssets.free[index];
    return BgAssets.premium[index - 14];
  }

  // ── Display ───────────────────────────────────────────────────────────────

  String get label {
    switch (this) {
      case BackgroundStyle.sky:              return 'Sunrise Clouds';
      case BackgroundStyle.darkSky:          return 'Starlit Horizon';
      case BackgroundStyle.galaxy:           return 'Galaxy Mirror';
      case BackgroundStyle.garden:           return 'Flower Garden';
      case BackgroundStyle.gardenGate:       return 'Rose Arch';
      case BackgroundStyle.monsoon:          return 'Rainy Village';
      case BackgroundStyle.night:            return 'Moonlit Cabin';
      case BackgroundStyle.nightStar:        return 'Milky Way';
      case BackgroundStyle.beach:            return 'Garden Terrace';
      case BackgroundStyle.morning:          return 'River Sunrise';
      case BackgroundStyle.morningView:      return 'Misty Sunrise';
      case BackgroundStyle.morningViewWater: return 'Creek at Dawn';
      case BackgroundStyle.peacock:          return 'Peacock Garden';
      case BackgroundStyle.bsMorning:        return 'Golden Creek';
      case BackgroundStyle.premium01:        return 'Alpine Cascade';
      case BackgroundStyle.premium02:        return 'Mountain Stream';
      case BackgroundStyle.premium03:        return 'Alpine Glow';
      case BackgroundStyle.premium04:        return 'Peak Reflection';
      case BackgroundStyle.premium05:        return 'Summit Stream';
      case BackgroundStyle.premium06:        return 'Alpine Meadow';
      case BackgroundStyle.premium07:        return 'Lake Cabin';
      case BackgroundStyle.premium08:        return 'Alpine Brook';
      case BackgroundStyle.premium09:        return 'Lakeside Path';
      case BackgroundStyle.premium10:        return 'Tropical Sunset';
      case BackgroundStyle.premium11:        return 'Meadow Walk';
      case BackgroundStyle.premium12:        return 'Moraine Lake';
      case BackgroundStyle.premium13:        return 'Golden Clouds';
      case BackgroundStyle.premium14:        return 'Forest Stream';
      case BackgroundStyle.premium15:        return 'Lakeside Dock';
      case BackgroundStyle.premium16:        return 'Mountain Valley';
      case BackgroundStyle.premium17:        return 'Lake Lantern';
      case BackgroundStyle.premium18:        return 'Hidden Waterfall';
      case BackgroundStyle.premium19:        return 'Crystal Lake';
      case BackgroundStyle.premium20:        return 'Wildflower Hill';
      case BackgroundStyle.premium21:        return 'Flower Valley';
      case BackgroundStyle.premium22:        return 'Cottage Garden';
      case BackgroundStyle.premium23:        return 'Lantern Bridge';
      case BackgroundStyle.premium24:        return 'Sunset Cottage';
      case BackgroundStyle.premium25:        return 'Cascade Garden';
      case BackgroundStyle.premium26:        return 'Autumn Stream';
      case BackgroundStyle.premium27:        return 'Twilight Cabin';
      case BackgroundStyle.premium28:        return 'Dusk Cabin';
      case BackgroundStyle.premium29:        return 'Alpine Lake';
      case BackgroundStyle.premium30:        return 'Rocky Stream';
      case BackgroundStyle.premium31:        return 'Sunrise Rapids';
      case BackgroundStyle.premium32:        return 'Golden Rapids';
      case BackgroundStyle.premium33:        return 'Blossom Garden';
      case BackgroundStyle.premium34:        return 'Gazebo Garden';
      case BackgroundStyle.premium35:        return 'Forest Path';
      case BackgroundStyle.premium36:        return 'Garden Lantern';
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
