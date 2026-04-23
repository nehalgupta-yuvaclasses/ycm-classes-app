import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_error.dart';
import '../domain/models/batch_model.dart';
import '../../../core/supabase/supabase_client.dart';

class BatchService {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Fetch all courses that the current user is enrolled in.
  /// Joining with courses and instructors to populate the BatchModel.
  Future<List<BatchModel>> getMyBatches(String userId) async {
    final response = await _client
        .from('enrollments')
        .select(
          'id, student_id, course_id, created_at, courses(id, title, description, thumbnail_url, buying_price, selling_price, author, subtitle, category, visibility, instructor_id, instructors(full_name, profile_image), modules(id, lessons(id)))',
        )
        .eq('student_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    return data.map((json) => BatchModel.fromJson(json)).toList();
  }

  /// Streams enrollment and progress changes for the current user.
  Stream<List<Map<String, dynamic>>> streamEnrollments(String userId) {
    return _client
        .from('enrollments')
        .stream(primaryKey: ['id'])
      .eq('student_id', userId);
  }

  /// Updates progress for a particular enrollment record.
  Future<void> updateProgressByEnrollmentId({
    required String enrollmentId,
    required int completedLessons,
    required int totalLessons,
  }) async {
    throw AppError(
      'Enrollment progress columns are not available in the current schema. Sync progress from a dedicated progress table before calling this method.',
    );
  }
}
