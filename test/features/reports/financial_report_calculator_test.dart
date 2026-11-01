import 'package:catat_uang/features/dashboard/domain/entities/dashboard_period.dart';
import 'package:catat_uang/features/dashboard/domain/services/dashboard_calculator.dart';
import 'package:catat_uang/features/debts/domain/entities/debt.dart';
import 'package:catat_uang/features/debts/domain/entities/debt_type.dart';
import 'package:catat_uang/features/reports/domain/entities/report_date_range.dart';
import 'package:catat_uang/features/reports/domain/entities/report_period.dart';
import 'package:catat_uang/features/reports/domain/services/financial_report_calculator.dart';
import 'package:catat_uang/features/transactions/domain/entities/money_transaction.dart';
import 'package:catat_uang/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = ReportDateRange(
    start: DateTime(2026, 11, 1),
    endExclusive: DateTime(2026, 12, 1),
  );
  final transactions = [
    _transaction('sale', TransactionType.income, 120000, DateTime(2026, 11, 1)),
    _transaction(
      'receivable-payment',
      TransactionType.income,
      25000,
      DateTime(2026, 11, 15),
    ),
    _transaction(
      'purchase',
      TransactionType.expense,
      40000,
      DateTime(2026, 11, 30, 23),
    ),
    _transaction(
      'outside-range',
      TransactionType.income,
      900000,
      DateTime(2026, 12, 1),
    ),
  ];
  final debts = [
    _debt('receivable', DebtType.receivable, amount: 100000, paid: 25000),
    _debt('payable', DebtType.payable, amount: 80000, paid: 30000),
  ];

  test('ringkasan laporan identik dengan kalkulator dashboard', () {
    final report = FinancialReportCalculator.build(
      transactions: transactions,
      debts: debts,
      period: ReportPeriod.monthly,
      range: range,
      generatedAt: DateTime(2026, 12, 1),
    );
    final dashboard = DashboardCalculator.build(
      transactions: transactions,
      period: DashboardPeriod.monthly,
      startDate: range.start,
      endDateExclusive: range.endExclusive,
    );

    expect(report.income, dashboard.summary.income);
    expect(report.expense, dashboard.summary.expense);
    expect(report.net, dashboard.summary.net);
    expect(report.income, 145000);
    expect(report.expense, 40000);
    expect(report.net, 105000);
    expect(report.cashBalance, 1005000);
    expect(report.transactions.map((transaction) => transaction.id), [
      'purchase',
      'receivable-payment',
      'sale',
    ]);
  });

  test('saldo utang dan piutang hanya memakai sisa tagihan', () {
    final report = FinancialReportCalculator.build(
      transactions: transactions,
      debts: debts,
      period: ReportPeriod.monthly,
      range: range,
    );

    expect(report.receivableOutstanding, 75000);
    expect(report.payableOutstanding, 50000);
    expect(report.income, 145000);
    expect(report.expense, 40000);
  });

  test('rentang harian, mingguan, bulanan, dan tahunan terbentuk tepat', () {
    final anchor = DateTime(2024, 2, 29, 16);

    expect(
      ReportDateRange.forPeriod(
        period: ReportPeriod.daily,
        anchor: anchor,
      ).endExclusive,
      DateTime(2024, 3, 1),
    );
    expect(
      ReportDateRange.forPeriod(
        period: ReportPeriod.weekly,
        anchor: anchor,
      ).start.weekday,
      DateTime.monday,
    );
    expect(
      ReportDateRange.forPeriod(
        period: ReportPeriod.monthly,
        anchor: anchor,
      ).endExclusive,
      DateTime(2024, 3),
    );
    expect(
      ReportDateRange.forPeriod(
        period: ReportPeriod.yearly,
        anchor: anchor,
      ).endExclusive,
      DateTime(2025),
    );
  });
}

MoneyTransaction _transaction(
  String id,
  TransactionType type,
  int amount,
  DateTime date,
) {
  return MoneyTransaction(
    id: id,
    userId: 'user-1',
    type: type,
    amount: amount,
    categoryId: type.isIncome ? 'sales' : 'ingredients',
    paymentMethodId: 'cash',
    transactionDate: date,
    description: id,
    createdAt: date,
    updatedAt: date,
  );
}

Debt _debt(String id, DebtType type, {required int amount, required int paid}) {
  final date = DateTime(2026, 11, 1);
  return Debt(
    id: id,
    userId: 'user-1',
    type: type,
    contactName: id,
    phone: '',
    amount: amount,
    paidAmount: paid,
    transactionDate: date,
    dueDate: DateTime(2026, 12, 1),
    note: '',
    createdAt: date,
    updatedAt: date,
  );
}
