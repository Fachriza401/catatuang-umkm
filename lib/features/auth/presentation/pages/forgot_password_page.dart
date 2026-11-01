import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final sent = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendResetEmail(_emailController.text.trim());
    if (!mounted) return;
    if (sent) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final error = state.error;
    final isLoading = state.isLoading;

    return AuthScaffold(
      title: 'Lupa password?',
      subtitle: 'Masukkan email akun Anda. Buka tautan reset di Android yang '
          'memiliki CatatUang.',
      showBack: true,
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppStatusBanner(
                  message:
                      'Tautan reset sudah dikirim. Buka email ini di Android '
                      'yang memiliki CatatUang, bukan browser desktop.',
                  tone: AppStatusTone.success,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Kembali ke Masuk',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.go(AppRoutes.login),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Kirim ke Email Lain',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => setState(() => _sent = false),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    AppStatusBanner(
                      message: error is AppFailure
                          ? error.message
                          : 'Tautan reset gagal dikirim. Silakan coba lagi.',
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    enabled: !isLoading,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'Kirim Tautan Reset',
                    icon: Icons.send_rounded,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
