import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/screen_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GAME HUB  — Play entry, progress, bubble style, level map shortcut
// ═══════════════════════════════════════════════════════════════════════════════

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final svc  = Get.find<StyleService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          ScreenHeader(
            backgroundAsset: BgAssets.levelMapHeader,
            titleIcon: Icons.sports_esports_rounded,
            title: 'Game Hub',
            subtitle: 'Pop bubbles & beat your best score',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 8.h),
                children: [
                  // ── Play button ──────────────────────────────────────────
                  _BigPlayButton(onTap: () {
                    Get.back();
                    ctrl.navigateToGame();
                  }),
                  SizedBox(height: 2.5.h),

                  // ── Progress card ────────────────────────────────────────
                  _SectionTitle(title: '📊  Progress'),
                  SizedBox(height: 1.h),
                  Obx(() {
                    final best    = ctrl.bestScore.value;
                    final today   = ctrl.todayTotalScore.value;
                    final current = svc.currentLevel.value;
                    final pct     = ((current - 1) / 100).clamp(0.0, 1.0);
                    return _GlassCard(
                      child: Column(children: [
                        Row(children: [
                          _StatBubble(emoji: '🏆', label: 'Best', value: '$best'),
                          SizedBox(width: 3.w),
                          _StatBubble(emoji: '⭐', label: 'Today', value: '$today'),
                          SizedBox(width: 3.w),
                          _StatBubble(emoji: '🎯', label: 'Level', value: '$current'),
                        ]),
                        SizedBox(height: 2.h),
                        Row(children: [
                          Text('Level Progress',
                              style: TextStyle(fontSize: 9.5.sp, color: const Color(0xFF888899))),
                          const Spacer(),
                          Text('$current / 100',
                              style: TextStyle(
                                  fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                        ]),
                        SizedBox(height: 0.8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF0F2FF),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                          ),
                        ),
                      ]),
                    );
                  }),

                  SizedBox(height: 2.5.h),

                  // ── Quick actions ────────────────────────────────────────
                  _SectionTitle(title: '⚡  Quick Actions'),
                  SizedBox(height: 1.h),
                  Row(children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.bubble_chart_rounded,
                        label: 'Bubble\nStyle',
                        gradient: const [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                        onTap: () => Get.toNamed(AppRoutes.bubbleStyle),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.map_rounded,
                        label: 'Level\nMap',
                        gradient: const [Color(0xFF1565C0), Color(0xFF6C63FF)],
                        onTap: () => Get.toNamed(AppRoutes.levels),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Progress\nStats',
                        gradient: const [Color(0xFF43A047), Color(0xFF81C784)],
                        onTap: () => Get.toNamed(AppRoutes.score),
                      ),
                    ),
                  ]),

                  SizedBox(height: 2.5.h),

                  // ── Current level node preview ────────────────────────────
                  _SectionTitle(title: '🎮  Current Level'),
                  SizedBox(height: 1.h),
                  Obx(() {
                    final level = svc.currentLevel.value;
                    final stars = svc.getStarsForLevel(level > 1 ? level - 1 : 1);
                    return _GlassCard(
                      child: Row(children: [
                        Container(
                          width: 15.w, height: 15.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level $level',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: List.generate(3, (i) => Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: i < stars ? Colors.amber : const Color(0xFFDDDDEE),
                                )),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                level <= 10 ? 'Beginner zone' :
                                level <= 30 ? 'Getting harder' :
                                level <= 60 ? 'Expert territory' : 'Master level',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF888899),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.levels),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF6C63FF).withOpacity(0.50)),
                            ),
                            child: Text(
                              'Map',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF9B97FF),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Big play button ──────────────────────────────────────────────────────────

class _BigPlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BigPlayButton({required this.onTap});

  @override
  State<_BigPlayButton> createState() => _BigPlayButtonState();
}

class _BigPlayButtonState extends State<_BigPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.50),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 34),
              SizedBox(width: 3.w),
              Text(
                'PLAY NOW',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A2E),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E4F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _StatBubble({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(height: 0.4.h),
            Text(value,
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1A2E))),
            Text(label,
                style: TextStyle(fontSize: 8.sp, color: const Color(0xFF888899))),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withOpacity(0.40),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 7.w),
              SizedBox(height: 0.8.h),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
