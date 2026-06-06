class LevelConfig {
  final int level;
  final int maxBubbles;
  final int scoreThreshold;

  const LevelConfig({
    required this.level,
    required this.maxBubbles,
    required this.scoreThreshold,
  });

  /// Every 500 points → next level (unbounded, skin/bg cycles after level 9).
  static int levelForScore(int score) => (score ~/ 500) + 1;

  /// Speed ramp: +0.08× every 500 points, max 2.0× — gentle kids pace.
  static double speedMultiplierForScore(int score) {
    final milestone = score ~/ 500;
    return (0.50 + milestone * 0.08).clamp(0.50, 2.0);
  }

  static const List<LevelConfig> _levels = [
    LevelConfig(level: 1, maxBubbles: 5,  scoreThreshold: 0),
    LevelConfig(level: 2, maxBubbles: 8,  scoreThreshold: 500),
    LevelConfig(level: 3, maxBubbles: 11, scoreThreshold: 1000),
    LevelConfig(level: 4, maxBubbles: 14, scoreThreshold: 1500),
    LevelConfig(level: 5, maxBubbles: 17, scoreThreshold: 2000),
    LevelConfig(level: 6, maxBubbles: 20, scoreThreshold: 2500),
    LevelConfig(level: 7, maxBubbles: 23, scoreThreshold: 3000),
    LevelConfig(level: 8, maxBubbles: 26, scoreThreshold: 3500),
    LevelConfig(level: 9, maxBubbles: 30, scoreThreshold: 4000),
  ];

  static LevelConfig forScore(int score) {
    LevelConfig result = _levels.first;
    for (final cfg in _levels) {
      if (score >= cfg.scoreThreshold) result = cfg;
    }
    return result;
  }
}
