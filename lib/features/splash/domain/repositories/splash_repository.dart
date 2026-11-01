import '../entities/splash_result.dart';

abstract interface class SplashRepository {
  Future<SplashResult> resolve();
}
