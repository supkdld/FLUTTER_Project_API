import 'package:flutter/material.dart';

import '../controllers/history_controller.dart';
import 'figure_card.dart';
import 'flower.dart';
import 'palette.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final HistoryController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  final _form = GlobalKey<FormState>();
  int _tab = 0;
  bool _alphabetical = false;
  HistoryController get controller => widget.controller;

  static const suggestions = [
    ('Мария Кюри', 'Marie Curie', 'Наука', Icons.science_outlined),
    (
      'Леонардо да Винчи',
      'Leonardo da Vinci',
      'Искусство',
      Icons.palette_outlined,
    ),
    ('Джейн Остин', 'Jane Austen', 'Литература', Icons.menu_book_rounded),
    ('Клеопатра', 'Cleopatra', 'История', Icons.account_balance_outlined),
  ];

  @override
  void initState() {
    super.initState();
    controller.addListener(_showStorageError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStorageError());
  }

  void _showStorageError() {
    if (!mounted || controller.storageError == null) return;
    final message = controller.storageError!;
    controller.dismissStorageError();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit([String? name]) {
    if (name != null) {
      _search.text = name;
      setState(() => _tab = 0);
    }
    if (name == null && !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    controller.search(_search.text);
  }

  @override
  void dispose() {
    controller.removeListener(_showStorageError);
    _search.dispose();
    super.dispose();
  }

  Widget _heading(String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              onRefresh: () async {
                if (_tab == 0 && controller.query.isNotEmpty) {
                  await controller.search(controller.query);
                }
              },
              child: ListView(
                key: PageStorageKey(_tab),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Palette.rose,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_florist_outlined,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'лепестки истории',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.5,
                              ),
                            ),
                            Text(
                              'маленькие открытия каждый день',
                              style: TextStyle(
                                fontSize: 11,
                                color: Palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_tab == 0) ..._searchContent(),
                  if (_tab == 1) ..._favoritesContent(),
                  if (_tab == 2) ..._historyContent(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          FocusScope.of(context).unfocus();
          setState(() => _tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.saved_search_rounded),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Избранное',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'История',
          ),
        ],
      ),
    ),
  );

  List<Widget> _searchContent() {
    final figures = [...controller.results];
    if (_alphabetical) figures.sort((a, b) => a.name.compareTo(b.name));
    return [
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 14, 22),
        decoration: BoxDecoration(
          color: Palette.sage.withValues(alpha: .33),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ЛЮДИ И ИХ ИСТОРИИ',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.8,
                      color: Palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Знакомься\nс великими',
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Собери свой букет\nудивительных личностей',
                    style: TextStyle(
                      fontSize: 12,
                      color: Palette.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Flower(size: 100),
          ],
        ),
      ),
      _heading('Кого откроем сегодня?'),
      Form(
        key: _form,
        child: TextFormField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Введите имя для поиска'
              : null,
          decoration: InputDecoration(
            hintText: 'Например, Albert Einstein',
            hintStyle: const TextStyle(fontSize: 13, color: Palette.muted),
            prefixIcon: const Icon(Icons.search_rounded, color: Palette.olive),
            suffixIcon: IconButton(
              tooltip: 'Очистить поле',
              onPressed: _search.clear,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ),
      ),
      const SizedBox(height: 9),
      const Text(
        'Вводи имя на английском или выбери подсказку',
        style: TextStyle(fontSize: 11, color: Palette.muted),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: () => _submit(),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('Найти личность'),
      ),
      if (!controller.searched) ...[
        _heading(
          'С чего начнем?',
          trailing: const Icon(
            Icons.spa_outlined,
            size: 20,
            color: Palette.olive,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < suggestions.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: Material(
                    color: i == 1 || i == 2
                        ? Palette.blush
                        : Palette.rose.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _submit(suggestions[i].$2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              suggestions[i].$4,
                              color: Palette.olive,
                              size: 28,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              suggestions[i].$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestions[i].$3,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (controller.loading)
        const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text('Собираем лепестки истории…'),
            ],
          ),
        ),
      if (controller.searched && !controller.loading) ...[
        _heading(
          'Найдено ${figures.length}',
          trailing: IconButton(
            tooltip: _alphabetical ? 'Порядок сервиса' : 'По алфавиту',
            onPressed: () => setState(() => _alphabetical = !_alphabetical),
            icon: Icon(
              Icons.sort_by_alpha_rounded,
              color: _alphabetical ? Palette.ink : Palette.olive,
            ),
          ),
        ),
        Text(
          'По запросу ${controller.query}',
          style: const TextStyle(color: Palette.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (controller.error != null)
          _message(
            Icons.cloud_off_rounded,
            'Поиск немного задержался',
            controller.error!,
            action: OutlinedButton.icon(
              onPressed: controller.loadingMore
                  ? null
                  : () => controller.search(
                      controller.query,
                      more: figures.isNotEmpty,
                    ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Попробовать снова'),
            ),
          ),
        if (figures.isEmpty && controller.error == null)
          _message(
            Icons.travel_explore_rounded,
            'Пока никого не нашли',
            'Проверь написание имени на английском\nМожно ввести только часть имени',
          ),
        for (var i = 0; i < figures.length; i++)
          FigureCard(figure: figures[i], controller: controller, index: i),
        if (controller.hasMore && controller.error == null)
          OutlinedButton(
            onPressed: controller.loadingMore
                ? null
                : () => controller.search(controller.query, more: true),
            child: controller.loadingMore
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Показать еще'),
          ),
      ],
      const SizedBox(height: 26),
      const Center(
        child: Text(
          'Расти вместе с историями  ♡',
          style: TextStyle(fontSize: 12, color: Palette.muted),
        ),
      ),
    ];
  }

  List<Widget> _favoritesContent() => [
    _heading('Мой букет историй'),
    Text(
      'Сохранено ${controller.favorites.length}  ·  доступно без интернета',
      style: const TextStyle(fontSize: 12, color: Palette.muted),
    ),
    const SizedBox(height: 22),
    if (controller.favorites.isEmpty)
      _message(
        Icons.favorite_border_rounded,
        'Здесь расцветет твой букет',
        'Нажми на сердечко рядом с личностью\nЕе история останется с тобой',
      ),
    for (var i = 0; i < controller.favorites.length; i++)
      FigureCard(
        figure: controller.favorites[i],
        controller: controller,
        index: i,
      ),
  ];

  List<Widget> _historyContent() => [
    _heading(
      'Тропинка открытий',
      trailing: controller.history.isEmpty
          ? null
          : IconButton(
              tooltip: 'Очистить историю',
              onPressed: () => controller.clearHistory(),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Palette.olive,
              ),
            ),
    ),
    const Text(
      'Твои последние поиски. Нажми, чтобы повторить',
      style: TextStyle(fontSize: 12, color: Palette.muted),
    ),
    const SizedBox(height: 22),
    if (controller.history.isEmpty)
      _message(
        Icons.history_rounded,
        'Первое открытие впереди',
        'Имена появятся здесь после поиска',
      ),
    for (final query in controller.history)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Palette.blush,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            leading: const Icon(Icons.history_rounded, color: Palette.olive),
            title: Text(query),
            trailing: const Icon(
              Icons.north_west_rounded,
              color: Palette.olive,
              size: 18,
            ),
            onTap: () => _submit(query),
          ),
        ),
      ),
  ];

  Widget _message(IconData icon, String title, String text, {Widget? action}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Palette.blush,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Palette.olive),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 9),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.muted,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      );
}
