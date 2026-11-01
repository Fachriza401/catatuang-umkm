import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/business_profile.dart';
import '../providers/business_profile_providers.dart';

class BusinessProfileController extends AsyncNotifier<BusinessProfile?> {
  @override
  Future<BusinessProfile?> build() async {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return null;
    final getProfile = ref.watch(getBusinessProfileUseCaseProvider);
    return getProfile(user.id);
  }

  Future<BusinessProfile> save(BusinessProfile profile) async {
    final saveProfile = ref.read(saveBusinessProfileUseCaseProvider);
    final saved = await saveProfile(profile);
    state = AsyncData(saved);
    return saved;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      state = const AsyncData(null);
      return;
    }
    state = await AsyncValue.guard(() async {
      final getProfile = ref.read(getBusinessProfileUseCaseProvider);
      return getProfile(user.id);
    });
  }
}
