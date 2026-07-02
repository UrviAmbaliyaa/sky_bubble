import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/background_assets.dart';
import '../../core/services/remote_ad_config_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/style_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/screen_header.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEVELS SCREEN — Snake map with live-reactive level tracking
//  No animations — pure StatelessWidget.
// ═══════════════════════════════════════════════════════════════════════════════

const int    _kPerRow   = 4;
const int    _kMaxLevel = 100;

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  StyleService get _svc => Get.find<StyleService>();

  @override
  Widget build(BuildContext context) {
    final totalRows = ((_kMaxLevel - 1) ~/ _kPerRow) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          ScreenHeader(
            backgroundAsset: BgAssets.levelMapHeader,
            titleIcon: Icons.map_rounded,
            title: 'Level Map',
            subtitle: 'Track your journey • Level active',
          ),

          Expanded(
            child: SafeArea(
              top: false,
              child: Obx(() {
                final current = _svc.currentLevel.value;
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 10.h),
                  itemCount: totalRows + 1,
                  itemBuilder: (_, rowIdx) {
                    if (rowIdx == 0) return _LearningBanner(svc: _svc);
                    final actualRow = rowIdx - 1;
                    final start  = actualRow * _kPerRow + 1;
                    final end    = (start + _kPerRow - 1).clamp(1, _kMaxLevel);
                    final levels = List.generate(end - start + 1, (i) => start + i);
                    return _SnakeRow(
                      levels:    levels,
                      reversed:  false,
                      current:   current,
                      svc:       _svc,
                      isLastRow: actualRow == totalRows - 1,
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Snake row ────────────────────────────────────────────────────────────────

class _SnakeRow extends StatelessWidget {
  final List<int>  levels;
  final bool       reversed;
  final int        current;
  final StyleService svc;
  final bool       isLastRow;

  const _SnakeRow({
    required this.levels,
    required this.reversed,
    required this.current,
    required this.svc,
    required this.isLastRow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: levels.map((lv) {
        final st = lv < current
            ? _NodeState.done
            : lv == current
                ? _NodeState.current
                : _NodeState.locked;
        return _LevelNode(level: lv, state: st, svc: svc);
      }).toList(),
    );
  }
}

enum _NodeState { done, current, locked }

// ─── Available background pool ────────────────────────────────────────────────

List<String> _availablePool(StyleService svc) {
  final free    = List<String>.from(BgAssets.free);
  final premium = svc.unlockedBackgrounds.map((b) => b.assetPath).toList();
  return [...free, ...premium];
}

// ─── Level node ───────────────────────────────────────────────────────────────

class _LevelNode extends StatelessWidget {
  final int        level;
  final _NodeState state;
  final StyleService svc;

  const _LevelNode({
    required this.level,
    required this.state,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.9.h),
      child: GestureDetector(
        onTap: state == _NodeState.locked ? null : () {
          HomeController? homeCtrl;
          try { homeCtrl = Get.find<HomeController>(); } catch (_) {}
          if (homeCtrl != null) {
            homeCtrl.showModeSelection(startLevel: level);
          } else {
            // Fallback: HomeController not in stack, navigate directly to game
            RemoteAdConfigService? remote;
            try { remote = Get.find<RemoteAdConfigService>(); } catch (_) {}
            final adsOn   = remote?.adsEnabled.value     ?? false;
            final moreAds = remote?.moreAdsEnabled.value ?? false;
            void goToGame() => Get.toNamed(AppRoutes.game,
                arguments: {'bestScore': 0, 'startLevel': level});
            if (adsOn && moreAds) {
              Get.find<AdService>().showInterstitial(onDismissed: goToGame);
            } else {
              goToGame();
            }
          }
        },
        child: Obx(() {
          final pool    = _availablePool(svc);
          final bgAsset = pool[(level - 1) % pool.length];
          final nodeSize = 16.w;
          final isCurrent = state == _NodeState.current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: nodeSize,
                height: nodeSize,
                child: _NodeBody(
                  level:    level,
                  state:    state,
                  bgAsset:  bgAsset,
                  nodeSize: nodeSize,
                ),
              ),
              SizedBox(height: 0.4.h),
              Text(
                '$level',
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isCurrent ? const Color(0xFF6C63FF) : const Color(0xFF444466),
                ),
              ),
              SizedBox(height: 0.3.h),
              _LevelStars(level: level, state: state, svc: svc),
              // 📚 badge if this level was cleared in learning mode
              if (svc.learningLevel.value > level)
                Text('📚', style: TextStyle(fontSize: 8.sp)),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Node body ────────────────────────────────────────────────────────────────

class _NodeBody extends StatelessWidget {
  final int        level;
  final _NodeState state;
  final String     bgAsset;
  final double     nodeSize;

  const _NodeBody({
    required this.level,
    required this.state,
    required this.bgAsset,
    required this.nodeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Background image — always fully visible
        ClipOval(
          child: Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFFEEF0FF)),
          ),
        ),

        // State overlay
        if (state == _NodeState.done)
          Center(child: _DoneOverlay(nodeSize: nodeSize, level: level))
        else if (state == _NodeState.current)
          Center(child: _CurrentOverlay(nodeSize: nodeSize, level: level))
        else
          Center(child: _LockedOverlay(nodeSize: nodeSize)),

        // Outer ring — no shadows
        _NodeRing(state: state),
      ],
    );
  }
}

// ─── Outer ring — removed (no borders) ───────────────────────────────────────

class _NodeRing extends StatelessWidget {
  final _NodeState state;
  const _NodeRing({required this.state});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── Done overlay — clear image + level number + checkmark ───────────────────

class _DoneOverlay extends StatelessWidget {
  final double nodeSize;
  final int    level;
  const _DoneOverlay({required this.nodeSize, required this.level});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Checkmark — centred
        Center(
          child: Container(
            width:  nodeSize * 0.44,
            height: nodeSize * 0.44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF43E97B),
            ),
            child: Icon(Icons.check_rounded,
                color: Colors.white, size: nodeSize * 0.28),
          ),
        ),
      ],
    );
  }
}

// ─── Current overlay — level number + play button ────────────────────────────

class _CurrentOverlay extends StatelessWidget {
  final double nodeSize;
  final int    level;
  const _CurrentOverlay({required this.nodeSize, required this.level});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.black.withValues(alpha: 0.22),
        child: Center(
          child: Container(
            width:  nodeSize * 0.52,
            height: nodeSize * 0.52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: nodeSize * 0.34),
          ),
        ),
      ),
    );
  }
}

