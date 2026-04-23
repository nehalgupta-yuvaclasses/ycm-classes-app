import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/data_change.dart';
import '../../data/models/test_model.dart';
import '../../data/repositories/test_repository.dart';
import '../../data/repositories/attempt_repository.dart';

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository();
});

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final testCourseFilterProvider = StateProvider<String?>((ref) => null);

class TestFeedController extends StateNotifier<AsyncValue<List<TestModel>>> {
  TestFeedController(this._repository) : super(const AsyncLoading());

  final TestRepository _repository;
  StreamSubscription<DataChange<TestModel>>? _realtimeSubscription;
  final List<TestModel> _items = [];
  String? _courseId;
  String? _subjectId;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> initialize({String? courseId, String? subjectId}) async {
    _courseId = courseId;
    _subjectId = subjectId;
    await refresh();
    _attachRealtime();
  }

  void updateFilters({String? courseId, String? subjectId}) {
    if (courseId == _courseId && subjectId == _subjectId) {
      return;
    }

    _courseId = courseId;
    _subjectId = subjectId;
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
    if (!_hasMore || state.isLoading) {
      return;
    }

    await _loadPage(forceRefresh: false);
  }

  Future<void> _loadPage({required bool forceRefresh}) async {
    if (_offset == 0) {
      state = const AsyncLoading();
    }

    try {
      final page = await _repository.fetchTests(
        courseId: _courseId,
        subjectId: _subjectId,
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
    _realtimeSubscription = _repository.watchTestChanges(courseId: _courseId, subjectId: _subjectId).listen(
      _applyChange,
      onError: (error, stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  void _applyChange(DataChange<TestModel> change) {
    final test = change.current ?? change.previous;
    if (test == null) {
      return;
    }

    final existingIndex = _items.indexWhere((item) => item.id == change.id);

    switch (change.type) {
      case RealtimeMutationType.deleted:
        if (existingIndex != -1) {
          _items.removeAt(existingIndex);
        }
        break;
      case RealtimeMutationType.inserted:
      case RealtimeMutationType.updated:
        if (existingIndex == -1) {
          _items.insert(0, test);
        } else {
          _items[existingIndex] = test;
        }
        break;
    }

    state = AsyncData(List.unmodifiable(_items));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

final testProvider = StateNotifierProvider.autoDispose<TestFeedController, AsyncValue<List<TestModel>>>((ref) {
  final controller = TestFeedController(ref.read(testRepositoryProvider));

  ref.listen<String?>(testCourseFilterProvider, (_, next) {
    controller.updateFilters(courseId: next, subjectId: null);
  });

  unawaited(controller.initialize(courseId: ref.read(testCourseFilterProvider), subjectId: null));

  return controller;
});

final testsProvider = testProvider;

final testDetailProvider = FutureProvider.family<TestModel, String>((ref, testId) async {
  return ref.read(testRepositoryProvider).fetchTestById(testId);
});

final testSeriesProvider = FutureProvider<List<TestModel>>((ref) async {
  final page = await ref.read(testRepositoryProvider).fetchTests(limit: 100, offset: 0);
  return page.items;
});

final streamTestAttemptsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final client = SupabaseClientManager.client;
  final attemptRepository = ref.read(attemptRepositoryProvider);

  return _buildEnrolledTestStream(client: client, attemptRepository: attemptRepository, userId: userId);
});

final myEnrolledTestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    yield [];
    return;
  }

  final userId = authState.user!.id;
  final client = SupabaseClientManager.client;
  final attemptRepository = ref.read(attemptRepositoryProvider);

  yield* _buildEnrolledTestStream(client: client, attemptRepository: attemptRepository, userId: userId);
});

Stream<List<Map<String, dynamic>>> _buildEnrolledTestStream({
  required dynamic client,
  required AttemptRepository attemptRepository,
  required String userId,
}) async* {
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<List<Map<String, dynamic>>> loadPayload() async {
    final enrollmentsResponse = await client
        .from('enrollments')
        .select('course_id')
        .eq('student_id', userId);

    final enrolledCourseIds = (enrollmentsResponse as List)
        .map((row) => (row as Map<String, dynamic>)['course_id']?.toString() ?? '')
        .where((courseId) => courseId.isNotEmpty)
        .toSet()
        .toList();

    if (enrolledCourseIds.isEmpty) {
      return [];
    }

    final testsResponse = await client
        .from('tests')
        .select('id, course_id, subject_id, title, duration, total_marks, status, created_at, updated_at')
        .inFilter('course_id', enrolledCourseIds)
        .order('created_at', ascending: false);

    final tests = (testsResponse as List)
        .whereType<Map<String, dynamic>>()
        .map(TestModel.fromJson)
        .toList();

    final attemptsPage = await attemptRepository.fetchAttempts(
      studentId: userId,
      limit: 100,
      offset: 0,
      forceRefresh: true,
    );
    final latestAttempts = <String, Map<String, dynamic>>{};

    for (final attempt in attemptsPage.items) {
      latestAttempts[attempt.testId ?? attempt.id] = {
        'id': attempt.id,
        'score': attempt.score,
        'status': attempt.status,
        'total_marks': attempt.totalMarks,
        'submitted_at': attempt.submittedAt?.toIso8601String(),
      };
    }

    return tests.map((test) {
      return <String, dynamic>{
        'id': test.id,
        'title': test.title,
        'duration_minutes': test.durationMinutes,
        'total_questions': test.totalQuestions,
        'test_series': <String, dynamic>{
          'id': test.id,
          'title': test.title,
          'category': test.subjectId ?? test.courseId ?? 'General',
          'total_tests': test.totalQuestions,
          'price': test.totalMarks.toString(),
        },
        'status': latestAttempts[test.id]?['status']?.toString().toLowerCase().contains('complete') == true ? 'Completed' : 'Pending',
        'score': latestAttempts[test.id]?['score'],
        'total_marks': latestAttempts[test.id]?['total_marks'] ?? test.totalMarks,
        'completed_at': latestAttempts[test.id]?['submitted_at'],
      };
    }).toList();
  }

  Future<void> emitLatest() async {
    if (controller.isClosed) return;
    controller.add(await loadPayload());
  }

  await emitLatest();

  final enrollmentSubscription = client
      .from('enrollments')
      .stream(primaryKey: ['id'])
      .eq('student_id', userId)
      .listen((_) => emitLatest());

  final attemptSubscription = attemptRepository.watchAttempts(studentId: userId).listen((_) => emitLatest());

  controller.onCancel = () async {
    await enrollmentSubscription.cancel();
    await attemptSubscription.cancel();
  };

  yield* controller.stream;
}