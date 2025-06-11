import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The available control modes for the robot.
enum ControlMode { buttons, joystick }

/// Manages user settings, including theme, control mode, and connection info.
class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ControlMode _controlMode = ControlMode.buttons;
  bool _useDynamicColor = true;
  String _ip = '10.0.2.2';
  String _port = '8000';

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// The current control mode.
  ControlMode get controlMode => _controlMode;

  /// Whether dynamic color is enabled.
  bool get useDynamicColor => _useDynamicColor;

  /// The current IP address.
  String get ip => _ip;

  /// The current port.
  String get port => _port;

  /// Loads settings from persistent storage.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt('themeMode') ?? 0;
    final controlIndex = prefs.getInt('controlMode') ?? 0;
    final dynamicColor = prefs.getBool('useDynamicColor') ?? true;
    final ip = prefs.getString('ip') ?? '10.0.2.2';
    final port = prefs.getString('port') ?? '8000';

    _themeMode = ThemeMode.values[themeIndex];
    _controlMode = ControlMode.values[controlIndex];
    _useDynamicColor = dynamicColor;
    _ip = ip;
    _port = port;

    notifyListeners();
  }

  /// Updates the theme mode and saves it.
  Future<void> updateTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
    notifyListeners();
  }

  /// Updates the control mode and saves it.
  Future<void> updateControlMode(ControlMode mode) async {
    _controlMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('controlMode', ControlMode.values.indexOf(mode));
    notifyListeners();
  }

  /// Updates the dynamic color setting and saves it.
  Future<void> updateUseDynamicColor(bool useDynamic) async {
    _useDynamicColor = useDynamic;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', useDynamic);
    notifyListeners();
  }

  /// Updates the IP address and saves it.
  Future<void> updateIp(String ip) async {
    _ip = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    notifyListeners();
  }

  /// Updates the port and saves it.
  Future<void> updatePort(String port) async {
    _port = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('port', port);
    notifyListeners();
  }
}
