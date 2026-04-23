import '../../../data/models/attempt_model.dart';
import '../../../data/repositories/attempt_repository.dart';
import '../../../data/repositories/test_repository.dart';

class TestService {
  TestService({TestRepository? testRepository, AttemptRepository? attemptRepository})
      : _testRepository = testRepository ?? TestRepository(),
        _attemptRepository = attemptRepository ?? AttemptRepository();

  final TestRepository _testRepository;
  final AttemptRepository _attemptRepository;

  Future<List<Map<String, dynamic>>> getMyEnrolledTests(String userId) async {
    final testsPage = await _testRepository.fetchTests(limit: 100, offset: 0);
    final attemptsPage = await _attemptRepository.fetchAttempts(studentId: userId, limit: 100, offset: 0);

    final latestAttempts = <String, AttemptModel>{};
    for (final attempt in attemptsPage.items) {
      latestAttempts[attempt.testId ?? attempt.id] = attempt;
    }

    return testsPage.items.map((test) {
      final attempt = latestAttempts[test.id];
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
        'status': attempt?.status.toLowerCase().contains('complete') == true ? 'Completed' : 'Pending',
        'score': attempt?.score,
        'total_marks': attempt?.totalMarks ?? test.totalMarks,
        'completed_at': attempt?.submittedAt?.toIso8601String(),
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> streamTestAttempts(String userId) async* {
    yield await getMyEnrolledTests(userId);

    await for (final _ in _attemptRepository.watchAttempts(studentId: userId)) {
      yield await getMyEnrolledTests(userId);
    }
  }
}
