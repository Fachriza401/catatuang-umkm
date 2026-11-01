import '../../../../core/usecase/use_case.dart';
import '../entities/business_profile.dart';
import '../repositories/business_profile_repository.dart';

enum PostAuthDestination { setupProfile, home }

class GetBusinessProfileUseCase implements UseCase<BusinessProfile?, String> {
  const GetBusinessProfileUseCase(this._repository);

  final BusinessProfileRepository _repository;

  @override
  Future<BusinessProfile?> call(String input) {
    return _repository.getByUserId(input);
  }
}

class SaveBusinessProfileUseCase
    implements UseCase<BusinessProfile, BusinessProfile> {
  const SaveBusinessProfileUseCase(this._repository);

  final BusinessProfileRepository _repository;

  @override
  Future<BusinessProfile> call(BusinessProfile input) {
    return _repository.save(input);
  }
}

class ResolvePostAuthDestinationUseCase
    implements UseCase<PostAuthDestination, String> {
  const ResolvePostAuthDestinationUseCase(this._repository);

  final BusinessProfileRepository _repository;

  @override
  Future<PostAuthDestination> call(String input) async {
    final profile = await _repository.getByUserId(input);
    return profile == null
        ? PostAuthDestination.setupProfile
        : PostAuthDestination.home;
  }
}
