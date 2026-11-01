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
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  bool _isSaved = false;
  AppFailure? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      setState(() => _isSaved = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = mapToAppFailure(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _isSaved ? 'Password diperbarui' : 'Buat password baru',
      subtitle: _isSaved
          ? 'Password akun Anda berhasil diperbarui.'
          : 'Masukkan password baru untuk akun Anda.',
      showBack: false,
      child: _isSaved
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppStatusBanner(
                  message: 'Password berhasil diperbarui.',
                  tone: AppStatusTone.success,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Kembali ke Masuk',
                  icon: Icons.login_rounded,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AppStatusBanner(
                      message: _error!.message,
                      tone: AppStatusTone.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppPasswordField(
                    controller: _passwordController,
                    label: 'Password baru',
                    hint: 'Buat password yang kuat',
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                    helperText:
                        'Minimal 8 karakter, huruf besar, kecil, dan angka.',
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPasswordField(
                    controller: _confirmController,
                    label: 'Konfirmasi password baru',
                    hint: 'Ulangi password baru',
                    textInputAction: TextInputAction.done,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    enabled: !_isSaving,
                    onFieldSubmitted: (_) => _savePassword(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: 'Simpan password baru',
                    icon: Icons.lock_reset_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _savePassword,
                  ),
                ],
              ),
            ),
    );
  }
}
