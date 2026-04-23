import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/explore_service.dart';
import '../../data/repositories/explore_repository.dart';
import '../../../course/domain/models/course_model.dart';
import '../../domain/models/category_model.dart';

final exploreServiceProvider = Provider<ExploreService>((ref) {
  return ExploreService();
});

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepository(ref.read(exploreServiceProvider));
});

/// The current search query.
final exploreSearchQueryProvider = StateProvider<String>((ref) => '');

/// Placeholder categories (empty since user doesn't want them)
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) async* {
  yield [];
});

/// Streams the courses based on current search query.
final exploreCoursesProvider = StreamProvider<List<CourseModel>>((ref) async* {
  final repository = ref.read(exploreRepositoryProvider);
  final query = ref.watch(exploreSearchQueryProvider);
  
  // Watch for any changes in the courses table to trigger re-fetch
  ref.watch(streamCoursesTableProvider);
  
  final courses = await repository.getCourses(
    searchQuery: query,
  );
  yield courses;
});

final streamCoursesTableProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(exploreRepositoryProvider).streamCourses();
});
