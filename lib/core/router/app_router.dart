import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/business_profile/presentation/pages/business_profile_setup_page.dart';
import '../../features/business_profile/presentation/pages/business_settings_page.dart';
import '../../features/calculator/presentation/pages/calculator_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/debts/presentation/pages/debt_detail_page.dart';
import '../../features/debts/presentation/pages/debt_form_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/domain/entities/transaction_type.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_button.dart';
import '../widgets/app_empty_state.dart';
import 'app_shell.dart';
import 'app_routes.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshNotifier = _AuthRefreshNotifier(authRepository.authStateChanges);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final loggedIn = authRepository.currentUser != null;
      final location = state.matchedLocation;
      if (authRepository.isPasswordRecovery &&
          location != AppRoutes.resetPassword) {
        return AppRoutes.resetPassword;
      }
      final isProtected =
          location == AppRoutes.home ||
          location == AppRoutes.reports ||
          location == AppRoutes.calculator ||
          location == AppRoutes.settings ||
          location == AppRoutes.setupProfile ||
          location.startsWith('/transactions') ||
          location.startsWith(AppRoutes.debts);
      if (!loggedIn && isProtected) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: AppRoutes.setupProfile,
        builder: (context, state) => const BusinessProfileSetupPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final type = state.uri.queryParameters['type'];
                      final amount = int.tryParse(
                        state.uri.queryParameters['amount'] ?? '',
                      );
                      return TransactionFormPage(
                        initialType: TransactionType.fromStorage(
                          type ?? TransactionType.expense.storageValue,
                        ),
                        initialAmount: amount ?? 0,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => TransactionFormPage(
                      transactionId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.debts,
                builder: (context, state) => const DebtsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const DebtFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        DebtDetailPage(debtId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calculator,
                builder: (context, state) => const CalculatorPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const BusinessSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorPage(
      message: state.error?.toString() ?? 'Halaman tidak ditemukan.',
    ),
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AppUser?> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AppUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: AppEmptyState(
              icon: Icons.explore_off_outlined,
              title: 'Halaman tidak ditemukan',
              message: message,
              action: AppButton(
                label: 'Kembali ke Beranda',
                icon: Icons.home_rounded,
                isExpanded: false,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
