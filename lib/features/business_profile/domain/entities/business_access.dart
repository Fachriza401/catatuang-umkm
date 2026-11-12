class BusinessAccess {
  const BusinessAccess({
    required this.businessId,
    this.plan = 'free',
    this.subscriptionStatus = 'active',
    this.transactionsUsed = 0,
    this.monthlyTransactionLimit,
    this.attachmentsEnabled = true,
  });

  final String businessId;
  final String plan;
  final String subscriptionStatus;
  final int transactionsUsed;
  final int? monthlyTransactionLimit;
  final bool attachmentsEnabled;

  bool get canManageSettings => true;
  bool get canCreateTransactions => true;
  bool get canEditTransactions => true;
  bool get canDeleteTransactions => true;

  factory BusinessAccess.fromJson(Map<String, dynamic> json) {
    return BusinessAccess(
      businessId: json['business_id'] as String,
      plan: json['plan'] as String? ?? 'free',
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      transactionsUsed: json['transactions_used'] as int? ?? 0,
      monthlyTransactionLimit: null,
      attachmentsEnabled: json['attachments_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'plan': plan,
    'subscription_status': subscriptionStatus,
    'transactions_used': transactionsUsed,
    'monthly_transaction_limit': null,
    'attachments_enabled': attachmentsEnabled,
  };

  factory BusinessAccess.ownerFallback(String userId) {
    return BusinessAccess(
      businessId: userId,
      plan: 'free',
      subscriptionStatus: 'active',
      transactionsUsed: 0,
      monthlyTransactionLimit: null,
      attachmentsEnabled: true,
    );
  }
}
