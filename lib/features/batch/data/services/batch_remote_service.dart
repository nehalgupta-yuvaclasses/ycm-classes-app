import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/utils/app_error.dart';
import '../../domain/models/batch_model.dart';

class BatchRemoteService {
  BatchRemoteService({SupabaseClient? client}) : _client = client ?? SupabaseClientManager.client;

  final SupabaseClient _client;

  Future<List<BatchModel>> getMyBatches(String userId) async {
    final selectClause =
        'id, student_id, user_id, course_id, created_at, courses(id, title, description, thumbnail_url, buying_price, selling_price, author, subtitle, category, visibility, instructor_id, instructors(full_name, profile_image), modules(id, lessons(id)))';

    final responses = await Future.wait([
      _client
          .from('enrollments')
          .select(selectClause)
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      _client
          .from('enrollments')
          .select(selectClause)
          .eq('student_id', userId)
          .order('created_at', ascending: false),
    ]);

    final merged = <String, Map<String, dynamic>>{};
    for (final response in responses) {
      final data = List<dynamic>.from(response as List<dynamic>);
      for (final row in data) {
        if (row is Map<String, dynamic>) {
          final key = row['course_id']?.toString() ?? row['id']?.toString() ?? '';
          if (key.isNotEmpty) {
            merged[key] = row;
          }
        }
      }
    }

    return merged.values.map((json) => BatchModel.fromJson(json)).toList();
  }

  Stream<List<Map<String, dynamic>>> watchEnrollments(String userId) {
    return _client.from('enrollments').stream(primaryKey: ['id']).map((rows) {
      return rows.where((row) {
        final rowUserId = row['user_id']?.toString();
        final rowStudentId = row['student_id']?.toString();
        return rowUserId == userId || rowStudentId == userId;
      }).toList();
    });
  }

  Future<void> updateLessonProgress({
    required String enrollmentId,
    required int completed,
    required int total,
  }) async {
    throw AppError(
      'Enrollment progress columns are not available in the current schema. Sync progress from a dedicated progress table before calling this method.',
    );
  }
}