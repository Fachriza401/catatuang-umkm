import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_period.dart';

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({
    super.key,
    required this.points,
    required this.period,
  });

  final List<DashboardChartPoint> points;
  final DashboardPeriod period;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Belum ada data untuk ditampilkan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final maxValue = points.fold<int>(
      0,
      (max, point) => math.max(max, math.max(point.income, point.expense)),
    );

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ChartColumn(
                      point: point,
                      maxValue: maxValue,
                      label: _labelFor(point.bucketStart),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelFor(DateTime date) {
    return switch (period) {
      DashboardPeriod.daily => AppDateFormat.weekdayShort(date),
      DashboardPeriod.weekly => AppDateFormat.shortDate(date),
      DashboardPeriod.monthly => AppDateFormat.monthShort(date),
      DashboardPeriod.yearly => AppDateFormat.monthShort(date),
    };
  }
}

class _ChartColumn extends StatelessWidget {
  const _ChartColumn({
    required this.point,
    required this.maxValue,
    required this.label,
  });

  final DashboardChartPoint point;
  final int maxValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 112.0;
    final incomeHeight =
        maxValue == 0 ? 0.0 : (point.income / maxValue) * maxBarHeight;
    final expenseHeight =
        maxValue == 0 ? 0.0 : (point.expense / maxValue) * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: maxBarHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Bar(height: incomeHeight, color: AppColors.success),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _Bar(height: expenseHeight, color: AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasValue = height > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: hasValue ? math.max(height, 4) : 4,
      decoration: BoxDecoration(
        color: hasValue ? color : AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }
}
