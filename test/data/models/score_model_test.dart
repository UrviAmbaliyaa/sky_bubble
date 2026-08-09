import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_pumping/data/models/score_model.dart';

void main() {
  group('ScoreModel', () {
    test('should convert to and from JSON correctly', () {
      final now = DateTime.now();
      final score = ScoreModel(score: 1500, level: 3, playedAt: now);

      final json = score.toJson();
      expect(json['score'], equals(1500));
      expect(json['level'], equals(3));
      expect(json['playedAt'], equals(now.toIso8601String()));

      final reconstructed = ScoreModel.fromJson(json);
      expect(reconstructed.score, equals(score.score));
      expect(reconstructed.level, equals(score.level));
      expect(reconstructed.playedAt, equals(now));
    });
  });
}
