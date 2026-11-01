import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/transaction_sync_status.dart';
import '../../domain/entities/transaction_type.dart';

abstract final class TransactionMapper {
  static MoneyTransaction fromEntry(TransactionEntry entry) {
    return MoneyTransaction(
      id: entry.id,
      userId: entry.userId,
      type: TransactionType.fromStorage(entry.type),
      amount: entry.amount,
      categoryId: entry.categoryId,
      paymentMethodId: entry.paymentMethodId,
      transactionDate: entry.transactionDate,
      description: entry.description,
      attachmentPath: entry.attachmentPath,
      attachmentUrl: entry.attachmentUrl,
      syncStatus: TransactionSyncStatus.fromStorage(entry.syncStatus),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      serverUpdatedAt: entry.serverUpdatedAt,
      deletedAt: entry.deletedAt,
    );
  }

  static TransactionEntriesCompanion toCompanion(MoneyTransaction transaction) {
    return TransactionEntriesCompanion(
      id: Value(transaction.id),
      userId: Value(transaction.userId),
      type: Value(transaction.type.storageValue),
      amount: Value(transaction.amount),
      categoryId: Value(transaction.categoryId),
      paymentMethodId: Value(transaction.paymentMethodId),
      transactionDate: Value(transaction.transactionDate),
      description: Value(transaction.description),
      attachmentPath: Value(transaction.attachmentPath),
      attachmentUrl: Value(transaction.attachmentUrl),
      syncStatus: Value(transaction.syncStatus.storageValue),
      createdAt: Value(transaction.createdAt),
      updatedAt: Value(transaction.updatedAt),
      serverUpdatedAt: Value(transaction.serverUpdatedAt),
      deletedAt: Value(transaction.deletedAt),
    );
  }

  static Map<String, dynamic> toRemote(
    TransactionEntry entry, {
    String? attachmentUrl,
  }) {
    return {
      'id': entry.id,
      'user_id': entry.userId,
      'type': entry.type,
      'amount': entry.amount,
      'category_id': entry.categoryId,
      'payment_method_id': entry.paymentMethodId,
      'transaction_date': entry.transactionDate.toUtc().toIso8601String(),
      'description': entry.description,
      'attachment_url': attachmentUrl ?? entry.attachmentUrl,
      'created_at': entry.createdAt.toUtc().toIso8601String(),
      'updated_at': entry.updatedAt.toUtc().toIso8601String(),
      'deleted_at': entry.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static TransactionEntriesCompanion fromRemote(
    Map<String, dynamic> row, {
    String? attachmentPath,
  }) {
    final serverUpdatedAt = DateTime.parse(
      row['updated_at'] as String,
    ).toLocal();
    return TransactionEntriesCompanion(
      id: Value(row['id'] as String),
      userId: Value(row['user_id'] as String),
      type: Value(row['type'] as String),
      amount: Value(row['amount'] as int),
      categoryId: Value(row['category_id'] as String),
      paymentMethodId: Value(row['payment_method_id'] as String),
      transactionDate: Value(
        DateTime.parse(row['transaction_date'] as String).toLocal(),
      ),
      description: Value(row['description'] as String? ?? ''),
      attachmentPath: Value(attachmentPath),
      attachmentUrl: Value(row['attachment_url'] as String?),
      syncStatus: const Value('synced'),
      serverUpdatedAt: Value(serverUpdatedAt),
      createdAt: Value(DateTime.parse(row['created_at'] as String).toLocal()),
      updatedAt: Value(serverUpdatedAt),
      deletedAt: Value(
        row['deleted_at'] == null
            ? null
            : DateTime.parse(row['deleted_at'] as String).toLocal(),
      ),
    );
  }
}
