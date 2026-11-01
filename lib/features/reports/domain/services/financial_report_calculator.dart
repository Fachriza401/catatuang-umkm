import '../../../dashboard/domain/entities/dashboard_period.dart';
import '../../../dashboard/domain/services/dashboard_calculator.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/domain/entities/debt_type.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/financial_report.dart';
import '../entities/report_date_range.dart';
import '../entities/report_period.dart';

abstract final class FinancialReportCalculator {
  static FinancialReport build({
    required List<MoneyTransaction> transactions,
    required List<Debt> debts,
    required ReportPeriod period,
    required ReportDateRange range,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final dashboardPeriod = _dashboardPeriod(period, range);
    final dashboard = DashboardCalculator.build(
      transactions: transactions,
      period: dashboardPeriod,
      now: now,
      startDate: range.start,
      endDateExclusive: range.endExclusive,
    );
    final details = transactions
        .where(
          (transaction) =>
              !transaction.isDeleted &&
              !transaction.transactionDate.isBefore(range.start) &&
              transaction.transactionDate.isBefore(range.endExclusive),
        )
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return FinancialReport(
      period: period,
      range: range,
      dashboard: dashboard,
      transactions: List.unmodifiable(details),
      receivableOutstanding: _outstanding(debts, DebtType.receivable),
      payableOutstanding: _outstanding(debts, DebtType.payable),
      generatedAt: now,
    );
  }

  static DashboardPeriod _dashboardPeriod(
    ReportPeriod period,
    ReportDateRange range,
  ) {
    return switch (period) {
      ReportPeriod.daily => DashboardPeriod.daily,
      ReportPeriod.weekly => DashboardPeriod.weekly,
      ReportPeriod.monthly => DashboardPeriod.monthly,
      ReportPeriod.yearly => DashboardPeriod.yearly,
      ReportPeriod.custom =>
        range.endExclusive.difference(range.start).inDays <= 1
            ? DashboardPeriod.daily
            : range.endExclusive.difference(range.start).inDays <= 7
                ? DashboardPeriod.weekly
                : range.endExclusive.difference(range.start).inDays <= 45
                    ? DashboardPeriod.monthly
                    : DashboardPeriod.yearly,
    };
  }

  static int _outstanding(List<Debt> debts, DebtType type) {
    return debts
        .where((debt) => debt.type == type)
        .fold(0, (total, debt) => total + debt.remainingAmount);
  }
}
