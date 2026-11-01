class BusinessAccess {
  const BusinessAccess({
    required this.businessId,
    required this.role,
    required this.plan,
    required this.subscriptionStatus,
    required this.membersUsed,
    required this.maxMembers,
    required this.transactionsUsed,
    this.monthlyTransactionLimit,
    required this.attachmentsEnabled,
  });

  final String businessId;
  final String role;
  final String plan;
  final String subscriptionStatus;
  final int membersUsed;
  final int maxMembers;
  final int transactionsUsed;
  final int? monthlyTransactionLimit;
  final bool attachmentsEnabled;

  bool get canManageSettings => role == 'owner' || role == 'admin';
  bool get canManageMembers => canManageSettings;
  bool get canCreateTransactions =>
      role == 'owner' || role == 'admin' || role == 'cashier';
  bool get isOwner => role == 'owner';

  factory BusinessAccess.fromJson(Map<String, dynamic> json) {
    return BusinessAccess(
      businessId: json['business_id'] as String,
      role: json['role'] as String? ?? 'viewer',
      plan: json['plan'] as String? ?? 'free',
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      membersUsed: json['members_used'] as int? ?? 1,
      maxMembers: json['max_members'] as int? ?? 1,
      transactionsUsed: json['transactions_used'] as int? ?? 0,
      monthlyTransactionLimit: json['monthly_transaction_limit'] as int?,
      attachmentsEnabled: json['attachments_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'role': role,
        'plan': plan,
        'subscription_status': subscriptionStatus,
        'members_used': membersUsed,
        'max_members': maxMembers,
        'transactions_used': transactionsUsed,
        'monthly_transaction_limit': monthlyTransactionLimit,
        'attachments_enabled': attachmentsEnabled,
      };

  factory BusinessAccess.ownerFallback(String userId) {
    return BusinessAccess(
      businessId: userId,
      role: 'owner',
      plan: 'free',
      subscriptionStatus: 'offline',
      membersUsed: 1,
      maxMembers: 1,
      transactionsUsed: 0,
      monthlyTransactionLimit: 200,
      attachmentsEnabled: false,
    );
  }
}