// ─── Level stars (shown below all nodes) ─────────────────────────────────────

class _LevelStars extends StatelessWidget {
  final int level;
  final _NodeState state;
  final StyleService svc;
  const _LevelStars({required this.level, required this.state, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stars = svc.getStarsForLevel(level);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final earned = i < stars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Icon(
              Icons.star_rounded,
              size: 15,
              color: earned ? const Color(0xFFFFCC00) : const Color(0xFFDDDDDD),
              shadows: earned
                  ? [const Shadow(color: Color(0xFFFFAA00), blurRadius: 4)]
                  : null,
            ),
          );
        }),
      );
    });
  }
}

// ─── Locked overlay — dimmed image + lock icon ────────────────────────────────

class _LockedOverlay extends StatelessWidget {
  final double nodeSize;
  const _LockedOverlay({required this.nodeSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width:  nodeSize * 0.46,
            height: nodeSize * 0.46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.30),
            ),
            child: Icon(Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: nodeSize * 0.28),
          ),
        ),
      ),
    );
  }
}

// ─── Learning mode banner (top of level map) ─────────────────────────────────

class _LearningBanner extends StatelessWidget {
  final StyleService svc;
  const _LearningBanner({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lvl   = svc.learningLevel.value;
      final words = svc.totalWordsLearned.value;
      if (words == 0) return const SizedBox.shrink(); // never played learning

      String tierEmoji;
      String tierLabel;
      Color  tierColor;
      if (lvl <= 10)       { tierEmoji = '🌱'; tierLabel = 'Easy';   tierColor = const Color(0xFF43A047); }
      else if (lvl <= 30)  { tierEmoji = '🌿'; tierLabel = 'Medium'; tierColor = const Color(0xFF0288D1); }
      else if (lvl <= 60)  { tierEmoji = '🌳'; tierLabel = 'Hard';   tierColor = const Color(0xFF7B1FA2); }
      else                 { tierEmoji = '🔥'; tierLabel = 'Expert'; tierColor = const Color(0xFFE64A19); }

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.learning),
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0.5.h, 0, 1.5.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A237E), tierColor.withOpacity(0.85)],
              begin: Alignment.centerLeft,
              end:   Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:      tierColor.withOpacity(0.30),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Text(tierEmoji, style: const TextStyle(fontSize: 28)),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '📚 Learning Progress',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Level $lvl • $tierLabel tier • $words words learned',
                    style: TextStyle(
                      fontSize: 8.5.sp,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Play',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
