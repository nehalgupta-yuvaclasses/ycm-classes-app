import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/app_error.dart';
import '../domain/models/profile_models.dart';

class ProfileService {
  ProfileService();

  SupabaseClient get _client => SupabaseClientManager.client;

  firebase.FirebaseAuth get _firebaseAuth => firebase.FirebaseAuth.instance;

  Future<void> _ensureInitialized() async {
    if (!SupabaseClientManager.isInitialized) {
      await SupabaseClientManager.initialize();
    }
  }

  Future<ProfileModel?> getProfile() async {
    await _ensureInitialized();

    try {
      final identifiers = await _getUserIdentifiers();
      if (identifiers == null) return null;

      Map<String, dynamic>? row;
      if (identifiers['firebaseUid'] != null) {
        row = await _client
            .from('students')
            .select(
              'id, user_id, full_name, name, email, phone, firebase_uid, aspirant_type, city, state, created_at',
            )
            .eq('firebase_uid', identifiers['firebaseUid'])
            .maybeSingle();
      }

      if (row == null && identifiers['supabaseUid'] != null) {
        row = await _client
            .from('students')
            .select(
              'id, user_id, full_name, name, email, phone, firebase_uid, aspirant_type, city, state, created_at',
            )
            .eq('user_id', identifiers['supabaseUid'])
            .maybeSingle();
      }

      if (row == null && identifiers['email'] != null) {
        row = await _client
            .from('students')
            .select(
              'id, user_id, full_name, name, email, phone, firebase_uid, aspirant_type, city, state, created_at',
            )
            .eq('email', identifiers['email'])
            .maybeSingle();
      }

      if (row == null && identifiers['phone'] != null) {
        row = await _client
            .from('students')
            .select(
              'id, user_id, full_name, name, email, phone, firebase_uid, aspirant_type, city, state, created_at',
            )
            .eq('phone', identifiers['phone'])
            .maybeSingle();
      }

      if (row == null) return null;
      return ProfileModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw AppError(e.message);
    }
  }

  Future<UserStatsModel?> getUserStats() async {
    await _ensureInitialized();

    try {
      final identifiers = await _getUserIdentifiers();
      if (identifiers == null) return null;

      String? studentId = identifiers['studentId'] as String?;

      if (studentId == null) {
        final profile = await getProfile();
        studentId = profile?.id;
      }

      if (studentId == null) return null;

      final enrollmentsResponse = await _client
          .from('enrollments')
          .select('id')
          .eq('student_id', studentId);
      final enrolledCoursesCount = enrollmentsResponse.length;

      final attemptsResponse = await _client
          .from('attempts')
          .select('id, score, status, tests(total_marks)')
          .eq('student_id', studentId);
      final attempts = List<Map<String, dynamic>>.from(attemptsResponse);
      final attemptsCount = attempts.length;
      final completedAttempts = attempts
          .where((attempt) => (attempt['status']?.toString() ?? '') == 'completed')
          .toList();
      final completedAttemptsCount = completedAttempts.length;

      double? averageScorePercentage;
      if (completedAttempts.isNotEmpty) {
        final percentages = completedAttempts.map((attempt) {
          final score = (attempt['score'] as num?)?.toDouble() ?? 0;
          final test = attempt['tests'];
          final testMap = test is Map<String, dynamic>
              ? test
              : test is Map
                  ? Map<String, dynamic>.from(test)
                  : const <String, dynamic>{};
          final totalMarks = (testMap['total_marks'] as num?)?.toDouble() ?? 0;
          if (totalMarks <= 0) {
            return score;
          }
          return (score / totalMarks) * 100;
        }).toList();
        averageScorePercentage = percentages.reduce((sum, value) => sum + value) / percentages.length;
      }

      return UserStatsModel(
        userId: studentId,
        enrolledCoursesCount: enrolledCoursesCount,
        attemptsCount: attemptsCount,
        completedAttemptsCount: completedAttemptsCount,
        averageScorePercentage: averageScorePercentage,
      );
    } on PostgrestException catch (e) {
      if (e.code == '42P01') return null;
      throw AppError(e.message);
    }
  }

  Future<void> updateProfile({required String fullName, String? phone}) async {
    await _ensureInitialized();

    try {
      final identifiers = await _getUserIdentifiers();
      if (identifiers == null) {
        throw const AppError('No authenticated user found.');
      }

      if (identifiers['studentId'] != null) {
        await _client
            .from('students')
            .update({'full_name': fullName, 'name': fullName, 'phone': phone})
            .eq('id', identifiers['studentId']);
      } else if (identifiers['firebaseUid'] != null) {
        await _client
            .from('students')
            .update({'full_name': fullName, 'name': fullName, 'phone': phone})
            .eq('firebase_uid', identifiers['firebaseUid']);
      } else if (identifiers['email'] != null) {
        await _client
            .from('students')
            .update({'full_name': fullName, 'name': fullName, 'phone': phone})
            .eq('email', identifiers['email']);
      } else {
        throw const AppError(
          'Cannot update profile: user not found in database.',
        );
      }
    } on PostgrestException catch (e) {
      throw AppError(e.message);
    }
  }

  Stream<ProfileModel?> listenProfileRealtime() async* {
    await _ensureInitialized();
    final identifiers = await _getUserIdentifiers();
    if (identifiers == null) {
      yield null;
      return;
    }

    if (identifiers['studentId'] != null) {
      yield* _client
          .from('students')
          .stream(primaryKey: ['id'])
          .eq('id', identifiers['studentId'])
          .map(
            (rows) => rows.isEmpty ? null : ProfileModel.fromJson(rows.first),
          );
    } else if (identifiers['firebaseUid'] != null) {
      yield* _client
          .from('students')
          .stream(primaryKey: ['id'])
          .eq('firebase_uid', identifiers['firebaseUid'])
          .map(
            (rows) => rows.isEmpty ? null : ProfileModel.fromJson(rows.first),
          );
    } else if (identifiers['email'] != null) {
      yield* _client
          .from('students')
          .stream(primaryKey: ['id'])
          .eq('email', identifiers['email'])
          .map(
            (rows) => rows.isEmpty ? null : ProfileModel.fromJson(rows.first),
          );
    } else {
      yield null;
    }
  }

  Stream<UserStatsModel?> listenStatsRealtime() async* {
    await _ensureInitialized();
    final identifiers = await _getUserIdentifiers();
    if (identifiers == null) {
      yield null;
      return;
    }

    final profile = await getProfile();
    final studentId = profile?.id;
    if (studentId == null) {
      yield null;
      return;
    }

    final controller = StreamController<UserStatsModel?>();

    Future<void> emitLatest() async {
      if (controller.isClosed) return;
      controller.add(await getUserStats());
    }

    await emitLatest();

    final enrollmentSubscription = _client
        .from('enrollments')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .listen((_) => emitLatest());

    final attemptSubscription = _client
        .from('attempts')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .listen((_) => emitLatest());

    controller.onCancel = () async {
      await enrollmentSubscription.cancel();
      await attemptSubscription.cancel();
    };

    yield* controller.stream;
  }

  Future<Map<String, dynamic>?> _getUserIdentifiers() async {
    final firebaseUser = _firebaseAuth.currentUser;
    final supabaseUser = _client.auth.currentUser;

    if (firebaseUser == null && supabaseUser == null) {
      return null;
    }

    return {
      'firebaseUid': firebaseUser?.uid,
      'supabaseUid': supabaseUser?.id,
      'phone': firebaseUser?.phoneNumber ?? supabaseUser?.phone,
      'email': firebaseUser?.email ?? supabaseUser?.email,
      'studentId': null as String?,
    };
  }
}
