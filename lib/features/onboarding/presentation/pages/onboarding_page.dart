import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;
  bool _isFinishing = false;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.receipt_long_rounded,
      title: 'Catat setiap transaksi',
      description:
          'Pemasukan dan pengeluaran usaha tercatat rapi lengkap dengan '
          'kategori, tanggal, metode pembayaran, dan bukti transaksi.',
      color: AppColors.primary,
      softColor: AppColors.primarySoft,
    ),
    _OnboardingSlide(
      icon: Icons.insights_rounded,
      title: 'Pantau arus kas usaha',
      description:
          'Lihat saldo kas, laba rugi, dan tren pemasukan vs pengeluaran '
          'harian, mingguan, hingga bulanan dalam satu dashboard.',
      color: AppColors.success,
      softColor: AppColors.successSoft,
    ),
    _OnboardingSlide(
      icon: Icons.cloud_done_rounded,
      title: 'Aman dan tersinkron',
      description:
          'Data tersimpan di perangkat dengan SQLite dan disinkronkan ke '
          'Supabase saat koneksi tersedia. Usaha tetap bisa dicatat offline.',
      color: AppColors.info,
      softColor: AppColors.infoSoft,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await ref.read(onboardingRepositoryProvider).markCompleted();
      if (mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFinishing = false);
      AppSnackbar.error(
        context,
        'Gagal menyimpan status onboarding. Silakan coba lagi.',
      );
    }
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'CatatUang',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isFinishing ? null : _finish,
                    child: const Text('Lewati'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  return _SlideView(slide: _slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AppButton(
                      label: _index == _slides.length - 1
                          ? 'Mulai Sekarang'
                          : 'Lanjut',
                      icon: _index == _slides.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      isLoading: _isFinishing,
                      onPressed: _isFinishing ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [slide.softColor, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(56),
                  border: Border.all(
                    color: slide.color.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(slide.icon, color: slide.color, size: 86),
              ),
              const SizedBox(height: AppSpacing.huge),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.softColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color softColor;
}
