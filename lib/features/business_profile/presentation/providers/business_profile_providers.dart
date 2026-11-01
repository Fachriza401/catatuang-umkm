import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/business_profile_repository_impl.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/repositories/business_profile_repository.dart';
import '../../domain/usecases/business_profile_use_cases.dart';
import '../controllers/business_profile_controller.dart';

final businessProfileRepositoryProvider = Provider<BusinessProfileRepository>((
  ref,
) {
  return BusinessProfileRepositoryImpl(ref.watch(supabaseServiceProvider));
});

final getBusinessProfileUseCaseProvider = Provider<GetBusinessProfileUseCase>((
  ref,
) {
  return GetBusinessProfileUseCase(
    ref.watch(businessProfileRepositoryProvider),
  );
});

final saveBusinessProfileUseCaseProvider = Provider<SaveBusinessProfileUseCase>(
  (ref) {
    return SaveBusinessProfileUseCase(
      ref.watch(businessProfileRepositoryProvider),
    );
  },
);

final businessProfileControllerProvider = AsyncNotifierProvider.autoDispose<
    BusinessProfileController, BusinessProfile?>(BusinessProfileController.new);

final businessProfileByIdProvider = FutureProvider.autoDispose
    .family<BusinessProfile?, String>((ref, businessId) {
  return ref.watch(getBusinessProfileUseCaseProvider)(businessId);
});
