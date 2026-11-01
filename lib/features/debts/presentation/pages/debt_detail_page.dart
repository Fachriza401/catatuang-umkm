import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_payment.dart';
import '../../domain/entities/debt_type.dart';
import '../providers/debt_providers.dart';

class DebtDetailPage extends ConsumerWidget {
  const DebtDetailPage({super.key, required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }
    final access = ref.watch(businessAccessProvider).when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }
    return ref.watch(debtsProvider(access.businessId)).when(
          loading: () =>
              const Scaffold(body: Center(child: AppLoadingIndicator())),
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(error.toString())),
          ),
          data: (debts) {
            Debt? debt;
            for (final item in debts) {
              if (item.id == debtId) debt = item;
            }
            if (debt == null) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Catatan tidak ditemukan',
                    message: 'Catatan ini mungkin sudah tidak tersedia.',
                  ),
                ),
              );
            }
            return _DebtDetails(
              debt: debt,
              canRegisterPayment: access.canCreateTransactions,
            );
          },
        );
  }
}

class _DebtDetails extends ConsumerWidget {
  const _DebtDetails({required this.debt, required this.canRegisterPayment});

  final Debt debt;
  final bool canRegisterPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(debtPaymentsProvider(debt.id));
    final isReceivable = debt.type == DebtType.receivable;
    final color = isReceivable ? AppColors.success : AppColors.danger;
    return Scaffold(
      appBar: AppBar(title: Text(debt.type.label)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.contactName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (debt.phone.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    debt.phone,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _AmountLine(label: 'Nominal awal', amount: debt.amount),
                const SizedBox(height: AppSpacing.sm),
                _AmountLine(label: 'Sudah dibayar', amount: debt.paidAmount),
                const Divider(height: AppSpacing.xl),
                _AmountLine(
                  label: 'Sisa tagihan',
                  amount: debt.remainingAmount,
                  color: color,
                  bold: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Transaksi: ${AppDateFormat.fullDate(debt.transactionDate)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.alarm_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Jatuh tempo: ${AppDateFormat.fullDate(debt.dueDate)}',
                      ),
                    ),
                  ],
                ),
                if (debt.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Catatan: ${debt.note}'),
                ],
                const SizedBox(height: AppSpacing.md),
                Chip(
                  label: Text(debt.status.label),
                  avatar: Icon(
                    debt.status.name == 'paid'
                        ? Icons.check_circle_outline_rounded
                        : Icons.schedule_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          if (debt.remainingAmount > 0 && canRegisterPayment) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: isReceivable
                  ? 'Catat pembayaran masuk'
                  : 'Catat pembayaran utang',
              icon: Icons.payments_outlined,
              onPressed: () async {
                final saved = await showDialog<bool>(
                  context: context,
                  builder: (_) => _PaymentDialog(debt: debt),
                );
                if (saved == true) {
                  ref.invalidate(debtPaymentsProvider(debt.id));
                  if (context.mounted) {
                    AppSnackbar.success(
                      context,
                      'Pembayaran berhasil dicatat.',
                    );
                  }
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Riwayat pembayaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          payments.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: AppLoadingIndicator()),
            ),
            error: (error, stackTrace) => Text('Riwayat gagal dimuat: $error'),
            data: (items) => items.isEmpty
                ? const AppCard(
                    child: Text('Belum ada pembayaran untuk catatan ini.'),
                  )
                : Column(
                    children: items
                        .map(
                          (payment) => _PaymentTile(
                            payment: payment,
                            isReceivable: isReceivable,
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.amount,
    this.color,
    this.bold = false,
  });

  final String label;
  final int amount;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.isReceivable});

  final DebtPayment payment;
  final bool isReceivable;

  @override
  Widget build(BuildContext context) {
    final color = isReceivable ? AppColors.success : AppColors.danger;
    final softColor =
        isReceivable ? AppColors.successSoft : AppColors.dangerSoft;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: softColor,
              child: Icon(
                isReceivable
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
                  Text(AppDateFormat.fullDate(payment.paymentDate)),
                  if (payment.note.isNotEmpty)
                    Text(
                      payment.note,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (payment.syncStatus != 'synced')
                    Text(
                      payment.syncStatus == 'failed'
                          ? 'Sinkronisasi gagal'
                          : 'Menunggu sinkronisasi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: payment.syncStatus == 'failed'
                                ? AppColors.warning
                                : AppColors.textMuted,
                          ),
                    ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(payment.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.debt});

  final Debt debt;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _paymentDate = DateUtils.dateOnly(DateTime.now());
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = CurrencyFormatter.input(
      widget.debt.remainingAmount,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = CurrencyFormatter.parse(_amountController.text)!;
    if (amount > widget.debt.remainingAmount) {
      _formKey.currentState!.validate();
      AppSnackbar.error(context, 'Pembayaran melebihi sisa tagihan.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(debtRepositoryProvider).registerPayment(
            debt: widget.debt,
            amount: amount,
            paymentDate: _paymentDate,
            note: _noteController.text,
          );
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.debt.type == DebtType.receivable
            ? 'Catat pembayaran masuk'
            : 'Catat pembayaran utang',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sisa tagihan ${CurrencyFormatter.format(widget.debt.remainingAmount)}',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _amountController,
                label: 'Nominal pembayaran',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                validator: (value) {
                  final error = Validators.transactionAmount(value);
                  if (error != null) return error;
                  final amount = CurrencyFormatter.parse(value)!;
                  if (amount > widget.debt.remainingAmount) {
                    return 'Melebihi sisa tagihan.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: ValueKey(_paymentDate),
                label: 'Tanggal pembayaran',
                initialValue: AppDateFormat.fullDate(_paymentDate),
                readOnly: true,
                prefixIcon: Icons.calendar_today_outlined,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    cancelText: 'Batal',
                    confirmText: 'Pilih',
                  );
                  if (picked != null) setState(() => _paymentDate = picked);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _noteController,
                label: 'Catatan (opsional)',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan pembayaran'),
        ),
      ],
    );
  }
}
