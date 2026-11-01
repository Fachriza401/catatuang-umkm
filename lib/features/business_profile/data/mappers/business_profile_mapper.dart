import '../../domain/entities/business_profile.dart';

abstract final class BusinessProfileMapper {
  static BusinessProfile fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      businessType: json['business_type'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toJson(BusinessProfile profile) {
    return {
      'user_id': profile.userId,
      'business_name': profile.businessName.trim(),
      'owner_name': profile.ownerName.trim(),
      'business_type': profile.businessType.trim(),
      'phone': profile.phone.trim(),
      'address': profile.address.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
