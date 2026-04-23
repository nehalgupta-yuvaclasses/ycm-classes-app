import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attempt_model.dart';
import '../../data/models/data_change.dart';
import '../../data/repositories/attempt_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

class AttemptFeedController extends StateNotifier<AsyncValue<List<AttemptModel>>> {
  AttemptFeedController(this._repository) : super(const AsyncLoading());

  final AttemptRepository _repository;
  StreamSubscription<DataChange<AttemptModel>>? _realtimeSubscription;
  final List<AttemptModel> _items = [];
  String? _studentId;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> initialize({required String? studentId}) async {
    _studentId = studentId;
    await refresh();
    _attachRealtime();
  }

  void updateStudentId(String? studentId) {
    if (studentId == _studentId) {
      return;
    }

    _studentId = studentId;
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
    if (!_hasMore || state.isLoading || _studentId == null) {
      return;
    }

    await _loadPage(forceRefresh: false);
  }

  Future<void> _loadPage({required bool forceRefresh}) async {
    if (_studentId == null || _studentId!.isEmpty) {
      state = const AsyncData(<AttemptModel>[]);
      return;
    }

    if (_offset == 0) {
      state = const AsyncLoading();
    }

    try {
      final page = await _repository.fetchAttempts(
        studentId: _studentId!,
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
    if (_studentId == null || _studentId!.isEmpty) {
      return;
    }

    _realtimeSubscription = _repository.watchAttempts(studentId: _studentId!).listen(
      _applyChange,
      onError: (error, stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  void _applyChange(DataChange<AttemptModel> change) {
    final attempt = change.current ?? change.previous;
    if (attempt == null) {
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
          _items.insert(0, attempt);
        } else {
          _items[existingIndex] = attempt;
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

final attemptProvider = StateNotifierProvider.autoDispose<AttemptFeedController, AsyncValue<List<AttemptModel>>>((ref) {
  final controller = AttemptFeedController(ref.read(attemptRepositoryProvider));
  final authState = ref.read(authControllerProvider);

  ref.listen(authControllerProvider, (_, next) {
    controller.updateStudentId(next.user?.id);
  });

  unawaited(controller.initialize(studentId: authState.user?.id));

  return controller;
});

final attemptsProvider = attemptProvider;