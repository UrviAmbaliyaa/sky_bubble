import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/constants/background_assets.dart';
import '../../data/models/level_config.dart';
import '../../data/services/style_service.dart';
import '../widgets/coin_display.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  LEVELS SCREEN — Snake map with live-reactive level tracking
//
//  Layout
//  ──────
//  • Sticky hero header (sky background, glassmorphic stats)
//  • Scrollable snake grid: 4 nodes per row, alternating direction
//  • Three node states: done (✓), current (PLAY), locked (🔒)
//  • All reactive state is accessed inside Obx so the map live-updates
// ═══════════════════════════════════════════════════════════════════════════════

const int    _kPerRow   = 4;
const int    _kMaxLevel = 100;
const double _kHeroFraction = 0.30;

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double>   _pulse;
  late final Animation<double>   _float;

  StyleService get _svc => Get.find<StyleService>();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalRows = ((_kMaxLevel - 1) ~/ _kPerRow) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          // ── Sticky hero (observes float animation only, coins observed inside) ─
          _HeroHeader(float: _float, svc: _svc),

          // ── Scrollable snake map — wrapped in Obx for live level updates ──────
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
                      pulse:     _pulse,
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

// ─── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final Animation<double> float;
  final StyleService      svc;

  const _HeroHeader({required this.float, required this.svc});

  @override
  Widget build(BuildContext context) {
    final heroH  = MediaQuery.of(context).size.height * _kHeroFraction;
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SizedBox(
        height: heroH + topPad,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (first free bg, always available)
            Image.asset(
              BgAssets.free[0],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A6E)),
            ),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x22000000),
                    Color(0xBB000000),
                    Color(0xFF0D0D1A),
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),

            // Decorative orbs
            Positioned(
              top: heroH * 0.05, right: -6.w,
              child: _Orb(size: 26.w, color: const Color(0xFF6C63FF), opacity: 0.22),
            ),
            Positioned(
              top: heroH * 0.25, left: -5.w,
              child: _Orb(size: 18.w, color: const Color(0xFF48CAE4), opacity: 0.18),
            ),
            Positioned(
              bottom: heroH * 0.15, right: 12.w,
              child: _Orb(size: 10.w, color: const Color(0xFFFFD700), opacity: 0.20),
            ),

            // Back button
            Positioned(
              top: topPad + 1.5.h, left: 4.w,
              child: _GlassBackButton(),
            ),

            // Coin pill (top-right)
            Positioned(
              top: topPad + 1.5.h, right: 4.w,
              child: Obx(() => _CoinPill(amount: svc.totalCoins.value)),
            ),

            // Bottom content (title + stats)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Obx(() {
                final current = svc.currentLevel.value;
                return Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 2.8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedBuilder(
                            animation: float,
                            builder: (_, __) => Transform.translate(
                              offset: Offset(0, float.value),
                              child: _MapIconCircle(),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Level Map',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  'Track your journey · Level $current active',
                                  style: TextStyle(
                                    fontSize: 8.5.sp,
                                    color: Colors.white.withOpacity(0.75),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.8.h),
                      // Stat chips
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.my_location_rounded,
                            label: 'Current',
                            value: 'Lvl $current',
                            gradColors: const [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                          ),
                          SizedBox(width: 2.w),
                          _StatChip(
                            icon: Icons.emoji_events_rounded,
                            label: 'Target',
                            value: '${LevelConfig.scoreTargetForLevel(current)} pts',
                            gradColors: const [Color(0xFFFFD700), Color(0xFFFF8C00)],
                          ),
                          SizedBox(width: 2.w),
                          _StatChip(
                            icon: Icons.lock_open_rounded,
                            label: 'Left',
                            value: '${_kMaxLevel - current + 1} lvls',
                            gradColors: const [Color(0xFF43E97B), Color(0xFF11998E)],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass back button ────────────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 11.w, height: 11.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.50), width: 1.2),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 4.8.w),
          ),
        ),
      ),
    );
  }
}

// ─── Coin pill ────────────────────────────────────────────────────────────────

class _CoinPill extends StatelessWidget {
  final int amount;
  const _CoinPill({required this.amount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.65),
              width: 1.2,
            ),
          ),
          child: CoinDisplay(amount: amount, imageSize: 16, fontSize: 13, gap: 4),
        ),
      ),
    );
  }
}

// ─── Map icon circle ──────────────────────────────────────────────────────────

class _MapIconCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13.w, height: 13.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.55),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.map_rounded, color: Colors.white, size: 6.w),
    );
  }
}

// ─── Decorative orb ───────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final String      value;
  final List<Color> gradColors;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(1.2.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradColors),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 3.5.w),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 7.sp,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Snake row ────────────────────────────────────────────────────────────────

class _SnakeRow extends StatelessWidget {
  final List<int>         levels;
  final bool              reversed;
  final int               current;
  final Animation<double> pulse;
  final StyleService      svc;
  final bool              isLastRow;

