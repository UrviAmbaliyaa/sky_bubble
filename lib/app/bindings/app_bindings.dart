import 'package:get/get.dart';
import '../../domain/usecases/score_usecases.dart';
import '../../presentation/controllers/game_controller.dart';
import '../../presentation/controllers/home_controller.dart';
import '../../presentation/controllers/score_controller.dart';
import '../../presentation/controllers/ad_watch_controller.dart';
import '../../presentation/controllers/splash_controller.dart';
import '../../presentation/controllers/more_options_controller.dart';

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
    Get.put<HomeController>(
      HomeController(Get.find<GetScoresUseCase>()),
    );
  }
}

class GameBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<GameController>(GameController(Get.find<SaveScoreUseCase>()));
  }
}

class ScoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ScoreController>(ScoreController(Get.find<GetScoresUseCase>()));
  }
}

class LevelsBinding extends Bindings {
  @override
  void dependencies() {
    // LevelsScreen reads directly from StyleService (already permanent).
    // No extra controller needed.
  }
}

class AdWatchBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AdWatchController>(AdWatchController());
  }
}

class MoreOptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MoreOptionsController>(MoreOptionsController());
  }
}
