import 'package:drift/drift.dart';

import 'app_database_platform.dart'
    if (dart.library.html) 'app_database_platform_web.dart'
    if (dart.library.io) 'app_database_platform_native.dart';

part 'app_database.g.dart';

class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class TransactionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text()();
  TextColumn get paymentMethodId => text()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentUrl => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionOutboxEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get transactionId => text().unique()();
  TextColumn get operation => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get remoteSnapshot => text().nullable()();
  DateTimeColumn get baseServerUpdatedAt => dateTime().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DebtEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get contactName => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  IntColumn get amount => integer()();
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DebtPaymentEntries extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(DebtEntries, #id)();
  TextColumn get userId => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get ledgerTransactionId => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AppPreferences,
    TransactionEntries,
    TransactionOutboxEntries,
    DebtEntries,
    DebtPaymentEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(transactionEntries);
          }
          if (from < 3) {
            await migrator.createTable(debtEntries);
            await migrator.createTable(debtPaymentEntries);
          }
          if (from < 4) {
            await migrator.addColumn(
              transactionEntries,
              transactionEntries.serverUpdatedAt,
            );
            await migrator.createTable(transactionOutboxEntries);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> warmUp() async {
    await customSelect('SELECT 1').get();
  }

  Future<String?> readPreference(String preferenceKey) async {
    final query = select(appPreferences)
      ..where((table) => table.key.equals(preferenceKey));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> writePreference(String preferenceKey, String value) async {
    await into(appPreferences).insertOnConflictUpdate(
      AppPreferencesCompanion.insert(
        key: preferenceKey,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removePreference(String preferenceKey) async {
    await (delete(
      appPreferences,
    )..where((table) => table.key.equals(preferenceKey)))
        .go();
  }

  Stream<List<TransactionEntry>> watchTransactions({required String userId}) {
    final query = select(transactionEntries)
      ..where(
        (table) =>
            table.userId.equals(userId) &
            (table.deletedAt.isNull() | table.syncStatus.equals('conflict')),
      )
      ..orderBy([
        (table) => OrderingTerm.desc(table.transactionDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.watch();
  }

  Stream<List<TransactionEntry>> watchRecentTransactions({
    required String userId,
    int limit = 5,
  }) {
    final query = select(transactionEntries)
      ..where(
        (table) =>
            table.userId.equals(userId) &
            (table.deletedAt.isNull() | table.syncStatus.equals('conflict')),
      )
      ..orderBy([
        (table) => OrderingTerm.desc(table.transactionDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ])
      ..limit(limit);
    return query.watch();
  }

  Future<List<TransactionEntry>> getTransactions(String userId) {
    final query = select(transactionEntries)
      ..where(
        (table) =>
            table.userId.equals(userId) &
            (table.deletedAt.isNull() | table.syncStatus.equals('conflict')),
      )
      ..orderBy([
        (table) => OrderingTerm.desc(table.transactionDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.get();
  }

  Future<TransactionEntry?> getTransaction(String id) {
    final query = select(transactionEntries)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<void> upsertTransaction(TransactionEntriesCompanion entry) {
    return into(transactionEntries).insertOnConflictUpdate(entry);
  }

  Future<void> saveTransactionWithOutbox({
    required TransactionEntriesCompanion transaction,
    required TransactionOutboxEntriesCompanion outbox,
  }) async {
    await this.transaction(() async {
      await into(transactionEntries).insertOnConflictUpdate(transaction);
      await into(transactionOutboxEntries).insertOnConflictUpdate(outbox);
    });
  }

  Future<void> softDeleteTransaction({
    required String id,
    required String userId,
    required String outboxId,
    required DateTime updatedAt,
  }) async {
    await transaction(() async {
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(id)))
          .write(
        TransactionEntriesCompanion(
          deletedAt: Value(updatedAt),
          updatedAt: Value(updatedAt),
          syncStatus: const Value('pending'),
        ),
      );
      final existing = await (select(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(id)))
          .getSingleOrNull();
      await into(transactionOutboxEntries).insertOnConflictUpdate(
        TransactionOutboxEntriesCompanion.insert(
          id: outboxId,
          userId: userId,
          transactionId: id,
          operation: existing?.operation == 'create' ? 'create' : 'delete',
          status: const Value('pending'),
          attemptCount: Value(existing?.attemptCount ?? 0),
          baseServerUpdatedAt: Value(existing?.baseServerUpdatedAt),
          createdAt: existing?.createdAt ?? updatedAt,
          updatedAt: updatedAt,
        ),
      );
    });
  }

  Future<List<TransactionOutboxEntry>> getDueOutboxEntries(
    String userId, {
    required DateTime now,
  }) {
    final query = select(transactionOutboxEntries)
      ..where(
        (table) =>
            table.userId.equals(userId) &
            (table.status.equals('pending') | table.status.equals('failed')) &
            (table.nextAttemptAt.isNull() |
                table.nextAttemptAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]);
    return query.get();
  }

  Future<TransactionOutboxEntry?> getOutboxEntry(String transactionId) {
    return (select(transactionOutboxEntries)
          ..where((table) => table.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  Future<TransactionEntry?> getTransactionIncludingDeleted(String id) {
    return (select(
      transactionEntries,
    )..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<bool> markOutboxSyncing({
    required String transactionId,
    required String idempotencyKey,
  }) async {
    return transaction(() async {
      final outbox = await getOutboxEntry(transactionId);
      if (outbox == null || outbox.id != idempotencyKey) return false;
      await (update(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .write(
        TransactionOutboxEntriesCompanion(
          status: const Value('syncing'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(transactionId)))
          .write(
        const TransactionEntriesCompanion(syncStatus: Value('syncing')),
      );
      return true;
    });
  }

  Future<void> markOutboxPending(String transactionId) async {
    await _setOutboxState(transactionId, 'pending');
  }

  Future<void> markOutboxFailed({
    required String transactionId,
    required String idempotencyKey,
    required String error,
    required DateTime nextAttemptAt,
  }) async {
    await transaction(() async {
      final outbox = await getOutboxEntry(transactionId);
      if (outbox == null || outbox.id != idempotencyKey) return;
      await (update(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .write(
        TransactionOutboxEntriesCompanion(
          status: const Value('failed'),
          attemptCount: Value(outbox.attemptCount + 1),
          lastError: Value(error),
          nextAttemptAt: Value(nextAttemptAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(transactionId)))
          .write(
        const TransactionEntriesCompanion(syncStatus: Value('failed')),
      );
    });
  }

  Future<void> markOutboxConflict({
    required String transactionId,
    required String idempotencyKey,
    required String remoteSnapshot,
  }) async {
    await transaction(() async {
      final outbox = await getOutboxEntry(transactionId);
      if (outbox == null || outbox.id != idempotencyKey) return;
      await (update(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .write(
        TransactionOutboxEntriesCompanion(
          status: const Value('conflict'),
          remoteSnapshot: Value(remoteSnapshot),
          lastError: const Value('Data lokal dan server berubah bersamaan.'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(transactionId)))
          .write(
        const TransactionEntriesCompanion(syncStatus: Value('conflict')),
      );
    });
  }

  Future<void> markTransactionSynced({
    required String id,
    required String idempotencyKey,
    String? attachmentUrl,
    DateTime? serverUpdatedAt,
  }) async {
    await transaction(() async {
      final outbox = await getOutboxEntry(id);
      if (outbox == null || outbox.id != idempotencyKey) return;
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(id)))
          .write(
        TransactionEntriesCompanion(
          syncStatus: const Value('synced'),
          attachmentUrl: attachmentUrl == null
              ? const Value.absent()
              : Value(attachmentUrl),
          serverUpdatedAt: serverUpdatedAt == null
              ? const Value.absent()
              : Value(serverUpdatedAt),
        ),
      );
      await (delete(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(id)))
          .go();
    });
  }

  Future<void> markRemoteTransactionSynced({
    required TransactionEntriesCompanion transaction,
    required DateTime serverUpdatedAt,
  }) async {
    await this.transaction(() async {
      await into(transactionEntries).insertOnConflictUpdate(
        transaction.copyWith(
          syncStatus: const Value('synced'),
          serverUpdatedAt: Value(serverUpdatedAt),
        ),
      );
      await (delete(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transaction.id.value)))
          .go();
    });
  }

  Future<void> resolveOutboxKeepLocal({
    required String transactionId,
    required String idempotencyKey,
    required String operation,
    required DateTime? remoteUpdatedAt,
  }) async {
    await transaction(() async {
      await (update(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .write(
        TransactionOutboxEntriesCompanion(
          id: Value(idempotencyKey),
          operation: Value(operation),
          status: const Value('pending'),
          baseServerUpdatedAt: Value(remoteUpdatedAt),
          remoteSnapshot: const Value(null),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (update(
        transactionEntries,
      )..where((table) => table.id.equals(transactionId)))
          .write(
        TransactionEntriesCompanion(
          syncStatus: const Value('pending'),
          serverUpdatedAt: Value(remoteUpdatedAt),
        ),
      );
    });
  }

  Future<void> resolveOutboxUseRemote({
    required String transactionId,
    required TransactionEntriesCompanion remoteTransaction,
  }) async {
    await transaction(() async {
      if (remoteTransaction.id.present) {
        await into(transactionEntries).insertOnConflictUpdate(
          remoteTransaction.copyWith(syncStatus: const Value('synced')),
        );
      } else {
        await (delete(
          transactionEntries,
        )..where((table) => table.id.equals(transactionId)))
            .go();
      }
      await (delete(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .go();
    });
  }

  Future<void> recoverInterruptedSyncs() async {
    await transaction(() async {
      final syncing = await (select(
        transactionOutboxEntries,
      )..where((table) => table.status.equals('syncing')))
          .get();
      for (final entry in syncing) {
        await _setOutboxState(entry.transactionId, 'pending');
      }
    });
  }

  Future<void> _setOutboxState(String transactionId, String status) async {
    await transaction(() async {
      await (update(
        transactionOutboxEntries,
      )..where((table) => table.transactionId.equals(transactionId)))
          .write(
        TransactionOutboxEntriesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (update(transactionEntries)
            ..where((table) => table.id.equals(transactionId)))
          .write(TransactionEntriesCompanion(syncStatus: Value(status)));
    });
  }

  Stream<List<DebtEntry>> watchDebts(String userId) {
    final query = select(debtEntries)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.dueDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.watch();
  }

  Future<List<DebtEntry>> getDebts(String userId) {
    final query = select(debtEntries)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.dueDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.get();
  }

  Future<DebtEntry?> getDebt(String id) {
    return (select(
      debtEntries,
    )..where((table) => table.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DebtPaymentEntry>> getDebtPayments(String debtId) {
    final query = select(debtPaymentEntries)
      ..where((table) => table.debtId.equals(debtId))
      ..orderBy([(table) => OrderingTerm.desc(table.paymentDate)]);
    return query.get();
  }

  Future<void> insertDebt(DebtEntriesCompanion debt) {
    return into(debtEntries).insert(debt);
  }

  Future<void> upsertDebt(DebtEntriesCompanion debt) {
    return into(debtEntries).insertOnConflictUpdate(debt);
  }

  Future<void> updateDebtSyncStatus(String id, String status) async {
    await (update(debtEntries)..where((table) => table.id.equals(id))).write(
      DebtEntriesCompanion(syncStatus: Value(status)),
    );
  }

  Future<void> updatePaymentSyncStatus(String id, String status) async {
    await (update(debtPaymentEntries)..where((table) => table.id.equals(id)))
        .write(DebtPaymentEntriesCompanion(syncStatus: Value(status)));
  }

  Future<List<DebtEntry>> getPendingDebts(String userId) {
    return (select(debtEntries)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                (table.syncStatus.equals('pending') |
                    table.syncStatus.equals('failed')),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<List<DebtPaymentEntry>> getPendingDebtPayments(String userId) {
    return (select(debtPaymentEntries)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                (table.syncStatus.equals('pending') |
                    table.syncStatus.equals('failed')),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
  }

  Future<DebtPaymentEntry> recordDebtPayment({
    required DebtPaymentEntriesCompanion payment,
    required String ledgerTransactionId,
    required TransactionEntriesCompanion ledgerTransaction,
  }) {
    return transaction(() async {
      final existing = await (select(
        debtPaymentEntries,
      )..where((table) => table.id.equals(payment.id.value)))
          .getSingleOrNull();
      if (existing != null) {
        final requestedNote = payment.note.present ? payment.note.value : '';
        if (existing.debtId != payment.debtId.value ||
            existing.userId != payment.userId.value ||
            existing.amount != payment.amount.value ||
            existing.paymentDate != payment.paymentDate.value ||
            existing.note != requestedNote ||
            existing.ledgerTransactionId != ledgerTransactionId) {
          throw StateError('ID pembayaran sudah digunakan.');
        }
        return existing;
      }

      final debt = await (select(debtEntries)
            ..where((table) => table.id.equals(payment.debtId.value)))
          .getSingleOrNull();
      if (debt == null) throw StateError('Tagihan tidak ditemukan.');
      final remaining = debt.amount - debt.paidAmount;
      final paymentAmount = payment.amount.value;
      if (paymentAmount <= 0 || paymentAmount > remaining) {
        throw StateError('Pembayaran melebihi sisa tagihan.');
      }

      await into(debtPaymentEntries).insert(payment);
      await (update(
        debtEntries,
      )..where((table) => table.id.equals(debt.id)))
          .write(
        DebtEntriesCompanion(
          paidAmount: Value(debt.paidAmount + paymentAmount),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );
      await into(transactionEntries).insert(ledgerTransaction);
      await into(transactionOutboxEntries).insert(
        TransactionOutboxEntriesCompanion.insert(
          id: ledgerTransactionId,
          userId: payment.userId.value,
          transactionId: ledgerTransactionId,
          operation: 'create',
          status: const Value('pending'),
          createdAt: payment.createdAt.value,
          updatedAt: payment.createdAt.value,
        ),
      );
      return (select(
        debtPaymentEntries,
      )..where((table) => table.id.equals(payment.id.value)))
          .getSingle();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async => openAppDatabase());
}
