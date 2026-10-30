import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/localization/language_state.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _themeKey = 'coolcare_theme_mode';
  static const _localeKey = 'coolcare_locale';
  final FlutterSecureStorage _storage;

  ThemeMode themeMode = ThemeMode.light;
  Locale locale = const Locale('en');

  Future<void> load() async {
    final values = await Future.wait([
      _storage.read(key: _themeKey),
      _storage.read(key: _localeKey),
    ]);
    themeMode = values[0] == 'dark' ? ThemeMode.dark : ThemeMode.light;
    locale = Locale(values[1] == 'vi' ? 'vi' : 'en');
    LanguageState.code = locale.languageCode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _storage.write(key: _themeKey, value: themeMode.name);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) return;
    themeMode = value;
    notifyListeners();
    await _storage.write(key: _themeKey, value: themeMode.name);
  }

  Future<void> toggleLocale() async {
    locale = Locale(locale.languageCode == 'vi' ? 'en' : 'vi');
    LanguageState.code = locale.languageCode;
    notifyListeners();
    await _storage.write(key: _localeKey, value: locale.languageCode);
  }

  Future<void> setLocale(Locale value) async {
    if (locale.languageCode == value.languageCode) return;
    locale = Locale(value.languageCode == 'vi' ? 'vi' : 'en');
    LanguageState.code = locale.languageCode;
    notifyListeners();
    await _storage.write(key: _localeKey, value: locale.languageCode);
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static AppPreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope is missing above this context.');
    return scope!.notifier!;
  }
}
