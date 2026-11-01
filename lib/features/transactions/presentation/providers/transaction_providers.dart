import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/attachment_service.dart';
import '../../domain/entities/money_transaction.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/services/transaction_sync_service.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/transaction_use_cases.dart';

final transactionSyncServiceProvider = Provider<TransactionSyncService>((ref) {
  return TransactionSyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionSyncServiceProvider),
  );
});

final transactionsProvider = StreamProvider.autoDispose
    .family<List<MoneyTransaction>, String>((ref, userId) {
      return ref.watch(transactionRepositoryProvider).watchAll(userId: userId);
    });

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>(
  (ref) => CreateTransactionUseCase(ref.watch(transactionRepositoryProvider)),
);

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>(
  (ref) => UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider)),
);

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>(
  (ref) => DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider)),
);

final getTransactionUseCaseProvider = Provider<GetTransactionUseCase>(
  (ref) => GetTransactionUseCase(ref.watch(transactionRepositoryProvider)),
);

final syncTransactionsUseCaseProvider = Provider<SyncTransactionsUseCase>(
  (ref) => SyncTransactionsUseCase(ref.watch(transactionRepositoryProvider)),
);

final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(),
);

final signedTransactionAttachmentProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, storagePath) async {
  if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
    return storagePath;
  }
  final client = ref.watch(supabaseServiceProvider).client;
  if (client == null) return null;
  return client.storage
      .from('transaction-attachments')
      .createSignedUrl(storagePath, 3600)
      .timeout(const Duration(seconds: 10));
});
