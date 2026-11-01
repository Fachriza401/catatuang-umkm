import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_profile_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/repositories/splash_repository_impl.dart';
import '../../domain/entities/splash_result.dart';
import '../../domain/repositories/splash_repository.dart';
import '../../domain/usecases/initialize_app_use_case.dart';
import '../controllers/splash_controller.dart';

final splashRepositoryProvider = Provider<SplashRepository>((ref) {
  return SplashRepositoryImpl(
    supabaseService: ref.watch(supabaseServiceProvider),
    database: ref.watch(appDatabaseProvider),
    onboardingRepository: ref.watch(onboardingRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
    businessProfileRepository: ref.watch(businessProfileRepositoryProvider),
  );
});

final initializeAppUseCaseProvider = Provider<InitializeAppUseCase>((ref) {
  return InitializeAppUseCase(ref.watch(splashRepositoryProvider));
});

final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, SplashResult>(
      SplashController.new,
    );
