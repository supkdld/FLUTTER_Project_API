import 'package:dio/dio.dart';

import '../models/historical_figure.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message);

  final String message;
}

class HistoricalFiguresService {
  HistoricalFiguresService(this.dio);

  final Dio dio;

  Future<List<HistoricalFigure>> search(
    String name, {
    int offset = 0,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        'historicalfigures',
        queryParameters: {'name': name.trim(), 'offset': offset},
        cancelToken: cancelToken,
      );
      if (response.data is! List) {
        throw const FormatException('Expected a list');
      }
      return (response.data as List)
          .map(
            (item) => HistoricalFigure.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      final status = error.response?.statusCode;
      if (status == 401) {
        throw const ApiFailure(
          'Сервис не принял ключ API. Проверьте ключ в настройках проекта.',
        );
      }
      if (status == 403) {
        throw const ApiFailure(
          'Доступ к API закрыт. Проверьте ключ и доступ к Historical Figures в аккаунте API Ninjas.',
        );
      }
      if (status == 429) {
        throw const ApiFailure(
          'Слишком много запросов. Подождите немного и попробуйте снова.',
        );
      }
      if (status != null && status >= 500) {
        throw const ApiFailure(
          'Сервис временно недоступен. Попробуйте чуть позже.',
        );
      }
      if (status != null) {
        throw const ApiFailure(
          'Не удалось выполнить поиск. Попробуйте другое имя.',
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const ApiFailure('Ответ задерживается. Попробуйте еще раз.');
      }
      throw const ApiFailure(
        'Не удалось подключиться. Проверьте интернет и повторите поиск.',
      );
    } on FormatException {
      throw const ApiFailure(
        'Сервис прислал непонятный ответ. Попробуйте позже.',
      );
    } on TypeError {
      throw const ApiFailure('Не получилось прочитать ответ сервиса.');
    }
  }
}
