import '../../../../core/domain/repositories/abstract_repository.dart';
import '../models/batch_model.dart';

abstract interface class IBatchRepository extends AbstractRepository {
  const IBatchRepository();

  Future<List<BatchModel>> getMyBatches(String userId);

  Stream<List<Map<String, dynamic>>> watchEnrollments(String userId);

  Future<void> updateLessonProgress({
    required String enrollmentId,
    required int completed,
    required int total,
  });
}