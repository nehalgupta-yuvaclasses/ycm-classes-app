import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/batch_model.dart';
import '../../domain/providers/batch_usecases_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Streams the list of enrolled batches for the current user.
/// It syncs initially and then reacts whenever any field in the enrollment table changes.
final myBatchesProvider = StreamProvider<List<BatchModel>>((ref) async* {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated) {
    yield [];
    return;
  }

  final userId = authState.user!.id;
  final getMyBatchesUseCase = ref.read(getMyBatchesUseCaseProvider);
  final enrollmentsStream = ref.read(watchEnrollmentsUseCaseProvider).call(userId);

  yield await getMyBatchesUseCase(userId);

  await for (final _ in enrollmentsStream) {
    yield await getMyBatchesUseCase(userId);
  }
});

final streamEnrollmentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.read(watchEnrollmentsUseCaseProvider).call(userId);
});

final activeBatchesCountProvider = Provider<int>((ref) {
  final batchesAsync = ref.watch(myBatchesProvider);
  return batchesAsync.when(
    data: (batches) => batches.length,
    loading: () => 0,
    error: (err, stack) => 0,
  );
});

final batchDetailProvider = FutureProvider.family<BatchModel, String>((ref, id) async {
  final authState = ref.read(authControllerProvider);
  final userId = authState.user?.id ?? '';
  return ref.read(getMyBatchesUseCaseProvider).call(userId).then((list) => list.firstWhere((b) => b.id == id));
});
