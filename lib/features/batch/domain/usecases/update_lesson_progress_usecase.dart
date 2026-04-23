import '../repositories/i_batch_repository.dart';

class UpdateLessonProgressUseCase {
  const UpdateLessonProgressUseCase(this._repository);

  final IBatchRepository _repository;

  Future<void> call({
    required String enrollmentId,
    required int completed,
    required int total,
  }) {
    return _repository.updateLessonProgress(
      enrollmentId: enrollmentId,
      completed: completed,
      total: total,
    );
  }
}