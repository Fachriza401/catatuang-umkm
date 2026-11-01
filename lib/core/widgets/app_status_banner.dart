import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppStatusTone { info, success, warning, error }

class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.message,
    this.tone = AppStatusTone.info,
    this.icon,
  });

  final String message;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, defaultIcon) = switch (tone) {
      AppStatusTone.info => (
        AppColors.infoSoft,
        AppColors.primaryDark,
        Icons.info_outline_rounded,
      ),
      AppStatusTone.success => (
        AppColors.successSoft,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      AppStatusTone.warning => (
        AppColors.warningSoft,
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      AppStatusTone.error => (
        AppColors.dangerSoft,
        AppColors.danger,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
