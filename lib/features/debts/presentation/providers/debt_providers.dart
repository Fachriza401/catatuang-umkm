import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_payment.dart';
import '../../domain/repositories/debt_repository.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final debtsProvider = StreamProvider.autoDispose.family<List<Debt>, String>((
  ref,
  userId,
) {
  return ref.watch(debtRepositoryProvider).watchAll(userId: userId);
});

final debtPaymentsProvider = FutureProvider.autoDispose
    .family<List<DebtPayment>, String>((ref, debtId) {
      return ref.watch(debtRepositoryProvider).getPayments(debtId);
    });
