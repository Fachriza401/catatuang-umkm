import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../providers/auth_providers.dart';

class RegisterController extends AsyncNotifier<SignUpResult?> {
  @override
  Future<SignUpResult?> build() async => null;

  Future<SignUpResult?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final signUp = ref.read(signUpUseCaseProvider);
      final result = await signUp(
        SignUpParams(fullName: fullName, email: email, password: password),
      );
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(mapToAppFailure(error), stackTrace);
      return null;
    }
  }
}
