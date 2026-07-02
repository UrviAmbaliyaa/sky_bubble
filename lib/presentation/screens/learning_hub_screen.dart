import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/background_assets.dart';
import '../../core/constants/word_dictionary.dart';
import '../../data/services/style_service.dart';
import '../widgets/screen_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEARNING HUB  — Progress, Levels, Quiz Preview, Play button
// ═══════════════════════════════════════════════════════════════════════════════

class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<StyleService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          ScreenHeader(
            backgroundAsset: BgAssets.free[1],
            titleIcon: Icons.menu_book_rounded,
            title: 'Learning Hub',
            subtitle: 'Spell words · Build vocabulary',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final lvl   = svc.learningLevel.value;
                final words = svc.totalWordsLearned.value;

                String tierEmoji, tierLabel;
                Color tierColor;
                List<Color> tierGrad;
                if (lvl <= 10)       {
                  tierEmoji = '🌱'; tierLabel = 'Easy';
                  tierColor = const Color(0xFF43A047);
                  tierGrad  = const [Color(0xFF43A047), Color(0xFF81C784)];
                } else if (lvl <= 30) {
                  tierEmoji = '🌿'; tierLabel = 'Medium';
                  tierColor = const Color(0xFF0288D1);
                  tierGrad  = const [Color(0xFF0288D1), Color(0xFF4FC3F7)];
                } else if (lvl <= 60) {
                  tierEmoji = '🌳'; tierLabel = 'Hard';
                  tierColor = const Color(0xFF7B1FA2);
                  tierGrad  = const [Color(0xFF7B1FA2), Color(0xFFCE93D8)];
                } else {
                  tierEmoji = '🔥'; tierLabel = 'Expert';
                  tierColor = const Color(0xFFE64A19);
                  tierGrad  = const [Color(0xFFE64A19), Color(0xFFFF8A65)];
                }

                final nextLevelWords = 5 + (lvl - 1) * 3;
                final tierProgress   = ((lvl - 1) % 10) / 10.0;

                return ListView(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 8.h),
                  children: [
                    // ── Big Play button ──────────────────────────────────
                    _LearningPlayButton(gradient: tierGrad),
                    SizedBox(height: 2.5.h),

                    // ── Progress card ────────────────────────────────────
                    _SectionTitle('📊  Your Progress'),
                    SizedBox(height: 1.h),
                    _GlassCard(
                      child: Column(children: [
                        Row(children: [
                          _StatBubble(emoji: tierEmoji, label: 'Tier', value: tierLabel, color: tierColor),
                          SizedBox(width: 3.w),
                          _StatBubble(emoji: '📚', label: 'Level', value: '$lvl', color: const Color(0xFF6C63FF)),
                          SizedBox(width: 3.w),
                          _StatBubble(emoji: '✅', label: 'Words', value: '$words', color: const Color(0xFF43E97B)),
                        ]),
                        SizedBox(height: 2.h),
                        Row(children: [
                          Text('Tier Progress',
                              style: TextStyle(fontSize: 9.5.sp, color: const Color(0xFF888899))),
                          const Spacer(),
                          Text('$tierLabel tier',
                              style: TextStyle(
                                  fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                        ]),
                        SizedBox(height: 0.8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: tierProgress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF0F2FF),
                            valueColor: AlwaysStoppedAnimation(tierColor),
                          ),
                        ),
                        SizedBox(height: 1.2.h),
                        Text(
                          'Next level needs $nextLevelWords words',
                          style: TextStyle(fontSize: 9.sp, color: const Color(0xFFAAAAAA)),
                        ),
                      ]),
                    ),

                    SizedBox(height: 2.5.h),

                    // ── Tier levels overview ─────────────────────────────
                    _SectionTitle('🗺️  Learning Levels'),
                    SizedBox(height: 1.h),
                    _TierRow(currentLevel: lvl),

                    SizedBox(height: 2.5.h),

                    // ── Quiz preview section ─────────────────────────────
                    _SectionTitle('🧠  Quiz Preview'),
                    SizedBox(height: 1.h),
                    _QuizPreviewCard(level: lvl),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Learning play button ─────────────────────────────────────────────────────

class _LearningPlayButton extends StatefulWidget {
  final List<Color> gradient;
  const _LearningPlayButton({required this.gradient});

  @override
  State<_LearningPlayButton> createState() => _LearningPlayButtonState();
}

class _LearningPlayButtonState extends State<_LearningPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); Get.toNamed(AppRoutes.learning); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withOpacity(0.50),
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
                'START LEARNING',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tier row overview ────────────────────────────────────────────────────────

class _TierRow extends StatelessWidget {
  final int currentLevel;
  const _TierRow({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final tiers = [
      _TierInfo('🌱', 'Easy',   'L1–10\n3 letters',  const Color(0xFF43A047),  1, 10),
      _TierInfo('🌿', 'Medium', 'L11–30\n4 letters', const Color(0xFF0288D1), 11, 30),
      _TierInfo('🌳', 'Hard',   'L31–60\n5 letters', const Color(0xFF7B1FA2), 31, 60),
      _TierInfo('🔥', 'Expert', 'L61+\n6 letters',   const Color(0xFFE64A19), 61, 999),
    ];

    return Row(
      children: tiers.map((t) {
        final isActive = currentLevel >= t.minLvl && currentLevel <= t.maxLvl;
        final isDone   = currentLevel > t.maxLvl;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: tiers.last == t ? 0 : 2.w),
            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 1.w),
            decoration: BoxDecoration(
              color: isActive ? t.color.withOpacity(0.12) : const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? t.color.withOpacity(0.60) : const Color(0xFFE0E4F0),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Text(t.emoji, style: TextStyle(fontSize: 18.sp)),
                SizedBox(height: 0.4.h),
                Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isActive ? t.color : const Color(0xFF888899),
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  t.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 7.5.sp, color: const Color(0xFFAAAAAA), height: 1.2),
                ),
                if (isDone) ...[
                  SizedBox(height: 0.4.h),
                  Icon(Icons.check_circle_rounded, color: const Color(0xFF43E97B), size: 14),
                ] else if (isActive) ...[
                  SizedBox(height: 0.4.h),
                  Icon(Icons.play_arrow_rounded, color: t.color, size: 14),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TierInfo {
  final String emoji, name, desc;
  final Color color;
  final int minLvl, maxLvl;
  const _TierInfo(this.emoji, this.name, this.desc, this.color, this.minLvl, this.maxLvl);
}

// ─── Quiz preview card ────────────────────────────────────────────────────────

class _QuizPreviewCard extends StatelessWidget {
  final int level;
  const _QuizPreviewCard({required this.level});

  @override
  Widget build(BuildContext context) {
    // Pick a sample word from current tier for illustration
    final pool = WordDictionary.poolForLevel(level);
    final sample = pool.isNotEmpty ? pool[0] : const WordEntry('CAT', '🐱');
    final word = sample.word.toUpperCase();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('🧠',
                style: TextStyle(
                    fontFamily: '',
                    fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
                    fontSize: 20.sp)),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spell the Word',
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
                Text('Pop bubbles with the right letters',
                    style: TextStyle(fontSize: 8.5.sp, color: const Color(0xFF888899))),
              ],
            ),
          ]),
          SizedBox(height: 2.h),
          // Sample word boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(word.length, (i) {
              final revealed = i == 0;
              return Container(
                width: 10.w, height: 10.w,
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                decoration: BoxDecoration(
                  color: revealed
                      ? const Color(0xFF43E97B).withOpacity(0.15)
                      : const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: revealed
                        ? const Color(0xFF43E97B).withOpacity(0.60)
                        : const Color(0xFFD0D4E8),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    revealed ? word[i] : '?',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: revealed ? const Color(0xFF43E97B) : const Color(0xFFBBBBCC),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.5.h),
          Center(
            child: Text(
              'Pop bubbles to spell: ${sample.emoji}  ${word}',
              style: TextStyle(
                fontSize: 9.sp,
                color: const Color(0xFFAAAAAA),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

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
  final String emoji, label, value;
  final Color color;
  const _StatBubble({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(emoji,
                style: TextStyle(
                    fontFamily: '',
                    fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
                    fontSize: 16.sp)),
            SizedBox(height: 0.4.h),
            Text(value,
                style: TextStyle(
                    fontSize: 11.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1A1A2E))),
            Text(label, style: TextStyle(fontSize: 8.sp, color: const Color(0xFF888899))),
          ],
        ),
      ),
    );
  }
}
