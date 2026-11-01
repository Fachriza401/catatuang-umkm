import 'package:catat_uang/features/dashboard/domain/entities/dashboard_period.dart';
import 'package:catat_uang/features/dashboard/domain/services/dashboard_calculator.dart';
import 'package:catat_uang/features/transactions/domain/entities/money_transaction.dart';
import 'package:catat_uang/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 31, 12);

  final transactions = [
    _transaction(
      id: 'income-today',
      type: TransactionType.income,
      amount: 100000,
      date: DateTime(2026, 10, 31, 9),
    ),
    _transaction(
      id: 'expense-yesterday',
      type: TransactionType.expense,
      amount: 40000,
      date: DateTime(2026, 10, 30, 15),
    ),
    _transaction(
      id: 'expense-first-day',
      type: TransactionType.expense,
      amount: 10000,
      date: DateTime(2026, 10, 1, 8),
    ),
    _transaction(
      id: 'income-last-month',
      type: TransactionType.income,
      amount: 20000,
      date: DateTime(2026, 9, 15, 10),
    ),
    _transaction(
      id: 'deleted',
      type: TransactionType.expense,
      amount: 999999,
      date: DateTime(2026, 10, 31, 11),
      deletedAt: DateTime(2026, 10, 31, 11),
    ),
  ];

  test('menghitung saldo, ringkasan bulanan, dan transaksi terbaru', () {
    final data = DashboardCalculator.build(
      transactions: transactions,
      period: DashboardPeriod.monthly,
      now: now,
    );

    expect(data.cashBalance, 70000);
    expect(data.summary.income, 100000);
    expect(data.summary.expense, 50000);
    expect(data.summary.net, 50000);
    expect(data.summary.isProfit, isTrue);
    expect(data.chartPoints, hasLength(6));
    expect(data.chartPoints.last.bucketStart, DateTime(2026, 10));
    expect(data.chartPoints.last.income, 100000);
    expect(data.chartPoints.last.expense, 50000);
    expect(data.recentTransactions, hasLength(4));
    expect(data.recentTransactions.first.id, 'income-today');
  });

  test('filter harian hanya menghitung transaksi hari ini', () {
    final data = DashboardCalculator.build(
      transactions: transactions,
      period: DashboardPeriod.daily,
      now: now,
    );

    expect(data.summary.income, 100000);
    expect(data.summary.expense, 0);
    expect(data.summary.net, 100000);
    expect(data.chartPoints, hasLength(7));
    expect(data.chartPoints.last.bucketStart, DateTime(2026, 10, 31));
    expect(data.chartPoints.last.income, 100000);
  });

  test('filter mingguan memakai awal minggu Senin', () {
    final data = DashboardCalculator.build(
      transactions: transactions,
      period: DashboardPeriod.weekly,
      now: now,
    );

    expect(data.summary.income, 100000);
    expect(data.summary.expense, 40000);
    expect(data.summary.net, 60000);
    expect(data.chartPoints, hasLength(6));
    expect(data.chartPoints.last.bucketStart, DateTime(2026, 10, 26));
    expect(data.chartPoints.last.income, 100000);
    expect(data.chartPoints.last.expense, 40000);
  });

  test('transaksi terhapus tidak masuk perhitungan', () {
    final data = DashboardCalculator.build(
      transactions: transactions,
      period: DashboardPeriod.monthly,
      now: now,
    );

    expect(
      data.recentTransactions.any((transaction) => transaction.id == 'deleted'),
      isFalse,
    );
  });

  test('agregasi tetap akurat pada dataset transaksi besar', () {
    final largeDataset = List.generate(20000, (index) {
      final type =
          index.isEven ? TransactionType.income : TransactionType.expense;
      return _transaction(
        id: 'bulk-$index',
        type: type,
        amount: index + 1,
        date: DateTime(2026, 10, 1).add(Duration(days: index % 31)),
      );
    });

    final data = DashboardCalculator.build(
      transactions: largeDataset,
      period: DashboardPeriod.monthly,
      now: now,
    );

    expect(data.cashBalance, -10000);
    expect(data.summary.income, 100000000);
    expect(data.summary.expense, 100010000);
    expect(
      data.chartPoints.fold<int>(0, (total, point) => total + point.income),
      100000000,
    );
    expect(
      data.chartPoints.fold<int>(0, (total, point) => total + point.expense),
      100010000,
    );
  });
}

MoneyTransaction _transaction({
  required String id,
  required TransactionType type,
  required int amount,
  required DateTime date,
  DateTime? deletedAt,
}) {
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
    deletedAt: deletedAt,
  );
}
