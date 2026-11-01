class BusinessMember {
  const BusinessMember({
    required this.userId,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String userId;
  final String email;
  final String role;
  final DateTime createdAt;

  factory BusinessMember.fromJson(Map<String, dynamic> json) {
    return BusinessMember(
      userId: json['member_user_id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
