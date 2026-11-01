import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../domain/entities/splash_result.dart';
import '../providers/splash_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  void _navigate(SplashResult result) {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (result.destination) {
        case SplashDestination.onboarding:
          context.go(AppRoutes.onboarding);
        case SplashDestination.login:
          context.go(AppRoutes.login);
        case SplashDestination.verifyEmail:
          context.go(
            Uri(
              path: AppRoutes.verifyEmail,
              queryParameters: {'email': result.email ?? ''},
            ).toString(),
          );
        case SplashDestination.setupProfile:
          context.go(AppRoutes.setupProfile);
        case SplashDestination.home:
          context.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashControllerProvider, (previous, next) {
      next.whenData(_navigate);
    });

    final state = ref.watch(splashControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDeep, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                    ),
                    child: const AppLogo(size: 72),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppConfig.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.massive),
                  state.when(
                    loading: () => const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    error: (error, stackTrace) => Column(
                      children: [
                        Text(
                          error is AppFailure
                              ? error.message
                              : 'Aplikasi gagal disiapkan. Silakan coba lagi.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          variant: AppButtonVariant.secondary,
                          isExpanded: false,
                          onPressed: () {
                            _navigated = false;
                            ref.invalidate(splashControllerProvider);
                          },
                        ),
                      ],
                    ),
                    data: (_) => const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'v${AppConfig.appVersion}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
