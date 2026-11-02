import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'catat_uang'),
  );
  static const _savedEmailKey = 'catat_uang_remembered_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await _storage.read(key: _savedEmailKey);
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_rememberMe) {
      await _storage.write(
        key: _savedEmailKey,
        value: _emailController.text.trim(),
      );
    } else {
      await _storage.delete(key: _savedEmailKey);
    }

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

  Widget _buildCloudStatusBadge() {
    final isConfigured = AppConfig.isSupabaseConfigured;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isConfigured ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: (isConfigured ? AppColors.success : AppColors.warning)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConfigured ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isConfigured
                ? 'Supabase Cloud Aktif'
                : 'Konfigurasi Cloud Diperlukan',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isConfigured ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips() {
    const items = [
      (Icons.lock_outline_rounded, 'Privat'),
      (Icons.cloud_sync_outlined, 'Sinkron'),
      (Icons.bolt_rounded, 'Cepat'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 13, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  item.$2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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
      title: 'Selamat Datang Kembali 👋',
      subtitle:
          'Masuk ke akun CatatUang Anda untuk memantau keuangan dan pembukuan usaha.',
      headerBadge: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCloudStatusBadge(),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureChips(),
        ],
      ),
      showCardShadow: true,
      footer: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Belum punya akun?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.push(AppRoutes.register),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(
                'Daftar Sekarang',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDeep, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masuk ke akun Anda',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gunakan email usaha yang sudah terdaftar.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!AppConfig.isSupabaseConfigured) ...[
                const AppStatusBanner(
                  message:
                      'Supabase belum terkonfigurasi. Pastikan koneksi atau variabel '
                      'SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY aktif.',
                  tone: AppStatusTone.warning,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (error != null) ...[
                AppStatusBanner(
                  message: error is AppFailure
                      ? error.message
                      : 'Gagal masuk ke akun. Silakan periksa kembali data Anda.',
                  tone: AppStatusTone.error,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppTextField(
                controller: _emailController,
                label: 'Email Usaha',
                hint: 'nama@usaha.com',
                prefixIcon: Icons.alternate_email_rounded,
                suffixIcon: _emailController.text.isNotEmpty && !isLoading
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Hapus teks',
                        onPressed: () {
                          _emailController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPasswordField(
                controller: _passwordController,
                label: 'Kata Sandi',
                hint: 'Masukkan kata sandi Anda',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    Validators.required(value, label: 'Kata Sandi'),
                enabled: !isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: isLoading
                                  ? null
                                  : (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Ingat email saya',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lupa password?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isLoading ? 'Memverifikasi...' : 'Masuk ke Akun',
                icon: Icons.login_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Data pembukuan tersimpan secara lokal dan otomatis '
                        'disinkronkan dengan cloud saat online.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
