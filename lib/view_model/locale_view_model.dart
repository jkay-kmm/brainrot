// lib/view_model/app_view_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleViewModel extends ChangeNotifier {
  // Theme (đã có sẵn)
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ----- I18n -----
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale_code') ?? 'en';
    _locale = Locale(code);
    final theme = prefs.getString('theme_mode');
    if (theme == 'dark') _themeMode = ThemeMode.dark;
    notifyListeners();
  }

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
}
