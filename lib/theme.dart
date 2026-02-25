import 'package:flutter/material.dart';

class AppTheme {
  static final _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Colors.lightGreen[700]!,
    onPrimary: Colors.black,
    secondary: Colors.lightGreen[500]!,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: _lightScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.black,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Tema escuro é o mesmo que o claro por enquanto.
  static ThemeData darkTheme() {
    return lightTheme();
  }
}
