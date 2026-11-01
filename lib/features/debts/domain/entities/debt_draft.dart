import 'debt_type.dart';

class DebtDraft {
  const DebtDraft({
    required this.userId,
    required this.type,
    required this.contactName,
    required this.phone,
    required this.amount,
    required this.transactionDate,
    required this.dueDate,
    required this.note,
  });

  final String userId;
  final DebtType type;
  final String contactName;
  final String phone;
  final int amount;
  final DateTime transactionDate;
  final DateTime dueDate;
  final String note;
}
