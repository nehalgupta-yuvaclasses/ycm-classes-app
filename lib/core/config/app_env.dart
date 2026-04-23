import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static final String supabaseUrl = _getValue('SUPABASE_URL', 'VITE_SUPABASE_URL');
  static final String supabaseAnonKey = _getValue('SUPABASE_ANON_KEY', 'VITE_SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String _getValue(String key, [String? secondaryKey]) {
    // 1. Try --dart-define (compile-time)
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;

    if (secondaryKey != null) {
      final fromSecondaryEnv = String.fromEnvironment(secondaryKey);
      if (fromSecondaryEnv.isNotEmpty) return fromSecondaryEnv;
    }

    // 2. Try .env (run-time)
    final fromDotEnv = dotenv.env[key];
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;

    if (secondaryKey != null) {
      final fromSecondaryDotEnv = dotenv.env[secondaryKey];
      if (fromSecondaryDotEnv != null && fromSecondaryDotEnv.isNotEmpty) {
        return fromSecondaryDotEnv;
      }
    }

    return '';
  }
}
