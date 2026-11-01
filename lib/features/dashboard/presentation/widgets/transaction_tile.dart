import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/payment_method.dart';
import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_sync_status.dart';
import '../../../transactions/presentation/utils/transaction_ui.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final MoneyTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = TransactionCategory.byId(transaction.categoryId) ??
        TransactionCategory.fallbackFor(transaction.type);
    final payment = PaymentMethod.byId(transaction.paymentMethodId) ??
        PaymentMethod.fallback;
    final isIncome = transaction.isIncome;
    final accent = isIncome ? AppColors.success : AppColors.danger;
    final soft = isIncome ? AppColors.successSoft : AppColors.dangerSoft;
    final title = transaction.description.trim().isEmpty
        ? category.label
        : transaction.description.trim();
    final syncStatus = transaction.syncStatus;
    final statusLabel = switch (syncStatus) {
      TransactionSyncStatus.pending => 'Menunggu',
      TransactionSyncStatus.syncing => 'Menyinkronkan',
      TransactionSyncStatus.synced => 'Tersinkron',
      TransactionSyncStatus.failed => 'Gagal',
      TransactionSyncStatus.conflict => 'Konflik',
    };
    final statusColor = switch (syncStatus) {
      TransactionSyncStatus.pending => AppColors.warning,
      TransactionSyncStatus.syncing => AppColors.info,
      TransactionSyncStatus.synced => AppColors.success,
      TransactionSyncStatus.failed ||
      TransactionSyncStatus.conflict =>
        AppColors.danger,
    };
    final statusIcon = switch (syncStatus) {
      TransactionSyncStatus.pending => Icons.cloud_upload_outlined,
      TransactionSyncStatus.syncing => Icons.sync,
      TransactionSyncStatus.synced => Icons.cloud_done_outlined,
      TransactionSyncStatus.failed => Icons.sync_problem,
      TransactionSyncStatus.conflict => Icons.warning_amber_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(category.icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${category.label} • ${AppDateFormat.shortDate(transaction.transactionDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (transaction.hasAttachment) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          payment.icon,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          payment.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (syncStatus == TransactionSyncStatus.conflict)
                IconButton(
                  tooltip: 'Selesaikan konflik',
                  onPressed: () => _resolveConflict(context, ref),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resolveConflict(BuildContext context, WidgetRef ref) async {
    final useLocal = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konflik perubahan'),
        content: const Text(
          'Pilih data yang akan dipertahankan untuk transaksi ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Gunakan server'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gunakan lokal'),
          ),
        ],
      ),
    );
    if (useLocal == null || !context.mounted) return;

    try {
      final repository = ref.read(transactionRepositoryProvider);
      if (useLocal) {
        await repository.resolveConflictKeepLocal(transaction.id);
      } else {
        await repository.resolveConflictUseRemote(transaction.id);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konflik belum dapat diselesaikan.')),
      );
    }
  }
}
