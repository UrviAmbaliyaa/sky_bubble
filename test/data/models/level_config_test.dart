import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_pumping/data/models/level_config.dart';

void main() {
  group('LevelConfig', () {
    test('score target for level calculation', () {
      expect(LevelConfig.scoreTargetForLevel(1), equals(1000));
      expect(LevelConfig.scoreTargetForLevel(5), equals(5000));
      expect(LevelConfig.scoreTargetForLevel(10), equals(10000));
    });

    test('time limit for level calculation', () {
      expect(LevelConfig.timeLimitForLevel(1), equals(const Duration(minutes: 5)));
      expect(LevelConfig.timeLimitForLevel(10), equals(const Duration(minutes: 14)));
    });

    test('speed multiplier for level', () {
      expect(LevelConfig.speedMultiplierForLevel(1), closeTo(0.35, 0.01));
      expect(LevelConfig.speedMultiplierForLevel(100), closeTo(1.15, 0.01));
    });

    test('spawn interval for level', () {
      expect(LevelConfig.spawnIntervalForLevel(1), equals(2000));
      expect(LevelConfig.spawnIntervalForLevel(100), equals(800));
    });

    test('wave size range for level', () {
      expect(LevelConfig.waveSizeRange(1), equals((5, 7)));
      expect(LevelConfig.waveSizeRange(50), equals((5, 9)));
      expect(LevelConfig.waveSizeRange(100), equals((5, 12)));
    });
  });
}
