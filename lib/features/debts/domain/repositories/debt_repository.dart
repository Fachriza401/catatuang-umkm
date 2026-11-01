import '../entities/debt.dart';
import '../entities/debt_draft.dart';
import '../entities/debt_payment.dart';

abstract interface class DebtRepository {
  Stream<List<Debt>> watchAll({required String userId});

  Future<Debt> create(DebtDraft draft);

  Future<List<DebtPayment>> getPayments(String debtId);

  Future<DebtPayment> registerPayment({
    required Debt debt,
    required int amount,
    required DateTime paymentDate,
    required String note,
  });

  Future<void> sync(String userId);
}
