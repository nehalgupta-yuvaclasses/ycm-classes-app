import 'package:supabase_flutter/supabase_flutter.dart';
// import '../constants/api_constants.dart';

class SupabaseService {
  static Future<void> initialize() async {
    // await Supabase.initialize(
    //   url: ApiConstants.supabaseUrl,
    //   anonKey: ApiConstants.supabaseAnonKey,
    // );
  }

  // Since we're mocking, we return a null client or a fake one
  static SupabaseClient get client => throw UnimplementedError('Supabase is disabled. Use repositories instead.');
}
