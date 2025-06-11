import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/ros_socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.loadSettings();

  runApp(
    // MultiProvider is used to provide multiple objects (services) to the widget tree.
    // - SettingsService is a ChangeNotifier and is provided as a singleton.
    // - RosSocketService is created as a ProxyProvider, which means it depends on SettingsService.
    //   Whenever the IP or port changes in SettingsService, a new RosSocketService is created.
    //   The dispose callback ensures the WebSocket connection is closed when the provider is disposed.
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ProxyProvider<SettingsService, RosSocketService>(
          update:
              (_, settings, previous) => RosSocketService(
                AppConfig.velocityWebSocketUrl(settings.ip, settings.port),
              ),
          dispose: (_, rosService) => rosService.close(),
        ),
      ],
      child: const NaviMateApp(),
    ),
  );
}

class NaviMateApp extends StatelessWidget {
  const NaviMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Provider.of is used here to listen for changes in SettingsService.
        // This ensures that theme changes, dynamic color toggling, etc., are reflected in the UI.
        final settings = Provider.of<SettingsService>(context);

        // The logic below selects the theme based on user settings and platform support for dynamic color.
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
