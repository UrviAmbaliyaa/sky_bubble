import '../../data/models/score_model.dart';

abstract class IScoreRepository {
  void saveScore(ScoreModel score);
  List<ScoreModel> getAllScores();
}
