import '../../../../core/config/app_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../business_profile/domain/repositories/business_profile_repository.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../../domain/entities/splash_result.dart';
import '../../domain/repositories/splash_repository.dart';

class SplashRepositoryImpl implements SplashRepository {
  SplashRepositoryImpl({
    required this.supabaseService,
    required this.database,
    required this.onboardingRepository,
    required this.authRepository,
    required this.businessProfileRepository,
  });

  final SupabaseService supabaseService;
  final AppDatabase database;
  final OnboardingRepository onboardingRepository;
  final AuthRepository authRepository;
  final BusinessProfileRepository businessProfileRepository;

  @override
  Future<SplashResult> resolve() async {
    final minimumDelay = Future<void>.delayed(AppConfig.splashMinimumDuration);

    await Future.wait([supabaseService.initialize(), database.warmUp()]);

    final onboardingCompleted = await onboardingRepository.isCompleted();
    if (!onboardingCompleted) {
      await minimumDelay;
      return const SplashResult(destination: SplashDestination.onboarding);
    }

    final user = authRepository.currentUser;
    if (user == null) {
      await minimumDelay;
      return const SplashResult(destination: SplashDestination.login);
    }

    if (!user.isEmailVerified) {
      await minimumDelay;
      return SplashResult(
        destination: SplashDestination.verifyEmail,
        email: user.email,
      );
    }

    try {
      final profile = await businessProfileRepository.getByUserId(user.id);
      await minimumDelay;
      return SplashResult(
        destination: profile == null
            ? SplashDestination.setupProfile
            : SplashDestination.home,
      );
    } catch (_) {
      await minimumDelay;
      return const SplashResult(destination: SplashDestination.home);
    }
  }
}
