import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_type.dart';
import '../providers/debt_providers.dart';

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  DebtType? _selectedType;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    setState(() => _isSyncing = true);
    try {
      final access = await ref.read(businessAccessProvider.future);
      await ref
          .read(debtRepositoryProvider)
          .sync(access?.businessId ?? user.id);
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, 'Sinkronisasi gagal: $error');
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }
    final access = ref
        .watch(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }
    final businessId = access.businessId;
    final debtsAsync = ref.watch(debtsProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utang & Piutang'),
        actions: [
          IconButton(
            tooltip: 'Sinkronkan',
            onPressed: _isSyncing ? null : _sync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: access.canManageSettings
            ? () => context.push('/debts/new')
            : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah catatan'),
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Data gagal dimuat',
              message: error.toString(),
              action: FilledButton(
                onPressed: () => ref.invalidate(debtsProvider(businessId)),
                child: const Text('Coba lagi'),
              ),
            ),
          ),
        ),
        data: (debts) {
          final visibleDebts = debts
              .where(
                (debt) => _selectedType == null || debt.type == _selectedType,
              )
              .toList(growable: false);
          final totalReceivable = debts
              .where((debt) => debt.type == DebtType.receivable)
              .fold<int>(0, (total, debt) => total + debt.remainingAmount);
          final totalPayable = debts
              .where((debt) => debt.type == DebtType.payable)
              .fold<int>(0, (total, debt) => total + debt.remainingAmount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              120,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TotalCard(
                      label: 'Belum diterima',
                      amount: totalReceivable,
                      color: AppColors.success,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TotalCard(
                      label: 'Belum dibayar',
                      amount: totalPayable,
                      color: AppColors.danger,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedButton<DebtType?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Semua')),
                  ButtonSegment(
                    value: DebtType.receivable,
                    label: Text('Piutang'),
                  ),
                  ButtonSegment(value: DebtType.payable, label: Text('Utang')),
                ],
                selected: {_selectedType},
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                onSelectionChanged: (selected) {
                  setState(() => _selectedType = selected.first);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (visibleDebts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.huge),
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada catatan',
                    message:
                        'Catat utang atau piutang agar jatuh tempo dan pembayaran mudah dipantau.',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/debts/new'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah catatan'),
                    ),
                  ),
                )
              else
                ...visibleDebts.map(
                  (debt) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DebtTile(
                      debt: debt,
                      onTap: () => context.push('/debts/${debt.id}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.debt, required this.onTap});

  final Debt debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = debt.type == DebtType.receivable
        ? AppColors.success
        : AppColors.danger;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: debt.type == DebtType.receivable
                    ? AppColors.successSoft
                    : AppColors.dangerSoft,
                child: Icon(
                  debt.type == DebtType.receivable
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.contactName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${debt.type.label} · Jatuh tempo ${_date(debt.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  debt.status.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: debt.remainingAmount == 0
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (debt.syncStatus != 'synced')
                Tooltip(
                  message: debt.syncStatus == 'failed'
                      ? 'Sinkronisasi gagal. Coba sinkronkan kembali.'
                      : 'Menunggu sinkronisasi.',
                  child: Icon(
                    debt.syncStatus == 'failed'
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_upload_outlined,
                    color: debt.syncStatus == 'failed'
                        ? AppColors.warning
                        : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                CurrencyFormatter.format(debt.remainingAmount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
