import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final foreground = _foregroundColor;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDisabled ? AppColors.textMuted : foreground,
            ),
          ),
          if (label.isNotEmpty) const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: isDisabled ? AppColors.textMuted : foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isDisabled ? AppColors.textMuted : foreground,
            ),
          ),
        ),
      ],
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: isDisabled ? null : onPressed,
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
        ),
        child: content,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: isDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(0, 48),
        ),
        child: content,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: content,
      ),
    };

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Color get _foregroundColor {
    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary => AppColors.primary,
      AppButtonVariant.ghost => AppColors.textSecondary,
    };
  }
}
