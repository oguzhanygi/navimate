import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(value: settings, child: const NaviMateApp()),
  );
}

class NaviMateApp extends StatelessWidget {
  const NaviMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final settings = Provider.of<SettingsService>(context);

        final light =
            settings.useDynamicColor && lightDynamic != null
                ? ThemeData(colorScheme: lightDynamic, useMaterial3: true)
                : AppConfig.lightTheme;

        final dark =
            settings.useDynamicColor && darkDynamic != null
                ? ThemeData(colorScheme: darkDynamic, useMaterial3: true)
                : AppConfig.darkTheme;

        return MaterialApp(
          title: 'NaviMate',
          themeMode: settings.themeMode,
          theme: light,
          darkTheme: dark,
          home: const HomeScreen(),
        );
      },
    );
  }
}
