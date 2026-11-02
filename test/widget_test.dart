import 'dart:async';

import 'package:catat_uang/core/theme/app_theme.dart';
import 'package:catat_uang/core/utils/currency_formatter.dart';
import 'package:catat_uang/features/auth/domain/entities/app_user.dart';
import 'package:catat_uang/features/auth/presentation/providers/auth_providers.dart';
import 'package:catat_uang/features/business_profile/domain/entities/business_access.dart';
import 'package:catat_uang/features/business_profile/presentation/providers/business_access_provider.dart';
import 'package:catat_uang/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:catat_uang/features/debts/domain/entities/debt.dart';
import 'package:catat_uang/features/debts/presentation/providers/debt_reminder_providers.dart';
import 'package:catat_uang/features/transactions/domain/entities/money_transaction.dart';
import 'package:catat_uang/features/transactions/domain/entities/transaction_draft.dart';
import 'package:catat_uang/features/transactions/domain/entities/transaction_type.dart';
import 'package:catat_uang/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:catat_uang/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard menampilkan ringkasan dan reaktif terhadap data', (
    tester,
  ) async {
    final now = DateTime.now();
    final income = _transaction(
      id: 'income',
      type: TransactionType.income,
      amount: 500000,
      date: now,
    );
    final expense = _transaction(
      id: 'expense',
      type: TransactionType.expense,
      amount: 150000,
      date: now,
    );
    final yesterdayExpense = _transaction(
      id: 'yesterday-expense',
      type: TransactionType.expense,
      amount: 50000,
      date: now.subtract(const Duration(days: 1)),
    );
    final repository = _FakeTransactionRepository([
      income,
      expense,
      yesterdayExpense,
    ]);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAuthUserProvider.overrideWithValue(
            const AppUser(
              id: 'user-1',
              email: 'budi@usaha.com',
              fullName: 'Budi Santoso',
              isEmailVerified: true,
            ),
          ),
          businessAccessProvider.overrideWith(
            (ref) async => BusinessAccess.ownerFallback('user-1'),
          ),
          transactionRepositoryProvider.overrideWithValue(repository),
          dueDebtsProvider.overrideWith(
            (ref, businessId) => const AsyncValue<List<Debt>>.data(<Debt>[]),
          ),
          dueSoonDebtsProvider.overrideWith(
            (ref, businessId) => const AsyncValue<List<Debt>>.data(<Debt>[]),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saldo Kas'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Laba bersih'), findsOneWidget);
    expect(find.text('Transaksi Terakhir'), findsOneWidget);
    expect(find.text('Tambah Transaksi'), findsWidgets);
    expect(find.text(CurrencyFormatter.format(300000)), findsWidgets);

    await tester.tap(find.text('Harian'));
    await tester.pumpAndSettle();
    expect(find.text(CurrencyFormatter.format(350000)), findsWidgets);

    final newIncome = _transaction(
      id: 'new-income',
      type: TransactionType.income,
      amount: 100000,
      date: now,
    );
    repository.emit([income, expense, yesterdayExpense, newIncome]);
    await tester.pumpAndSettle();

    expect(find.text(CurrencyFormatter.format(450000)), findsWidgets);
    expect(find.text(CurrencyFormatter.format(400000)), findsWidgets);
  });
}

MoneyTransaction _transaction({
  required String id,
  required TransactionType type,
  required int amount,
  required DateTime date,
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
  );
}

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(List<MoneyTransaction> initial)
    : _transactions = List.of(initial);

  final _controller = StreamController<List<MoneyTransaction>>.broadcast();
  List<MoneyTransaction> _transactions;

  void emit(List<MoneyTransaction> transactions) {
    _transactions = List.of(transactions);
    _controller.add(List.unmodifiable(_transactions));
  }

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<MoneyTransaction>> watchAll({required String userId}) async* {
    yield List.unmodifiable(_transactions);
    yield* _controller.stream;
  }

  @override
  Stream<List<MoneyTransaction>> watchRecent({
    required String userId,
    int limit = 5,
  }) async* {
    yield _transactions.take(limit).toList(growable: false);
  }

  @override
  Future<List<MoneyTransaction>> getAll(String userId) async {
    return List.unmodifiable(_transactions);
  }

  @override
  Future<MoneyTransaction?> getById(String id) async {
    for (final transaction in _transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<MoneyTransaction> create(TransactionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<MoneyTransaction> update(MoneyTransaction transaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete({required String id, required String userId}) async {}

  @override
  Future<void> syncPending(String userId) async {}

  @override
  Future<void> resolveConflictKeepLocal(String transactionId) async {}

  @override
  Future<void> resolveConflictUseRemote(String transactionId) async {}
}
