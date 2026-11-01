import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/rupiah_calculator_engine.dart';

class RupiahCalculatorPanel extends StatefulWidget {
  const RupiahCalculatorPanel({
    super.key,
    this.initialValue = 0,
    this.submitLabel = 'Gunakan hasil',
    this.submitIcon = Icons.check_rounded,
    this.onSubmit,
  });

  final int initialValue;
  final String submitLabel;
  final IconData submitIcon;
  final ValueChanged<int>? onSubmit;

  @override
  State<RupiahCalculatorPanel> createState() => _RupiahCalculatorPanelState();
}

class _RupiahCalculatorPanelState extends State<RupiahCalculatorPanel> {
  late final RupiahCalculatorEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = RupiahCalculatorEngine(initialValue: widget.initialValue);
  }

  void _press(String key) {
    setState(() => _engine.press(key));
  }

  @override
  Widget build(BuildContext context) {
    final expression = _engine.pendingOperator == null
        ? 'Masukkan angka atau hitung cepat'
        : '${CurrencyFormatter.format(_engine.storedValue ?? 0)} '
              '${_engine.pendingOperator}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DisplayCard(engine: _engine, expression: expression),
        const SizedBox(height: AppSpacing.lg),
        _keypad(context),
        if (widget.onSubmit != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _engine.canSubmit
                ? () => widget.onSubmit!(_engine.value)
                : null,
            icon: Icon(widget.submitIcon),
            label: Text(widget.submitLabel),
          ),
        ],
      ],
    );
  }

  Widget _keypad(BuildContext context) {
    const rows = [
      ['AC', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              for (var index = 0; index < row.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CalculatorKey(label: row[index], onTap: _press),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: _CalculatorKey(label: '00', onTap: _press),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CalculatorKey(label: '0', onTap: _press),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: _CalculatorKey(label: '=', onTap: _press, isPrimary: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.engine, required this.expression});

  final RupiahCalculatorEngine engine;
  final String expression;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Kalkulator rupiah',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            expression,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(engine.value),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (engine.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              engine.errorMessage!,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.warningSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalculatorKey extends StatelessWidget {
  const _CalculatorKey({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final ValueChanged<String> onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isControl = label == 'AC' || label == '⌫';
    final isOperator =
        RupiahCalculatorEngine.operatorKeys.contains(label) || label == '%';
    final foreground = isPrimary
        ? Colors.white
        : isControl
        ? AppColors.danger
        : isOperator
        ? AppColors.primary
        : AppColors.textPrimary;
    final background = isPrimary
        ? AppColors.primary
        : isControl
        ? AppColors.dangerSoft
        : isOperator
        ? AppColors.primarySurface
        : AppColors.surfaceMuted;

    return SizedBox(
      height: 56,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => onTap(label),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