  const _SnakeRow({
    required this.levels,
    required this.reversed,
    required this.current,
    required this.pulse,
    required this.svc,
    required this.isLastRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: levels.map((lv) {
            final st = lv < current
                ? _NodeState.done
                : lv == current
                    ? _NodeState.current
                    : _NodeState.locked;
            return _LevelNode(level: lv, state: st, pulse: pulse, svc: svc);
          }).toList(),
        ),
        if (!isLastRow) _Connector(toRight: !reversed),
      ],
    );
  }
}

enum _NodeState { done, current, locked }

// ─── Row-end connector arrow ──────────────────────────────────────────────────

class _Connector extends StatelessWidget {
  final bool toRight;
  const _Connector({required this.toRight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        mainAxisAlignment:
            toRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!toRight) SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(1.2.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              toRight
                  ? Icons.subdirectory_arrow_right_rounded
                  : Icons.subdirectory_arrow_left_rounded,
              color: Colors.white,
              size: 5.w,
            ),
          ),
          if (toRight) SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

// ─── Available background pool helper ────────────────────────────────────────

List<String> _availablePool(StyleService svc) {
  final free    = List<String>.from(BgAssets.free);
  final premium = svc.unlockedBackgrounds.map((b) => b.assetPath).toList();
  return [...free, ...premium];
}

// ─── Level node ───────────────────────────────────────────────────────────────

class _LevelNode extends StatelessWidget {
  final int               level;
  final _NodeState        state;
  final Animation<double> pulse;
  final StyleService      svc;

  const _LevelNode({
    required this.level,
    required this.state,
    required this.pulse,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final nodeSize = state == _NodeState.current ? 20.w : 16.w;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.9.h),
      child: GestureDetector(
        onTap: state != _NodeState.locked
            ? () => Get.toNamed(AppRoutes.game, arguments: {'bestScore': 0})
            : null,
        child: Obx(() {
          final pool    = _availablePool(svc);
          final bgAsset = pool[(level - 1) % pool.length];
          return AnimatedBuilder(
            animation: pulse,
            builder: (_, child) => Transform.scale(
              scale: state == _NodeState.current ? pulse.value : 1.0,
              child: child,
            ),
            child: SizedBox(
              width: nodeSize,
              height: nodeSize,
              child: _NodeBody(
                level:    level,
                state:    state,
                bgAsset:  bgAsset,
                nodeSize: nodeSize,
              ),
            ),
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
      children: [
        // Background image
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
          _DoneOverlay(nodeSize: nodeSize)
        else if (state == _NodeState.current)
          _CurrentOverlay(level: level, nodeSize: nodeSize)
        else
          _LockedOverlay(level: level, nodeSize: nodeSize),

        // Outer ring
        _NodeRing(state: state),
      ],
    );
  }
}

// ─── Outer ring ───────────────────────────────────────────────────────────────

class _NodeRing extends StatelessWidget {
  final _NodeState state;
  const _NodeRing({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _NodeState.current:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6C63FF), width: 3.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.60),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      case _NodeState.done:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF43E97B), width: 2.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43E97B).withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        );
      case _NodeState.locked:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
        );
    }
  }
}

// ─── Done overlay ─────────────────────────────────────────────────────────────

class _DoneOverlay extends StatelessWidget {
  final double nodeSize;
  const _DoneOverlay({required this.nodeSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: const Color(0xFF43E97B).withOpacity(0.32),
        child: Center(
          child: Container(
            width:  nodeSize * 0.46,
            height: nodeSize * 0.46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF43E97B),
              boxShadow: [
                BoxShadow(color: Color(0x5543E97B), blurRadius: 8),
              ],
            ),
            child: Icon(Icons.check_rounded,
                color: Colors.white, size: nodeSize * 0.30),
          ),
        ),
      ),
    );
  }
}

// ─── Current overlay ──────────────────────────────────────────────────────────

class _CurrentOverlay extends StatelessWidget {
  final int    level;
  final double nodeSize;
  const _CurrentOverlay({required this.level, required this.nodeSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.black.withOpacity(0.28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$level',
              style: TextStyle(
                fontSize: nodeSize * 0.24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            SizedBox(height: nodeSize * 0.04),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: nodeSize * 0.10,
                vertical:   nodeSize * 0.03,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.55),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'PLAY',
                style: TextStyle(
                  fontSize: nodeSize * 0.14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Locked overlay ───────────────────────────────────────────────────────────
// Dark semi-opaque overlay with lock icon centred above the level number.
// Matches the screenshot: background image barely visible, white icon + number.

class _LockedOverlay extends StatelessWidget {
  final int    level;
  final double nodeSize;
  const _LockedOverlay({required this.level, required this.nodeSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        color: Colors.black.withOpacity(0.62),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.white.withOpacity(0.88),
                size: nodeSize * 0.30,
              ),
              SizedBox(height: nodeSize * 0.04),
              Text(
                '$level',
                style: TextStyle(
                  fontSize: nodeSize * 0.22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.88),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

