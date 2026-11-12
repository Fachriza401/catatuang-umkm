import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../../dashboard/presentation/widgets/transaction_tile.dart';
import '../providers/transaction_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  String _filter = 'all';
  String _query = '';
  bool _isSyncing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null || _isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final access = await ref.read(businessAccessProvider.future);
      await ref.read(syncTransactionsUseCaseProvider)(
        access?.businessId ?? user.id,
      );
      if (mounted) {
        AppSnackbar.info(context, 'Antrean sinkronisasi sudah diperiksa.');
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(
          context,
          error is AppFailure ? error.message : 'Sinkronisasi gagal.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _openNewTransaction() {
    context.push(AppRoutes.transactionNew);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sesi pengguna tidak tersedia.')),
      );
    }

    final transactions = ref.watch(transactionsProvider(user.id));
    final canCreate = ref.watch(businessAccessProvider).when(
          data: (access) => access?.canCreateTransactions ?? false,
          loading: () => false,
          error: (_, _) => false,
        );
    final canEdit = ref.watch(businessAccessProvider).when(
          data: (access) => access?.canEditTransactions ?? false,
          loading: () => false,
          error: (_, _) => false,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
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
          IconButton(
            tooltip: 'Tambah transaksi',
            onPressed: canCreate ? _openNewTransaction : null,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: transactions.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Transaksi gagal dimuat',
              message: error is AppFailure
                  ? error.message
                  : 'Periksa penyimpanan lokal lalu coba lagi.',
              action: FilledButton(
                onPressed: () => ref.invalidate(transactionsProvider(user.id)),
                child: const Text('Coba lagi'),
              ),
            ),
          ),
        ),
        data: (allTransactions) {
          final query = _query.trim().toLowerCase();
          final filtered = allTransactions.where((transaction) {
            final matchesType = _filter == 'all' ||
                (_filter == 'income' && transaction.type.isIncome) ||
                (_filter == 'expense' && transaction.type.isExpense);
            final matchesQuery = query.isEmpty ||
                transaction.description.toLowerCase().contains(query) ||
                transaction.categoryId.toLowerCase().contains(query) ||
                transaction.amount.toString().contains(query);
            return matchesType && matchesQuery;
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi atau nominal',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Semua')),
                          ButtonSegment(
                            value: 'income',
                            label: Text('Masuk'),
                          ),
                          ButtonSegment(
                            value: 'expense',
                            label: Text('Keluar'),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (selection) {
                          setState(() => _filter = selection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: query.isEmpty
                            ? 'Belum ada transaksi'
                            : 'Transaksi tidak ditemukan',
                        message: query.isEmpty
                            ? 'Transaksi yang dicatat akan muncul di sini.'
                            : 'Coba kata kunci atau filter lain.',
                        action: query.isEmpty && canCreate
                            ? FilledButton.icon(
                                onPressed: _openNewTransaction,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tambah transaksi'),
                              )
                            : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxxl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) => TransactionTile(
                          transaction: filtered[index],
                          onTap: canEdit
                              ? () => context.push(
                                  AppRoutes.transactionEdit(filtered[index].id),
                                )
                              : null,
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
