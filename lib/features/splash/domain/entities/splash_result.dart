enum SplashDestination { onboarding, login, verifyEmail, setupProfile, home }

class SplashResult {
  const SplashResult({required this.destination, this.email});

  final SplashDestination destination;
  final String? email;
}
