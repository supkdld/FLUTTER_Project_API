import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/controllers/history_controller.dart';
import 'package:flutter_application_1/core/api_key_interceptor.dart';
import 'package:flutter_application_1/models/historical_figure.dart';
import 'package:flutter_application_1/services/historical_figures_service.dart';
import 'package:flutter_application_1/services/local_storage.dart';
import 'package:flutter_application_1/ui/figure_card.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, Object>{};
  final failWrites = ValueNotifier(false);

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<List<String>?> getStringList(String key) async =>
      values[key] as List<String>?;

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites.value) throw StateError('Storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    if (failWrites.value) throw StateError('Storage unavailable');
    values[key] = List<String>.of(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object value, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

Map<String, Object> person(String name) => {
  'name': name,
  'title': 'Scientist',
  'info': {
    'born': '1867',
    'awards': ['Physics', 'Chemistry'],
    'extra_field': {'value': 'detail'},
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late MemoryPreferences preferences;
  late HistoryController controller;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.api-ninjas.com/v1/'));
    dio.interceptors.add(ApiKeyInterceptor('test-key'));
    preferences = MemoryPreferences();
    controller = HistoryController(
      HistoricalFiguresService(dio),
      LocalStorage(preferences),
    );
  });

  tearDown(() {
    controller.dispose();
    dio.close(force: true);
  });

  test(
    'Dio interceptor sends API key and service parses dynamic biography fields',
    () async {
      dio.httpClientAdapter = TestAdapter((options) async {
        expect(options.headers['X-Api-Key'], 'test-key');
        expect(options.uri.path, '/v1/historicalfigures');
        expect(options.queryParameters, {'name': 'Marie Curie', 'offset': 10});
        return jsonResponse([person('Marie Curie')]);
      });
      final result = await controller.service.search(
        ' Marie Curie ',
        offset: 10,
      );
      expect(result.single.name, 'Marie Curie');
      expect(
        HistoricalFigure.displayValue(result.single.info['awards']),
        'Physics\nChemistry',
      );
      expect(
        HistoricalFigure.displayValue(result.single.info['extra_field']),
        'value: detail',
      );
    },
  );

  test(
    'HTTP errors produce readable messages and reset loading state',
    () async {
      for (final status in [400, 401, 403, 429, 503]) {
        dio.httpClientAdapter = TestAdapter(
          (_) async => jsonResponse({'error': 'Failure'}, status),
        );
        await controller.search('Curie');
        expect(controller.error, isNotEmpty);
        expect(controller.loading, isFalse);
        expect(controller.history, isEmpty);
      }
    },
  );

  test('Malformed response is shown as an error instead of crashing', () async {
    dio.httpClientAdapter = TestAdapter(
      (_) async => jsonResponse({'unexpected': true}),
    );
    await controller.search('Curie');
    expect(controller.error, contains('непонятный ответ'));
    expect(controller.loading, isFalse);
  });

  test(
    'New search cancels stale request and preserves newest results',
    () async {
      final old = Completer<ResponseBody>();
      dio.httpClientAdapter = TestAdapter((options) async {
        if (options.queryParameters['name'] == 'Old') return old.future;
        return jsonResponse([person('New')]);
      });
      final first = controller.search('Old');
      await Future<void>.delayed(Duration.zero);
      await controller.search('New');
      old.complete(jsonResponse([person('Old')]));
      await first;
      expect(controller.results.single.name, 'New');
      expect(controller.query, 'New');
      expect(controller.error, isNull);
      expect(controller.history, ['New']);
    },
  );

  test(
    'Pagination uses offset and retries failed page without losing results',
    () async {
      var fail = true;
      final offsets = <int>[];
      dio.httpClientAdapter = TestAdapter((options) async {
        final offset = options.queryParameters['offset'] as int;
        offsets.add(offset);
        if (offset == 0) {
          return jsonResponse(List.generate(10, (i) => person('Person $i')));
        }
        if (fail) return jsonResponse({'error': 'Failure'}, 503);
        return jsonResponse([person('Person 9'), person('Person 10')]);
      });
      await controller.search('Person');
      await controller.search('Person', more: true);
      expect(controller.results.length, 10);
      expect(controller.error, isNotNull);
      fail = false;
      await controller.search('Person', more: true);
      expect(offsets, [0, 10, 10]);
      expect(controller.results.length, 11);
      expect(controller.hasMore, isFalse);
      expect(controller.error, isNull);
    },
  );

  test('Favorites and history are restored by a new controller', () async {
    dio.httpClientAdapter = TestAdapter(
      (_) async => jsonResponse([person('Marie Curie')]),
    );
    await controller.search('Marie');
    await controller.toggleFavorite(controller.results.single);
    final restored = HistoryController(
      controller.service,
      LocalStorage(preferences),
    );
    await restored.initialize();
    expect(restored.favorites.single.info['awards'], ['Physics', 'Chemistry']);
    expect(restored.history, ['Marie']);
    await restored.toggleFavorite(restored.favorites.single);
    await restored.clearHistory();
    expect(await restored.storage.readFavorites(), isEmpty);
    expect(await restored.storage.readHistory(), isEmpty);
    restored.dispose();
  });

  test('Failed local write rolls back favorite change', () async {
    preferences.failWrites.value = true;
    await controller.toggleFavorite(
      HistoricalFigure.fromJson(person('Marie Curie')),
    );
    expect(controller.favorites, isEmpty);
    expect(controller.storageError, isNotNull);
    expect(controller.saving, isFalse);
  });

  testWidgets(
    'Search validates input and opens full details and saved favorite',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      dio.httpClientAdapter = TestAdapter(
        (_) async => jsonResponse([person('Marie Curie')]),
      );
      await tester.pumpWidget(HistoryApp(controller: controller));
      await tester.tap(find.text('Найти личность'));
      await tester.pumpAndSettle();
      expect(find.text('Введите имя для поиска'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Marie Curie');
      await tester.tap(find.text('Найти личность'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Marie Curie').last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FigureCard));
      await tester.pumpAndSettle();
      expect(find.text('Ближе к личности'), findsOneWidget);
      expect(find.text('Physics\nChemistry'), findsOneWidget);
      await tester.tap(find.byTooltip('В избранное'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Избранное'));
      await tester.pumpAndSettle();
      expect(find.text('Marie Curie'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home fits a narrow phone and enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HistoryApp(controller: controller));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
