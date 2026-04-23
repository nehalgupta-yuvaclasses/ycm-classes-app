import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/utils/app_error.dart';
import '../models/banner_model.dart';
import '../models/course_model.dart';
import '../models/data_change.dart';
import '../models/pagination.dart';

class CourseRepository {
  CourseRepository({SupabaseClient? client}) : _client = client ?? SupabaseClientManager.client;

  final SupabaseClient _client;
  final Map<String, PaginatedResult<CourseModel>> _pageCache = {};
  final Map<String, CourseModel> _courseCache = {};
  final Map<String, Map<String, int>> _moduleOrderCache = {};
  final Map<String, List<BannerModel>> _bannerCache = {};

  String _pageKey({String? category, String? query, required int limit, required int offset}) {
    return 'category=${category ?? 'all'}|query=${query ?? ''}|limit=$limit|offset=$offset';
  }

  Future<PaginatedResult<CourseModel>> fetchCourses({
    String? category,
    String? query,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final key = _pageKey(category: category, query: query, limit: limit, offset: offset);
    if (!forceRefresh && _pageCache.containsKey(key)) {
      return _pageCache[key]!;
    }

    try {
      final response = await _queryCourses(category: category, query: query)
          .order('created_at', ascending: false)
          .range(offset, offset + limit);

      final rows = List<Map<String, dynamic>>.from(response);
      final items = rows.map(CourseModel.fromJson).toList();
      for (final course in items) {
        _courseCache[course.id] = course;
      }

      final result = PaginatedResult<CourseModel>(
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
      throw AppError('Failed to fetch courses: $error');
    }
  }

  Future<CourseModel> fetchCourseById(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _courseCache.containsKey(id)) {
      return _courseCache[id]!;
    }

    try {
      final bundle = await _fetchCourseDetailBundle(id);
      _courseCache[id] = bundle.course;
      _moduleOrderCache[id] = bundle.moduleOrderById;
      return bundle.course;
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to fetch course: $error');
    }
  }

  Stream<CourseModel> watchCourseById(String id) {
    final controller = StreamController<CourseModel>();
    final channel = _client.channel('public:course-detail:$id');
    final moduleIds = <String>{};

    Future<void> emitCurrent({bool forceRefresh = false}) async {
      final bundle = await _fetchCourseDetailBundle(id, forceRefresh: forceRefresh);
      _courseCache[id] = bundle.course;
      _moduleOrderCache[id] = bundle.moduleOrderById;
      moduleIds
        ..clear()
        ..addAll(bundle.moduleIds);

      if (!controller.isClosed) {
        controller.add(bundle.course);
      }
    }

    void watchCourseRowChanges() {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'courses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: id,
        ),
        callback: (_) => unawaited(emitCurrent(forceRefresh: true)),
      );
    }

