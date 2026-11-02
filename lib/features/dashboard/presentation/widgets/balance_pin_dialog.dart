import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class BalancePinDialogResult {
  const BalancePinDialogResult.submit(this.pin) : forgot = false;
  const BalancePinDialogResult.forgot() : pin = null, forgot = true;

  final String? pin;
  final bool forgot;
}

class BalancePinDialog extends StatefulWidget {
  const BalancePinDialog({super.key, required this.isCreating});

  final bool isCreating;

  static Future<BalancePinDialogResult?> show(
    BuildContext context, {
    required bool isCreating,
  }) {
    return showDialog<BalancePinDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BalancePinDialog(isCreating: isCreating),
    );
  }

  @override
  State<BalancePinDialog> createState() => _BalancePinDialogState();
}

class _BalancePinDialogState extends State<BalancePinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'PIN harus 4 sampai 6 angka.');
      return;
    }
    if (widget.isCreating && pin != _confirmController.text.trim()) {
      setState(() => _error = 'Konfirmasi PIN tidak sama.');
      return;
    }
    Navigator.of(context).pop(BalancePinDialogResult.submit(pin));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(
          widget.isCreating
              ? Icons.lock_person_rounded
              : Icons.lock_open_rounded,
          color: AppColors.primaryDeep,
        ),
      ),
      title: Text(
        widget.isCreating ? 'Buat PIN saldo' : 'Buka kunci saldo',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isCreating
                ? 'PIN ini dipakai untuk membuka saldo yang terkunci. '
                      'Jangan bagikan PIN kepada orang lain.'
                : 'Masukkan PIN untuk menampilkan kembali nominal saldo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _pinController,
            label: widget.isCreating ? 'PIN baru' : 'PIN saldo',
            hint: '4-6 angka',
            prefixIcon: Icons.pin_outlined,
            obscureText: true,
            keyboardType: TextInputType.number,
            textInputAction: widget.isCreating
                ? TextInputAction.next
                : TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onFieldSubmitted: widget.isCreating ? null : (_) => _submit(),
          ),
          if (widget.isCreating) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmController,
              label: 'Ulangi PIN',
              hint: 'Ketik ulang PIN',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        if (!widget.isCreating)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const BalancePinDialogResult.forgot()),
            child: const Text('Lupa PIN?'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        AppButton(
          label: widget.isCreating ? 'Simpan PIN' : 'Buka',
          icon: widget.isCreating
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          isExpanded: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}
