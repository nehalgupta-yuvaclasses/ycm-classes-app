import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/banner_model.dart';
import '../../data/models/course_model.dart';
import '../../data/models/data_change.dart';
import '../../data/repositories/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final categoryFilterProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');

class CourseFeedController extends StateNotifier<AsyncValue<List<CourseModel>>> {
  CourseFeedController(this._repository) : super(const AsyncLoading());

  final CourseRepository _repository;
  StreamSubscription<DataChange<CourseModel>>? _realtimeSubscription;
  final List<CourseModel> _items = [];
  String? _category;
  String? _query;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  Future<void> initialize({String? category, String? query}) async {
    _category = category;
    _query = query;
    await refresh();
    _attachRealtime();
  }

  void updateFilters({String? category, String? query}) {
    if (category == _category && query == _query) {
      return;
    }

    _category = category;
    _query = query;
    unawaited(refresh());
    _attachRealtime();
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    _items.clear();
    await _loadPage(forceRefresh: true);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    try {
      await _loadPage(forceRefresh: false);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _loadPage({required bool forceRefresh}) async {
    final shouldReset = _offset == 0;
    if (shouldReset) {
      state = const AsyncLoading();
    }

    try {
      final page = await _repository.fetchCourses(
        category: _category,
        query: _query,
        limit: _limit,
        offset: _offset,
        forceRefresh: forceRefresh,
      );

      if (_offset == 0) {
        _items
          ..clear()
          ..addAll(page.items);
      } else {
        _items.addAll(page.items);
      }

      _offset = _items.length;
      _hasMore = page.hasMore;
      state = AsyncData(List.unmodifiable(_items));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void _attachRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository.watchCourseChanges(category: _category == 'All' ? null : _category).listen(
      _applyCourseChange,
      onError: (error, stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  void _applyCourseChange(DataChange<CourseModel> change) {
    final course = change.current ?? change.previous;
    if (course == null) {
      return;
    }

    final matchesFilters = _matchesFilters(course);
    final existingIndex = _items.indexWhere((item) => item.id == change.id);

    switch (change.type) {
      case RealtimeMutationType.deleted:
        if (existingIndex != -1) {
          _items.removeAt(existingIndex);
        }
        break;
      case RealtimeMutationType.inserted:
      case RealtimeMutationType.updated:
        if (!matchesFilters) {
          if (existingIndex != -1) {
            _items.removeAt(existingIndex);
          }
          break;
        }

        if (existingIndex == -1) {
          _items.insert(0, course);
        } else {
          _items[existingIndex] = course;
        }
        break;
    }

    state = AsyncData(List.unmodifiable(_items));
  }

  bool _matchesFilters(CourseModel course) {
    final category = _category;
    if (category != null && category.isNotEmpty && category != 'All' && course.categoryName != category) {
      return false;
    }

    final query = _query?.trim().toLowerCase() ?? '';
    if (query.isEmpty) {
      return true;
    }

    return course.title.toLowerCase().contains(query) ||
        course.instructorName.toLowerCase().contains(query) ||
        course.categoryName.toLowerCase().contains(query) ||
        course.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

final courseProvider = StateNotifierProvider.autoDispose<CourseFeedController, AsyncValue<List<CourseModel>>>((ref) {
  final controller = CourseFeedController(ref.read(courseRepositoryProvider));

  ref.listen<String>(categoryFilterProvider, (_, next) {
    controller.updateFilters(category: next, query: ref.read(searchQueryProvider));
  });
  ref.listen<String>(searchQueryProvider, (_, next) {
    controller.updateFilters(category: ref.read(categoryFilterProvider), query: next);
  });

  unawaited(controller.initialize(
    category: ref.read(categoryFilterProvider),
    query: ref.read(searchQueryProvider),
  ));

  return controller;
});

final coursesProvider = courseProvider;

final featuredCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchFeaturedCourses();
});

final topPicksProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchTopPicks();
});

final recommendedCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchRecommendedCourses();
});

final bannersProvider = FutureProvider<List<BannerModel>>((ref) {
  return ref.read(courseRepositoryProvider).fetchBanners(forceRefresh: true);
});

final courseDetailProvider = StreamProvider.family<CourseModel, String>((ref, id) {
  return ref.read(courseRepositoryProvider).watchCourseById(id);
});