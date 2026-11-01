import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: compact ? 20 : 32,
      height: compact ? 20 : 32,
      child: const CircularProgressIndicator(strokeWidth: 2.4),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          if (message != null) ...[
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
