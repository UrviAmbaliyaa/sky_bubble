import '../../data/models/score_model.dart';
import '../repositories/i_score_repository.dart';

class SaveScoreUseCase {
  final IScoreRepository _repository;
  SaveScoreUseCase(this._repository);

  void call(ScoreModel score) => _repository.saveScore(score);
}

class GetScoresUseCase {
  final IScoreRepository _repository;
  GetScoresUseCase(this._repository);

  List<ScoreModel> call() => _repository.getAllScores();
}
