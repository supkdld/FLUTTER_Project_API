import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/historical_figure.dart';
import '../services/historical_figures_service.dart';
import '../services/local_storage.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this.service, this.storage);

  final HistoricalFiguresService service;
  final LocalStorage storage;
  List<HistoricalFigure> results = [];
  List<HistoricalFigure> favorites = [];
  List<String> history = [];
  String query = '';
  String? error;
  String? storageError;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  bool searched = false;
  bool saving = false;
  bool _disposed = false;
  int _offset = 0;
  CancelToken? _cancelToken;

  Future<void> initialize() async {
    try {
      favorites = await storage.readFavorites();
      history = await storage.readHistory();
    } on Object {
      storageError =
          'Не удалось прочитать сохраненные данные. Поиск по сети доступен.';
    }
  }

  bool isFavorite(HistoricalFigure figure) =>
      favorites.any((item) => item.id == figure.id);

  Future<void> search(String value, {bool more = false}) async {
    final name = value.trim();
    if (name.isEmpty || (more && (loading || loadingMore || !hasMore))) return;
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;
    error = null;
    if (more) {
      loadingMore = true;
    } else {
      query = name;
      loading = true;
      loadingMore = false;
      results = [];
      _offset = 0;
      hasMore = false;
      searched = true;
    }
    notifyListeners();
    try {
      final page = await service.search(
        name,
        offset: more ? _offset : 0,
        cancelToken: token,
      );
      if (_disposed || token.isCancelled) return;
      _offset += page.length;
      final unique = {for (final item in results) item.id: item};
      for (final item in page) {
        unique[item.id] = item;
      }
      results = unique.values.toList();
      hasMore = page.length == 10;
      if (!more) {
        history = [
          name,
          ...history.where((item) => item.toLowerCase() != name.toLowerCase()),
        ].take(12).toList();
        try {
          await storage.saveHistory(List.of(history));
        } on Object {
          storageError = 'Не удалось сохранить историю на устройстве.';
        }
      }
    } on ApiFailure catch (failure) {
      if (!_disposed && !token.isCancelled) error = failure.message;
    } on DioException catch (failure) {
      if (!CancelToken.isCancel(failure) && !_disposed && !token.isCancelled) {
        error = 'Не удалось выполнить запрос. Попробуйте снова.';
      }
    } finally {
      if (!_disposed && identical(_cancelToken, token)) {
        loading = false;
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(HistoricalFigure figure) async {
    if (saving) return;
    saving = true;
    final previous = List<HistoricalFigure>.of(favorites);
    favorites = isFavorite(figure)
        ? favorites.where((item) => item.id != figure.id).toList()
        : [...favorites, figure];
    notifyListeners();
    try {
      await storage.saveFavorites(List.of(favorites));
    } on Object {
      favorites = previous;
      storageError = 'Не удалось сохранить избранное. Попробуйте еще раз.';
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await storage.saveHistory([]);
      history = [];
    } on Object {
      storageError = 'Не удалось очистить историю.';
    }
    if (!_disposed) notifyListeners();
  }

  void dismissStorageError() {
    storageError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel();
    super.dispose();
  }
}
