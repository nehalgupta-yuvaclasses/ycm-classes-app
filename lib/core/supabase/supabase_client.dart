import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import '../utils/app_error.dart';

class SupabaseClientManager {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!AppEnv.isConfigured) {
      throw const AppError(
        'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
      );
    }

    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
      );
    } catch (_) {
      // Handles hot-reload/app lifecycle cases where Supabase is already initialized.
      final _ = Supabase.instance.client;
    }

    _initialized = true;
  }

  static bool get isInitialized => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw const AppError(
        'Supabase is not initialized yet. Call SupabaseClientManager.initialize() before using auth services.',
      );
    }
    return Supabase.instance.client;
  }
}
