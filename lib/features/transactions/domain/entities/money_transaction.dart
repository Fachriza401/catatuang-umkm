import 'transaction_sync_status.dart';
import 'transaction_type.dart';

class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.paymentMethodId,
    required this.transactionDate,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.attachmentPath,
    this.attachmentUrl,
    this.syncStatus = TransactionSyncStatus.pending,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final String paymentMethodId;
  final DateTime transactionDate;
  final String description;
  final String? attachmentPath;
  final String? attachmentUrl;
  final TransactionSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;

  bool get isIncome => type.isIncome;
  bool get isExpense => type.isExpense;
  bool get isDeleted => deletedAt != null;
  bool get hasAttachment =>
      (attachmentPath != null && attachmentPath!.isNotEmpty) ||
      (attachmentUrl != null && attachmentUrl!.isNotEmpty);

  int get signedAmount => isIncome ? amount : -amount;

  MoneyTransaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    int? amount,
    String? categoryId,
    String? paymentMethodId,
    DateTime? transactionDate,
    String? description,
    String? attachmentPath,
    bool clearAttachmentPath = false,
    String? attachmentUrl,
    bool clearAttachmentUrl = false,
    TransactionSyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      attachmentPath: clearAttachmentPath
          ? null
          : attachmentPath ?? this.attachmentPath,
      attachmentUrl: clearAttachmentUrl
          ? null
          : attachmentUrl ?? this.attachmentUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
