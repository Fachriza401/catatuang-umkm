import '../../../../core/error/app_failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/money_transaction.dart';
import '../entities/payment_method.dart';
import '../entities/transaction_category.dart';
import '../entities/transaction_draft.dart';
import '../repositories/transaction_repository.dart';

const maxTransactionAmount = 999999999999;

abstract final class TransactionValidator {
  static void validateDraft(TransactionDraft draft) {
    if (draft.userId.trim().isEmpty) {
      throw const ValidationFailure('Sesi pengguna tidak valid.');
    }
    _validateAmount(draft.amount);
    _validateCategory(draft.categoryId, draft.type.name);
    _validatePaymentMethod(draft.paymentMethodId);
    _validateDescription(draft.description);
  }

  static void validateTransaction(MoneyTransaction transaction) {
    if (transaction.id.trim().isEmpty) {
      throw const ValidationFailure('Transaksi tidak valid.');
    }
    if (transaction.userId.trim().isEmpty) {
      throw const ValidationFailure('Sesi pengguna tidak valid.');
    }
    _validateAmount(transaction.amount);
    _validateCategory(transaction.categoryId, transaction.type.name);
    _validatePaymentMethod(transaction.paymentMethodId);
    _validateDescription(transaction.description);
  }

  static void _validateAmount(int amount) {
    if (amount <= 0) {
      throw const ValidationFailure('Nominal harus lebih dari Rp0.');
    }
    if (amount > maxTransactionAmount) {
      throw const ValidationFailure(
        'Nominal melebihi batas maksimal transaksi.',
      );
    }
  }

  static void _validateCategory(String categoryId, String typeName) {
    final category = TransactionCategory.byId(categoryId);
    if (category == null) {
      throw const ValidationFailure('Kategori transaksi tidak valid.');
    }
    if (category.type.name != typeName) {
      throw const ValidationFailure(
        'Kategori tidak sesuai dengan jenis transaksi.',
      );
    }
  }

  static void _validatePaymentMethod(String paymentMethodId) {
    if (PaymentMethod.byId(paymentMethodId) == null) {
      throw const ValidationFailure('Metode pembayaran tidak valid.');
    }
  }

  static void _validateDescription(String description) {
    if (description.trim().length > 500) {
      throw const ValidationFailure('Deskripsi maksimal 500 karakter.');
    }
  }
}

class CreateTransactionUseCase
    implements UseCase<MoneyTransaction, TransactionDraft> {
  const CreateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<MoneyTransaction> call(TransactionDraft input) {
    TransactionValidator.validateDraft(input);
    return _repository.create(input);
  }
}

class UpdateTransactionUseCase
    implements UseCase<MoneyTransaction, MoneyTransaction> {
  const UpdateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<MoneyTransaction> call(MoneyTransaction input) {
    TransactionValidator.validateTransaction(input);
    return _repository.update(input);
  }
}

class DeleteTransactionParams {
  const DeleteTransactionParams({required this.id, required this.userId});

  final String id;
  final String userId;
}

class DeleteTransactionUseCase
    implements UseCase<void, DeleteTransactionParams> {
  const DeleteTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<void> call(DeleteTransactionParams input) {
    return _repository.delete(id: input.id, userId: input.userId);
  }
}

class GetTransactionUseCase implements UseCase<MoneyTransaction?, String> {
  const GetTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<MoneyTransaction?> call(String input) {
    return _repository.getById(input);
  }
}

class SyncTransactionsUseCase implements UseCase<void, String> {
  const SyncTransactionsUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<void> call(String input) {
    return _repository.syncPending(input);
  }
}
