import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'data/repositories/score_repository_impl.dart';
import 'data/services/ad_service.dart';
import 'data/services/sound_service.dart';
import 'data/services/storage_service.dart';
import 'data/services/style_service.dart';
import 'domain/repositories/i_score_repository.dart';
import 'domain/usecases/score_usecases.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Get.putAsync(() => StorageService().init(), permanent: true);
  await Get.putAsync(() => SoundService().init(),   permanent: true);
  await Get.putAsync(() => StyleService().init(),   permanent: true);
  await Get.putAsync(() => AdService().init(),      permanent: true);

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
      statusBarIconBrightness: Brightness.light, // white icons — Android
      statusBarBrightness: Brightness.dark,       // white icons — iOS
    ),
  );
  runApp(const BubblePopApp());
}
