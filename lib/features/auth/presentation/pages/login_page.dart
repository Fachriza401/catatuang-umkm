import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../business_profile/domain/usecases/business_profile_use_cases.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _navigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final destination = await ref
        .read(loginControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || destination == null) return;
    _goToDestination(destination);
  }

  void _goToDestination(PostAuthDestination destination) {
    if (_navigated) return;
    _navigated = true;
    switch (destination) {
      case PostAuthDestination.setupProfile:
        context.go(AppRoutes.setupProfile);
      case PostAuthDestination.home:
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final error = state.error;
    final isLoading = state.isLoading;

    ref.listen(loginControllerProvider, (previous, next) {
      final failure = next.error;
      if (failure is AuthFailure &&
          failure.isEmailNotConfirmed &&
          !_navigated) {
        _navigated = true;
        context.go(
          Uri(
            path: AppRoutes.verifyEmail,
            queryParameters: {'email': _emailController.text.trim()},
          ).toString(),
        );
      }
    });

    return AuthScaffold(
      title: 'Masuk ke CatatUang',
      subtitle:
          'Kelola pemasukan, pengeluaran, dan arus kas usaha dalam satu tempat.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Belum punya akun?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.register),
            child: const Text('Daftar'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!AppConfig.isSupabaseConfigured) ...[
                const AppStatusBanner(
                  message:
                      'Supabase belum dikonfigurasi. Jalankan aplikasi dengan '
                      'SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
                  tone: AppStatusTone.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (error != null) ...[
                AppStatusBanner(
                  message: error is AppFailure
                      ? error.message
                      : 'Gagal masuk. Silakan coba lagi.',
                  tone: AppStatusTone.error,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'nama@usaha.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPasswordField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Masukkan password Anda',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    Validators.required(value, label: 'Password'),
                enabled: !isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Lupa password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Masuk',
                icon: Icons.login_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Dengan masuk, data transaksi Anda akan tersimpan dengan aman '
                'di perangkat dan disinkronkan ke cloud.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
