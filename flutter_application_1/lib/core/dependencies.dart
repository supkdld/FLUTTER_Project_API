import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/history_controller.dart';
import '../services/historical_figures_service.dart';
import '../services/local_storage.dart';
import 'api_key_interceptor.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final config = jsonDecode(
    await rootBundle.loadString('config/api_key.json'),
  ) as Map<String, dynamic>;
  const environmentKey = String.fromEnvironment('API_NINJAS_KEY');
  final apiKey = environmentKey.isNotEmpty
      ? environmentKey
      : config['API_NINJAS_KEY'] as String;
  getIt.registerLazySingleton<ApiKeyInterceptor>(
    () => ApiKeyInterceptor(apiKey),
  );
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.api-ninjas.com/v1/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(getIt<ApiKeyInterceptor>());
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseBody: true,
        responseHeader: false,
        enabled: kDebugMode,
        logPrint: (value) =>
            debugPrint(value.toString().replaceAll(apiKey, '[hidden]')),
      ),
    );
    return dio;
  }, dispose: (dio) => dio.close(force: true));
  getIt.registerLazySingleton<HistoricalFiguresService>(
    () => HistoricalFiguresService(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LocalStorage>(
    () => LocalStorage(SharedPreferencesAsync()),
  );
  final controller = HistoryController(
    getIt<HistoricalFiguresService>(),
    getIt<LocalStorage>(),
  );
  await controller.initialize();
  getIt.registerSingleton<HistoryController>(
    controller,
    dispose: (value) => value.dispose(),
  );
}
