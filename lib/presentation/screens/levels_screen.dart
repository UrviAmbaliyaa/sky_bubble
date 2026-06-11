import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/background_assets.dart';
import '../../data/services/style_service.dart';
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
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 10.h),
                  itemCount: totalRows,
                  itemBuilder: (_, rowIdx) {
                    final start    = rowIdx * _kPerRow + 1;
                    final end      = (start + _kPerRow - 1).clamp(1, _kMaxLevel);
                    final levels   = List.generate(end - start + 1, (i) => start + i);
                    final reversed = rowIdx.isOdd;
                    return _SnakeRow(
                      levels:    reversed ? levels.reversed.toList() : levels,
                      reversed:  reversed,
                      current:   current,
                      svc:       _svc,
                      isLastRow: rowIdx == totalRows - 1,
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
        onTap: state != _NodeState.locked
            ? () => Get.toNamed(AppRoutes.game, arguments: {'bestScore': 0})
            : null,
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
          Center(child: _LockedOverlay(nodeSize: nodeSize, level: level)),

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

// ─── Locked overlay ───────────────────────────────────────────────────────────

class _LockedOverlay extends StatelessWidget {
  final double nodeSize;
  final int    level;
  const _LockedOverlay({required this.nodeSize, required this.level});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.black.withValues(alpha: 0.58),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Lock icon — centred
            Center(
              child: Icon(
                Icons.lock_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: nodeSize * 0.36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
