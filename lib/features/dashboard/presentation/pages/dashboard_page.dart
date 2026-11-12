import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/domain/entities/business_access.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/domain/entities/debt_type.dart';
import '../../../debts/presentation/providers/debt_reminder_providers.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_period.dart';
import '../providers/balance_privacy_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_pin_dialog.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/transaction_tile.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isSyncing = false;
  final Set<String> _notifiedDueDebtIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    if (mounted) setState(() => _isSyncing = true);
    try {
      final access = await ref.read(businessAccessProvider.future);
      await ref.read(syncTransactionsUseCaseProvider)(
        access?.businessId ?? user.id,
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _openNewTransaction() {
    context.push(AppRoutes.transactionNew);
  }

  void _openEditTransaction(MoneyTransaction transaction) {
    context.push(AppRoutes.transactionEdit(transaction.id));
  }

  Future<void> _logout() async {
    final user = ref.read(currentAuthUserProvider);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.danger, Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Keluar dari akun?',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user == null
                      ? 'Anda akan keluar dari sesi ini.'
                      : 'Sesi ${user.displayName} akan diakhiri di perangkat ini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Data transaksi tetap tersimpan di perangkat dan '
                          'akan disinkronkan kembali saat Anda masuk.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Ya, keluar sekarang',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Tetap di akun',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(signOutUseCaseProvider)(const NoParams());
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      final message = error is AppFailure
          ? error.message
          : 'Gagal keluar. Silakan coba lagi.';
      AppSnackbar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final dashboard = ref.watch(dashboardDataProvider);
    final privacy = ref.watch(balancePrivacyProvider);
    final access = ref
        .watch(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    final canCreateTransactions = access?.canCreateTransactions ?? false;
    final canEditTransactions = access?.canEditTransactions ?? false;
    BusinessAccess? resolvedAccess = access;
    if (resolvedAccess == null && user != null) {
      resolvedAccess = BusinessAccess.ownerFallback(user.id);
    }

    final businessId = resolvedAccess?.businessId;
    final dueDebtsAsync = businessId == null
        ? const AsyncValue<List<Debt>>.data(<Debt>[])
        : ref.watch(dueDebtsProvider(businessId));
    final dueDebtList = dueDebtsAsync.value ?? <Debt>[];
    final dueSoonAsync = businessId == null
        ? const AsyncValue<List<Debt>>.data(<Debt>[])
        : ref.watch(dueSoonDebtsProvider(businessId));
    final dueSoonList = dueSoonAsync.value ?? <Debt>[];
    final isBalanceHidden = privacy.value?.isLocked ?? false;
    if (businessId != null) {
      ref.listen(dueDebtsProvider(businessId), (previous, next) {
        final items = next.value;
        if (items == null) return;
        final fresh = items
            .where((debt) => !_notifiedDueDebtIds.contains(debt.id))
            .toList(growable: false);
        if (fresh.isEmpty) return;
        _notifiedDueDebtIds.addAll(fresh.map((debt) => debt.id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final names = fresh
              .take(2)
              .map((debt) => debt.contactName)
              .join(', ');
          final more = fresh.length > 2
              ? ' dan ${fresh.length - 2} lainnya'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Pengingat: $names$more sudah jatuh tempo.'),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () => context.go(AppRoutes.debts),
              ),
            ),
          );
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppDateFormat.greeting(DateTime.now())} ${AppDateFormat.greetingEmoji(DateTime.now())}, ${user?.displayName ?? 'Pengguna'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Kelola keuangan usaha Anda',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showDebtReminders(dueSoonList),
            tooltip: 'Pengingat jatuh tempo',
            icon: Badge(
              isLabelVisible: dueDebtList.isNotEmpty,
              label: Text('${dueDebtList.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.reports),
            tooltip: 'Laporan keuangan',
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            onPressed: _isSyncing ? null : _sync,
            tooltip: 'Sinkronkan data',
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            onSelected: (value) {
              if (value == 'logout') _logout();
              if (value == 'settings') context.push(AppRoutes.settings);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: AppSpacing.md),
                    Text('Pengaturan'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: AppSpacing.md),
                    Text('Keluar'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canCreateTransactions ? _openNewTransaction : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Transaksi'),
      ),
      body: dashboard.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stackTrace) => _DashboardError(
          message: error is AppFailure
              ? error.message
              : 'Dashboard gagal dimuat. Silakan coba lagi.',
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: _sync,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              120,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!AppConfig.isSupabaseConfigured) ...[
                        const AppStatusBanner(
                          message:
                              'Sinkronisasi cloud belum aktif. Transaksi '
                              'tetap tersimpan aman di perangkat ini.',
                          tone: AppStatusTone.warning,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _BalanceCard(
                        balance: data.cashBalance,
                        isHidden: isBalanceHidden,
                        hasPin: privacy.value?.hasPin ?? false,
                        isSyncing: _isSyncing,
                        onToggleLock: _toggleBalanceLock,
                      ),
                      if (dueDebtList.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DueReminderBanner(
                          debts: dueDebtList,
                          onTap: () => _showDebtReminders(dueSoonList),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _PeriodSelector(
                        selected: period,
                        onChanged: (value) {
                          ref
                              .read(dashboardPeriodProvider.notifier)
                              .select(value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Pemasukan',
                              amount: data.summary.income,
                              icon: Icons.south_west_rounded,
                              color: AppColors.success,
                              softColor: AppColors.successSoft,
                              isHidden: isBalanceHidden,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Pengeluaran',
                              amount: data.summary.expense,
                              icon: Icons.north_east_rounded,
                              color: AppColors.danger,
                              softColor: AppColors.dangerSoft,
                              isHidden: isBalanceHidden,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfitLossCard(data: data, isHidden: isBalanceHidden),
                      const SizedBox(height: AppSpacing.xl),
                      _ChartCard(data: data),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.handshake_outlined,
                              label: 'Utang & Piutang',
                              color: AppColors.info,
                              softColor: AppColors.infoSoft,
                              onTap: () => context.go(AppRoutes.debts),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.calculate_outlined,
                              label: 'Kalkulator',
                              color: AppColors.primary,
                              softColor: AppColors.primarySoft,
                              onTap: () => context.go(AppRoutes.calculator),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _RecentTransactions(
                        transactions: data.recentTransactions,
                        hideAmounts: isBalanceHidden,
                        onAdd: canCreateTransactions
                            ? _openNewTransaction
                            : null,
                        onTap: canEditTransactions
                            ? _openEditTransaction
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBalanceLock() async {
    final controller = ref.read(balancePrivacyProvider.notifier);
    final privacy = ref.read(balancePrivacyProvider).value;
    if (privacy == null) return;
    if (privacy.isLocked) {
      if (!privacy.hasPin) {
        final result = await BalancePinDialog.show(context, isCreating: true);
        if (result?.pin != null) {
          await controller.createPinAndUnlock(result!.pin!);
        }
        return;
      }
      final result = await BalancePinDialog.show(context, isCreating: false);
      if (result?.forgot == true) {
        await controller.clearPinAndUnlock();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN dihapus. Saldo bisa dilihat tanpa kunci.'),
            ),
          );
        }
        return;
      }
      if (result?.pin != null) {
        final valid = await controller.unlockWithPin(result!.pin!);
        if (!valid && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN salah. Coba lagi.')),
          );
        }
      }
      return;
    }
    if (!privacy.hasPin) {
      final result = await BalancePinDialog.show(context, isCreating: true);
      if (result?.pin != null) {
        await controller.createPinAndUnlock(result!.pin!);
        await controller.lock();
      }
      return;
    }
    await controller.lock();
  }

  Future<void> _showDebtReminders(List<Debt> debts) async {
    if (debts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada janji jatuh tempo terdekat.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Pengingat jatuh tempo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final debt in debts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: debt.type == DebtType.receivable
                    ? AppColors.successSoft
                    : AppColors.dangerSoft,
                child: Icon(
                  debt.type == DebtType.receivable
                      ? Icons.call_received_rounded
                      : Icons.call_made_rounded,
                  color: debt.type == DebtType.receivable
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              title: Text(debt.contactName),
              subtitle: Text(
                '${debt.type == DebtType.receivable ? "Piutang" : "Utang"} • Jatuh tempo ${debt.dueDate.day}/${debt.dueDate.month}/${debt.dueDate.year}',
              ),
              trailing: Text(
                CurrencyFormatter.format(debt.remainingAmount),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/debts/${debt.id}');
              },
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.isHidden,
    required this.hasPin,
    required this.isSyncing,
    required this.onToggleLock,
  });

  final int balance;
  final bool isHidden;
  final bool hasPin;
  final bool isSyncing;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primaryGlow(AppColors.primary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Stack(
          children: [
            Positioned(
              top: -42,
              right: -26,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -56,
              right: 40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Saldo Kas',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHidden
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHidden ? 'Terkunci' : 'Terbuka',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        onPressed: onToggleLock,
                        tooltip: isHidden
                            ? 'Buka kunci saldo'
                            : 'Kunci saldo dengan PIN',
                        icon: Icon(
                          isHidden
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isHidden
                          ? 'Rp •••••••'
                          : CurrencyFormatter.format(balance),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        isSyncing
                            ? Icons.cloud_sync_rounded
                            : isHidden
                            ? Icons.shield_rounded
                            : Icons.verified_user_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          isSyncing
                              ? 'Menyinkronkan transaksi...'
                              : isHidden
                              ? 'Saldo terkunci. Ketuk ikon kunci untuk membuka.'
                              : hasPin
                              ? 'Saldo dilindungi PIN pribadi'
                              : 'Saldo dari seluruh transaksi usaha',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueReminderBanner extends StatelessWidget {
  const _DueReminderBanner({required this.debts, required this.onTap});

  final List<Debt> debts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final names = debts.take(2).map((debt) => debt.contactName).join(', ');
    final more = debts.length > 2 ? ' +${debts.length - 2} lainnya' : '';
    return AppCard(
      onTap: onTap,
      showShadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.warning.withValues(alpha: 0.35),
      backgroundColor: AppColors.warningSoft.withValues(alpha: 0.55),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${debts.length} janji sudah jatuh tempo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$names$more. Ketuk untuk lihat detail.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final period in DashboardPeriod.values)
            Expanded(
              child: Material(
                color: period == selected
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: () => onChanged(period),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      period.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: period == selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.isHidden,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final Color softColor;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isHidden ? 'Rp ••••••' : CurrencyFormatter.format(amount),
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

class _ProfitLossCard extends StatelessWidget {
  const _ProfitLossCard({required this.data, required this.isHidden});

  final DashboardData data;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final isProfit = data.summary.isProfit;
    final color = isProfit ? AppColors.success : AppColors.danger;
    final softColor = isProfit ? AppColors.successSoft : AppColors.dangerSoft;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isProfit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfit ? 'Laba bersih' : 'Rugi bersih',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ringkasan ${data.period.summaryLabel.toLowerCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isHidden
                ? 'Rp ••••••'
                : CurrencyFormatter.format(data.summary.net.abs()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      showShadow: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arus Kas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.period.chartLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const _LegendDot(color: AppColors.success, label: 'Masuk'),
              const SizedBox(width: AppSpacing.md),
              const _LegendDot(color: AppColors.danger, label: 'Keluar'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          IncomeExpenseChart(points: data.chartPoints, period: data.period),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.hideAmounts,
    required this.onAdd,
    required this.onTap,
  });

  final List<MoneyTransaction> transactions;
  final bool hideAmounts;
  final VoidCallback? onAdd;
  final ValueChanged<MoneyTransaction>? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Transaksi Terakhir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (transactions.isNotEmpty)
                  Text(
                    '${transactions.length} terbaru',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                message:
                    'Mulai catat pemasukan dan pengeluaran usaha Anda agar '
                    'laporan keuangan lebih rapi.',
                action: onAdd == null
                    ? null
                    : AppButton(
                        label: 'Tambah Transaksi',
                        icon: Icons.add_rounded,
                        isExpanded: false,
                        onPressed: onAdd,
                      ),
              ),
            )
          else
            for (var index = 0; index < transactions.length; index++) ...[
              if (index > 0) const Divider(indent: AppSpacing.xl),
              TransactionTile(
                transaction: transactions[index],
                hideAmount: hideAmounts,
                onTap: onTap == null ? null : () => onTap!(transactions[index]),
              ),
            ],
          if (transactions.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        AppEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Dashboard gagal dimuat',
          message: message,
          action: AppButton(
            label: 'Coba lagi',
            icon: Icons.refresh_rounded,
            isExpanded: false,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
