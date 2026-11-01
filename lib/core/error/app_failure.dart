sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

final class AuthFailure extends AppFailure {
  const AuthFailure(
    super.message, {
    super.code,
    super.cause,
    this.isEmailNotConfirmed = false,
    this.isInvalidCredentials = false,
  });

  final bool isEmailNotConfirmed;
  final bool isInvalidCredentials;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.code, super.cause});
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.code, super.cause});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure(super.message, {super.code, super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.code, super.cause});
}

AppFailure mapToAppFailure(Object error, [StackTrace? stackTrace]) {
  if (error is AppFailure) return error;
  return UnknownFailure(
    'Terjadi kesalahan tak terduga. Silakan coba lagi.',
    cause: error,
  );
}
