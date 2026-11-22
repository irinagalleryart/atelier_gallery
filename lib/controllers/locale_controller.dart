import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing and persisting the application locale (Macedonian 'mk' or English 'en').
class LocaleController extends ChangeNotifier {
  static const String _prefKey = 'selected_locale';
  static const Locale defaultLocale = Locale('mk');

  Locale _locale = defaultLocale;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isMacedonian => _locale.languageCode == 'mk';
  bool get isEnglish => _locale.languageCode == 'en';

  /// Initializes locale from SharedPreferences storage.
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_prefKey);
      if (savedLanguageCode != null && _isSupported(savedLanguageCode)) {
        _locale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  /// Sets the active locale and persists the selection.
  Future<void> setLocale(Locale newLocale) async {
    if (!_isSupported(newLocale.languageCode) || _locale == newLocale) {
      return;
    }
    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }

  /// Convenience method to change language by language code string ('mk' or 'en').
  Future<void> setLanguageCode(String code) async {
    if (_isSupported(code)) {
      await setLocale(Locale(code));
    }
  }

  /// Toggles between Macedonian ('mk') and English ('en').
  Future<void> toggleLanguage() async {
    final targetCode = isMacedonian ? 'en' : 'mk';
    await setLanguageCode(targetCode);
  }

  bool _isSupported(String code) {
    return code == 'mk' || code == 'en';
  }
}
