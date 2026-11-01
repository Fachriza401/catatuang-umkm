import '../entities/business_profile.dart';

abstract interface class BusinessProfileRepository {
  Future<BusinessProfile?> getByUserId(String userId);

  Future<BusinessProfile> save(BusinessProfile profile);
}
