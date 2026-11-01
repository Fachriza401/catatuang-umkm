import '../../../../core/usecase/use_case.dart';
import '../entities/app_user.dart';
import '../entities/sign_up_result.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

class SignUpParams {
  const SignUpParams({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;
}

class VerifySignUpOtpParams {
  const VerifySignUpOtpParams({required this.email, required this.token});

  final String email;
  final String token;
}

class SignInUseCase implements UseCase<AppUser, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<AppUser> call(SignInParams input) {
    return _repository.signIn(email: input.email, password: input.password);
  }
}

class SignUpUseCase implements UseCase<SignUpResult, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<SignUpResult> call(SignUpParams input) {
    return _repository.signUp(
      fullName: input.fullName,
      email: input.email,
      password: input.password,
    );
  }
}

class SignOutUseCase implements UseCase<void, NoParams> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(NoParams input) => _repository.signOut();
}

class SendPasswordResetEmailUseCase implements UseCase<void, String> {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(String input) => _repository.sendPasswordResetEmail(input);
}

class ResendVerificationEmailUseCase implements UseCase<void, String> {
  const ResendVerificationEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(String input) => _repository.resendVerificationEmail(input);
}

class VerifySignUpOtpUseCase
    implements UseCase<AppUser, VerifySignUpOtpParams> {
  const VerifySignUpOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<AppUser> call(VerifySignUpOtpParams input) {
    return _repository.verifySignUpOtp(email: input.email, token: input.token);
  }
}

class RefreshSessionUseCase implements UseCase<AppUser?, NoParams> {
  const RefreshSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<AppUser?> call(NoParams input) => _repository.refreshSession();
}
