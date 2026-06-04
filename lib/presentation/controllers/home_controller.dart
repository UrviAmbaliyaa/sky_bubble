import 'dart:math' as math;
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../domain/usecases/score_usecases.dart';

class HomeController extends GetxController {
  final GetScoresUseCase _getScores;
  HomeController(this._getScores);

  final RxInt bestScore = 0.obs;
  final RxInt totalGamesPlayed = 0.obs;

  @override
  void onReady() {
    super.onReady();
    _loadStats();
  }

  void _loadStats() {
    final scores = _getScores();
    totalGamesPlayed.value = scores.length;
    if (scores.isNotEmpty) {
      bestScore.value = scores.map((s) => s.score).reduce(math.max);
    }
  }

  void navigateToGame() => Get.toNamed(AppRoutes.game);

  void navigateToScores() => Get.toNamed(AppRoutes.score);

  void refreshStats() => _loadStats();
}
