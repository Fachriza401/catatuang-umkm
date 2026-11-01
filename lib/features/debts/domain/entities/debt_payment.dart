class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.userId,
    required this.amount,
    required this.paymentDate,
    required this.note,
    required this.ledgerTransactionId,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  final String id;
  final String debtId;
  final String userId;
  final int amount;
  final DateTime paymentDate;
  final String note;
  final String ledgerTransactionId;
  final DateTime createdAt;
  final String syncStatus;
}
