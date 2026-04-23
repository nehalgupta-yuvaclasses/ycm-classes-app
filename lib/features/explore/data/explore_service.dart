import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../course/domain/models/course_model.dart';
import '../domain/models/category_model.dart';

class ExploreService {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// Fetch all active categories (Disabled)
  Future<List<CategoryModel>> getCategories() async {
    return [];
  }

  /// Fetch courses with instructor details.
  Future<List<CourseModel>> getCourses({
    String? categorySlug,
    String? searchQuery,
  }) async {
    var query = _client.from('courses').select(
      'id, title, description, status, thumbnail_url, students_count, buying_price, selling_price, author, subtitle, category, visibility, updated_at, instructor_id, instructors(full_name, profile_image)',
    );

    query = query.eq('status', 'Published');

    if (categorySlug != null && categorySlug.trim().isNotEmpty) {
      query = query.eq('category', categorySlug.trim());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final search = searchQuery.trim().replaceAll("'", "''");
      query = query.or('title.ilike.%$search%,description.ilike.%$search%,author.ilike.%$search%');
    }

    final response = await query.order('created_at', ascending: false);
    final List<dynamic> data = response;
    return data.map((json) => CourseModel.fromJson(json)).toList();
  }

  /// Real-time stream for course updates.
  Stream<List<Map<String, dynamic>>> streamCourses() {
    return _client.from('courses').stream(primaryKey: ['id']).eq('status', 'Published');
  }

  /// Real-time stream for category changes (Disabled).
  Stream<List<Map<String, dynamic>>> streamCategories() {
    return const Stream.empty();
  }
}
