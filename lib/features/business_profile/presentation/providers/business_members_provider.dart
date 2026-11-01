import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/entities/business_member.dart';

final businessMembersProvider = FutureProvider.autoDispose
    .family<List<BusinessMember>, String>((ref, businessId) async {
  final client = ref.watch(supabaseServiceProvider).client;
  if (client == null) return const [];
  final response = await client.rpc('list_business_members');
  return (response as List)
      .map(
        (row) => BusinessMember.fromJson(
          Map<String, dynamic>.from((row as Map).cast<String, dynamic>()),
        ),
      )
      .toList(growable: false);
});
