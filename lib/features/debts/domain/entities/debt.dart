import 'debt_status.dart';
import 'debt_type.dart';
import '../services/debt_calculator.dart';

class Debt {
  const Debt({
    required this.id,
    required this.userId,
    required this.type,
    required this.contactName,
    required this.phone,
    required this.amount,
    required this.paidAmount,
    required this.transactionDate,
    required this.dueDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  final String id;
  final String userId;
  final DebtType type;
  final String contactName;
  final String phone;
  final int amount;
  final int paidAmount;
  final DateTime transactionDate;
  final DateTime dueDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  int get remainingAmount => amount - paidAmount;
  DebtStatus get status =>
      DebtCalculator.status(amount: amount, paidAmount: paidAmount);
}
