import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_pumping/data/models/score_model.dart';
import 'package:bubble_pumping/domain/repositories/i_score_repository.dart';
import 'package:bubble_pumping/domain/usecases/score_usecases.dart';

class MockScoreRepository implements IScoreRepository {
  final List<ScoreModel> _scores = [];

  @override
  List<ScoreModel> getAllScores() => List.unmodifiable(_scores);

  @override
  void saveScore(ScoreModel score) {
    _scores.add(score);
  }
}

void main() {
  group('Score UseCases', () {
    late MockScoreRepository repository;
    late SaveScoreUseCase saveScoreUseCase;
    late GetScoresUseCase getScoresUseCase;

    setUp(() {
      repository = MockScoreRepository();
      saveScoreUseCase = SaveScoreUseCase(repository);
      getScoresUseCase = GetScoresUseCase(repository);
    });

    test('should save and get scores correctly', () {
      final score1 = ScoreModel(score: 500, level: 1, playedAt: DateTime.now());
      final score2 = ScoreModel(score: 1200, level: 2, playedAt: DateTime.now());

      saveScoreUseCase(score1);
      saveScoreUseCase(score2);

      final scores = getScoresUseCase();
      expect(scores.length, equals(2));
      expect(scores[0].score, equals(500));
      expect(scores[1].score, equals(1200));
    });
  });
}
