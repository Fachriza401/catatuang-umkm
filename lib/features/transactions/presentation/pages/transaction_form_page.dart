import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../calculator/presentation/widgets/rupiah_calculator_panel.dart';
import '../../../business_profile/presentation/providers/business_access_provider.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/transaction_category.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_sync_status.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/usecases/transaction_use_cases.dart';
import '../providers/transaction_providers.dart';
import '../utils/transaction_ui.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({
    super.key,
    this.transactionId,
    this.initialType = TransactionType.expense,
    this.initialAmount = 0,
  });

  final String? transactionId;
  final TransactionType initialType;
  final int initialAmount;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  late TransactionType _type;
  late DateTime _selectedDate;
  String _categoryId = '';
  String _paymentMethodId = PaymentMethod.fallback.id;
  String? _existingAttachmentPath;
  String? _existingAttachmentUrl;
  String? _pickedAttachmentPath;
  MoneyTransaction? _transaction;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categoryId = TransactionCategory.fallbackFor(_type).id;
    _selectedDate = DateTime.now();
    _dateController.text = AppDateFormat.fullDate(_selectedDate);
    if (widget.initialAmount > 0) {
      _amountController.text = CurrencyFormatter.input(widget.initialAmount);
    }
    if (widget.isEditing) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransaction());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await ref.read(getTransactionUseCaseProvider)(
        widget.transactionId!,
      );
      if (!mounted) return;
      if (transaction == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Transaksi tidak ditemukan atau sudah dihapus.';
        });
        return;
      }
      _applyTransaction(transaction);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is AppFailure
            ? error.message
            : 'Transaksi gagal dimuat. Silakan coba lagi.';
      });
    }
  }

  void _applyTransaction(MoneyTransaction transaction) {
    final category = TransactionCategory.byId(transaction.categoryId);
    final paymentMethod = PaymentMethod.byId(transaction.paymentMethodId);
    setState(() {
      _transaction = transaction;
      _type = transaction.type;
      _categoryId = category?.id ?? TransactionCategory.fallbackFor(_type).id;
      _paymentMethodId = paymentMethod?.id ?? PaymentMethod.fallback.id;
      _selectedDate = transaction.transactionDate;
      _dateController.text = AppDateFormat.fullDate(_selectedDate);
      _amountController.text = CurrencyFormatter.input(transaction.amount);
      _descriptionController.text = transaction.description;
      _existingAttachmentPath = transaction.attachmentPath;
      _existingAttachmentUrl = transaction.attachmentUrl;
      _pickedAttachmentPath = null;
      _isLoading = false;
    });
  }

  void _changeType(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _categoryId = TransactionCategory.fallbackFor(type).id;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text = AppDateFormat.fullDate(picked);
    });
  }

  Future<void> _openCalculator() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransactionCalculatorSheet(
        initialAmount: CurrencyFormatter.parse(_amountController.text) ?? 0,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _amountController.text = CurrencyFormatter.input(result);
      _errorMessage = null;
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final path = await ref.read(attachmentServiceProvider).pickImagePath();
      if (path == null || !mounted) return;
      setState(() => _pickedAttachmentPath = path);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Gagal memilih gambar. Periksa izin galeri lalu coba lagi.',
      );
    }
  }

  void _removeAttachment() {
    setState(() {
      _pickedAttachmentPath = null;
      _existingAttachmentPath = null;
      _existingAttachmentUrl = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving || _isDeleting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Nominal transaksi tidak valid.');
      return;
    }

    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
      setState(() => _errorMessage = 'Sesi Anda berakhir. Silakan masuk lagi.');
      return;
    }
    final access = ref
        .read(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null || !access.canCreateTransactions) {
      setState(
        () => _errorMessage = 'Akses pencatatan transaksi tidak tersedia.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      var attachmentPath = _existingAttachmentPath;
      if (_pickedAttachmentPath != null) {
        attachmentPath = await ref
            .read(attachmentServiceProvider)
            .persist(_pickedAttachmentPath!);
      }
      final attachmentUrl = _pickedAttachmentPath == null
          ? _existingAttachmentUrl
          : null;

      if (_transaction == null) {
        await ref.read(createTransactionUseCaseProvider)(
          TransactionDraft(
            userId: access.businessId,
            type: _type,
            amount: amount,
            categoryId: _categoryId,
            paymentMethodId: _paymentMethodId,
            transactionDate: _selectedDate,
            description: _descriptionController.text.trim(),
            attachmentPath: attachmentPath,
          ),
        );
        if (!mounted) return;
        AppSnackbar.success(context, '${_type.label} berhasil dicatat.');
        context.pop();
      } else {
        await ref.read(updateTransactionUseCaseProvider)(
          MoneyTransaction(
            id: _transaction!.id,
            userId: _transaction!.userId,
            type: _type,
            amount: amount,
            categoryId: _categoryId,
            paymentMethodId: _paymentMethodId,
            transactionDate: _selectedDate,
            description: _descriptionController.text.trim(),
            attachmentPath: attachmentPath,
            attachmentUrl: attachmentUrl,
            createdAt: _transaction!.createdAt,
            updatedAt: DateTime.now(),
            syncStatus: TransactionSyncStatus.pending,
          ),
        );
        if (!mounted) return;
        AppSnackbar.success(context, 'Transaksi berhasil diperbarui.');
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is AppFailure
            ? error.message
            : 'Transaksi gagal disimpan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final transaction = _transaction;
    if (transaction == null || _isSaving || _isDeleting) return;
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return;
    final access = ref
        .read(businessAccessProvider)
        .when(
          data: (value) => value,
          loading: () => null,
          error: (_, _) => null,
        );
    if (access == null || !access.canCreateTransactions) {
      AppSnackbar.error(context, 'Akses penghapusan transaksi tidak tersedia.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: const Text(
            'Transaksi ini akan dihapus dari dashboard. Tindakan ini tidak '
            'dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(deleteTransactionUseCaseProvider)(
        DeleteTransactionParams(id: transaction.id, userId: transaction.userId),
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Transaksi berhasil dihapus.');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is AppFailure
            ? error.message
            : 'Transaksi gagal dihapus. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Transaksi' : 'Tambah ${_type.label}';
    final isBusy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: isBusy ? null : _delete,
              tooltip: 'Hapus transaksi',
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: AppLoadingIndicator(message: 'Memuat transaksi...'),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            AppStatusBanner(
                              message: _errorMessage!,
                              tone: AppStatusTone.error,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _TypeSelector(
                            selected: _type,
                            onChanged: isBusy ? null : _changeType,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            showShadow: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nominal Transaksi',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  controller: _amountController,
                                  label: 'Nominal',
                                  hint: '0',
                                  prefixText: 'Rp ',
                                  suffixIcon: IconButton(
                                    tooltip: 'Buka kalkulator',
                                    onPressed: isBusy ? null : _openCalculator,
                                    icon: const Icon(Icons.calculate_outlined),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  inputFormatters: [RupiahInputFormatter()],
                                  validator: Validators.transactionAmount,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Nominal disimpan dalam rupiah tanpa desimal.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Kategori',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final category
                                  in TransactionCategory.forType(_type))
                                ChoiceChip(
                                  selected: _categoryId == category.id,
                                  onSelected: isBusy
                                      ? null
                                      : (_) {
                                          setState(() {
                                            _categoryId = category.id;
                                          });
                                        },
                                  avatar: Icon(category.icon, size: 16),
                                  label: Text(category.label),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          DropdownButtonFormField<String>(
                            initialValue: _paymentMethodId,
                            decoration: const InputDecoration(
                              labelText: 'Metode pembayaran',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            items: [
                              for (final method in PaymentMethod.all)
                                DropdownMenuItem(
                                  value: method.id,
                                  child: Row(
                                    children: [
                                      Icon(method.icon, size: 18),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(method.label),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: isBusy
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => _paymentMethodId = value);
                                  },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _dateController,
                            label: 'Tanggal transaksi',
                            readOnly: true,
                            prefixIcon: Icons.calendar_today_outlined,
                            suffixIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                            ),
                            onTap: isBusy ? null : _pickDate,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Deskripsi (opsional)',
                            hint: 'Contoh: Penjualan nasi kotak siang',
                            maxLines: 3,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Bukti Transaksi (opsional)',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _AttachmentPicker(
                            localPath:
                                _pickedAttachmentPath ??
                                _existingAttachmentPath,
                            remoteUrl: _existingAttachmentUrl,
                            enabled: !isBusy,
                            onPick: _pickAttachment,
                            onRemove: _removeAttachment,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppButton(
                            label: widget.isEditing
                                ? 'Simpan Perubahan'
                                : 'Simpan ${_type.label}',
                            icon: Icons.check_rounded,
                            isLoading: _isSaving,
                            onPressed: isBusy ? null : _save,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Batal',
                            variant: AppButtonVariant.ghost,
                            onPressed: isBusy ? null : () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeOption(
            type: TransactionType.income,
            icon: Icons.south_west_rounded,
            color: AppColors.success,
            softColor: AppColors.successSoft,
            isSelected: selected == TransactionType.income,
            onTap: onChanged == null
                ? null
                : () => onChanged!(TransactionType.income),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TypeOption(
            type: TransactionType.expense,
            icon: Icons.north_east_rounded,
            color: AppColors.danger,
            softColor: AppColors.dangerSoft,
            isSelected: selected == TransactionType.expense,
            onTap: onChanged == null
                ? null
                : () => onChanged!(TransactionType.expense),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.type,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionType type;
  final IconData icon;
  final Color color;
  final Color softColor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? softColor : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                type.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.localPath,
    required this.remoteUrl,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? localPath;
  final String? remoteUrl;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get hasAttachment =>
      (localPath != null && localPath!.isNotEmpty) ||
      (remoteUrl != null && remoteUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!hasAttachment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Pilih Bukti Transaksi',
            icon: Icons.image_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: enabled ? onPick : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pilih foto dari galeri. Bukti akan diunggah saat sinkronisasi cloud.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: _AttachmentPreview(localPath: localPath, remoteUrl: remoteUrl),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ganti',
                icon: Icons.swap_horiz_rounded,
                variant: AppButtonVariant.secondary,
                isExpanded: false,
                onPressed: enabled ? onPick : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Hapus',
                icon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.ghost,
                isExpanded: false,
                onPressed: enabled ? onRemove : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttachmentPreview extends ConsumerWidget {
  const _AttachmentPreview({required this.localPath, required this.remoteUrl});

  final String? localPath;
  final String? remoteUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = Container(
      height: 160,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textMuted,
        size: 32,
      ),
    );

    if (localPath != null && localPath!.isNotEmpty) {
      return Image.file(
        File(localPath!),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      return ref
          .watch(signedTransactionAttachmentProvider(remoteUrl!))
          .when(
            data: (signedUrl) => signedUrl == null
                ? placeholder
                : Image.network(
                    signedUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => placeholder,
                  ),
            loading: () => placeholder,
            error: (error, stackTrace) => placeholder,
          );
    }

    return placeholder;
  }
}

class _TransactionCalculatorSheet extends StatelessWidget {
  const _TransactionCalculatorSheet({required this.initialAmount});

  final int initialAmount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Kalkulator nominal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup kalkulator',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RupiahCalculatorPanel(
              initialValue: initialAmount,
              submitLabel: 'Gunakan hasil',
              onSubmit: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );
  }
}
