import 'dart:io';

import 'package:catat_uang/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final _now = DateTime(2026, 11, 1, 12);

void main() {
  test('transaksi dan outbox tersimpan atomik', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.customStatement('''
      CREATE TRIGGER reject_outbox_insert
      BEFORE INSERT ON transaction_outbox_entries
      BEGIN
        SELECT RAISE(ABORT, 'outbox unavailable');
      END
    ''');

    await expectLater(
      database.saveTransactionWithOutbox(
        transaction: _transaction('tx-rollback'),
        outbox: _outbox('key-rollback', 'tx-rollback'),
      ),
      throwsA(anything),
    );

    expect(
      await database.getTransactionIncludingDeleted('tx-rollback'),
      isNull,
    );
    expect(await database.getOutboxEntry('tx-rollback'), isNull);
  });

  test(
    'data offline tetap ada dan eligible setelah gagal dengan backoff',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.saveTransactionWithOutbox(
        transaction: _transaction('tx-offline'),
        outbox: _outbox('key-offline', 'tx-offline'),
      );

      final retryAt = _now.add(const Duration(seconds: 4));
      await database.markOutboxFailed(
        transactionId: 'tx-offline',
        idempotencyKey: 'key-offline',
        error: 'Supabase tidak dapat dijangkau',
        nextAttemptAt: retryAt,
      );

      expect(
        await database.getTransactionIncludingDeleted('tx-offline'),
        isNotNull,
      );
      expect(
        await database.getDueOutboxEntries('user-1', now: retryAt),
        hasLength(1),
      );
      expect(
        await database.getDueOutboxEntries(
          'user-1',
          now: retryAt.subtract(const Duration(milliseconds: 1)),
        ),
        isEmpty,
      );
    },
  );

  test(
    'restart ketika syncing memulihkan outbox tanpa kehilangan transaksi',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'catat-uang-sync-',
      );
      final file = File(p.join(directory.path, 'offline.sqlite'));
      var database = AppDatabase.forTesting(NativeDatabase(file));

      try {
        await database.saveTransactionWithOutbox(
          transaction: _transaction('tx-interrupted'),
          outbox: _outbox('key-interrupted', 'tx-interrupted'),
        );
        expect(
          await database.markOutboxSyncing(
            transactionId: 'tx-interrupted',
            idempotencyKey: 'key-interrupted',
          ),
          isTrue,
        );
        await database.close();

        database = AppDatabase.forTesting(NativeDatabase(file));
        final beforeRecovery = await database.getOutboxEntry('tx-interrupted');
        expect(beforeRecovery?.status, 'syncing');
        expect(beforeRecovery?.id, 'key-interrupted');
        expect(
          await database.getTransactionIncludingDeleted('tx-interrupted'),
          isNotNull,
        );

        await database.recoverInterruptedSyncs();

        expect(
          (await database.getOutboxEntry('tx-interrupted'))?.status,
          'pending',
        );
        expect(
          (await database.getTransactionIncludingDeleted(
            'tx-interrupted',
          ))
              ?.syncStatus,
          'pending',
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

TransactionEntriesCompanion _transaction(String id) {
  return TransactionEntriesCompanion.insert(
    id: id,
    userId: 'user-1',
    type: 'expense',
    amount: 12500,
    categoryId: 'ingredients',
    paymentMethodId: 'cash',
    transactionDate: _now,
    description: const Value('Belanja bahan'),
    createdAt: _now,
    updatedAt: _now,
  );
}

TransactionOutboxEntriesCompanion _outbox(String key, String transactionId) {
  return TransactionOutboxEntriesCompanion.insert(
    id: key,
    userId: 'user-1',
    transactionId: transactionId,
    operation: 'create',
    createdAt: _now,
    updatedAt: _now,
  );
}
