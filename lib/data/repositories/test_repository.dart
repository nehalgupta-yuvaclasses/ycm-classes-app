import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/utils/app_error.dart';
import '../models/data_change.dart';
import '../models/pagination.dart';
import '../models/test_model.dart';

class TestRepository {
  TestRepository({SupabaseClient? client}) : _client = client ?? SupabaseClientManager.client;

  final SupabaseClient _client;
  final Map<String, PaginatedResult<TestModel>> _pageCache = {};
  final Map<String, TestModel> _testCache = {};

  String _pageKey({String? courseId, String? subjectId, int limit = 20, int offset = 0}) {
    return 'course=${courseId ?? 'all'}|subject=${subjectId ?? 'all'}|limit=$limit|offset=$offset';
  }

  Future<PaginatedResult<TestModel>> fetchTests({
    String? courseId,
    String? subjectId,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final key = _pageKey(courseId: courseId, subjectId: subjectId, limit: limit, offset: offset);
    if (!forceRefresh && _pageCache.containsKey(key)) {
      return _pageCache[key]!;
    }

    try {
      var request = _client
          .from('tests')
          .select('id, course_id, subject_id, title, duration, total_marks, status, created_at, updated_at');

      if (courseId != null && courseId.isNotEmpty) {
        request = request.eq('course_id', courseId);
      }

      if (subjectId != null && subjectId.isNotEmpty) {
        request = request.eq('subject_id', subjectId);
      }

      final response = await request.order('created_at', ascending: false).range(offset, offset + limit);
      final rows = List<Map<String, dynamic>>.from(response);
      final items = rows.map(TestModel.fromJson).toList();
      for (final test in items) {
        _testCache[test.id] = test;
      }

      final result = PaginatedResult<TestModel>(
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
      throw AppError('Failed to fetch tests: $error');
    }
  }

  Future<TestModel> fetchTestById(String testId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _testCache.containsKey(testId)) {
      return _testCache[testId]!;
    }

    try {
      final response = await _client
          .from('tests')
          .select('id, course_id, subject_id, title, duration, total_marks, status, created_at, updated_at, questions(id, question_text, options, correct_answer, marks)')
          .eq('id', testId)
          .maybeSingle();

      if (response == null) {
        throw const AppError('Test not found.');
      }

      final test = TestModel.fromJson(Map<String, dynamic>.from(response));
      _testCache[test.id] = test;
      return test;
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to fetch test details: $error');
    }
  }

  Stream<DataChange<TestModel>> watchTestChanges({String? courseId, String? subjectId}) {
    final controller = StreamController<DataChange<TestModel>>();
    final channel = _client.channel('public:tests:${courseId ?? 'all'}:${subjectId ?? 'all'}');
    PostgresChangeFilter? filter;
    if (courseId != null && courseId.isNotEmpty) {
      filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'course_id', value: courseId);
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      filter = PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'subject_id', value: subjectId);
    }

    void emit(PostgresChangePayload payload) {
      final raw = payload.eventType == PostgresChangeEvent.delete ? payload.oldRecord : payload.newRecord;
      final row = Map<String, dynamic>.from(raw);
      if (row.isEmpty) {
        return;
      }

      final test = TestModel.fromJson(row);
      _testCache[test.id] = test;
      _pageCache.clear();
      final type = switch (payload.eventType) {
        PostgresChangeEvent.insert => RealtimeMutationType.inserted,
        PostgresChangeEvent.update => RealtimeMutationType.updated,
        PostgresChangeEvent.delete => RealtimeMutationType.deleted,
        _ => RealtimeMutationType.updated,
      };

      if (!controller.isClosed) {
        controller.add(
          DataChange<TestModel>(
            type: type,
            id: test.id,
            current: type == RealtimeMutationType.deleted ? null : test,
            previous: type == RealtimeMutationType.deleted ? test : null,
          ),
        );
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tests',
      filter: filter,
      callback: emit,
    ).subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }
}