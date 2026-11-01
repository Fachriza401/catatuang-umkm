import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_sync_status.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../mappers/transaction_mapper.dart';
import '../services/transaction_sync_service.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._database, this._syncService, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final TransactionSyncService _syncService;
  final Uuid _uuid;

  @override
  Stream<List<MoneyTransaction>> watchAll({required String userId}) {
    return _database.watchTransactions(userId: userId).map(_mapEntries);
  }

  @override
  Stream<List<MoneyTransaction>> watchRecent({
    required String userId,
    int limit = 5,
  }) {
    return _database
        .watchRecentTransactions(userId: userId, limit: limit)
        .map(_mapEntries);
  }

  @override
  Future<List<MoneyTransaction>> getAll(String userId) async {
    final entries = await _database.getTransactions(userId);
    return _mapEntries(entries);
  }

  @override
  Future<MoneyTransaction?> getById(String id) async {
    final entry = await _database.getTransaction(id);
    return entry == null ? null : TransactionMapper.fromEntry(entry);
  }

  @override
  Future<MoneyTransaction> create(TransactionDraft draft) async {
    final now = DateTime.now();
    final transaction = MoneyTransaction(
      id: _uuid.v4(),
      userId: draft.userId,
      type: draft.type,
      amount: draft.amount,
      categoryId: draft.categoryId,
      paymentMethodId: draft.paymentMethodId,
      transactionDate: draft.transactionDate,
      description: draft.description.trim(),
      attachmentPath: draft.attachmentPath,
      createdAt: now,
      updatedAt: now,
      syncStatus: TransactionSyncStatus.pending,
    );
    await _database.saveTransactionWithOutbox(
      transaction: TransactionMapper.toCompanion(transaction),
      outbox: TransactionOutboxEntriesCompanion.insert(
        id: transaction.id,
        userId: transaction.userId,
        transactionId: transaction.id,
        operation: 'create',
        createdAt: now,
        updatedAt: now,
      ),
    );
    _syncService.requestSync(transaction.userId);
    return transaction;
  }

  @override
  Future<MoneyTransaction> update(MoneyTransaction transaction) async {
    final existing = await _database.getTransactionIncludingDeleted(
      transaction.id,
    );
    if (existing == null) {
      throw StateError('Transaksi tidak ditemukan di penyimpanan lokal.');
    }
    final existingOutbox = await _database.getOutboxEntry(transaction.id);
    final updated = MoneyTransaction(
      id: transaction.id,
      userId: transaction.userId,
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      paymentMethodId: transaction.paymentMethodId,
      transactionDate: transaction.transactionDate,
      description: transaction.description.trim(),
      attachmentPath: transaction.attachmentPath,
      attachmentUrl: transaction.attachmentUrl,
      createdAt: transaction.createdAt,
      updatedAt: DateTime.now(),
      serverUpdatedAt: existing.serverUpdatedAt,
      syncStatus: TransactionSyncStatus.pending,
    );
    final now = DateTime.now();
    await _database.saveTransactionWithOutbox(
      transaction: TransactionMapper.toCompanion(updated),
      outbox: TransactionOutboxEntriesCompanion.insert(
        id: _uuid.v4(),
        userId: transaction.userId,
        transactionId: transaction.id,
        operation: existingOutbox?.operation == 'create' ||
                existing.serverUpdatedAt == null
            ? 'create'
            : 'update',
        status: const Value('pending'),
        attemptCount: Value(existingOutbox?.attemptCount ?? 0),
        baseServerUpdatedAt: Value(existing.serverUpdatedAt),
        createdAt: existingOutbox?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _syncService.requestSync(updated.userId);
    return updated;
  }

  @override
  Future<void> delete({required String id, required String userId}) async {
    await _database.softDeleteTransaction(
      id: id,
      userId: userId,
      outboxId: _uuid.v4(),
      updatedAt: DateTime.now(),
    );
    _syncService.requestSync(userId);
  }

  @override
  Future<void> syncPending(String userId) {
    return _syncService.syncPending(userId);
  }

  @override
  Future<void> resolveConflictKeepLocal(String transactionId) async {
    final outbox = await _database.getOutboxEntry(transactionId);
    final remote = outbox?.remoteSnapshot;
    if (outbox == null || remote == null) {
      throw StateError('Data konflik tidak tersedia.');
    }
    final decoded = jsonDecode(remote);
    final row = decoded == null
        ? null
        : Map<String, dynamic>.from((decoded as Map).cast<String, dynamic>());
    final serverUpdatedAt = row == null
        ? null
        : DateTime.parse(row['updated_at'] as String).toLocal();
    await _database.resolveOutboxKeepLocal(
      transactionId: transactionId,
      idempotencyKey: _uuid.v4(),
      operation: row == null
          ? 'create'
          : outbox.operation == 'create'
              ? 'update'
              : outbox.operation,
      remoteUpdatedAt: serverUpdatedAt,
    );
    _syncService.requestSync(outbox.userId);
  }

  @override
  Future<void> resolveConflictUseRemote(String transactionId) async {
    final outbox = await _database.getOutboxEntry(transactionId);
    final snapshot = outbox?.remoteSnapshot;
    if (outbox == null || snapshot == null) {
      throw StateError('Data konflik tidak tersedia.');
    }
    final decoded = jsonDecode(snapshot);
    final remote = decoded == null
        ? null
        : Map<String, dynamic>.from((decoded as Map).cast<String, dynamic>());
    final remoteId = remote?['id'] as String?;
    await _database.resolveOutboxUseRemote(
      transactionId: transactionId,
      remoteTransaction: remoteId == null
          ? const TransactionEntriesCompanion()
          : TransactionMapper.fromRemote(remote!),
    );
  }

  List<MoneyTransaction> _mapEntries(List<TransactionEntry> entries) {
    return entries.map(TransactionMapper.fromEntry).toList(growable: false);
  }
}
