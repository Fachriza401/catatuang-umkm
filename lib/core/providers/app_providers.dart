import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../services/supabase_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(
    url: AppConfig.supabaseUrl,
    key: AppConfig.supabaseKey,
  );
});
