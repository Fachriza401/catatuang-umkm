import 'transaction_type.dart';

class TransactionDraft {
  const TransactionDraft({
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.paymentMethodId,
    required this.transactionDate,
    this.description = '',
    this.attachmentPath,
  });

  final String userId;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final String paymentMethodId;
  final DateTime transactionDate;
  final String description;
  final String? attachmentPath;
}
