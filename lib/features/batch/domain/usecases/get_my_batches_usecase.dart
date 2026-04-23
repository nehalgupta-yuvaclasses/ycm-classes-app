import '../models/batch_model.dart';
import '../repositories/i_batch_repository.dart';

class GetMyBatchesUseCase {
  const GetMyBatchesUseCase(this._repository);

  final IBatchRepository _repository;

  Future<List<BatchModel>> call(String userId) {
    return _repository.getMyBatches(userId);
  }
}