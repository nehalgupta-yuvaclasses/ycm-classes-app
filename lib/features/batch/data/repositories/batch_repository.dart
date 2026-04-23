import '../../domain/models/batch_model.dart';
import '../../domain/repositories/i_batch_repository.dart';
import '../services/batch_remote_service.dart';

class BatchRepository implements IBatchRepository {
  BatchRepository(this._service);

  final BatchRemoteService _service;

  /// Fetches the user's enrolled batches with course and instructor joins.
  @override
  Future<List<BatchModel>> getMyBatches(String userId) async {
    try {
      return await _service.getMyBatches(userId);
    } catch (e) {
      throw Exception('Failed to fetch enrolled batches: $e');
    }
  }

  /// Streams for new enrollments OR progress updates on existing ones.
  @override
  Stream<List<Map<String, dynamic>>> watchEnrollments(String userId) {
    return _service.watchEnrollments(userId);
  }

  /// Updates progress on a specific enrollment.
  @override
  Future<void> updateLessonProgress({
    required String enrollmentId,
    required int completed,
    required int total,
  }) async {
    await _service.updateLessonProgress(
      enrollmentId: enrollmentId,
      completed: completed,
      total: total,
    );
  }
}
