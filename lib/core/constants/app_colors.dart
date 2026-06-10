import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  APP COLORS  — single source of truth for every color in the app.
//
//  Usage:  AppColors.primary, AppColors.glassBorder, AppColors.earnCoin …
//  ⚠️  Never use Color(0xFFXXXXXX) directly in widgets or screens.
//      Always reference a named constant from this file.
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
  static const Color earnCoin              = Color(0xFF00D4FF);
  static const Color earnAward             = Color(0xFF43E97B);
  static const Color earnAwardInsufficient = Color(0xFFFF6B9D);
  static const Color pink                  = Color(0xFFFF6B9D);
  static const Color pinkLight             = Color(0xFFFF4081);

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
  static const Color scoreCardBg  = Color(0xFFF5F7FF);
  static const Color scoreDivider = Color(0xFFE8ECF4);
  static const Color scoreSubtle  = Color(0xFFA0A8C0);

  // ── Common accent shades ──────────────────────────────────────────────────────
  static const Color gold        = Color(0xFFFFD700);
  static const Color goldLight   = Color(0xFFFFEE58);
  static const Color goldDark    = Color(0xFFFF8C00);
  static const Color teal        = Color(0xFF4DB6AC);
  static const Color cyan        = Color(0xFF00BCD4);
  static const Color cyanLight   = Color(0xFF80DEEA);
  static const Color green       = Color(0xFF43E97B);
  static const Color greenTeal   = Color(0xFF38F9D7);
  static const Color orange      = Color(0xFFFF8C00);
  static const Color purple      = Color(0xFF7B2FBE);
  static const Color purpleLight = Color(0xFF9575CD);
  static const Color indigo      = Color(0xFF3D1A78);

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

  // ── Level Map screen ──────────────────────────────────────────────────────────
  // Header background gradient stops (over the premium_bg_08 image)
  static const Color levelMapOverlayTop    = Color(0x55000000); // 33 % black
  static const Color levelMapOverlayMid    = Color(0x11000000); //  7 % black
  static const Color levelMapOverlayBotMid = Color(0xCC0D1535); // 80 % navy
  static const Color levelMapOverlayBot    = Color(0xFF0D1535); // solid navy

  // Stat chip background (dark navy card)
  static const Color levelMapChipBg        = Color(0xFF1A2040);
  static const Color levelMapChipBorder    = Color(0xFF2A3260);

  // Map icon circle gradient
  static const Color levelMapIconStart     = Color(0xFF7B61FF);
  static const Color levelMapIconEnd       = Color(0xFF48CAE4);

  // Subtitle accent ("Level X active")
  static const Color levelMapAccentText    = Color(0xFF9D86FF);

  // Coin pill
  static const Color levelMapCoinBg        = Color(0xCC000000); // 80 % black
  static const Color levelMapCoinBorder    = Color(0xFFFFD700);

  // Stat icon gradients
  static const Color levelMapCurrentStart  = Color(0xFF7B61FF);
  static const Color levelMapCurrentEnd    = Color(0xFF48CAE4);
  static const Color levelMapTargetStart   = Color(0xFFFFB300);
  static const Color levelMapTargetEnd     = Color(0xFFFF6D00);
  static const Color levelMapLeftStart     = Color(0xFF43E97B);
  static const Color levelMapLeftEnd       = Color(0xFF11998E);

  // Node ring / connector colours
  static const Color nodeRingCurrent   = Color(0xFF7B61FF);
  static const Color nodeRingDone      = Color(0xFF43E97B);
  static const Color connectorStart    = Color(0xFF7B61FF);
  static const Color connectorEnd      = Color(0xFF48CAE4);

  // ── Level Map — snake grid ────────────────────────────────────────────────
  // Scaffold background for the levels screen
  static const Color levelMapScaffold  = Color(0xFFF0F2FF);
  // Fallback color when a node image is missing
  static const Color nodeImageFallback = Color(0xFFEEF0FF);
  // Node play-badge gradient colours
  static const Color nodeBadgeStart    = Color(0xFF6C63FF);
  static const Color nodeBadgeEnd      = Color(0xFF48CAE4);
  // Done-overlay fill tint (green at ~32 % opacity)
  static const Color nodeDoneTint      = Color(0x5243E97B);
  // Done-overlay icon circle glow
  static const Color nodeDoneShadow    = Color(0x5543E97B);

  // ── Snake map redesign (new node + connector design) ──────────────────────
  // Lavender scaffold background
  static const Color snakeMapBg           = Color(0xFFEAE8F5);

  // Done node: solid green circle
  static const Color nodeDiscDone         = Color(0xFF4CAF50);
  static const Color nodeDiscDoneShadow   = Color(0x554CAF50);

  // Current/Active node: blue-purple gradient
  static const Color nodeDiscActiveTop    = Color(0xFF9B72FF);
  static const Color nodeDiscActiveBot    = Color(0xFF5B8DEF);
  static const Color nodeDiscActiveGlow   = Color(0x669B72FF);
  static const Color nodeDiscActiveRing   = Color(0xFFB09BFF);

  // Locked node: dark navy disc
  static const Color nodeDiscLocked       = Color(0xFF1C2140);
  static const Color nodeDiscLockedBorder = Color(0xFF2E3560);

  // "ACTIVE" badge on current node
  static const Color nodeActiveBadge      = Color(0xFFFF9500);
  static const Color nodeActiveBadgeText  = Color(0xFFFFFFFF);

  // Dot connector between nodes and side arc connector
  static const Color nodeDotConnector     = Color(0xFFCDCBEF);

  // Scroll-down FAB
  static const Color scrollFabBg          = Color(0xFF4A4A6A);

  // ── Node platform (stone base + grass + flowers) ──────────────────────────
  static const Color platformBase         = Color(0xFF181820);
  static const Color platformFace         = Color(0xFF2E2E40);
  static const Color platformHighlight    = Color(0xFF454558);
  static const Color platformGrassMain    = Color(0xFF5CB030);
  static const Color platformGrassDark    = Color(0xFF3A7E20);

  // Dot connector between nodes in snake map rows
  static const Color snakeConnectorDot    = Color(0xFFCDCBEF);

  // Done node radial gradient (light center)
  static const Color nodeDiscDoneLight    = Color(0xFF6ADF62);
  // Active node inner circle blue body
  static const Color nodeDiscActiveBlue   = Color(0xFF2E44B8);
  static const Color nodeDiscActiveBlueLt = Color(0xFF4E68DC);
}
