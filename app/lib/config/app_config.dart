import 'package:flutter/material.dart';

class AppConfig {
  // IP address of the server
  static const String baseUrl = '192.168.251.173:8000';

  // Endpoints
  static const String cameraStreamUrl = 'http://$baseUrl/camera/stream';
  static const String velocityWebSocketUrl = 'ws://$baseUrl/robot/velocity';
  static const String mapUrl = 'http://$baseUrl/map?map_name=turtlebot3_house';
  static const String goalUrl = 'http://$baseUrl/robot/goal';
  static const String positionUrl = 'http://$baseUrl/robot/position';

  // Map-specific constants
  static const double mapResolution = 19.2;
  static const double mapOriginX = -4.46;
  static const double mapOriginY = -10.2;

  // Light Theme fallback
  static ThemeData lightTheme = ThemeData(
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
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      inversePrimary: Colors.blue,
      surface: Colors.grey[900]!,
    ),
    useMaterial3: true,
  );
}
