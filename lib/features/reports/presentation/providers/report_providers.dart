import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

final reportTransactionsProvider = StreamProvider.autoDispose
    .family<List<MoneyTransaction>, String>((ref, userId) {
  return ref.watch(transactionRepositoryProvider).watchAll(userId: userId);
});
