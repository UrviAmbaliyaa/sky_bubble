import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/score_model.dart';

class StorageService extends GetxService {
  static const _scoresKey = 'scores';
  late final GetStorage _box;

  Future<StorageService> init() async {
    _box = GetStorage();
    return this;
  }

  List<ScoreModel> readScores() {
    final raw = _box.read<List>(_scoresKey);
    if (raw == null) return [];
    return raw
        .map((e) => ScoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void writeScore(ScoreModel score) {
    final existing = readScores();
    existing.add(score);
    _box.write(_scoresKey, existing.map((s) => s.toJson()).toList());
  }

  void clearScores() => _box.remove(_scoresKey);
}
