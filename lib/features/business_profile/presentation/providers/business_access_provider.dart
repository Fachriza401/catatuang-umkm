import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/business_access.dart';

final businessAccessProvider = FutureProvider.autoDispose<BusinessAccess?>((
  ref,
) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return null;

  late final AppDatabase database;
  try {
    database = ref.watch(appDatabaseProvider);
  } on Object {
    return BusinessAccess.ownerFallback(user.id);
  }
  final cacheKey = 'business-access:${user.id}';
  String? cached;
  try {
    cached = await database.readPreference(cacheKey);
  } on Object {
    cached = null;
  }
  final client = ref.watch(supabaseServiceProvider).client;
  if (client != null) {
    try {
      final response = await client
          .rpc('get_my_business_access')
          .timeout(const Duration(seconds: 10));
      final access = BusinessAccess.fromJson(
        Map<String, dynamic>.from((response as Map).cast<String, dynamic>()),
      );
      await database.writePreference(cacheKey, jsonEncode(access.toJson()));
      return access;
    } on Object {
      // A cached business context keeps local data usable while offline.
    }
  }

  if (cached != null) {
    try {
      return BusinessAccess.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    } on Object {
      await database.removePreference(cacheKey);
    }
  }
  return BusinessAccess.ownerFallback(user.id);
});
