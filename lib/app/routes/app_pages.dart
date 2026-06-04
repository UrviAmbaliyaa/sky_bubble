import 'package:get/get.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/score_screen.dart';
import '../bindings/app_bindings.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GameScreen(),
      binding: GameBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: AppRoutes.score,
      page: () => const ScoreScreen(),
      binding: ScoreBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
