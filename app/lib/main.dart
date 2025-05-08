import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'config/fallback_themes.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NaviMateApp());
}

class NaviMateApp extends StatelessWidget {
  const NaviMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final light =
            lightDynamic != null
                ? ThemeData(colorScheme: lightDynamic, useMaterial3: true)
                // Fallback for older systems
                : lightTheme;

        final dark =
            darkDynamic != null
                ? ThemeData(colorScheme: darkDynamic, useMaterial3: true)
                // Fallback for older systems
                : darkTheme;

        return MaterialApp(
          title: 'NaviMate',
          themeMode: ThemeMode.system,
          theme: light,
          darkTheme: dark,
          home: const HomeScreen(),
        );
      },
    );
  }
}
