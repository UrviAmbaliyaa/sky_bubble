import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Selectable bubble styles.
enum BubbleStyle {
  classic, // Iridescent glass bubble (level-based skins) — FREE
  blur,    // Frosted / soft blur effect                  — 100 coins + 1 award
  heart,   // Rainbow iridescent heart-shaped bubble      — 200 coins + 2 awards
  star,    // Golden glowing 5-point star bubble          — 300 coins + 3 awards
  diamond, // Icy crystal diamond bubble                  — 400 coins + 4 awards
  dog1,    // Cute puppy 1 — 500 coins + 5 awards
  dog2,    // Cute puppy 2 — 500 coins + 5 awards
  dog3,    // Cute puppy 3 — 500 coins + 5 awards
}

extension BubbleStyleInfo on BubbleStyle {
  String get label {
    switch (this) {
      case BubbleStyle.classic: return 'Classic';
      case BubbleStyle.blur:    return 'Frosted';
      case BubbleStyle.heart:   return 'Heart';
      case BubbleStyle.star:    return 'Star';
      case BubbleStyle.diamond: return 'Diamond';
      case BubbleStyle.dog1:    return 'Cute Puppy';
      case BubbleStyle.dog2:    return 'Happy Dog';
      case BubbleStyle.dog3:    return 'Bunny';
    }
  }

  String get emoji {
    switch (this) {
      case BubbleStyle.classic: return '🫧';
      case BubbleStyle.blur:    return '☁️';
      case BubbleStyle.heart:   return '💗';
      case BubbleStyle.star:    return '⭐';
      case BubbleStyle.diamond: return '💎';
      case BubbleStyle.dog1:    return '🐶';
      case BubbleStyle.dog2:    return '🐕';
      case BubbleStyle.dog3:    return '🐰';
    }
  }

  String get description {
    switch (this) {
      case BubbleStyle.classic: return 'Iridescent glass that changes every level';
      case BubbleStyle.blur:    return 'Soft frosted-glass with a gentle glow';
      case BubbleStyle.heart:   return 'Rainbow iridescent heart-shaped bubbles';
      case BubbleStyle.star:    return 'Golden glowing star with sparkles';
      case BubbleStyle.diamond: return 'Icy crystal diamond with sharp facets';
      case BubbleStyle.dog1:    return 'Cute puppy bouncing inside a warm bubble';
      case BubbleStyle.dog2:    return 'Happy pup floating in a minty bubble';
      case BubbleStyle.dog3:    return 'Fluffy bunny hopping in a dreamy purple bubble';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case BubbleStyle.classic: return [const Color(0xFF4FC3F7), const Color(0xFF0072FF)];
      case BubbleStyle.blur:    return [const Color(0xFF90CAF9), const Color(0xFF5C7BCA)];
      case BubbleStyle.heart:   return [const Color(0xFFFF6B9D), const Color(0xFFCE93D8)];
      case BubbleStyle.star:    return [const Color(0xFFFFD54F), const Color(0xFFFF9100)];
      case BubbleStyle.diamond: return [const Color(0xFF80DEEA), const Color(0xFF00838F)];
      case BubbleStyle.dog1:    return [const Color(0xFFFFCC80), const Color(0xFFFF8A65)];
      case BubbleStyle.dog2:    return [const Color(0xFFA5D6A7), const Color(0xFF43A047)];
      case BubbleStyle.dog3:    return [const Color(0xFFCE93D8), const Color(0xFF8E24AA)];
    }
  }

  /// Coin cost to unlock. 0 means free.
  int get coinCost {
    switch (this) {
      case BubbleStyle.classic: return 0;
      case BubbleStyle.blur:    return 100;
      case BubbleStyle.heart:   return 200;
      case BubbleStyle.star:    return 300;
      case BubbleStyle.diamond: return 400;
      case BubbleStyle.dog1:
      case BubbleStyle.dog2:
      case BubbleStyle.dog3:    return kDebugMode ? 0 : 500;
    }
  }

  /// Award cost to unlock alongside coins. 0 means free.
  int get awardCost {
    switch (this) {
      case BubbleStyle.classic: return 0;
      case BubbleStyle.blur:    return 1;
      case BubbleStyle.heart:   return 2;
      case BubbleStyle.star:    return 3;
      case BubbleStyle.diamond: return 4;
      case BubbleStyle.dog1:
      case BubbleStyle.dog2:
      case BubbleStyle.dog3:    return kDebugMode ? 0 : 5;
    }
  }

  /// Which dog asset path this style uses. Null for non-dog styles.
  String? get dogAssetPath {
    switch (this) {
      case BubbleStyle.dog1: return 'assets/dog/dog.png';
      case BubbleStyle.dog2: return 'assets/dog/dog_2.png';
      case BubbleStyle.dog3: return 'assets/dog/dog_3.png';
      default:               return null;
    }
  }

  bool get isDogStyle => dogAssetPath != null;

  bool get isPremium => coinCost > 0;

  String get key => name;

  static BubbleStyle fromKey(String key) {
    return BubbleStyle.values.firstWhere(
      (s) => s.name == key,
      orElse: () => BubbleStyle.classic,
    );
  }
}
