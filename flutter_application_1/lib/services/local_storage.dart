import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/historical_figure.dart';

class LocalStorage {
  LocalStorage(this.preferences);

  final SharedPreferencesAsync preferences;

  Future<List<HistoricalFigure>> readFavorites() async =>
      HistoricalFigure.decodeSaved(await preferences.getString('favorites'));

  Future<List<String>> readHistory() async =>
      await preferences.getStringList('history') ?? [];

  Future<void> saveFavorites(List<HistoricalFigure> figures) =>
      preferences.setString(
        'favorites',
        jsonEncode(figures.map((figure) => figure.toJson()).toList()),
      );

  Future<void> saveHistory(List<String> history) =>
      preferences.setStringList('history', history);
}
