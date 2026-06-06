import 'package:flutter/material.dart';

/// Selectable bubble styles.
enum BubbleStyle {
  classic, // Iridescent glass bubble (level-based skins)
  blur,    // Frosted / soft blur effect
  heart,   // Rainbow iridescent heart-shaped bubble
  star,    // Golden glowing 5-point star bubble
  diamond, // Icy crystal diamond bubble
}

extension BubbleStyleInfo on BubbleStyle {
  String get label {
    switch (this) {
      case BubbleStyle.classic: return 'Classic';
      case BubbleStyle.blur:    return 'Frosted';
      case BubbleStyle.heart:   return 'Heart';
      case BubbleStyle.star:    return 'Star';
      case BubbleStyle.diamond: return 'Diamond';
    }
  }

  String get emoji {
    switch (this) {
      case BubbleStyle.classic: return '🫧';
      case BubbleStyle.blur:    return '☁️';
      case BubbleStyle.heart:   return '🩷';
      case BubbleStyle.star:    return '⭐';
      case BubbleStyle.diamond: return '💎';
    }
  }

  String get description {
    switch (this) {
      case BubbleStyle.classic: return 'Iridescent glass that changes every level';
      case BubbleStyle.blur:    return 'Soft frosted-glass with a gentle glow';
      case BubbleStyle.heart:   return 'Rainbow iridescent heart-shaped bubbles';
      case BubbleStyle.star:    return 'Golden glowing star with sparkles';
      case BubbleStyle.diamond: return 'Icy crystal diamond with sharp facets';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case BubbleStyle.classic: return [const Color(0xFF4FC3F7), const Color(0xFF0072FF)];
      case BubbleStyle.blur:    return [const Color(0xFF90CAF9), const Color(0xFF5C7BCA)];
      case BubbleStyle.heart:   return [const Color(0xFFFF6B9D), const Color(0xFFCE93D8)];
      case BubbleStyle.star:    return [const Color(0xFFFFD54F), const Color(0xFFFF9100)];
      case BubbleStyle.diamond: return [const Color(0xFF80DEEA), const Color(0xFF00838F)];
    }
  }

  String get key => name;

  static BubbleStyle fromKey(String key) {
    return BubbleStyle.values.firstWhere(
      (s) => s.name == key,
      orElse: () => BubbleStyle.classic,
    );
  }
}
