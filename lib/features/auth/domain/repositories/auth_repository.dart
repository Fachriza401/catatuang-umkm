import '../entities/app_user.dart';
import '../entities/sign_up_result.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  bool get isPasswordRecovery;

  Future<AppUser> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updatePassword(String password);

  Future<void> resendVerificationEmail(String email);

  Future<AppUser> verifySignUpOtp({
    required String email,
    required String token,
  });

  Future<AppUser?> refreshSession();
}
