import 'package:flutter/material.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleDark(bool enableDark) {
    setThemeMode(enableDark ? ThemeMode.dark : ThemeMode.light);
  }
}