    void watchModuleChanges() {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'modules',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'course_id',
          value: id,
        ),
        callback: (_) => unawaited(emitCurrent(forceRefresh: true)),
      );
    }

    Future<void> attachRealtime() async {
      try {
        await emitCurrent(forceRefresh: true);

        watchCourseRowChanges();
        watchModuleChanges();

        channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lessons',
          callback: (payload) {
            final raw = payload.eventType == PostgresChangeEvent.delete ? payload.oldRecord : payload.newRecord;
            if (raw.isEmpty) return;

            final record = Map<String, dynamic>.from(raw);
            final moduleId = record['module_id']?.toString() ?? '';
            if (moduleId.isEmpty || !moduleIds.contains(moduleId)) {
              return;
            }

            final lesson = LessonModel.fromJson(record);
            final currentCourse = _courseCache[id];
            if (currentCourse == null) {
              unawaited(emitCurrent(forceRefresh: true));
              return;
            }

            final updatedLessons = _applyLessonChange(id, currentCourse.lessons ?? [], lesson, payload.eventType);
            final updatedCourse = currentCourse.copyWith(lessons: updatedLessons);
            _courseCache[id] = updatedCourse;
            if (!controller.isClosed) {
              controller.add(updatedCourse);
            }
          },
        );

        channel.subscribe();
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    unawaited(attachRealtime());

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<_CourseDetailBundle> _fetchCourseDetailBundle(String id, {bool forceRefresh = false}) async {
    final cached = _courseCache[id];
    if (!forceRefresh && cached != null) {
      return _CourseDetailBundle(course: cached, moduleIds: const [], moduleOrderById: _moduleOrderCache[id] ?? const {});
    }

    final response = await _client
          .from('courses')
          .select(
            'id, title, description, status, thumbnail_url, students_count, buying_price, selling_price, author, subtitle, category, visibility, updated_at, instructor_id, instructors(full_name, profile_image)',
          )
          .eq('id', id)
          .maybeSingle();

    if (response == null) {
      throw const AppError('Course not found.');
    }

    final moduleResponse = await _client
        .from('modules')
        .select('id, course_id, "order"')
        .eq('course_id', id)
        .order('order', ascending: true);

    final moduleRows = List<Map<String, dynamic>>.from(moduleResponse);
    final moduleIds = moduleRows.map((row) => row['id'] as String).toList();
    final moduleOrderById = <String, int>{};
    for (final row in moduleRows) {
      moduleOrderById[row['id'] as String] = (row['order'] as int?) ?? 0;
    }

    final lessonsResponse = moduleIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
            .from('lessons')
        .select('id, module_id, title, video_url, notes, duration, "order", lesson_type, live_url, scheduled_at, is_live, live_started_at, live_ended_at, live_by')
        .inFilter('module_id', moduleIds);

    final lessonRows = List<Map<String, dynamic>>.from(lessonsResponse);
    lessonRows.sort((left, right) {
      final leftOrder = moduleOrderById[left['module_id'] as String? ?? ''] ?? 0;
      final rightOrder = moduleOrderById[right['module_id'] as String? ?? ''] ?? 0;
      if (leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }

      return ((left['order'] as int?) ?? 0).compareTo((right['order'] as int?) ?? 0);
    });

    final payload = Map<String, dynamic>.from(response);
    payload['lessons'] = lessonRows;
    final course = CourseModel.fromJson(payload);
    return _CourseDetailBundle(course: course, moduleIds: moduleIds, moduleOrderById: moduleOrderById);
  }

  List<LessonModel> _applyLessonChange(String courseId, List<LessonModel> currentLessons, LessonModel nextLesson, PostgresChangeEvent eventType) {
    final lessons = [...currentLessons];
    final existingIndex = lessons.indexWhere((lesson) => lesson.id == nextLesson.id);

    switch (eventType) {
      case PostgresChangeEvent.delete:
        if (existingIndex != -1) {
          lessons.removeAt(existingIndex);
        }
        break;
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        if (existingIndex == -1) {
          lessons.add(nextLesson);
        } else {
          lessons[existingIndex] = nextLesson;
        }
        break;
      case PostgresChangeEvent.all:
        if (existingIndex == -1) {
          lessons.add(nextLesson);
        } else {
          lessons[existingIndex] = nextLesson;
        }
        break;
    }

    final moduleOrderById = _moduleOrderCache[courseId] ?? const <String, int>{};
    lessons.sort((left, right) {
      final leftModuleOrder = moduleOrderById[left.moduleId] ?? 0;
      final rightModuleOrder = moduleOrderById[right.moduleId] ?? 0;
      if (leftModuleOrder != rightModuleOrder) {
        return leftModuleOrder.compareTo(rightModuleOrder);
      }

      return left.order.compareTo(right.order);
    });

    return lessons;
  }

  Stream<DataChange<CourseModel>> watchCourseChanges({String? category}) {
    final controller = StreamController<DataChange<CourseModel>>();
    final channel = _client.channel('public:courses:${category ?? 'all'}');
    final filter = category == null || category == 'All'
        ? null
        : PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'category',
            value: category,
          );

    void emit(PostgresChangePayload payload) {
      final raw = payload.eventType == PostgresChangeEvent.delete ? payload.oldRecord : payload.newRecord;
      final row = Map<String, dynamic>.from(raw);
      if (row.isEmpty) {
        return;
      }

      final course = CourseModel.fromJson(row);
      _courseCache[course.id] = course;
      _pageCache.clear();
      final type = switch (payload.eventType) {
        PostgresChangeEvent.insert => RealtimeMutationType.inserted,
        PostgresChangeEvent.update => RealtimeMutationType.updated,
        PostgresChangeEvent.delete => RealtimeMutationType.deleted,
        _ => RealtimeMutationType.updated,
      };

      if (!controller.isClosed) {
        controller.add(
          DataChange<CourseModel>(
            type: type,
            id: course.id,
            current: type == RealtimeMutationType.deleted ? null : course,
            previous: type == RealtimeMutationType.deleted ? course : null,
          ),
        );
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'courses',
      filter: filter,
      callback: emit,
    ).subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<List<BannerModel>> fetchBanners({bool forceRefresh = false}) async {
    const cacheKey = 'banners';
    if (!forceRefresh && _bannerCache.containsKey(cacheKey)) {
      return _bannerCache[cacheKey]!;
    }

    try {
      final response = await _client
          .from('banners')
          .select('id, title, subtitle, image_url, cta_link, cta_text, sort_order, is_active, created_at')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);
      final banners = rows.map(BannerModel.fromJson).toList();
      _bannerCache[cacheKey] = banners;
      return banners;
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to fetch banners: $error');
    }
  }

  Stream<List<BannerModel>> watchBanners() {
    final controller = StreamController<List<BannerModel>>();
    final channel = _client.channel('public:banners');

    Future<void> emitCurrent() async {
      final banners = await fetchBanners(forceRefresh: true);
      if (!controller.isClosed) {
        controller.add(banners);
      }
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'banners',
      callback: (_) {
        _bannerCache.clear();
        unawaited(emitCurrent());
      },
    ).subscribe();

    controller.onListen = () {
      unawaited(emitCurrent());
    };

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<List<CourseModel>> fetchFeaturedCourses({int limit = 10, bool forceRefresh = false}) async {
    final page = await fetchCourses(limit: limit, offset: 0, forceRefresh: forceRefresh);
    return page.items.where((course) => course.isFeatured || course.status?.toLowerCase() == 'published').toList();
  }

  Future<List<CourseModel>> fetchTopPicks({int limit = 10, bool forceRefresh = false}) async {
    final page = await fetchCourses(limit: limit, offset: 0, forceRefresh: forceRefresh);
    final sorted = [...page.items]..sort((left, right) => right.studentsCount.compareTo(left.studentsCount));
    return sorted.take(limit).toList();
  }

  Future<List<CourseModel>> fetchRecommendedCourses({int limit = 10, bool forceRefresh = false}) async {
    final page = await fetchCourses(limit: limit * 2, offset: 0, forceRefresh: forceRefresh);
    return page.items.where((course) => !course.isFeatured || course.studentsCount < 5000).take(limit).toList();
  }

  PostgrestFilterBuilder _queryCourses({String? category, String? query}) {
    var request = _client
        .from('courses')
        .select(
          'id, title, description, status, thumbnail_url, students_count, buying_price, selling_price, author, subtitle, category, visibility, updated_at, instructor_id, instructors(full_name, profile_image)',
        );

    if (category != null && category.isNotEmpty && category != 'All') {
      request = request.eq('category', category);
    }

    if (query != null && query.trim().isNotEmpty) {
      final search = query.trim().replaceAll("'", "''");
      request = request.or('title.ilike.%$search%,description.ilike.%$search%,author.ilike.%$search%');
    }

    return request;
  }
}

class _CourseDetailBundle {
  final CourseModel course;
  final List<String> moduleIds;
  final Map<String, int> moduleOrderById;

  const _CourseDetailBundle({
    required this.course,
    required this.moduleIds,
    required this.moduleOrderById,
  });
}