import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_banner.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../domain/entities/business_profile.dart';
import '../providers/business_profile_providers.dart';

class BusinessProfileSetupPage extends ConsumerStatefulWidget {
  const BusinessProfileSetupPage({super.key});

  @override
  ConsumerState<BusinessProfileSetupPage> createState() =>
      _BusinessProfileSetupPageState();
}

class _BusinessProfileSetupPageState
    extends ConsumerState<BusinessProfileSetupPage> {
  static const _businessTypes = [
    'Kuliner',
    'Fashion & Pakaian',
    'Retail / Toko',
    'Jasa',
    'Kerajinan',
    'Pertanian',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _businessType;
  BusinessProfile? _existingProfile;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ownerController.text = ref.read(currentAuthUserProvider)?.fullName ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(businessProfileControllerProvider.future);
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _existingProfile = profile;
          _businessNameController.text = profile.businessName;
          _ownerController.text = profile.ownerName;
          _phoneController.text = profile.phone;
          _addressController.text = profile.address;
          _businessType = _businessTypes.contains(profile.businessType)
              ? profile.businessType
              : _businessTypes.last;
        });
      }
    } catch (_) {
      // Form tetap dapat digunakan; error akan muncul saat menyimpan.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    FocusScope.of(context).unfocus();

    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
      setState(() => _errorMessage = 'Sesi Anda berakhir. Silakan masuk lagi.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final profile = BusinessProfile(
        id: _existingProfile?.id,
        userId: user.id,
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        businessType: _businessType!,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      await ref.read(businessProfileControllerProvider.notifier).save(profile);
      if (!mounted) return;
      AppSnackbar.success(context, 'Profil usaha berhasil disimpan.');
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is AppFailure
            ? error.message
            : 'Profil usaha gagal disimpan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(signOutUseCaseProvider)(const NoParams());
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        error is AppFailure ? error.message : 'Gagal keluar dari akun.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Lengkapi profil usaha',
      subtitle:
          'Data ini membantu CatatUang menyesuaikan pembukuan untuk usaha Anda.',
      footer: Column(
        children: [
          Text(
            'Profil dapat diubah kapan saja.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: _isSaving ? null : _logout,
            child: const Text('Keluar dari akun'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_errorMessage != null) ...[
              AppStatusBanner(
                message: _errorMessage!,
                tone: AppStatusTone.error,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              controller: _businessNameController,
              label: 'Nama usaha',
              hint: 'Contoh: Warung Bu Sari',
              prefixIcon: Icons.storefront_outlined,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: Validators.businessName,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _ownerController,
              label: 'Nama pemilik',
              hint: 'Nama penanggung jawab usaha',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: Validators.fullName,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              key: ValueKey(_businessType),
              initialValue: _businessType,
              decoration: const InputDecoration(
                labelText: 'Jenis usaha',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final type in _businessTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _businessType = value),
              validator: Validators.businessType,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _phoneController,
              label: 'Nomor telepon',
              hint: '08xxxxxxxxxx',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _addressController,
              label: 'Alamat usaha',
              hint: 'Alamat lengkap usaha Anda',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: Validators.address,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Simpan & Lanjutkan',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
