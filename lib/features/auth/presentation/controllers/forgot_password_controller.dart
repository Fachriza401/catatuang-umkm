import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> sendResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      final sendReset = ref.read(sendPasswordResetEmailUseCaseProvider);
      await sendReset(email);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(mapToAppFailure(error), stackTrace);
      return false;
    }
  }
}
