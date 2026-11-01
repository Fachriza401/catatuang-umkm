import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/sign_up_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/app_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._supabaseService);

  final SupabaseService _supabaseService;
  bool _isPasswordRecovery = false;

  @override
  bool get isPasswordRecovery => _isPasswordRecovery;

  SupabaseClient get _client {
    if (!_supabaseService.isConfigured) {
      throw const ConfigurationFailure(
        'Supabase belum dikonfigurasi. Jalankan aplikasi dengan SUPABASE_URL '
        'dan SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    final client = _supabaseService.client;
    if (client == null) {
      throw const ConfigurationFailure(
        'Layanan autentikasi belum siap. Silakan muat ulang aplikasi.',
      );
    }
    return client;
  }

  @override
  Stream<AppUser?> get authStateChanges async* {
    await _supabaseService.initialize();
    final client = _supabaseService.client;
    if (client == null) {
      yield null;
      return;
    }
    yield AppUserMapper.fromNullableSupabase(client.auth.currentUser);
    yield* client.auth.onAuthStateChange.map((state) {
      _isPasswordRecovery = state.event == AuthChangeEvent.passwordRecovery;
      return AppUserMapper.fromNullableSupabase(state.session?.user);
    });
  }

  @override
  AppUser? get currentUser {
    final client = _supabaseService.client;
    if (client == null) return null;
    return AppUserMapper.fromNullableSupabase(client.auth.currentUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          'Akun tidak ditemukan. Periksa kembali email Anda.',
        );
      }
      return AppUserMapper.fromSupabase(user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppConfig.authRedirectUrl,
        data: {'full_name': fullName.trim()},
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          'Registrasi belum berhasil. Silakan coba lagi.',
        );
      }

      return SignUpResult(
        outcome: response.session == null
            ? SignUpOutcome.emailVerificationRequired
            : SignUpOutcome.signedIn,
        user: AppUserMapper.fromSupabase(user),
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUrl,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      _isPasswordRecovery = false;
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        email: email.trim(),
        type: OtpType.signup,
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<AppUser> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          'Verifikasi kode gagal. Silakan minta kode baru.',
        );
      }
      return AppUserMapper.fromSupabase(user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<AppUser?> refreshSession() async {
    try {
      final session = _client.auth.currentSession;
      final refreshToken = session?.refreshToken;
      if (session == null || refreshToken == null || refreshToken.isEmpty) {
        return AppUserMapper.fromNullableSupabase(_client.auth.currentUser);
      }

      final response = await _client.auth.refreshSession();
      return AppUserMapper.fromNullableSupabase(
        response.user ?? response.session?.user,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  AuthFailure _mapAuthException(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return AuthFailure(
        'Email Anda belum diverifikasi. Silakan periksa kotak masuk.',
        code: error.code,
        cause: error,
        isEmailNotConfirmed: true,
      );
    }

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return AuthFailure(
        'Email atau password salah.',
        code: error.code,
        cause: error,
        isInvalidCredentials: true,
      );
    }

    if (code == 'user_already_exists' ||
        message.contains('already registered') ||
        message.contains('already exists')) {
      return AuthFailure(
        'Email sudah terdaftar. Silakan masuk atau gunakan email lain.',
        code: error.code,
        cause: error,
      );
    }

    if (code == 'weak_password' || message.contains('password should be')) {
      return AuthFailure(
        'Password terlalu lemah. Gunakan minimal 8 karakter dengan huruf '
        'besar, huruf kecil, dan angka.',
        code: error.code,
        cause: error,
      );
    }

    if (code.contains('rate_limit') ||
        message.contains('rate limit') ||
        error.statusCode == '429') {
      return AuthFailure(
        'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.',
        code: error.code,
        cause: error,
      );
    }

    if (code == 'same_password') {
      return AuthFailure(
        'Password baru tidak boleh sama dengan password sebelumnya.',
        code: error.code,
        cause: error,
      );
    }

    if (code == 'invalid_otp' ||
        code == 'otp_expired' ||
        message.contains('invalid otp') ||
        message.contains('token has expired')) {
      return AuthFailure(
        'Kode verifikasi salah atau sudah kedaluwarsa. Silakan minta kode '
        'baru.',
        code: error.code,
        cause: error,
      );
    }

    if (message.contains('expired')) {
      return AuthFailure(
        'Tautan sudah kedaluwarsa. Silakan minta tautan baru.',
        code: error.code,
        cause: error,
      );
    }

    if (error.statusCode == null) {
      return AuthFailure(
        'Tidak dapat terhubung ke layanan autentikasi. Periksa koneksi '
        'internet Anda.',
        code: error.code,
        cause: error,
      );
    }

    return AuthFailure(
      'Autentikasi gagal. Silakan coba lagi.',
      code: error.code,
      cause: error,
    );
  }

  AppFailure _mapUnexpectedError(Object error) {
    if (error is AppFailure) return error;
    return NetworkFailure(
      'Tidak dapat memproses permintaan. Periksa koneksi internet Anda.',
      cause: error,
    );
  }
}
