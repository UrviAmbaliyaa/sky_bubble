import 'package:get/get.dart';
import '../../data/repositories/score_repository_impl.dart';
import '../../domain/repositories/i_score_repository.dart';
import '../../domain/usecases/score_usecases.dart';
import '../../presentation/controllers/game_controller.dart';
import '../../presentation/controllers/home_controller.dart';
import '../../presentation/controllers/score_controller.dart';
import '../../presentation/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Get.put (eager) so onReady fires; lazyPut would never trigger because
    // the splash build() has no controller.xxx references.
    Get.put<SplashController>(SplashController());
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IScoreRepository>(ScoreRepositoryImpl(), permanent: true);
    Get.put(GetScoresUseCase(Get.find<IScoreRepository>()), permanent: true);
    // Not permanent: HomeController must be recreated each time home is pushed
    // (including after Get.offAllNamed) so onReady → _loadStats() runs fresh.
    Get.put<HomeController>(
      HomeController(Get.find<GetScoresUseCase>()),
    );
  }
}

class GameBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true ensures the repo and use-case survive across navigations
    // so scores are always written, whether the player is new or returning.
    if (!Get.isRegistered<IScoreRepository>()) {
      Get.put<IScoreRepository>(ScoreRepositoryImpl(), permanent: true);
    }
    if (!Get.isRegistered<SaveScoreUseCase>()) {
      Get.put(SaveScoreUseCase(Get.find<IScoreRepository>()), permanent: true);
    }
    // Eager put so GameController.onReady() fires and starts the game loop.
    Get.put<GameController>(GameController(Get.find<SaveScoreUseCase>()));
  }
}

class ScoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<IScoreRepository>(ScoreRepositoryImpl());
    Get.put(GetScoresUseCase(Get.find<IScoreRepository>()));
    Get.put<ScoreController>(ScoreController(Get.find<GetScoresUseCase>()));
  }
}
