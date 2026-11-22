import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Manages application configuration loaded from YAML and/or dart-define overrides.
class AppConfig {
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static bool _isLoaded = false;

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;
  static bool get isLoaded => _isLoaded;

  static String _cleanUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (cleaned.endsWith('/rest/v1')) {
      cleaned = cleaned.substring(0, cleaned.length - 8);
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Loads configuration from --dart-define or assets/config/config.yaml.
  static Future<void> load() async {
    if (_isLoaded) return;

    // 1. Check dart-define overrides first
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (dartDefineUrl.isNotEmpty && dartDefineAnonKey.isNotEmpty) {
      _supabaseUrl = _cleanUrl(dartDefineUrl);
      _supabaseAnonKey = dartDefineAnonKey.trim();
      _isLoaded = true;
      debugPrint('AppConfig: Loaded configuration from --dart-define.');
      return;
    }

    // 2. Try loading from assets/config/config.yaml
    try {
      final yamlString = await rootBundle.loadString('assets/config/config.yaml');
      final yamlMap = loadYaml(yamlString) as Map?;

      if (yamlMap != null) {
        final rawUrl = (yamlMap['supabase_url'] as String?)?.trim() ?? '';
        if (rawUrl.isNotEmpty) {
          _supabaseUrl = _cleanUrl(rawUrl);
        }
        _supabaseAnonKey = (yamlMap['supabase_anon_key'] as String?)?.trim() ?? '';
      }
    } catch (e) {
      debugPrint('AppConfig: Could not load assets/config/config.yaml ($e). Using fallbacks.');
    }

    // 3. Fallback to dart-define defaults or placeholders if still empty
    if (_supabaseUrl.isEmpty) {
      _supabaseUrl = dartDefineUrl.isNotEmpty
          ? _cleanUrl(dartDefineUrl)
          : 'https://your-supabase-project.supabase.co';
    }
    if (_supabaseAnonKey.isEmpty) {
      _supabaseAnonKey = dartDefineAnonKey.isNotEmpty
          ? dartDefineAnonKey.trim()
          : 'your-supabase-anon-key';
    }

    _isLoaded = true;
    debugPrint('AppConfig: Configuration loaded successfully.');
  }
}
