import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/social_model.dart';
import '../services/social_service.dart';

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService();
});

final socialsProvider = StreamProvider<SocialModel>((ref) {
  return ref.read(socialServiceProvider).listenSocialsRealtime();
});