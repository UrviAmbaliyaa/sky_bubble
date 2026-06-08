import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  APP COLORS  — single source of truth for every color in the app.
//
//  Usage:  AppColors.primary, AppColors.glassBorder, AppColors.earnCoin …
//  Never use Color(0xFFXXXXXX) directly in widgets or screens.
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Core palette ─────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8FAFF);
  static const Color gameBackground = Color(0xFFEFF6FF);
  static const Color surface        = Colors.white;
  static const Color primary        = Color(0xFF4FC3F7);
  static const Color primaryDeep    = Color(0xFF0072FF);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textDark   = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF666680);
  static const Color textLight  = Color(0xFF9099B0);
  static const Color textWhite  = Colors.white;

  // ── Status / HUD ─────────────────────────────────────────────────────────────
  static const Color scoreGold  = Color(0xFFFFD700);
  static const Color scoreGoldD = Color(0xFFFFB300);
  static const Color levelGreen = Color(0xFF4CAF50);
  static const Color liveRed    = Color(0xFFFF5252);
  static const Color heartRed   = Color(0xFFFF4D6D);

  // ── Play button gradient ──────────────────────────────────────────────────────
  static const Color startGradientStart = Color(0xFFFFE066);
  static const Color startGradientMid   = Color(0xFFFF9500);
  static const Color startGradientEnd   = Color(0xFFFF5F00);

  // ── Glassmorphic UI ───────────────────────────────────────────────────────────
  static const Color glassWhite     = Color(0x26FFFFFF); // white 15 %
  static const Color glassBorder    = Color(0x59FFFFFF); // white 35 %
  static const Color glassBorderB   = Color(0x66FFFFFF); // white 40 %
  static const Color glassDark      = Color(0x47000000); // black 28 %
  static const Color glassSurface   = Color(0xBFFFFFFF); // white 75 %

  // ── Screen / overlay backgrounds ─────────────────────────────────────────────
  static const Color screenDarkTop    = Color(0xFF0D1B3E);
  static const Color screenDarkBottom = Color(0xFF0A0E1A);
  static const Color overlayDark      = Color(0xFF0A0020);
  static const Color barrierColor     = Color(0x8A000000); // black 54 %

  // ── Style-screen accent (header gradient) ─────────────────────────────────────
  static const Color styleScreenBg    = Color(0xFFF5F7FF);
  static const Color styleHeaderTop   = Color(0xFF1A1A6E);
  static const Color styleHeaderMid   = Color(0xFF6C63FF);
  static const Color styleHeaderBot   = Color(0xFF48CAE4);

  // ── Earn / reward ─────────────────────────────────────────────────────────────
  static const Color earnCoin            = Color(0xFF00D4FF);
  static const Color earnAward           = Color(0xFF43E97B);
  static const Color earnAwardInsufficient = Color(0xFFFF6B9D);
  static const Color pink               = Color(0xFFFF6B9D);
  static const Color pinkLight          = Color(0xFFFF4081);

  // ── Aurora skin (lv 71-80) ────────────────────────────────────────────────────
  static const Color aurora       = Color(0xFF00E676);
  static const Color auroraPurple = Color(0xFFCE93D8);
  static const Color auroraDeep   = Color(0xFF7C4DFF);

  // ── Plasma skin (lv 81-90) ────────────────────────────────────────────────────
  static const Color plasma     = Color(0xFFE040FB);
  static const Color plasmaHot  = Color(0xFFFF4081);
  static const Color plasmaWarm = Color(0xFFFFAB40);

  // ── Cosmic skin (lv 91-100) ───────────────────────────────────────────────────
  static const Color cosmicDeep   = Color(0xFF3D1A78);
  static const Color cosmicCyan   = Color(0xFF00BCD4);
  static const Color cosmicPurple = Color(0xFF7C4DFF);

  // ── Ad-watch screen ───────────────────────────────────────────────────────────
  static const Color adBgGlow = Color(0xFF7B2FBE);

  // ── Score screen ─────────────────────────────────────────────────────────────
  static const Color scoreCardBg   = Color(0xFFF5F7FF);
  static const Color scoreDivider  = Color(0xFFE8ECF4);
  static const Color scoreSubtle   = Color(0xFFA0A8C0);

  // ── Common accent shades ──────────────────────────────────────────────────────
  static const Color gold       = Color(0xFFFFD700);
  static const Color goldLight  = Color(0xFFFFEE58);
  static const Color goldDark   = Color(0xFFFF8C00);
  static const Color teal       = Color(0xFF4DB6AC);
  static const Color cyan       = Color(0xFF00BCD4);
  static const Color cyanLight  = Color(0xFF80DEEA);
  static const Color green      = Color(0xFF43E97B);
  static const Color greenTeal  = Color(0xFF38F9D7);
  static const Color orange     = Color(0xFFFF8C00);
  static const Color purple     = Color(0xFF7B2FBE);
  static const Color purpleLight= Color(0xFF9575CD);
  static const Color indigo     = Color(0xFF3D1A78);

  // ── Bubble base palette ───────────────────────────────────────────────────────
  static const List<Color> bubbleColors = [
    Color(0xFFFF6B9D), Color(0xFF4FC3F7), Color(0xFF81C784),
    Color(0xFFFFD54F), Color(0xFFFF8A65), Color(0xFFBA68C8),
    Color(0xFF4DB6AC), Color(0xFFE57373), Color(0xFF7986CB),
    Color(0xFF64B5F6),
  ];

  // ── Per-background bubble palettes (14 total) ─────────────────────────────────
  static const List<List<Color>> _levelPalettes = [
    [Color(0xFF4FC3F7), Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFF29B6F6)],
    [Color(0xFF5C6BC0), Color(0xFF7986CB), Color(0xFF9575CD), Color(0xFF4FC3F7), Color(0xFF3949AB)],
    [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF9C27B0), Color(0xFFE040FB), Color(0xFF7C4DFF)],
    [Color(0xFF81C784), Color(0xFFA5D6A7), Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFFAED581)],
    [Color(0xFFDCE775), Color(0xFFD4E157), Color(0xFFAED581), Color(0xFF9CCC65), Color(0xFF8BC34A)],
    [Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFF00ACC1)],
    [Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF90A4AE), Color(0xFF78909C), Color(0xFF4FC3F7)],
    [Color(0xFFFFD54F), Color(0xFFFFCA28), Color(0xFFFFF176), Color(0xFFFFEE58), Color(0xFFFFB300)],
    [Color(0xFF4FC3F7), Color(0xFF00BCD4), Color(0xFF80DEEA), Color(0xFFFF8A65), Color(0xFFFFAB91)],
    [Color(0xFFFF8A65), Color(0xFFFFAB91), Color(0xFFFFCC80), Color(0xFFFF7043), Color(0xFFFFD54F)],
    [Color(0xFFEF9A9A), Color(0xFFE57373), Color(0xFFFF8A65), Color(0xFFFFCC80), Color(0xFFFF7043)],
    [Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFF26C6DA), Color(0xFF4FC3F7), Color(0xFF00E5FF)],
    [Color(0xFF4DB6AC), Color(0xFF26A69A), Color(0xFF66BB6A), Color(0xFF80CBC4), Color(0xFF00BFA5)],
    [Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFF8A65), Color(0xFFFFAB91), Color(0xFFFF7043)],
  ];

  static List<Color> bubbleColorsForLevel(int level) =>
      _levelPalettes[(level - 1) % _levelPalettes.length];
}

// ═══════════════════════════════════════════════════════════════════════════════
//  APP DIMENSIONS  — single source of truth for spacing and radii.
//
//  Note: pixel values here are LOGICAL (device-independent). For responsive
//  sizing use Flutter Sizer (.w / .h / .sp) in widgets instead.
// ═══════════════════════════════════════════════════════════════════════════════

class AppDimensions {
  AppDimensions._();

  static const double paddingXS = 4.0;
  static const double paddingS  = 8.0;
  static const double paddingM  = 16.0;
  static const double paddingL  = 24.0;
  static const double paddingXL = 40.0;

  static const double radiusS  = 8.0;
  static const double radiusM  = 12.0;
  static const double radiusL  = 20.0;
  static const double radiusXL = 32.0;
  static const double radiusFull = 50.0;

  static const double startButtonSize = 190.0;
  static const double hudHeight       = 64.0;
  static const double iconSizeS       = 16.0;
  static const double iconSizeM       = 24.0;
  static const double iconSizeL       = 32.0;
}
