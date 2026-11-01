import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/repositories/business_profile_repository.dart';
import '../mappers/business_profile_mapper.dart';

class BusinessProfileRepositoryImpl implements BusinessProfileRepository {
  BusinessProfileRepositoryImpl(this._supabaseService);

  static const _table = 'business_profiles';

  final SupabaseService _supabaseService;

  SupabaseClient get _client {
    if (!_supabaseService.isConfigured) {
      throw const ConfigurationFailure(
        'Supabase belum dikonfigurasi. Profil usaha tidak dapat disimpan.',
      );
    }
    final client = _supabaseService.client;
    if (client == null) {
      throw const ConfigurationFailure(
        'Layanan data belum siap. Silakan muat ulang aplikasi.',
      );
    }
    return client;
  }

  @override
  Future<BusinessProfile?> getByUserId(String userId) async {
    try {
      var businessId = userId;
      if (_client.auth.currentUser?.id == userId) {
        try {
          final access = await _client
              .rpc('get_my_business_access')
              .timeout(const Duration(seconds: 10));
          businessId = (access as Map)['business_id'] as String? ?? userId;
        } on Object {
          businessId = userId;
        }
      }
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', businessId)
          .maybeSingle();
      if (response == null) return null;
      return BusinessProfileMapper.fromJson(response);
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async {
    try {
      final response = await _client.rpc(
        'update_business_profile',
        params: {
          'p_business_name': profile.businessName,
          'p_owner_name': profile.ownerName,
          'p_business_type': profile.businessType,
          'p_phone': profile.phone,
          'p_address': profile.address,
        },
      );
      return BusinessProfileMapper.fromJson(
        Map<String, dynamic>.from((response as Map).cast<String, dynamic>()),
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } catch (error) {
      throw _mapUnexpectedError(error);
    }
  }

  AppFailure _mapPostgrestException(PostgrestException error) {
    final code = error.code ?? '';
    if (code == '42P01' || code == 'PGRST205') {
      return DatabaseFailure(
        'Tabel profil usaha belum tersedia di Supabase. Jalankan skrip '
        'database CatatUang terlebih dahulu.',
        code: code,
        cause: error,
      );
    }
    if (code == '42501' || code == 'PGRST301') {
      return DatabaseFailure(
        'Anda tidak memiliki akses untuk menyimpan profil usaha.',
        code: code,
        cause: error,
      );
    }
    if (code == '23505') {
      return DatabaseFailure(
        'Profil usaha untuk akun ini sudah ada.',
        code: code,
        cause: error,
      );
    }
    return DatabaseFailure(
      'Profil usaha gagal diproses. Silakan coba lagi.',
      code: code,
      cause: error,
    );
  }

  AppFailure _mapUnexpectedError(Object error) {
    if (error is AppFailure) return error;
    return NetworkFailure(
      'Tidak dapat terhubung ke layanan data. Periksa koneksi internet Anda.',
      cause: error,
    );
  }
}
