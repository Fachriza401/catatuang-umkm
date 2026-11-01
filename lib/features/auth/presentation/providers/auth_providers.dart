import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../controllers/forgot_password_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';
import '../controllers/verify_email_controller.dart';
import '../../../business_profile/domain/usecases/business_profile_use_cases.dart';
import '../../../business_profile/presentation/providers/business_profile_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseServiceProvider));
});

final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentAuthUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.hasValue) return authState.value;
  return ref.watch(authRepositoryProvider).currentUser;
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>((ref) {
      return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
    });

final resendVerificationEmailUseCaseProvider =
    Provider<ResendVerificationEmailUseCase>((ref) {
      return ResendVerificationEmailUseCase(ref.watch(authRepositoryProvider));
    });

final refreshSessionUseCaseProvider = Provider<RefreshSessionUseCase>((ref) {
  return RefreshSessionUseCase(ref.watch(authRepositoryProvider));
});

final verifySignUpOtpUseCaseProvider = Provider<VerifySignUpOtpUseCase>((ref) {
  return VerifySignUpOtpUseCase(ref.watch(authRepositoryProvider));
});

final resolvePostAuthDestinationUseCaseProvider =
    Provider<ResolvePostAuthDestinationUseCase>((ref) {
      return ResolvePostAuthDestinationUseCase(
        ref.watch(businessProfileRepositoryProvider),
      );
    });

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, PostAuthDestination?>(
      LoginController.new,
    );

final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, SignUpResult?>(
      RegisterController.new,
    );

final forgotPasswordControllerProvider =
    AsyncNotifierProvider.autoDispose<ForgotPasswordController, void>(
      ForgotPasswordController.new,
    );

final verifyEmailControllerProvider =
    AsyncNotifierProvider.autoDispose<
      VerifyEmailController,
      PostAuthDestination?
    >(VerifyEmailController.new);
