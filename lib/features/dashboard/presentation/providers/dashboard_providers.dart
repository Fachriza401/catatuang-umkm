import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_period.dart';
import '../../domain/usecases/watch_dashboard_use_case.dart';

class DashboardPeriodController extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.monthly;

  void select(DashboardPeriod period) {
    state = period;
  }
}

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodController, DashboardPeriod>(
  DashboardPeriodController.new,
);

final watchDashboardUseCaseProvider = Provider<WatchDashboardUseCase>((ref) {
  return WatchDashboardUseCase(ref.watch(transactionRepositoryProvider));
});

final dashboardDataProvider = StreamProvider.autoDispose<DashboardData>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  final period = ref.watch(dashboardPeriodProvider);
  if (user == null) {
    return Stream.value(DashboardData.empty(period));
  }
  final access = ref
      .watch(businessAccessProvider)
      .when(data: (value) => value, loading: () => null, error: (_, _) => null);
  if (access == null) return Stream.value(DashboardData.empty(period));

  final watchDashboard = ref.watch(watchDashboardUseCaseProvider);
  return watchDashboard(
    DashboardParams(userId: access.businessId, period: period),
  );
});
