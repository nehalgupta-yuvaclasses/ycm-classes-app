import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/app_error.dart';
import '../models/social_model.dart';

class SocialService {
  SocialService();

  SupabaseClient get _client => SupabaseClientManager.client;

  Future<void> _ensureInitialized() async {
    if (!SupabaseClientManager.isInitialized) {
      await SupabaseClientManager.initialize();
    }
  }

  Future<SocialModel> getSocials() async {
    await _ensureInitialized();

    try {
      final row = await _client
          .from('site_settings')
          .select('id, key, value, created_at, updated_at')
          .eq('key', 'socials')
          .maybeSingle();

      if (row == null) {
        return SocialModel.empty();
      }

      return SocialModel.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw AppError(e.message);
    }
  }

  Stream<SocialModel> listenSocialsRealtime() async* {
    await _ensureInitialized();

    final controller = StreamController<SocialModel>();

    Future<void> emitLatest() async {
      if (controller.isClosed) return;
      controller.add(await getSocials());
    }

    await emitLatest();

    final subscription = _client
        .from('site_settings')
        .stream(primaryKey: ['id'])
        .eq('key', 'socials')
        .listen((_) => emitLatest());

    controller.onCancel = () async {
      await subscription.cancel();
    };

    yield* controller.stream;
  }
}