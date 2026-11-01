import '../../../../core/usecase/use_case.dart';
import '../entities/splash_result.dart';
import '../repositories/splash_repository.dart';

class InitializeAppUseCase implements UseCase<SplashResult, NoParams> {
  const InitializeAppUseCase(this._repository);

  final SplashRepository _repository;

  @override
  Future<SplashResult> call(NoParams input) => _repository.resolve();
}
