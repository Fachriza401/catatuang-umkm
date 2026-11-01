import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../business_profile/domain/usecases/business_profile_use_cases.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 0;

  String get _email {
    final fromQuery = widget.email?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return ref.read(currentAuthUserProvider)?.email ?? '';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining <= 1) {
          _secondsRemaining = 0;
          timer.cancel();
        } else {
          _secondsRemaining--;
        }
      });
    });
  }

  Future<void> _resend() async {
    final email = _email;
    if (email.isEmpty || _secondsRemaining > 0) return;
    final sent = await ref
        .read(verifyEmailControllerProvider.notifier)
        .resend(email);
    if (!mounted) return;
    if (sent) {
      _startCooldown();
      AppSnackbar.success(context, 'Email verifikasi berhasil dikirim ulang.');
    }
  }

  Future<void> _verifyCode() async {
    final email = _email;
    if (email.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final destination = await ref
        .read(verifyEmailControllerProvider.notifier)
        .verifyCode(email: email, code: _codeController.text.trim());
    if (!mounted || destination == null) return;
    switch (destination) {
      case PostAuthDestination.setupProfile:
        context.go(AppRoutes.setupProfile);
      case PostAuthDestination.home:
        context.go(AppRoutes.home);
    }
  }

  Future<void> _checkVerification() async {
    final destination = await ref
        .read(verifyEmailControllerProvider.notifier)
        .checkVerification();
    if (!mounted) return;
    if (destination == null) {
      AppSnackbar.info(
        context,
        'Aplikasi belum menerima sesi verifikasi. Buka tautan terbaru di '
        'Android, atau masuk jika tautan dibuka di browser lain.',
      );
      return;
    }
    switch (destination) {
      case PostAuthDestination.setupProfile:
        context.go(AppRoutes.setupProfile);
      case PostAuthDestination.home:
        context.go(AppRoutes.home);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(signOutUseCaseProvider)(const NoParams());
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        error is AppFailure ? error.message : 'Gagal keluar dari akun.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
    final error = state.error;
    final isLoading = state.isLoading;
    final email = _email;

    return AuthScaffold(
      title: 'Verifikasi email',
      subtitle: 'Satu langkah lagi sebelum Anda mulai mencatat keuangan usaha.',
      showBack: true,
      footer: TextButton(onPressed: _signOut, child: const Text('Ganti akun')),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(color: AppColors.primarySoft),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Periksa kotak masuk Anda',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              email.isEmpty
                  ? 'Email akun tidak ditemukan. Silakan masuk kembali.'
                  : 'Kami mengirim tautan dan kode verifikasi ke\n$email',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (error != null) ...[
              AppStatusBanner(
                message: error is AppFailure
                    ? error.message
                    : 'Verifikasi gagal diproses. Silakan coba lagi.',
                tone: AppStatusTone.error,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const AppStatusBanner(
              message:
                  'Masukkan 6 digit kode dari email. Alternatif: buka tautan '
                  'di Android agar sesi kembali ke aplikasi.',
              tone: AppStatusTone.info,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _codeController,
              label: 'Kode verifikasi',
              hint: '6 digit dari email',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.verificationCode,
              enabled: !isLoading && email.isNotEmpty,
              onFieldSubmitted: (_) => _verifyCode(),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Verifikasi Kode',
              icon: Icons.verified_user_outlined,
              isLoading: isLoading,
              onPressed: isLoading || email.isEmpty ? null : _verifyCode,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Saya Sudah Verifikasi',
              icon: Icons.verified_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: isLoading || email.isEmpty ? null : _checkVerification,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _secondsRemaining > 0
                  ? 'Kirim Ulang (${_secondsRemaining}s)'
                  : 'Kirim Ulang Email',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: isLoading || email.isEmpty || _secondsRemaining > 0
                  ? null
                  : _resend,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Sudah konfirmasi di browser? Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
