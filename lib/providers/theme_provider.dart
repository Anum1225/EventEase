import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State management for theme mode switching with local disk persistence
class ThemeProvider with ChangeNotifier {
  static const String _prefKey = 'eventease_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefKey);
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[modeIndex];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, mode.index);
    } catch (_) {}
  }

  void toggleTheme() {
    if (isDarkMode) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
