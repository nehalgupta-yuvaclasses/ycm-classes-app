import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/utils/app_error.dart';
import '../models/attempt_model.dart';
import '../models/data_change.dart';
import '../models/pagination.dart';

class AttemptRepository {
  AttemptRepository({SupabaseClient? client}) : _client = client ?? SupabaseClientManager.client;

  final SupabaseClient _client;
  final Map<String, PaginatedResult<AttemptModel>> _pageCache = {};
  final Map<String, AttemptModel> _attemptCache = {};

  String _pageKey({required String studentId, int limit = 20, int offset = 0}) {
    return 'student=$studentId|limit=$limit|offset=$offset';
  }

  Future<PaginatedResult<AttemptModel>> fetchAttempts({
    required String studentId,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final key = _pageKey(studentId: studentId, limit: limit, offset: offset);
    if (!forceRefresh && _pageCache.containsKey(key)) {
      return _pageCache[key]!;
    }

    try {
      final response = await _client
          .from('attempts')
          .select('id, student_id, test_id, score, status, submitted_at, created_at, tests(title, total_marks), students(full_name)')
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false)
          .range(offset, offset + limit);

      final rows = List<Map<String, dynamic>>.from(response);
      final items = rows.map(AttemptModel.fromJson).toList();
      for (final attempt in items) {
        _attemptCache[attempt.id] = attempt;
      }

      final result = PaginatedResult<AttemptModel>(
        items: items,
        limit: limit,
        offset: offset,
        hasMore: items.length > limit,
      );
      final trimmed = result.hasMore ? result.copyWith(items: items.take(limit).toList()) : result;
      _pageCache[key] = trimmed;
      return trimmed;
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to fetch attempts: $error');
    }
  }

  Future<AttemptModel?> fetchLatestAttempt({required String studentId, required String testId}) async {
    try {
      final response = await _client
          .from('attempts')
          .select('id, student_id, test_id, score, status, submitted_at, created_at, tests(title, total_marks), students(full_name)')
          .eq('student_id', studentId)
          .eq('test_id', testId)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final attempt = AttemptModel.fromJson(Map<String, dynamic>.from(response));
      _attemptCache[attempt.id] = attempt;
      return attempt;
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to fetch attempt: $error');
    }
  }

  Stream<DataChange<AttemptModel>> watchAttempts({required String studentId}) {
    final controller = StreamController<DataChange<AttemptModel>>();
    final channel = _client.channel('public:attempts:$studentId');

    void emit(PostgresChangePayload payload) {
      final raw = payload.eventType == PostgresChangeEvent.delete ? payload.oldRecord : payload.newRecord;
      final row = Map<String, dynamic>.from(raw);
      if (row.isEmpty) {
        return;
      }

      final attempt = AttemptModel.fromJson(row);
      _attemptCache[attempt.id] = attempt;
      _pageCache.clear();
      final type = switch (payload.eventType) {
        PostgresChangeEvent.insert => RealtimeMutationType.inserted,
        PostgresChangeEvent.update => RealtimeMutationType.updated,
        PostgresChangeEvent.delete => RealtimeMutationType.deleted,
        _ => RealtimeMutationType.updated,
      };

      if (!controller.isClosed) {
        controller.add(
          DataChange<AttemptModel>(
            type: type,
            id: attempt.id,
            current: type == RealtimeMutationType.deleted ? null : attempt,
            previous: type == RealtimeMutationType.deleted ? attempt : null,
          ),
        );
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'attempts',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'student_id', value: studentId),
      callback: emit,
    ).subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }
}