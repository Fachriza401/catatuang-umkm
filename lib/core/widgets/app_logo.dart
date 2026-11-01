import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
    this.wordmarkColor = AppColors.textPrimary,
  });

  final double size;
  final bool showWordmark;
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.primaryGlow(AppColors.primary),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: size * 0.48,
        color: Colors.white,
      ),
    );

    if (!showWordmark) {
      return Semantics(label: 'Logo CatatUang', child: mark);
    }

    return Semantics(
      label: 'Logo CatatUang',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(height: AppSpacing.md),
          Text(
            'CatatUang',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: wordmarkColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
