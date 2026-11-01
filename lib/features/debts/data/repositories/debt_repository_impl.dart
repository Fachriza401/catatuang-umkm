import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_draft.dart';
import '../../domain/entities/debt_payment.dart';
import '../../domain/entities/debt_type.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/services/debt_calculator.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._database, this._supabaseService, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  static const _remoteTable = 'debts';
  static const _paymentTable = 'debt_payments';

  final AppDatabase _database;
  final SupabaseService _supabaseService;
  final Uuid _uuid;
  bool _isSyncing = false;

  @override
  Stream<List<Debt>> watchAll({required String userId}) {
    return _database
        .watchDebts(userId)
        .map((entries) => entries.map(_debtFromEntry).toList(growable: false));
  }

  @override
  Future<Debt> create(DebtDraft draft) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final debt = Debt(
      id: id,
      userId: draft.userId,
      type: draft.type,
      contactName: draft.contactName.trim(),
      phone: draft.phone.trim(),
      amount: draft.amount,
      paidAmount: 0,
      transactionDate: draft.transactionDate,
      dueDate: draft.dueDate,
      note: draft.note.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _database.insertDebt(_debtCompanion(debt, syncStatus: 'pending'));
    await sync(draft.userId);
    return debt;
  }

  @override
  Future<List<DebtPayment>> getPayments(String debtId) async {
    final entries = await _database.getDebtPayments(debtId);
    return entries.map(_paymentFromEntry).toList(growable: false);
  }

  @override
  Future<DebtPayment> registerPayment({
    required Debt debt,
    required int amount,
    required DateTime paymentDate,
    required String note,
  }) async {
    try {
      DebtCalculator.applyPayment(
        amount: debt.amount,
        paidAmount: debt.paidAmount,
        paymentAmount: amount,
      );
    } on ArgumentError catch (error) {
      throw ValidationFailure(
        error.message?.toString() ?? 'Pembayaran tidak valid.',
      );
    }

    final paymentId = _uuid.v4();
    final ledgerId = _uuid.v4();
    final now = DateTime.now();
    final isIncome = debt.type == DebtType.receivable;
    final payment = DebtPayment(
      id: paymentId,
      debtId: debt.id,
      userId: debt.userId,
      amount: amount,
      paymentDate: paymentDate,
      note: note.trim(),
      ledgerTransactionId: ledgerId,
      createdAt: now,
    );
    try {
      await _database.recordDebtPayment(
        payment: DebtPaymentEntriesCompanion.insert(
          id: payment.id,
          debtId: payment.debtId,
          userId: payment.userId,
          amount: payment.amount,
          paymentDate: payment.paymentDate,
          note: Value(payment.note),
          ledgerTransactionId: payment.ledgerTransactionId,
          syncStatus: const Value('pending'),
          createdAt: payment.createdAt,
        ),
        ledgerTransactionId: ledgerId,
        ledgerTransaction: TransactionEntriesCompanion.insert(
          id: ledgerId,
          userId: debt.userId,
          type: isIncome
              ? TransactionType.income.storageValue
              : TransactionType.expense.storageValue,
          amount: amount,
          categoryId: isIncome ? 'other_income' : 'other_expense',
          paymentMethodId: 'cash',
          transactionDate: paymentDate,
          description: Value(_ledgerDescription(debt, payment.note)),
          syncStatus: const Value('payment_pending'),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } on StateError catch (error) {
      throw ValidationFailure(error.message.toString());
    }

    await sync(debt.userId);
    return payment;
  }

  @override
  Future<void> sync(String userId) async {
    if (_isSyncing) return;
    final client = _supabaseService.client;
    if (!_supabaseService.isConfigured ||
        client == null ||
        client.auth.currentUser == null) {
      return;
    }

    _isSyncing = true;
    try {
      await _syncPending(client, userId);
      await _pullRemote(client, userId);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPending(SupabaseClient client, String userId) async {
    for (final entry in await _database.getPendingDebts(userId)) {
      try {
        await client.from(_remoteTable).upsert(
              _debtToRemote(entry),
              onConflict: 'id',
              ignoreDuplicates: true,
            );
        await _database.updateDebtSyncStatus(entry.id, 'synced');
      } catch (_) {
        await _database.updateDebtSyncStatus(entry.id, 'failed');
      }
    }

    for (final payment in await _database.getPendingDebtPayments(userId)) {
      final debt = await _database.getDebt(payment.debtId);
      if (debt == null) {
        await _database.updatePaymentSyncStatus(payment.id, 'failed');
        continue;
      }
      try {
        await client.rpc(
          'record_debt_payment',
          params: {
            'p_payment_id': payment.id,
            'p_debt_id': payment.debtId,
            'p_amount': payment.amount,
            'p_payment_date': payment.paymentDate.toUtc().toIso8601String(),
            'p_note': payment.note,
            'p_ledger_transaction_id': payment.ledgerTransactionId,
            'p_ledger_description': _ledgerDescription(
              _debtFromEntry(debt),
              payment.note,
            ),
          },
        );
        await _database.updatePaymentSyncStatus(payment.id, 'synced');
        await _database.markTransactionSynced(
          id: payment.ledgerTransactionId,
          idempotencyKey: payment.ledgerTransactionId,
        );
      } catch (_) {
        await _database.updatePaymentSyncStatus(payment.id, 'failed');
      }
    }
  }

  Future<void> _pullRemote(SupabaseClient client, String userId) async {
    final rows = await client
        .from(_remoteTable)
        .select()
        .eq('user_id', userId)
        .order('due_date');
    final localDebts = await _database.getDebts(userId);
    final localById = {for (final debt in localDebts) debt.id: debt};
    for (final row in rows) {
      final remote = row;
      final local = localById[remote['id'] as String];
      if (local != null &&
          (local.syncStatus == 'pending' || local.syncStatus == 'failed')) {
        continue;
      }
      final debt = _debtFromRemote(remote);
      await _database.upsertDebt(_debtCompanion(debt, syncStatus: 'synced'));
      final payments = await client
          .from(_paymentTable)
          .select()
          .eq('debt_id', debt.id)
          .order('payment_date');
      for (final payment in payments) {
        await _pullPayment(client, userId, debt, payment);
      }
    }
  }

  Future<void> _pullPayment(
    SupabaseClient client,
    String userId,
    Debt debt,
    Map<String, dynamic> row,
  ) async {
    final paymentId = row['id'] as String;
    final ledgerId = row['ledger_transaction_id'] as String;
    final date = DateTime.parse(row['payment_date'] as String).toLocal();
    final amount = row['amount'] as int;
    await _database.into(_database.debtPaymentEntries).insertOnConflictUpdate(
          DebtPaymentEntriesCompanion.insert(
            id: paymentId,
            debtId: debt.id,
            userId: userId,
            amount: amount,
            paymentDate: date,
            note: Value(row['note'] as String? ?? ''),
            ledgerTransactionId: ledgerId,
            syncStatus: const Value('synced'),
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          ),
        );
    final isIncome = debt.type == DebtType.receivable;
    await _database.upsertTransaction(
      TransactionEntriesCompanion.insert(
        id: ledgerId,
        userId: userId,
        type: isIncome
            ? TransactionType.income.storageValue
            : TransactionType.expense.storageValue,
        amount: amount,
        categoryId: isIncome ? 'other_income' : 'other_expense',
        paymentMethodId: 'cash',
        transactionDate: date,
        description: Value(
          _ledgerDescription(debt, row['note'] as String? ?? ''),
        ),
        syncStatus: const Value('synced'),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(row['created_at'] as String).toLocal(),
      ),
    );
  }

  Debt _debtFromEntry(DebtEntry entry) => Debt(
        id: entry.id,
        userId: entry.userId,
        type: DebtType.fromStorage(entry.type),
        contactName: entry.contactName,
        phone: entry.phone,
        amount: entry.amount,
        paidAmount: entry.paidAmount,
        transactionDate: entry.transactionDate,
        dueDate: entry.dueDate,
        note: entry.note,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        syncStatus: entry.syncStatus,
      );

  Debt _debtFromRemote(Map<String, dynamic> row) => Debt(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        type: DebtType.fromStorage(row['type'] as String),
        contactName: row['contact_name'] as String,
        phone: row['phone'] as String? ?? '',
        amount: row['amount'] as int,
        paidAmount: row['paid_amount'] as int,
        transactionDate: DateTime.parse(
          row['transaction_date'] as String,
        ).toLocal(),
        dueDate: DateTime.parse(row['due_date'] as String).toLocal(),
        note: row['note'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
        syncStatus: 'synced',
      );

  DebtPayment _paymentFromEntry(DebtPaymentEntry entry) => DebtPayment(
        id: entry.id,
        debtId: entry.debtId,
        userId: entry.userId,
        amount: entry.amount,
        paymentDate: entry.paymentDate,
        note: entry.note,
        ledgerTransactionId: entry.ledgerTransactionId,
        createdAt: entry.createdAt,
        syncStatus: entry.syncStatus,
      );

  DebtEntriesCompanion _debtCompanion(
    Debt debt, {
    required String syncStatus,
  }) =>
      DebtEntriesCompanion.insert(
        id: debt.id,
        userId: debt.userId,
        type: debt.type.storageValue,
        contactName: debt.contactName,
        phone: Value(debt.phone),
        amount: debt.amount,
        paidAmount: Value(debt.paidAmount),
        transactionDate: debt.transactionDate,
        dueDate: debt.dueDate,
        note: Value(debt.note),
        syncStatus: Value(syncStatus),
        createdAt: debt.createdAt,
        updatedAt: debt.updatedAt,
      );

  Map<String, dynamic> _debtToRemote(DebtEntry debt) => {
        'id': debt.id,
        'user_id': debt.userId,
        'type': debt.type,
        'contact_name': debt.contactName,
        'phone': debt.phone,
        'amount': debt.amount,
        'paid_amount': 0,
        'transaction_date': debt.transactionDate.toUtc().toIso8601String(),
        'due_date': debt.dueDate.toUtc().toIso8601String(),
        'note': debt.note,
        'created_at': debt.createdAt.toUtc().toIso8601String(),
        'updated_at': debt.updatedAt.toUtc().toIso8601String(),
      };

  String _ledgerDescription(Debt debt, String paymentNote) {
    final direction = debt.type == DebtType.receivable
        ? 'Pembayaran piutang'
        : 'Pembayaran utang';
    final note = paymentNote.isEmpty ? '' : ' - $paymentNote';
    return '$direction ${debt.contactName}$note';
  }
}
