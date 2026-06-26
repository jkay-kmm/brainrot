import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    final next = _locale.languageCode == 'vi' ? const Locale('en') : const Locale('vi');
    await setLocale(next);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final code = prefs.getString('locale_code') ?? 'en';
    _locale = Locale(code);
    final themeRaw = prefs.getString('theme_mode') ?? 'system';
    _themeMode = switch (themeRaw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };

    notifyListeners();
  }
}
