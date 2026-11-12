import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/business_access.dart';
import '../../domain/entities/business_profile.dart';
import '../providers/business_access_provider.dart';
import '../providers/business_profile_providers.dart';

class BusinessSettingsPage extends ConsumerStatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  ConsumerState<BusinessSettingsPage> createState() =>
      _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends ConsumerState<BusinessSettingsPage> {
  late final TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  bool _isUpdatingEmail = false;
  bool _isUpdatingPassword = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: ref.read(currentAuthUserProvider)?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(businessAccessProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (businessAccess) {
          if (businessAccess == null) {
            return const Center(child: Text('Sesi pengguna tidak tersedia.'));
          }
          final profile = ref.watch(
            businessProfileByIdProvider(businessAccess.businessId),
          );
          return profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text(error.toString())),
            data: (businessProfile) => _settingsContent(
              businessAccess,
              businessProfile ?? _emptyProfile(businessAccess.businessId),
            ),
          );
        },
      ),
    );
  }

  BusinessProfile _emptyProfile(String businessId) {
    return BusinessProfile(
      userId: businessId,
      businessName: '',
      ownerName: '',
      businessType: '',
      phone: '',
      address: '',
    );
  }

  Widget _settingsContent(BusinessAccess access, BusinessProfile profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BusinessHeroCard(access: access, profile: profile),
                const SizedBox(height: AppSpacing.xxl),
                _SettingsSection(
                  title: 'Profil usaha',
                  subtitle: 'Informasi usaha yang tampil di aplikasi',
                  icon: Icons.storefront_outlined,
                  children: [
                    _BusinessProfileEditor(
                      key: ValueKey(access.businessId),
                      businessId: access.businessId,
                      profile: profile,
                      enabled: access.canManageSettings,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _PlanSummary(access: access),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSection(
                  title: 'Keamanan akun',
                  subtitle: 'Email, password, dan penghapusan akun',
                  icon: Icons.shield_outlined,
                  tone: AppColors.textSecondary,
                  toneSoft: AppColors.surfaceMuted,
                  children: [_accountSettings()],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email akun',
            helperText:
                'Perubahan email perlu dikonfirmasi lewat tautan email.',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Ubah email',
          icon: Icons.mark_email_read_outlined,
          variant: AppButtonVariant.secondary,
          isLoading: _isUpdatingEmail,
          onPressed: _updateEmail,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password baru',
            helperText: 'Gunakan minimal 8 karakter.',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Ubah password',
          icon: Icons.password_rounded,
          variant: AppButtonVariant.secondary,
          isLoading: _isUpdatingPassword,
          onPressed: _updatePassword,
        ),
        const SizedBox(height: AppSpacing.xl),
        _DangerZone(isDeleting: _isDeletingAccount, onDelete: _deleteAccount),
      ],
    );
  }

  Future<void> _updateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Masukkan alamat email yang valid.');
      return;
    }
    setState(() => _isUpdatingEmail = true);
    try {
      final client = ref.read(supabaseServiceProvider).client;
      if (client == null) throw StateError('Sesi Supabase tidak tersedia.');
      await client.auth.updateUser(UserAttributes(email: email));
      _showMessage('Periksa email untuk menyelesaikan perubahan alamat.');
    } catch (error) {
      _showMessage('Email gagal diperbarui: $error');
    } finally {
      if (mounted) setState(() => _isUpdatingEmail = false);
    }
  }

  Future<void> _updatePassword() async {
    final password = _newPasswordController.text;
    if (password.length < 8) {
      _showMessage('Password baru minimal 8 karakter.');
      return;
    }
    setState(() => _isUpdatingPassword = true);
    try {
      final client = ref.read(supabaseServiceProvider).client;
      if (client == null) throw StateError('Sesi Supabase tidak tersedia.');
      await client.auth.updateUser(UserAttributes(password: password));
      _newPasswordController.clear();
      _showMessage('Password berhasil diperbarui.');
    } catch (error) {
      _showMessage('Password gagal diperbarui: $error');
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmation = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun dan data usaha?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tindakan ini permanen. Ketik HAPUS untuk mengonfirmasi.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmation,
              decoration: const InputDecoration(labelText: 'Ketik HAPUS'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              confirmation.text.trim() == 'HAPUS',
            ),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    confirmation.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      final client = ref.read(supabaseServiceProvider).client;
      if (client == null) throw StateError('Sesi Supabase tidak tersedia.');
      await client.functions.invoke('delete-account');
      await client.auth.signOut(scope: SignOutScope.local);
      if (mounted) context.go(AppRoutes.login);
    } catch (error) {
      _showMessage('Akun gagal dihapus: $error');
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BusinessHeroCard extends StatelessWidget {
  const _BusinessHeroCard({required this.access, required this.profile});

  final BusinessAccess access;
  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final businessName = profile.businessName.trim();
    final ownerName = profile.ownerName.trim();
    final businessType = profile.businessType.trim();
    final details = [
      ownerName,
      businessType,
    ].where((value) => value.isNotEmpty).join(' • ');
    final displayName = businessName.isEmpty ? 'Profil usaha' : businessName;
    final transactionValue = access.monthlyTransactionLimit == null
        ? '${access.transactionsUsed}'
        : '${access.transactionsUsed}/${access.monthlyTransactionLimit}';

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
              top: -48,
              right: -28,
              child: _GlowCircle(size: 160, opacity: 0.08),
            ),
            Positioned(
              bottom: -60,
              right: 64,
              child: _GlowCircle(size: 130, opacity: 0.05),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        alignment: Alignment.center,
                        child: businessName.isEmpty
                            ? const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 26,
                              )
                            : Text(
                                businessName.characters.first.toUpperCase(),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              details.isEmpty
                                  ? 'Lengkapi informasi profil usaha'
                                  : details,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.16),
                    height: 1,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.receipt_long_outlined,
                          label: 'Transaksi',
                          value: transactionValue,
                        ),
                      ),
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.image_outlined,
                          label: 'Bukti',
                          value: access.attachmentsEnabled
                              ? 'Aktif'
                              : 'Tidak aktif',
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.72)),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.tone = AppColors.primary,
    this.toneSoft = AppColors.primarySoft,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tone;
  final Color toneSoft;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: toneSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: tone, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _BusinessProfileEditor extends ConsumerStatefulWidget {
  const _BusinessProfileEditor({
    super.key,
    required this.businessId,
    required this.profile,
    required this.enabled,
  });

  final String businessId;
  final BusinessProfile profile;
  final bool enabled;

  @override
  ConsumerState<_BusinessProfileEditor> createState() =>
      _BusinessProfileEditorState();
}

