import 'package:flutter/material.dart';

import '../controllers/history_controller.dart';
import '../models/historical_figure.dart';
import 'palette.dart';

class FigureCard extends StatelessWidget {
  const FigureCard({
    super.key,
    required this.figure,
    required this.controller,
    required this.index,
  });

  final HistoricalFigure figure;
  final HistoryController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final favorite = controller.isFavorite(figure);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: index.isEven
            ? Colors.white
            : Palette.blush.withValues(alpha: .6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Palette.rose),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  FigureDetails(figure: figure, controller: controller),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 55,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Palette.blush
                        : Palette.sage.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    index.isEven
                        ? Icons.auto_stories_rounded
                        : Icons.local_florist_rounded,
                    color: Palette.olive,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        figure.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (figure.title.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          figure.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Palette.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Открыть историю  →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
                  onPressed: controller.saving
                      ? null
                      : () => controller.toggleFavorite(figure),
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Palette.olive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FigureDetails extends StatelessWidget {
  const FigureDetails({
    super.key,
    required this.figure,
    required this.controller,
  });

  final HistoricalFigure figure;
  final HistoryController controller;

  static const labels = {
    'born': 'Рождение',
    'died': 'Смерть',
    'years': 'Годы деятельности',
    'occupation': 'Занятия',
    'notable_work': 'Известные работы',
    'awards': 'Награды',
    'parents': 'Родители',
    'spouses': 'Супруги',
    'spouse': 'Супруги',
    'children': 'Дети',
    'partners': 'Партнеры',
    'office': 'Должности',
    'conflicts': 'События и сражения',
    'resting_place': 'Место захоронения',
    'cause_of_death': 'Причина смерти',
    'nationality': 'Национальность',
    'education': 'Образование',
    'known_for': 'Чем известен',
    'alma_mater': 'Учебное заведение',
    'birth_name': 'Имя при рождении',
    'full_name': 'Полное имя',
    'reign': 'Правление',
    'predecessor': 'Предшественник',
    'successor': 'Преемник',
    'religion': 'Религия',
    'citizenship': 'Гражданство',
    'signature': 'Подпись',
    'fields': 'Области работы',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Страница истории'),
        actions: [
          IconButton(
            tooltip: controller.isFavorite(figure)
                ? 'Убрать из избранного'
                : 'В избранное',
            onPressed: controller.saving
                ? null
                : () => controller.toggleFavorite(figure),
            icon: Icon(
              controller.isFavorite(figure)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Palette.olive,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Palette.blush,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: Palette.olive,
                    size: 38,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    figure.name,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    figure.title,
                    style: const TextStyle(color: Palette.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Ближе к личности',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Биографические сведения из API Ninjas\nДанные сервиса приведены на английском',
              style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 20),
            if (figure.info.values.every(
              (value) => HistoricalFigure.displayValue(value).isEmpty,
            ))
              const Text('У этой личности пока нет дополнительных сведений.'),
            for (final entry in figure.info.entries)
              if (HistoricalFigure.displayValue(entry.value).isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Palette.sage.withValues(alpha: .35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[entry.key] ?? entry.key.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Palette.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        HistoricalFigure.displayValue(entry.value),
                        style: const TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Каждая жизнь оставляет свой лепесток',
                style: TextStyle(color: Palette.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
