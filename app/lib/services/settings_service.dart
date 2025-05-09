import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ControlMode { buttons, joystick }

class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ControlMode _controlMode = ControlMode.buttons;
  bool _useDynamicColor = true;

  ThemeMode get themeMode => _themeMode;

  ControlMode get controlMode => _controlMode;

  bool get useDynamicColor => _useDynamicColor;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt('themeMode') ?? 0;
    final controlIndex = prefs.getInt('controlMode') ?? 0;
    final dynamicColor = prefs.getBool('useDynamicColor') ?? true;

    _themeMode = ThemeMode.values[themeIndex];
    _controlMode = ControlMode.values[controlIndex];
    _useDynamicColor = dynamicColor;

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
}
