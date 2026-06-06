import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Safely loads a background image asset with a cinematic Ken-Burns effect:
///   • Horizontal pan  — smoothly sweeps left → right → left (±40 px)
///   • Zoom in / out   — scale pulses between 1.08 and 1.22
///
/// Falls back to [fallback] while the asset is loading or if it is missing,
/// so no platform-level exception is ever thrown for a missing file.
class SafeAssetBackground extends StatefulWidget {
  final String assetPath;
  final double progress; // kept for API compatibility (unused internally)
  final Widget fallback;

  const SafeAssetBackground({
    super.key,
    required this.assetPath,
    required this.progress,
    required this.fallback,
  });

  @override
  State<SafeAssetBackground> createState() => _SafeAssetBackgroundState();
}

enum _AssetState { checking, found, missing }

class _SafeAssetBackgroundState extends State<SafeAssetBackground>
    with TickerProviderStateMixin {
  _AssetState _state = _AssetState.checking;

  // Pan controller  — left ↔ right, 8-second cycle
  late AnimationController _panCtrl;
  late Animation<double> _panX;

  // Zoom controller — zoom in then out, 12-second cycle
  late AnimationController _zoomCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // ── Pan: sweeps ±30 px horizontally ───────────────────────────────────
    // Scale stays ≥ 1.25 so a 30 px pan never exposes a screen edge on any
    // device (worst case: 320 px wide → margin = 320*0.125 = 40 px > 30 px).
    _panCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _panX = Tween<double>(begin: -30.0, end: 30.0).animate(
      CurvedAnimation(parent: _panCtrl, curve: Curves.easeInOut),
    );

    // ── Zoom: 1.25 → 1.38 → 1.25 ─────────────────────────────────────────
    _zoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.25, end: 1.38).animate(
      CurvedAnimation(parent: _zoomCtrl, curve: Curves.easeInOut),
    );

    _checkAsset(widget.assetPath);
  }

  @override
  void didUpdateWidget(SafeAssetBackground old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath) {
      setState(() => _state = _AssetState.checking);
      _checkAsset(widget.assetPath);
    }
  }

  Future<void> _checkAsset(String path) async {
    try {
      await rootBundle.load(path);
      if (mounted) setState(() => _state = _AssetState.found);
    } catch (_) {
      if (mounted) setState(() => _state = _AssetState.missing);
    }
  }

  @override
  void dispose() {
    _panCtrl.dispose();
    _zoomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state != _AssetState.found) return widget.fallback;

    return AnimatedBuilder(
      animation: Listenable.merge([_panCtrl, _zoomCtrl]),
      builder: (_, __) {
        // Add a gentle vertical drift at half the pan frequency for variety
        final dy = math.sin(_panCtrl.value * math.pi) * 18.0;

        return ClipRect(
          child: Transform.translate(
            offset: Offset(_panX.value, dy),
            child: Transform.scale(
              scale: _scale.value,
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }
}
