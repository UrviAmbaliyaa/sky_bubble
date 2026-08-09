// ═══════════════════════════════════════════════════════════════════════════════
//  SINGLE COMMON ENTRY FILE FOR ALL AD FUNCTIONALITY
//
//  Import this single file anywhere in your app:
//    import 'core/ads/ads.dart';
//
//  Contains:
//    - AdIds (Platform-specific Android vs iOS test & live unit IDs)
//    - AdWidgetManager (Central AdMob controller, ATT requests, interstitials)
//    - BannerAdWidget (Standalone inline banner widget)
//    - GlobalBannerWidget (Persistent bottom banner widget)
//    - FirestoreAdConfigService (Cloud Firestore app_config/admob listener)
// ═══════════════════════════════════════════════════════════════════════════════

export '../services/firestore_ad_config_service.dart';
export 'ad_widget_manager.dart';
