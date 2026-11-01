import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/dashboard_data.dart';
import '../entities/dashboard_period.dart';
import '../services/dashboard_calculator.dart';

class DashboardParams {
  const DashboardParams({required this.userId, required this.period, this.now});

  final String userId;
  final DashboardPeriod period;
  final DateTime? now;
}

class WatchDashboardUseCase {
  const WatchDashboardUseCase(this._repository);

  final TransactionRepository _repository;

  Stream<DashboardData> call(DashboardParams input) {
    return _repository.watchAll(userId: input.userId).map((transactions) {
      return DashboardCalculator.build(
        transactions: transactions,
        period: input.period,
        now: input.now,
      );
    });
  }
}
