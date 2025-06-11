import 'package:flutter/material.dart';

/// Provides application-wide configuration, including URL generators and theme data.
class AppConfig {
  // Dynamic URL generators

  /// Returns the base URL for the given [ip] and [port].
  static String baseUrl(String ip, String port) => '$ip:$port';

  /// Returns the camera stream URL for the given [ip] and [port].
  static String cameraStreamUrl(String ip, String port) =>
      'http://$ip:$port/camera/stream';

  /// Returns the velocity WebSocket URL for the given [ip] and [port].
  static String velocityWebSocketUrl(String ip, String port) =>
      'ws://$ip:$port/robot/velocity';

  /// Returns the map download URL for the given [ip], [port], and [mapName].
  static String mapDownloadUrl(String ip, String port, String mapName) =>
      'http://$ip:$port/map/download?map_name=$mapName';

  /// Returns the map list URL for the given [ip] and [port].
  static String mapListUrl(String ip, String port) =>
      'http://$ip:$port/map/list';

  /// Returns the map change URL for the given [ip] and [port].
  static String mapChangeUrl(String ip, String port) =>
      'http://$ip:$port/map/change';

  /// Returns the mapping start URL for the given [ip] and [port].
  static String mappingStartUrl(String ip, String port) =>
      'http://$ip:$port/mapping/start';

  /// Returns the mapping stop URL for the given [ip] and [port].
  static String mappingStopUrl(String ip, String port) =>
      'http://$ip:$port/mapping/stop';

  /// Returns the map save URL for the given [ip] and [port].
  static String mapSaveUrl(String ip, String port) =>
      'http://$ip:$port/mapping/save';

  /// Returns the mapping stream URL for the given [ip] and [port].
  static String mappingStreamUrl(String ip, String port) =>
      'http://$ip:$port/mapping/stream';

  /// Returns the goal URL for the given [ip] and [port].
  static String goalUrl(String ip, String port) =>
      'http://$ip:$port/robot/goal';

  /// Returns the robot position URL for the given [ip] and [port].
  static String positionUrl(String ip, String port) =>
      'http://$ip:$port/robot/position';

  /// Returns the cancel goal URL for the given [ip] and [port].
  static String cancelGoalUrl(String ip, String port) =>
      'http://$ip:$port/robot/cancel';

  // Map-specific constants

  /// The resolution of the map in pixels per meter.
  static const double mapResolution = 19.2;

  /// The X origin of the map in world coordinates.
  static const double mapOriginX = -4.46;

  /// The Y origin of the map in world coordinates.
  static const double mapOriginY = -10.2;

  // Light Theme fallback

  /// The default light theme for the app.
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF3DA9BA), // #3DA9BA
      secondary: Color(0xFF8DD2D5), // #8DD2D5
      inversePrimary: Color(0xFF3DA9BA), // #3DA9BA
      surface: Colors.white,
      onSurface: Colors.grey[900]!,
    ),
    useMaterial3: true,
  );

  // Dark Theme fallback

  /// The default dark theme for the app.
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF3DA9BA), // #3DA9BA
      secondary: Color(0xFF8DD2D5), // #8DD2D5
      inversePrimary: Color(0xFF136884), // #3DA9BA
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
    ),
    useMaterial3: true,
  );
}
