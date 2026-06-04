import 'package:get/get.dart';
import '../../domain/repositories/i_score_repository.dart';
import '../models/score_model.dart';
import '../services/storage_service.dart';

class ScoreRepositoryImpl implements IScoreRepository {
  final StorageService _storage = Get.find<StorageService>();

  @override
  void saveScore(ScoreModel score) => _storage.writeScore(score);

  @override
  List<ScoreModel> getAllScores() => _storage.readScores();
}
