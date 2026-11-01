import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../business_profile/domain/usecases/business_profile_use_cases.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../providers/auth_providers.dart';

class LoginController extends AsyncNotifier<PostAuthDestination?> {
  @override
  Future<PostAuthDestination?> build() async => null;

  Future<PostAuthDestination?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final signIn = ref.read(signInUseCaseProvider);
      final user = await signIn(SignInParams(email: email, password: password));
      final resolveDestination = ref.read(
        resolvePostAuthDestinationUseCaseProvider,
      );
      final destination = await resolveDestination(user.id);
      state = AsyncData(destination);
      return destination;
    } catch (error, stackTrace) {
      state = AsyncError(mapToAppFailure(error), stackTrace);
      return null;
    }
  }
}
