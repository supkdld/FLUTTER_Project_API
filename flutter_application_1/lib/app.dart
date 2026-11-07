import 'package:flutter/material.dart';

import 'core/dependencies.dart';
import 'controllers/history_controller.dart';
import 'ui/home_page.dart';
import 'ui/palette.dart';

class HistoryApp extends StatelessWidget {
  const HistoryApp({super.key, this.controller});

  final HistoryController? controller;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: Palette.olive).copyWith(
      primary: Palette.olive,
      onPrimary: Colors.white,
      secondary: Palette.coral,
      surface: Palette.background,
      onSurface: Palette.ink,
      outline: Palette.sage,
    );
    return MaterialApp(
      title: 'Лепестки истории',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: Palette.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.background,
          foregroundColor: Palette.ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Palette.rose),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Palette.olive, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Palette.background,
          indicatorColor: Palette.rose,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: HomePage(controller: controller ?? getIt<HistoryController>()),
    );
  }
}
