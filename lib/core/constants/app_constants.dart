import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFF);
  static const Color gameBackground = Color(0xFFEFF6FF);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF4FC3F7);
  static const Color scoreGold = Color(0xFFFFD700);
  static const Color levelGreen = Color(0xFF4CAF50);
  static const Color liveRed = Color(0xFFFF5252);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF666680);
  static const Color startGradientStart = Color(0xFFFFE066);
  static const Color startGradientMid = Color(0xFFFF9500);
  static const Color startGradientEnd = Color(0xFFFF5F00);

  static const List<Color> bubbleColors = [
    Color(0xFFFF6B9D),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFFFD54F),
    Color(0xFFFF8A65),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFE57373),
    Color(0xFF7986CB),
    Color(0xFF64B5F6),
  ];

  // One color palette per background (14 total), matched to the scene mood.
  // Cycles with the same modulo as BgAssets.forLevel so bubbles always feel
  // at home in the current background.
  static const List<List<Color>> _levelPalettes = [
    // 0 – bg_sky: sky blues & whites
    [Color(0xFF4FC3F7), Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFF29B6F6)],
    // 1 – bg_dark_sky: deep blues & lavender
    [Color(0xFF5C6BC0), Color(0xFF7986CB), Color(0xFF9575CD), Color(0xFF4FC3F7), Color(0xFF3949AB)],
    // 2 – bg_galaxy: purples & cosmic
    [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF9C27B0), Color(0xFFE040FB), Color(0xFF7C4DFF)],
    // 3 – bg_garden: fresh greens
    [Color(0xFF81C784), Color(0xFFA5D6A7), Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFFAED581)],
    // 4 – bg_garden_gate: warm greens & lime
    [Color(0xFFDCE775), Color(0xFFD4E157), Color(0xFFAED581), Color(0xFF9CCC65), Color(0xFF8BC34A)],
    // 5 – bg_moonsoon: stormy grays & teals
    [Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFF00ACC1)],
    // 6 – bg_night: midnight blues & silvers
    [Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF90A4AE), Color(0xFF78909C), Color(0xFF4FC3F7)],
    // 7 – bg_night_star: gold & silver star tones
    [Color(0xFFFFD54F), Color(0xFFFFCA28), Color(0xFFFFF176), Color(0xFFFFEE58), Color(0xFFFFB300)],
    // 8 – beach_sky: ocean & coral
    [Color(0xFF4FC3F7), Color(0xFF00BCD4), Color(0xFF80DEEA), Color(0xFFFF8A65), Color(0xFFFFAB91)],
    // 9 – bg_morning: sunrise oranges
    [Color(0xFFFF8A65), Color(0xFFFFAB91), Color(0xFFFFCC80), Color(0xFFFF7043), Color(0xFFFFD54F)],
    // 10 – bg_morning_view: warm reds & gold
    [Color(0xFFEF9A9A), Color(0xFFE57373), Color(0xFFFF8A65), Color(0xFFFFCC80), Color(0xFFFF7043)],
    // 11 – bg_morning_view_water: teals & aqua
    [Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFF26C6DA), Color(0xFF4FC3F7), Color(0xFF00E5FF)],
    // 12 – bg_peacoc: teal & emerald
    [Color(0xFF4DB6AC), Color(0xFF26A69A), Color(0xFF66BB6A), Color(0xFF80CBC4), Color(0xFF00BFA5)],
    // 13 – bs_morning: warm morning rose & amber
    [Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFF8A65), Color(0xFFFFAB91), Color(0xFFFF7043)],
  ];

  /// Returns the color palette that matches the current background for [level].
  static List<Color> bubbleColorsForLevel(int level) =>
      _levelPalettes[(level - 1) % _levelPalettes.length];
}

class AppDimensions {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 40.0;
  static const double radiusM = 12.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 32.0;
  static const double startButtonSize = 190.0;
  static const double hudHeight = 64.0;
}
