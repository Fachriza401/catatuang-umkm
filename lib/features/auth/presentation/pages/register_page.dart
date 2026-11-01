import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _navigated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(registerControllerProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || result == null || _navigated) return;
    _navigated = true;
    if (result.requiresEmailVerification) {
      context.go(
        Uri(
          path: AppRoutes.verifyEmail,
          queryParameters: {'email': _emailController.text.trim()},
        ).toString(),
      );
    } else {
      context.go(AppRoutes.setupProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final error = state.error;
    final isLoading = state.isLoading;

    return AuthScaffold(
      title: 'Buat akun usaha',
      subtitle: 'Gratis, cepat, dan siap membantu pembukuan usaha kecil Anda.',
      showBack: true,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sudah punya akun?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Masuk'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                AppStatusBanner(
                  message: error is AppFailure
                      ? error.message
                      : 'Registrasi gagal. Silakan coba lagi.',
                  tone: AppStatusTone.error,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Nama lengkap',
                hint: 'Nama Anda',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                hint: 'Buat password yang kuat',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                helperText:
                    'Minimal 8 karakter, huruf besar, kecil, dan angka.',
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPasswordField(
                controller: _confirmController,
                label: 'Konfirmasi password',
                hint: 'Ulangi password',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
                enabled: !isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Daftar Sekarang',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
