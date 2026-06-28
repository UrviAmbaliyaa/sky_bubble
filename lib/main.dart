import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/remote_ad_config_service.dart';
import 'core/services/update_service.dart';
import 'data/repositories/score_repository_impl.dart';
import 'data/services/ad_service.dart';
import 'data/services/sound_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/style_service.dart';
import 'domain/repositories/i_score_repository.dart';
import 'domain/usecases/score_usecases.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  await Get.putAsync(() => StorageService().init(),         permanent: true);
  await Get.putAsync(() => SoundService().init(),           permanent: true);
  await Get.putAsync(() => StyleService().init(),           permanent: true);
  // RemoteAdConfigService must be ready before AdService so AdsIdManager
  // can read the configured ad IDs on first initialisation.
  Get.put<NavigationService>(NavigationService(), permanent: true);
  await Get.putAsync(() => RemoteAdConfigService().init(),  permanent: true);
  await Get.putAsync(() => AdService().init(),              permanent: true);
  await Get.putAsync(() => ConnectivityService().init(),    permanent: true);
  await Get.putAsync(() => UpdateService().init(),          permanent: true);

  // Register shared domain dependencies once at startup so individual
  // bindings never re-register them as permanent (which causes the
  // SmartManagement warning on back-navigation).
  Get.put<IScoreRepository>(ScoreRepositoryImpl(), permanent: true);
  Get.put<GetScoresUseCase>(
    GetScoresUseCase(Get.find<IScoreRepository>()),
    permanent: true,
  );
  Get.put<SaveScoreUseCase>(
    SaveScoreUseCase(Get.find<IScoreRepository>()),
    permanent: true,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const BubblePopApp());
}
