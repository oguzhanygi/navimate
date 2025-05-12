import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ControlMode { buttons, joystick }

class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ControlMode _controlMode = ControlMode.buttons;
  bool _useDynamicColor = true;
  String _ip = '10.0.2.2';
  String _port = '8000';

  ThemeMode get themeMode => _themeMode;

  ControlMode get controlMode => _controlMode;

  bool get useDynamicColor => _useDynamicColor;

  String get ip => _ip;

  String get port => _port;

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

  Future<void> updateTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', ThemeMode.values.indexOf(mode));
    notifyListeners();
  }

  Future<void> updateControlMode(ControlMode mode) async {
    _controlMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('controlMode', ControlMode.values.indexOf(mode));
    notifyListeners();
  }

  Future<void> updateUseDynamicColor(bool useDynamic) async {
    _useDynamicColor = useDynamic;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', useDynamic);
    notifyListeners();
  }

  Future<void> updateIp(String ip) async {
    _ip = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    notifyListeners();
  }

  Future<void> updatePort(String port) async {
    _port = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('port', port);
    notifyListeners();
  }
}
