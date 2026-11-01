import '../entities/money_transaction.dart';
import '../entities/transaction_draft.dart';

abstract interface class TransactionRepository {
  Stream<List<MoneyTransaction>> watchAll({required String userId});

  Stream<List<MoneyTransaction>> watchRecent({
    required String userId,
    int limit = 5,
  });

  Future<List<MoneyTransaction>> getAll(String userId);

  Future<MoneyTransaction?> getById(String id);

  Future<MoneyTransaction> create(TransactionDraft draft);

  Future<MoneyTransaction> update(MoneyTransaction transaction);

  Future<void> delete({required String id, required String userId});

  Future<void> syncPending(String userId);

  Future<void> resolveConflictKeepLocal(String transactionId);

  Future<void> resolveConflictUseRemote(String transactionId);
}
