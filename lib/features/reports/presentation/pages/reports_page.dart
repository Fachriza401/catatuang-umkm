import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/domain/entities/business_profile.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../../business_profile/presentation/providers/business_profile_providers.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../data/services/report_pdf_service.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/services/financial_report_calculator.dart';
import '../providers/report_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final _pdfService = ReportPdfService();
  ReportPeriod _period = ReportPeriod.monthly;
  DateTime _anchor = DateTime.now();
  ReportDateRange? _customRange;
  bool _isExporting = false;
  ReportPdfFormat _pdfFormat = ReportPdfFormat.a4;

  ReportDateRange get _range => ReportDateRange.forPeriod(
    period: _period,
    anchor: _anchor,
    customRange: _customRange,
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sesi pengguna tidak tersedia.')),
      );
    }
    final access = ref
        .watch(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final businessId = access.businessId;

    final transactions = ref.watch(reportTransactionsProvider(businessId));
    final debts = ref.watch(debtsProvider(businessId));
    final profileState = ref.watch(businessProfileByIdProvider(businessId));
    final profile = profileState.when(
      data: (value) => value,
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(
          onRetry: () {
            ref.invalidate(reportTransactionsProvider(businessId));
          },
        ),
        data: (transactionRows) => debts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _LoadError(
            onRetry: () {
              ref.invalidate(debtsProvider(businessId));
            },
          ),
          data: (debtRows) {
            final report = FinancialReportCalculator.build(
              transactions: transactionRows,
              debts: debtRows,
              period: _period,
              range: _range,
            );
            return _reportBody(report, profile, businessId);
          },
        ),
      ),
    );
  }

  Widget _reportBody(
    FinancialReport report,
    BusinessProfile? profile,
    String userId,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportTransactionsProvider(userId));
        ref.invalidate(debtsProvider(userId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _periodControls(report.range),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<ReportPdfFormat>(
                    initialValue: _pdfFormat,
                    decoration: const InputDecoration(
                      labelText: 'Ukuran kertas PDF',
                    ),
                    items: [
                      for (final format in ReportPdfFormat.values)
                        DropdownMenuItem(
                          value: format,
                          child: Text(format.label),
                        ),
                    ],
                    onChanged: _isExporting
                        ? null
                        : (format) {
                            if (format != null) {
                              setState(() => _pdfFormat = format);
                            }
                          },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _pdfFormat == ReportPdfFormat.a4
                        ? 'PDF dibuat sesuai ukuran A4.'
                        : 'PDF struk dibuat dengan lebar kertas ${_pdfFormat == ReportPdfFormat.thermal58 ? '58' : '80'} mm.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_period.label} | ${report.range.label}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bagikan laporan',
                        onPressed: _isExporting
                            ? null
                            : () => _createPdf(report, profile, share: true),
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _createPdf(report, profile, share: false),
                      icon: _isExporting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isExporting ? 'Menyiapkan PDF' : 'Export PDF',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeading('Ringkasan arus kas'),
                  const SizedBox(height: AppSpacing.md),
                  _metricGrid(report),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeading('Utang dan piutang'),
                  const SizedBox(height: AppSpacing.md),
                  _debtSummary(report),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeading('Laba/rugi sederhana'),
                  const SizedBox(height: AppSpacing.md),
                  _profitLoss(report),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeading('Pemasukan dan pengeluaran'),
                  const SizedBox(height: AppSpacing.md),
                  _chart(report),
                  const SizedBox(height: AppSpacing.xl),
                  _sectionHeading('Detail transaksi'),
                  const SizedBox(height: AppSpacing.sm),
                  _transactionDetails(report.transactions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodControls(ReportDateRange range) {
    final presets = ReportPeriod.values
        .where((period) => period != ReportPeriod.custom)
        .toList(growable: false);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ReportPeriod>(
            showSelectedIcon: false,
            segments: [
              for (final period in presets)
                ButtonSegment(value: period, label: Text(period.label)),
            ],
            selected: _period == ReportPeriod.custom ? {} : {_period},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              setState(() {
                _period = selection.first;
                _customRange = null;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Periode sebelumnya',
              onPressed: () => _shiftPeriod(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Flexible(
              child: Text(
                range.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Periode berikutnya',
              onPressed: range.start.isAfter(DateTime.now())
                  ? null
                  : () => _shiftPeriod(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: 'Pilih rentang tanggal',
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
      ],
    );
  }

  void _shiftPeriod(int delta) {
    final shifted = _range.shift(delta, _period);
    setState(() {
      if (_period == ReportPeriod.custom) {
        _customRange = shifted;
      } else {
        _anchor = shifted.start;
      }
    });
  }

  Future<void> _pickDateRange() async {
    final range = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: range.start,
        end: range.endInclusive,
      ),
      helpText: 'Pilih rentang laporan',
      saveText: 'Terapkan',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = ReportPeriod.custom;
      _customRange = ReportDateRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        endExclusive: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day + 1,
        ),
      );
    });
  }

  Widget _sectionHeading(String label) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _metricGrid(FinancialReport report) {
    final metrics = [
      _Metric(
        'Pemasukan',
        report.income,
        Icons.south_west_rounded,
        AppColors.success,
      ),
      _Metric(
        'Pengeluaran',
        report.expense,
        Icons.north_east_rounded,
        AppColors.danger,
      ),
      _Metric(
        'Arus kas bersih',
        report.net,
        Icons.swap_vert_rounded,
        report.net >= 0 ? AppColors.success : AppColors.danger,
      ),
      _Metric(
        'Saldo saat ini',
        report.cashBalance,
        Icons.account_balance_wallet_outlined,
        AppColors.primary,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }

  Widget _debtSummary(FinancialReport report) {
    return _panel(
      child: Row(
        children: [
          Expanded(
            child: _DebtAmount(
              label: 'Sisa piutang',
              value: report.receivableOutstanding,
              color: AppColors.info,
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: _DebtAmount(
              label: 'Sisa utang',
              value: report.payableOutstanding,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitLoss(FinancialReport report) {
    final profit = report.net >= 0;
    final color = profit ? AppColors.success : AppColors.danger;
    return _panel(
      child: Row(
        children: [
          Icon(
            profit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              profit ? 'Laba' : 'Rugi',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            CurrencyFormatter.format(report.net.abs()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart(FinancialReport report) {
    final points = report.dashboard.chartPoints;
    if (points.isEmpty) {
      return _panel(child: const Text('Belum ada data grafik.'));
    }
    final maxValue = points.fold<double>(
      0,
      (maxValue, point) => math.max(
        maxValue,
        math.max(point.income.toDouble(), point.expense.toDouble()),
      ),
    );
    final interval = math.max(1, (points.length / 7).ceil());
    final chartWidth = math.max(360.0, points.length * 38.0);
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.lg,
            children: const [
              _Legend(color: AppColors.success, label: 'Pemasukan'),
              _Legend(color: AppColors.danger, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue == 0 ? 1 : maxValue * 1.18,
                    barGroups: [
                      for (var index = 0; index < points.length; index++)
                        BarChartGroupData(
                          x: index,
                          barsSpace: 3,
                          barRods: [
                            _rod(points[index].income, AppColors.success),
                            _rod(points[index].expense, AppColors.danger),
                          ],
                        ),
                    ],
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: interval.toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 6,
                              child: Text(
                                _chartLabel(points[index].bucketStart, report),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 220),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartRodData _rod(int value, Color color) {
    return BarChartRodData(
      toY: value.toDouble(),
      color: color,
      width: 10,
      borderRadius: BorderRadius.circular(AppRadius.xs),
    );
  }

  String _chartLabel(DateTime date, FinancialReport report) {
    if (report.range.endExclusive.difference(report.range.start) <=
        const Duration(days: 1)) {
      return '${date.hour.toString().padLeft(2, '0')}:00';
    }
    if (report.range.endExclusive.difference(report.range.start).inDays > 140) {
      return AppDateFormat.monthShort(date);
    }
    return '${date.day}/${date.month}';
  }

  Widget _transactionDetails(List<MoneyTransaction> transactions) {
    if (transactions.isEmpty) {
      return _panel(child: const Text('Tidak ada transaksi pada periode ini.'));
    }
    return Column(
      children: [
        for (var index = 0; index < transactions.length; index++) ...[
          _TransactionRow(transaction: transactions[index]),
          if (index != transactions.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Future<void> _createPdf(
    FinancialReport report,
    BusinessProfile? profile, {
    required bool share,
  }) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _pdfService.build(
        report: report,
        businessProfile: profile,
        format: _pdfFormat,
      );
      final filename =
          'CatatUang-Laporan-${report.range.start.toIso8601String().substring(0, 10)}-${_pdfFormat.name}.pdf';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      } else {
        await Printing.layoutPdf(
          name: filename,
          format: _pdfService.pageFormatFor(report, _pdfFormat),
          onLayout: (_) async => bytes,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF laporan gagal dibuat.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _Metric {
  const _Metric(this.label, this.amount, this.icon, this.color);

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 18, color: metric.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            CurrencyFormatter.format(metric.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: metric.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtAmount extends StatelessWidget {
  const _DebtAmount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    final color = income ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.trim().isEmpty
                      ? transaction.type.label
                      : transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppDateFormat.fullDate(transaction.transactionDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${income ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Laporan gagal dimuat.'),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
