import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../domain/entities/debt_draft.dart';
import '../../domain/entities/debt_type.dart';
import '../providers/debt_providers.dart';

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({super.key});

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DebtType _type = DebtType.receivable;
  DateTime _transactionDate = DateUtils.dateOnly(DateTime.now());
  DateTime _dueDate = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 30)),
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool dueDate}) async {
    final current = dueDate ? _dueDate : _transactionDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: dueDate
          ? 'Pilih tanggal jatuh tempo'
          : 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (dueDate) {
        _dueDate = picked;
      } else {
        _transactionDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate.isBefore(_transactionDate)) {
      AppSnackbar.error(
        context,
        'Jatuh tempo tidak boleh sebelum tanggal transaksi.',
      );
      return;
    }
    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
      AppSnackbar.error(
        context,
        'Sesi akun tidak ditemukan. Silakan masuk kembali.',
      );
      return;
    }
    final access = ref
        .read(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null || !access.canManageSettings) {
      AppSnackbar.error(
        context,
        'Hanya pemilik usaha yang dapat mencatat utang.',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(debtRepositoryProvider)
          .create(
            DebtDraft(
              userId: access.businessId,
              type: _type,
              contactName: _nameController.text,
              phone: _phoneController.text,
              amount: CurrencyFormatter.parse(_amountController.text)!,
              transactionDate: _transactionDate,
              dueDate: _dueDate,
              note: _noteController.text,
            ),
          );
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat utang/piutang')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Pilih jenis catatan',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(
                    value: DebtType.receivable,
                    icon: Icon(Icons.south_west_rounded),
                    label: Text('Piutang'),
                  ),
                  ButtonSegment(
                    value: DebtType.payable,
                    icon: Icon(Icons.north_east_rounded),
                    label: Text('Utang'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selected) {
                  setState(() => _type = selected.first);
                },
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _nameController,
                label: 'Nama ${_type.contactLabel.toLowerCase()}',
                hint: 'Contoh: Toko Sumber Rezeki',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.required(
                  value,
                  label: 'Nama ${_type.contactLabel.toLowerCase()}',
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Nomor telepon (opsional)',
                hint: '08xxxxxxxxxx',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Nominal tagihan',
                hint: '0',
                prefixText: 'Rp ',
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                validator: Validators.transactionAmount,
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Tanggal transaksi',
                date: _transactionDate,
                onTap: () => _selectDate(dueDate: false),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Tanggal jatuh tempo',
                date: _dueDate,
                onTap: () => _selectDate(dueDate: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _noteController,
                label: 'Catatan (opsional)',
                hint: 'Tambahkan keterangan',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Text(
                'Nilai tagihan awal tidak dihitung sebagai pemasukan atau pengeluaran kas. Arus kas dicatat saat pembayaran diterima atau dilakukan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Simpan catatan',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      key: ValueKey(date),
      label: label,
      initialValue: AppDateFormat.fullDate(date),
      prefixIcon: Icons.calendar_today_outlined,
      readOnly: true,
      onTap: onTap,
      suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
    );
  }
}
