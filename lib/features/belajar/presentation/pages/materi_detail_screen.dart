import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/learning_module.dart';

class MateriDetailScreen extends StatelessWidget {
  const MateriDetailScreen({super.key, required this.module});

  final LearningModule? module;

  @override
  Widget build(BuildContext context) {
    final article = module;
    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali ke Belajar',
            onPressed: () => context.go(AppRoutes.belajar),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Materi tidak ditemukan'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Materi ini tidak tersedia. Kembali ke daftar Belajar.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali ke Belajar',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.belajar);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Belajar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.topic,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    article.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final section in article.sections) ...[
                    _LearningSection(section: section),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.belajar),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Kembali ke daftar materi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSection extends StatelessWidget {
  const _LearningSection({required this.section});

  final LearningSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.heading,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              section.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
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
