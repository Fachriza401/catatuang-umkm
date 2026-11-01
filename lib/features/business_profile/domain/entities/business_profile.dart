class BusinessProfile {
  const BusinessProfile({
    this.id,
    required this.userId,
    required this.businessName,
    required this.ownerName,
    required this.businessType,
    required this.phone,
    required this.address,
  });

  final String? id;
  final String userId;
  final String businessName;
  final String ownerName;
  final String businessType;
  final String phone;
  final String address;

  BusinessProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? ownerName,
    String? businessType,
    String? phone,
    String? address,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
