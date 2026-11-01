import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/splash_result.dart';
import '../providers/splash_providers.dart';

class SplashController extends AsyncNotifier<SplashResult> {
  @override
  Future<SplashResult> build() async {
    final initialize = ref.watch(initializeAppUseCaseProvider);
    try {
      return await initialize(const NoParams());
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('App startup failed: $error\n$stackTrace');
      }
      rethrow;
    }
  }
}
