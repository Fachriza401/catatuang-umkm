import '../../../transactions/domain/entities/money_transaction.dart';
import 'dashboard_period.dart';

class DashboardSummary {
  const DashboardSummary({required this.income, required this.expense});

  final int income;
  final int expense;

  int get net => income - expense;
  bool get isProfit => net >= 0;
}

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.bucketStart,
    required this.income,
    required this.expense,
  });

  final DateTime bucketStart;
  final int income;
  final int expense;
}

class DashboardData {
  const DashboardData({
    required this.period,
    required this.cashBalance,
    required this.summary,
    required this.chartPoints,
    required this.recentTransactions,
  });

  final DashboardPeriod period;
  final int cashBalance;
  final DashboardSummary summary;
  final List<DashboardChartPoint> chartPoints;
  final List<MoneyTransaction> recentTransactions;

  factory DashboardData.empty(DashboardPeriod period) {
    return DashboardData(
      period: period,
      cashBalance: 0,
      summary: const DashboardSummary(income: 0, expense: 0),
      chartPoints: const [],
      recentTransactions: const [],
    );
  }
}
