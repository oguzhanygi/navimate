import 'package:flutter/material.dart';

class AppConfig {
  // Dynamic URL generators
  static String baseUrl(String ip, String port) => '$ip:$port';
  static String cameraStreamUrl(String ip, String port) =>
      'http://$ip:$port/camera/stream';
  static String velocityWebSocketUrl(String ip, String port) =>
      'ws://$ip:$port/robot/velocity';
  static String mapUrl(String ip, String port) =>
      'http://$ip:$port/map?map_name=turtlebot3_house';
  static String goalUrl(String ip, String port) =>
      'http://$ip:$port/robot/goal';
  static String positionUrl(String ip, String port) =>
      'http://$ip:$port/robot/position';

  // Map-specific constants
  static const double mapResolution = 19.2;
  static const double mapOriginX = -4.46;
  static const double mapOriginY = -10.2;

  // Light Theme fallback
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
