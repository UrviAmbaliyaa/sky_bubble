import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/background_assets.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/safe_asset_background.dart';
import '../widgets/screen_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          ScreenHeader(
            backgroundAsset: BgAssets.free[2],
            titleIcon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Customize your experience',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 6.h),
                children: [
                  _SectionLabel(label: 'APPEARANCE'),
                  _SettingsTile(
                    icon: Icons.wallpaper_rounded,
                    iconColor: const Color(0xFF9C27B0),
                    gradient: const [Color(0xFF9C27B0), Color(0xFFCE93D8)],
                    title: 'Background',
                    subtitle: 'Change the game background theme',
                    onTap: () => Get.toNamed(AppRoutes.backgroundStyle),
                  ),
                  // _SettingsTile(
                  //   icon: Icons.bubble_chart_rounded,
                  //   iconColor: const Color(0xFF0288D1),
                  //   gradient: const [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                  //   title: 'Bubble Style',
                  //   subtitle: 'Pick your favourite bubble look',
                  //   onTap: () => Get.toNamed(AppRoutes.bubbleStyle),
                  // ),
                  // SizedBox(height: 1.5.h),
                  _SectionLabel(label: 'REWARDS'),
                  Obx(() {
                    RemoteAdConfigService? remote;
                    try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
                    final adsOn = remote?.adsEnabled.value ?? false;
                    if (!adsOn) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SettingsTile(
                          icon: Icons.monetization_on_rounded,
                          iconColor: Colors.amber,
                          gradient: const [Color(0xFFF9A825), Color(0xFFFFD54F)],
                          title: 'Earn Coins',
                          subtitle: 'Watch ads to earn free coins',
                          onTap: () => Get.toNamed(AppRoutes.adWatch),
                          trailing: Obx(() {
                            final svc = Get.find<StyleService>();
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.withOpacity(0.50)),
                              ),
                              child: Text(
                                '${svc.totalCoins.value} 🪙',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber,
                                ),
                              ),
                            );
                          }),
                        ),
                        _EarnAwardTile(),
                      ],
                    );
                  }),
                  SizedBox(height: 1.5.h),
                  _SectionLabel(label: 'GAME'),
                  _SettingsTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF43A047),
                    gradient: const [Color(0xFF43A047), Color(0xFF81C784)],
                    title: 'Progress',
                    subtitle: 'View your scores and learning stats',
                    onTap: () => Get.toNamed(AppRoutes.score),
                  ),
                  _SettingsTile(
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFF1565C0),
                    gradient: const [Color(0xFF1565C0), Color(0xFF4FC3F7)],
                    title: 'Levels',
                    subtitle: 'Browse the level map',
                    onTap: () => Get.toNamed(AppRoutes.levels),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h, top: 0.5.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF444466).withOpacity(0.55),
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

// ─── Settings tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: EdgeInsets.only(bottom: 1.2.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E4F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            // Icon badge
            Container(
              width: 11.w, height: 11.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.40),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 6.w),
            ),
            SizedBox(width: 3.5.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      )),
                  Text(widget.subtitle,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        color: const Color(0xFF444466).withOpacity(0.70),
                      )),
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              SizedBox(width: 2.w),
              widget.trailing!,
            ] else
              Icon(Icons.chevron_right_rounded, color: const Color(0xFF9090B0), size: 6.w),
          ]),
        ),
      ),
    );
  }
}

// ─── Earn Award tile (special — shows coin cost + buy logic) ─────────────────

class _EarnAwardTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    HomeController? ctrl;
    try { ctrl = Get.find<HomeController>(); } catch (_) {}

    return Obx(() {
      final svc       = Get.find<StyleService>();
      final canAfford = svc.totalCoins.value >= StyleService.awardPurchaseCost;
      final busy      = ctrl?.isBuyingAward.value ?? false;

      return GestureDetector(
        onTap: busy ? null : () => ctrl?.buyAwardWithCoins(),
        child: Container(
          margin: EdgeInsets.only(bottom: 1.2.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
          decoration: BoxDecoration(
            gradient: canAfford
                ? const LinearGradient(
                    colors: [Color(0xFFC62828), Color(0xFFEF9A9A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  )
                : null,
            color: canAfford ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: canAfford ? const Color(0xFFC62828).withOpacity(0.50) : const Color(0xFFE0E4F0),
              width: 1.2,
            ),
          ),
          child: Row(children: [
            Container(
              width: 11.w, height: 11.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.40), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 6.w),
            ),
            SizedBox(width: 3.5.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Earn Award',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: canAfford ? Colors.white : const Color(0xFF1A1A2E))),
                Text(
                  canAfford
                      ? 'Spend ${StyleService.awardPurchaseCost} coins to earn a medal'
                      : 'Need ${StyleService.awardPurchaseCost} coins to unlock',
                  style: TextStyle(
                      fontSize: 9.5.sp,
                      color: canAfford
                          ? Colors.white.withOpacity(0.75)
                          : const Color(0xFF444466).withOpacity(0.65)),
                ),
              ]),
            ),
            SizedBox(width: 2.w),
            if (busy)
              SizedBox(
                width: 5.w, height: 5.w,
                child: const CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(canAfford ? 0.25 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${StyleService.awardPurchaseCost} 🪙',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(canAfford ? 1.0 : 0.40),
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}
