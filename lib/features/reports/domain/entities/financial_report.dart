import '../../../dashboard/domain/entities/dashboard_data.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import 'report_date_range.dart';
import 'report_period.dart';

class FinancialReport {
  const FinancialReport({
    required this.period,
    required this.range,
    required this.dashboard,
    required this.transactions,
    required this.receivableOutstanding,
    required this.payableOutstanding,
    required this.generatedAt,
  });

  final ReportPeriod period;
  final ReportDateRange range;
  final DashboardData dashboard;
  final List<MoneyTransaction> transactions;
  final int receivableOutstanding;
  final int payableOutstanding;
  final DateTime generatedAt;

  int get income => dashboard.summary.income;
  int get expense => dashboard.summary.expense;
  int get net => dashboard.summary.net;
  int get cashBalance => dashboard.cashBalance;
  bool get isProfit => dashboard.summary.isProfit;
}
