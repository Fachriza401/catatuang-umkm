import '../../../../core/database/app_database.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._database);

  static const _completedKey = 'onboarding_completed';

  final AppDatabase _database;

  @override
  Future<bool> isCompleted() async {
    final value = await _database.readPreference(_completedKey);
    return value == 'true';
  }

  @override
  Future<void> markCompleted() {
    return _database.writePreference(_completedKey, 'true');
  }
}
