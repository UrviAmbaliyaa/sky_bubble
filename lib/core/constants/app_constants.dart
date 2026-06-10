// ── AppColors is defined in its dedicated file; re-exported here for
//    backward-compatible imports across the codebase.
export 'app_colors.dart';

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
