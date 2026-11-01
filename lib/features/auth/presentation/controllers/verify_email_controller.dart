import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../business_profile/domain/usecases/business_profile_use_cases.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../providers/auth_providers.dart';

class VerifyEmailController extends AsyncNotifier<PostAuthDestination?> {
  @override
  Future<PostAuthDestination?> build() async => null;

  Future<bool> resend(String email) async {
    state = const AsyncLoading();
    try {
      final resendEmail = ref.read(resendVerificationEmailUseCaseProvider);
      await resendEmail(email);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(mapToAppFailure(error), stackTrace);
      return false;
    }
  }

  Future<PostAuthDestination?> verifyCode({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading();
    try {
      final verifyOtp = ref.read(verifySignUpOtpUseCaseProvider);
      final user = await verifyOtp(
        VerifySignUpOtpParams(email: email, token: code),
      );

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

  Future<PostAuthDestination?> checkVerification() async {
    state = const AsyncLoading();
    try {
      final refreshSession = ref.read(refreshSessionUseCaseProvider);
      final user = await refreshSession(const NoParams());
      if (user == null || !user.isEmailVerified) {
        state = const AsyncData(null);
        return null;
      }

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
