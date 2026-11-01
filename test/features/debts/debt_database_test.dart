import 'package:catat_uang/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _transactionDate = DateTime(2026, 10, 31);

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('pembayaran yang melebihi sisa tagihan tidak mengubah data', () async {
    await _insertDebt(database);

    await expectLater(
      database.recordDebtPayment(
        payment: _payment('payment-1', 'ledger-1', amount: 501),
        ledgerTransactionId: 'ledger-1',
        ledgerTransaction: _ledgerTransaction('ledger-1', amount: 501),
      ),
      throwsA(isA<StateError>()),
    );

    final debt = await database.getDebt('debt-1');
    expect(debt?.paidAmount, 0);
    expect(await database.getDebtPayments('debt-1'), isEmpty);
    expect(await database.getTransactions('user-1'), isEmpty);
  });

  test(
    'pembayaran berhasil memperbarui sisa dan transaksi kas secara atomik',
    () async {
      await _insertDebt(database);

      await database.recordDebtPayment(
        payment: _payment('payment-1', 'ledger-1', amount: 200),
        ledgerTransactionId: 'ledger-1',
        ledgerTransaction: _ledgerTransaction('ledger-1', amount: 200),
      );

      final debt = await database.getDebt('debt-1');
      final payments = await database.getDebtPayments('debt-1');
      final transactions = await database.getTransactions('user-1');
      expect(debt?.paidAmount, 200);
      expect(payments, hasLength(1));
      expect(transactions, hasLength(1));
      expect(transactions.single.amount, 200);
    },
  );

  test(
    'ID pembayaran yang sama menghasilkan satu riwayat dan transaksi kas',
    () async {
      await _insertDebt(database);

      final first = await database.recordDebtPayment(
        payment: _payment('payment-1', 'ledger-1', amount: 200),
        ledgerTransactionId: 'ledger-1',
        ledgerTransaction: _ledgerTransaction('ledger-1', amount: 200),
      );
      final retry = await database.recordDebtPayment(
        payment: _payment('payment-1', 'ledger-1', amount: 200),
        ledgerTransactionId: 'ledger-1',
        ledgerTransaction: _ledgerTransaction('ledger-1', amount: 200),
      );

      expect(retry.id, first.id);
      expect(await database.getDebtPayments('debt-1'), hasLength(1));
      expect(await database.getTransactions('user-1'), hasLength(1));
      expect((await database.getDebt('debt-1'))?.paidAmount, 200);
    },
  );
}

Future<void> _insertDebt(AppDatabase database) {
  return database.insertDebt(
    DebtEntriesCompanion.insert(
      id: 'debt-1',
      userId: 'user-1',
      type: 'receivable',
      contactName: 'Pelanggan',
      amount: 500,
      transactionDate: _transactionDate,
      dueDate: _transactionDate.add(const Duration(days: 30)),
      createdAt: _transactionDate,
      updatedAt: _transactionDate,
    ),
  );
}

DebtPaymentEntriesCompanion _payment(
  String id,
  String ledgerId, {
  required int amount,
}) {
  return DebtPaymentEntriesCompanion.insert(
    id: id,
    debtId: 'debt-1',
    userId: 'user-1',
    amount: amount,
    paymentDate: _transactionDate,
    ledgerTransactionId: ledgerId,
    createdAt: _transactionDate,
  );
}

TransactionEntriesCompanion _ledgerTransaction(
  String id, {
  required int amount,
}) {
  return TransactionEntriesCompanion.insert(
    id: id,
    userId: 'user-1',
    type: 'income',
    amount: amount,
    categoryId: 'other_income',
    paymentMethodId: 'cash',
    transactionDate: _transactionDate,
    createdAt: _transactionDate,
    updatedAt: _transactionDate,
  );
}
