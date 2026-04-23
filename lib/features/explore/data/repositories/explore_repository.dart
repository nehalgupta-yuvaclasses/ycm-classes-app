import '../../../course/domain/models/course_model.dart';
import '../../domain/models/category_model.dart';
import '../explore_service.dart';

class ExploreRepository {
  final ExploreService _service;
  ExploreRepository(this._service);

  Future<List<CategoryModel>> getCategories() async {
    try {
      return await _service.getCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CourseModel>> getCourses({String? categorySlug, String? searchQuery}) async {
    try {
      return await _service.getCourses(categorySlug: categorySlug, searchQuery: searchQuery);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> streamCourses() {
    return _service.streamCourses();
  }

  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _service.streamCategories();
  }
}
