import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/batch_repository.dart';
import '../../data/services/batch_remote_service.dart';
import '../repositories/i_batch_repository.dart';
import '../usecases/get_my_batches_usecase.dart';
import '../usecases/update_lesson_progress_usecase.dart';
import '../usecases/watch_enrollments_usecase.dart';

final batchRemoteServiceProvider = Provider<BatchRemoteService>((ref) {
  return BatchRemoteService();
});

final batchRepositoryProvider = Provider<IBatchRepository>((ref) {
  return BatchRepository(ref.read(batchRemoteServiceProvider));
});

final getMyBatchesUseCaseProvider = Provider<GetMyBatchesUseCase>((ref) {
  return GetMyBatchesUseCase(ref.read(batchRepositoryProvider));
});

final watchEnrollmentsUseCaseProvider = Provider<WatchEnrollmentsUseCase>((ref) {
  return WatchEnrollmentsUseCase(ref.read(batchRepositoryProvider));
});

final updateLessonProgressUseCaseProvider = Provider<UpdateLessonProgressUseCase>((ref) {
  return UpdateLessonProgressUseCase(ref.read(batchRepositoryProvider));
});