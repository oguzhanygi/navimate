import 'package:flutter/material.dart';

// Light Theme fallback
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    inversePrimary: Colors.blue,
    surface: Colors.white,
  ),
  useMaterial3: true,
);

// Dark Theme fallback
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    inversePrimary: Colors.blue,
    surface: Colors.grey[900]!,
  ),
  useMaterial3: true,
);