class _BusinessProfileEditorState
    extends ConsumerState<_BusinessProfileEditor> {
  late final TextEditingController _businessName;
  late final TextEditingController _ownerName;
  late final TextEditingController _businessType;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _businessName = TextEditingController(text: widget.profile.businessName);
    _ownerName = TextEditingController(text: widget.profile.ownerName);
    _businessType = TextEditingController(text: widget.profile.businessType);
    _phone = TextEditingController(text: widget.profile.phone);
    _address = TextEditingController(text: widget.profile.address);
  }

  @override
  void didUpdateWidget(covariant _BusinessProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.businessName != widget.profile.businessName) {
      _businessName.text = widget.profile.businessName;
      _ownerName.text = widget.profile.ownerName;
      _businessType.text = widget.profile.businessType;
      _phone.text = widget.profile.phone;
      _address.text = widget.profile.address;
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _businessType.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessNameField = TextField(
      controller: _businessName,
      enabled: widget.enabled && !_saving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nama usaha',
        prefixIcon: Icon(Icons.storefront_outlined),
      ),
    );
    final ownerNameField = TextField(
      controller: _ownerName,
      enabled: widget.enabled && !_saving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nama pemilik',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
    );
    final businessTypeField = TextField(
      controller: _businessType,
      enabled: widget.enabled && !_saving,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Bidang usaha',
        prefixIcon: Icon(Icons.category_outlined),
      ),
    );
    final phoneField = TextField(
      controller: _phone,
      enabled: widget.enabled && !_saving,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Telepon',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );
    final addressField = TextField(
      controller: _address,
      enabled: widget.enabled && !_saving,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Alamat',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  businessNameField,
                  const SizedBox(height: AppSpacing.md),
                  ownerNameField,
                  const SizedBox(height: AppSpacing.md),
                  businessTypeField,
                  const SizedBox(height: AppSpacing.md),
                  phoneField,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: businessNameField),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: ownerNameField),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: businessTypeField),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: phoneField),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        addressField,
        if (widget.enabled) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? 'Menyimpan...' : 'Simpan profil usaha',
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    if (_businessName.text.trim().isEmpty) {
      _showMessage(context, 'Nama usaha wajib diisi.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(saveBusinessProfileUseCaseProvider)(
        BusinessProfile(
          userId: widget.businessId,
          businessName: _businessName.text.trim(),
          ownerName: _ownerName.text.trim(),
          businessType: _businessType.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
        ),
      );
      ref.invalidate(businessProfileByIdProvider(widget.businessId));
      if (!mounted) return;
      _showMessage(context, 'Profil usaha berhasil disimpan.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(context, 'Profil usaha gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.access});

  final BusinessAccess access;

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Penggunaan usaha',
      subtitle: 'Ringkasan penggunaan fitur usaha saat ini',
      icon: Icons.query_stats_outlined,
      tone: AppColors.info,
      toneSoft: AppColors.infoSoft,
      children: [
        _UsageMeter(
          label: 'Transaksi bulan ini',
          used: access.transactionsUsed,
          limit: access.monthlyTransactionLimit,
          color: AppColors.success,
        ),
        _FeatureRow(
          icon: Icons.image_outlined,
          label: 'Bukti transaksi privat',
          enabled: access.attachmentsEnabled,
        ),
      ],
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({
    required this.label,
    required this.used,
    required this.limit,
    required this.color,
  });

  final String label;
  final int used;
  final int? limit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit != null && limit! > 0;
    final ratio = hasLimit ? (used / limit!).clamp(0.0, 1.0).toDouble() : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(
              hasLimit ? '$used / $limit' : '$used / tanpa batas',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.surfaceMuted,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Icon(
          enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
          size: 18,
          color: enabled ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          enabled ? 'Aktif' : 'Tidak termasuk',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: enabled ? AppColors.success : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.isDeleting, required this.onDelete});

  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Hapus akun',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Menghapus akun juga menghapus data usaha, transaksi, dan '
            'lampiran secara permanen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: isDeleting ? 'Menghapus akun...' : 'Hapus akun',
            icon: Icons.delete_forever_outlined,
            variant: AppButtonVariant.danger,
            isLoading: isDeleting,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
