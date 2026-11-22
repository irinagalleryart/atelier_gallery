import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';

/// Centralized service for initializing and accessing Supabase client.
class SupabaseService {
  static bool _initialized = false;

  /// Returns whether Supabase has been initialized successfully.
  static bool get isInitialized => _initialized;

  /// Returns the configured Supabase URL.
  static String get supabaseUrl => AppConfig.supabaseUrl;

  /// Returns the configured Supabase anon key.
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  /// Initializes Supabase Flutter SDK safely using AppConfig.
  static Future<void> initialize() async {
    if (_initialized) return;

    final url = AppConfig.supabaseUrl;
    final anonKey = AppConfig.supabaseAnonKey;

    if (url.isEmpty ||
        url.contains('your-supabase-project') ||
        anonKey.isEmpty ||
        anonKey.contains('your-supabase-anon-key')) {
      debugPrint(
        'SupabaseService: WARNING - Using placeholder credentials. Update assets/config/config.yaml '
        'or provide valid --dart-define=SUPABASE_URL and --dart-define=SUPABASE_ANON_KEY parameters.',
      );
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      _initialized = true;
      debugPrint('SupabaseService: Initialized successfully.');
    } catch (e) {
      debugPrint('SupabaseService initialization error: `e`');
      rethrow;
    }
  }

  /// Direct getter for the active SupabaseClient instance.
  static SupabaseClient get client {
    if (!_initialized) {
      StateError(
        'SupabaseService has not been initialized. Call SupabaseService.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }
}
