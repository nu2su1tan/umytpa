import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the language the user picked and remembers it between launches.
///
/// `null` means "follow the system language".
class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._locale);

  static const String _key = 'app_language';
  static const List<Locale> supported = <Locale>[Locale('en'), Locale('ru')];

  final SharedPreferences _prefs;
  Locale? _locale;

  /// The explicitly chosen language, or `null` to follow the system.
  Locale? get locale => _locale;

  static Future<LocaleController> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_key);
    final Locale? saved = supported
        .where((Locale l) => l.languageCode == code)
        .firstOrNull;
    return LocaleController._(prefs, saved);
  }

  /// Switches the language; pass `null` to follow the system again.
  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) {
      return;
    }
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
  }
}
