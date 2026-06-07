class LevelConfig {
  final int level;
  final int maxBubbles;
  final int scoreThreshold;

  const LevelConfig({
    required this.level,
    required this.maxBubbles,
    required this.scoreThreshold,
  });

  /// Every 200 points → next level (unbounded, skin/bg cycles after level 9).
  static int levelForScore(int score) => (score ~/ 200) + 1;

  /// Speed ramp: starts at 0.65× (medium), +0.05× every 200 pts, max 1.6×.
  static double speedMultiplierForScore(int score) {
    final milestone = score ~/ 200;
    return (0.65 + milestone * 0.05).clamp(0.65, 1.6);
  }

  static const List<LevelConfig> _levels = [
    LevelConfig(level: 1, maxBubbles: 5,  scoreThreshold: 0),
    LevelConfig(level: 2, maxBubbles: 8,  scoreThreshold: 200),
    LevelConfig(level: 3, maxBubbles: 11, scoreThreshold: 400),
    LevelConfig(level: 4, maxBubbles: 14, scoreThreshold: 600),
    LevelConfig(level: 5, maxBubbles: 17, scoreThreshold: 800),
    LevelConfig(level: 6, maxBubbles: 20, scoreThreshold: 1000),
    LevelConfig(level: 7, maxBubbles: 23, scoreThreshold: 1200),
    LevelConfig(level: 8, maxBubbles: 26, scoreThreshold: 1400),
    LevelConfig(level: 9, maxBubbles: 30, scoreThreshold: 1600),
  ];

  static LevelConfig forScore(int score) {
    LevelConfig result = _levels.first;
    for (final cfg in _levels) {
      if (score >= cfg.scoreThreshold) result = cfg;
    }
    return result;
  }

  // ─── Wave size ──────────────────────────────────────────────────────────────
  // Returns (minBubbles, maxBubbles) spawned simultaneously per wave.
  // Hard rule: minimum is always 2–3, maximum never exceeds 5.
  // The caller clamps against remaining screen capacity so maxBubbles on-screen
  // is never exceeded regardless of the wave size returned here.
  //
  // Level 1–2  →  2–3   (always at least 2 right from the start)
  // Level 3–4  →  2–4
  // Level 5+   →  3–5   (hard max: 5 bubbles per wave)
  static (int, int) waveSizeRange(int level) {
    if (level <= 2) return (2, 3);
    if (level <= 4) return (2, 4);
    return (3, 5); // level 5 and above — always 3–5 bubbles per wave
  }
}
