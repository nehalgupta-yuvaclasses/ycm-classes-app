import '../repositories/i_batch_repository.dart';

class WatchEnrollmentsUseCase {
  const WatchEnrollmentsUseCase(this._repository);

  final IBatchRepository _repository;

  Stream<List<Map<String, dynamic>>> call(String userId) {
    return _repository.watchEnrollments(userId);
  }
}