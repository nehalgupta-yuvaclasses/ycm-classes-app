import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_service.dart';
import '../../domain/models/profile_models.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileViewState>((ref) {
  return ProfileController(ref.read(profileServiceProvider));
});

class ProfileController extends StateNotifier<ProfileViewState> {
  ProfileController(this._service) : super(ProfileViewState.initial) {
    _initialize();
  }

  final ProfileService _service;
  StreamSubscription<ProfileModel?>? _profileSubscription;
  StreamSubscription<UserStatsModel?>? _statsSubscription;

  Future<void> _initialize() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final results = await Future.wait([
        _service.getProfile(),
        _service.getUserStats(),
      ]);

      final profile = results[0] as ProfileModel?;
      final stats = results[1] as UserStatsModel?;

      state = state.copyWith(
        loading: false,
        profile: profile,
        stats: stats,
        clearError: true,
        keepProfile: false,
        keepStats: false,
      );

      await _attachRealtime();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e),
      );
    }
  }

  Future<void> _attachRealtime() async {
    await _profileSubscription?.cancel();
    await _statsSubscription?.cancel();

    _profileSubscription = _service.listenProfileRealtime().listen(
      (profile) {
        state = state.copyWith(
          profile: profile,
          clearError: true,
          keepProfile: false,
        );
      },
      onError: (error) {
        // If we already have profile data, don't show a fatal error for realtime sync
        if (state.profile == null) {
          state = state.copyWith(error: _friendlyError(error));
        } else {
          debugPrint('Realtime profile sync error: $error');
        }
      },
    );

    _statsSubscription = _service.listenStatsRealtime().listen(
      (stats) {
        state = state.copyWith(
          stats: stats,
          clearError: true,
          keepStats: false,
        );
      },
      onError: (error) {
        // If we already have stats data, don't show a fatal error for realtime sync
        if (state.stats == null) {
          state = state.copyWith(error: _friendlyError(error));
        } else {
          debugPrint('Realtime stats sync error: $error');
        }
      },
    );
  }

  Future<void> refresh() async {
    await _initialize();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(updating: true, clearError: true);

    try {
      await _service.updateProfile(fullName: fullName, phone: phone);
      state = state.copyWith(updating: false, clearError: true);
    } catch (e) {
      state = state.copyWith(updating: false, error: _friendlyError(e));
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('42703')) {
      return 'Profile schema is partially outdated. Please apply latest Supabase migrations.';
    }
    if (text.contains('42P01') || text.toLowerCase().contains('user_stats')) {
      return 'Stats table is missing. Please apply latest Supabase migrations.';
    }
    if (text.toLowerCase().contains('permission') || text.toLowerCase().contains('rls')) {
      return 'Permission denied for profile data. Check RLS policies.';
    }
    if (text.toLowerCase().contains('realtime') || text.contains('timedOut')) {
      return 'Live updates are currently unavailable due to connection issues. Pull down to refresh manually.';
    }
    return text;
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _statsSubscription?.cancel();
    super.dispose();
  }
}
