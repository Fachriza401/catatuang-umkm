import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

abstract final class AppUserMapper {
  static AppUser fromSupabase(User user) {
    final metadata = user.userMetadata;
    final metadataName = metadata?['full_name'];
    final fullName = metadataName is String ? metadataName.trim() : '';
    final email = user.email?.trim() ?? '';
    final fallbackName = email.isNotEmpty ? email.split('@').first : 'Pengguna';

    return AppUser(
      id: user.id,
      email: email,
      fullName: fullName.isNotEmpty ? fullName : fallbackName,
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  static AppUser? fromNullableSupabase(User? user) {
    if (user == null) return null;
    return fromSupabase(user);
  }
}
