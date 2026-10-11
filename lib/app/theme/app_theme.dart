import 'package:flutter/material.dart';

/// Solvara app theme.
///
/// Primary color is a civic blue. All user-facing text is Indonesian
/// (set in the MaterialApp locale, not here).
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF1A6FC4); // civic blue

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
      );
}
