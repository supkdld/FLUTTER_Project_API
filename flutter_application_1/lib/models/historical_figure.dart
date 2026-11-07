import 'dart:convert';

class HistoricalFigure {
  const HistoricalFigure({
    required this.name,
    required this.title,
    required this.info,
  });

  final String name;
  final String title;
  final Map<String, dynamic> info;

  String get id => '${name.toLowerCase()}|${title.toLowerCase()}';

  factory HistoricalFigure.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Missing figure name');
    }
    return HistoricalFigure(
      name: name.trim(),
      title: json['title']?.toString() ?? '',
      info: json['info'] is Map
          ? Map<String, dynamic>.from(json['info'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'title': title, 'info': info};

  static String displayValue(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .map(displayValue)
          .where((item) => item.isNotEmpty)
          .join('\n');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${displayValue(entry.value)}')
          .join('\n');
    }
    return value.toString().trim();
  }

  static List<HistoricalFigure> decodeSaved(String? value) {
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List)
          .map(
            (item) => HistoricalFigure.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on Object {
      return [];
    }
  }
}
