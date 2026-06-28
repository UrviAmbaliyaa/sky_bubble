// ═══════════════════════════════════════════════════════════════════════════════
//  LEVEL CONFIG  — 100-level progression system
//
//  Design goals
//  ─────────────
//  • Level 1   : very relaxed — bubbles cross in ~6 s, few on screen, slow spawn
//  • Level 50  : moderate  — ~3.5 s crossing, medium density
//  • Level 100 : challenging — ~2 s crossing, dense waves, fast spawns
//
//  All parameters are computed from the level number with simple math so there
//  are no lookup tables to maintain and any level 1-100 (and beyond) is handled.
//
//  Scoring: 2000 pts for level 1, +500 per subsequent level.
// ═══════════════════════════════════════════════════════════════════════════════

class LevelConfig {
  final int level;
  final int maxBubbles;
  final int scoreThreshold;

  const LevelConfig({
    required this.level,
    required this.maxBubbles,
    required this.scoreThreshold,
  });

  // ─── Per-level score target — used for star rating only ────────────────────
  //
  // 3 stars: score >= target; 2 stars: >= target/2; 1 star: any completion.
  static int scoreTargetForLevel(int level) => level * 1000;

  // ─── Time-based level limit: Level 1 = 5 min, +1 min per level ─────────────
  // Level 1 → 5 min, Level 2 → 6 min, Level N → N + 4 min.
  static Duration timeLimitForLevel(int level) =>
      Duration(minutes: level + 4);

  // ─── Level from cumulative score (used only for speed/spawn formulas) ───────
  // Approximates level from a running score total. First level = 1000 pts,
  // each subsequent level adds 200 pts more, so cumulative target at level N is:
  //   sum = N*1000 + N*(N-1)/2 * 200   →  solve approximately as N ≈ sqrt(score/100)
  static int levelForScore(int score) {
    // Binary search for accuracy
    int lo = 1, hi = 200;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      final cumulative = _cumulativeTarget(mid);
      if (cumulative <= score) lo = mid; else hi = mid - 1;
    }
    return lo;
  }

  // Cumulative score needed to have completed [n] levels
  static int _cumulativeTarget(int n) {
    int total = 0;
    for (int i = 1; i <= n; i++) total += scoreTargetForLevel(i);
    return total;
  }

  // ─── Speed multiplier (0.30 → 1.0 over 100 levels) ─────────────────────────
  //
  // Uses a smooth curve so early levels feel very gentle and mid-to-late levels
  // feel progressively more demanding without any sudden jumps.
  //
  // Formula: mult = minMult + (maxMult - minMult) * t²
  //   where t = clamp((level - 1) / 99, 0, 1)
  //
  // t² gives a gentle start (acceleration) rather than a linear ramp — the
  // first 20 levels barely move, which keeps new players comfortable.
  //
  // level  1 → 0.30×  (very slow — ~6 s crossing at 800 px screen)
  // level 25 → 0.40×
  // level 50 → 0.58×
  // level 75 → 0.79×
  // level100 → 1.00×
  static const double _minSpeedMult = 0.35;
  static const double _maxSpeedMult = 1.15;

  static double speedMultiplierForLevel(int level) {
    final t = ((level - 1) / 99.0).clamp(0.0, 1.0);
    return _minSpeedMult + (_maxSpeedMult - _minSpeedMult) * t * t;
  }

  /// Convenience: derive level from score first, then return the multiplier.
  static double speedMultiplierForScore(int score) =>
      speedMultiplierForLevel(levelForScore(score));

  // ─── Spawn interval (ms) — 2000 ms → 800 ms over 100 levels ────────────────
  //
  // Shorter interval = bubbles arrive more frequently.
  // Uses a linear decay so the rhythm tightens steadily.
  //
  // level  1 → 2000 ms
  // level 50 → 1400 ms
  // level100 →  800 ms
  static int spawnIntervalForLevel(int level) {
    final t = ((level - 1) / 99.0).clamp(0.0, 1.0);
    return (2000 - (1200 * t)).round().clamp(800, 2000);
  }

  // ─── Max bubbles on screen — 8 → 25 over 100 levels ────────────────────────
  //
  // Starts at 8 (was 4) so the minimum wave of 5 always fits on screen even at
  // level 1. Grows to 25 at level 100 for dense late-game action.
  static int maxBubblesForLevel(int level) {
    final t = ((level - 1) / 99.0).clamp(0.0, 1.0);
    return (8 + (17 * t)).round().clamp(8, 25);
  }

  // ─── Wave size range ────────────────────────────────────────────────────────
  //
  // Minimum is always 5 so the screen never feels empty, especially at low
  // levels where the spawn interval is slowest (2000 ms).  The max grows with
  // level for progressively denser waves.
  //
  // Level  1–10  → 5–7  bubbles/wave
  // Level 11–30  → 5–8
  // Level 31–60  → 5–9
  // Level 61–80  → 5–10
  // Level 81–100 → 5–12  (max density)
  static (int, int) waveSizeRange(int level) {
    if (level <= 10) return (5, 7);
    if (level <= 30) return (5, 8);
    if (level <= 60) return (5, 9);
    if (level <= 80) return (5, 10);
    return (5, 12);
  }

  // ─── forScore (used by game_controller for capacity check) ─────────────────
  //
  // Returns a LevelConfig-compatible object derived purely from math so there
  // is no table to maintain.  Only maxBubbles is used by the caller.
  static LevelConfig forScore(int score) {
    final lv = levelForScore(score);
    return LevelConfig(
      level: lv,
      maxBubbles: maxBubblesForLevel(lv),
      scoreThreshold: (lv - 1) * 2000,
    );
  }
}
