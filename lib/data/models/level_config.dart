import '../../core/constants/app_config.dart';

class LevelConfig {
  final int level;
  final int maxBubbles;
  final int scoreThreshold;

  const LevelConfig({
    required this.level,
    required this.maxBubbles,
    required this.scoreThreshold,
  });

  // Speed milestone: +0.40× at every 200 score points (unchanged in test mode)
  static double speedMultiplierForScore(int score) {
    final milestone = score ~/ 200;
    return (0.50 + milestone * 0.40).clamp(0.50, 5.0);
  }

  static const List<LevelConfig> _levels = [
    LevelConfig(level: 1, maxBubbles: 4,  scoreThreshold: 0),
    LevelConfig(level: 2, maxBubbles: 6,  scoreThreshold: 50),
    LevelConfig(level: 3, maxBubbles: 8,  scoreThreshold: 150),
    LevelConfig(level: 4, maxBubbles: 10, scoreThreshold: 300),
    LevelConfig(level: 5, maxBubbles: 12, scoreThreshold: 500),
    LevelConfig(level: 6, maxBubbles: 15, scoreThreshold: 800),
    LevelConfig(level: 7, maxBubbles: 18, scoreThreshold: 1200),
  ];

  /// In test mode every level unlocks every 30 score points so all 7 skins
  /// are reachable in a single short game session.
  static LevelConfig forScore(int score) {
    if (kTestingMode) {
      final idx = (score ~/ 30).clamp(0, _levels.length - 1);
      return _levels[idx];
    }
    LevelConfig result = _levels.first;
    for (final cfg in _levels) {
      if (score >= cfg.scoreThreshold) result = cfg;
    }
    return result;
  }
}
