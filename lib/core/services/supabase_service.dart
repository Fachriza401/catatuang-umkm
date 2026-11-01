import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/secure_local_storage.dart';

class SupabaseService {
  SupabaseService({required this.url, required this.key});

  final String url;
  final String key;

  bool _isInitialized = false;
  Future<void>? _initialization;

  bool get isConfigured => url.isNotEmpty && key.isNotEmpty;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  Future<void> initialize() {
    return _initialization ??= _initialize().whenComplete(() {
      if (!_isInitialized) _initialization = null;
    });
  }

  Future<void> _initialize() async {
    if (!isConfigured || _isInitialized) return;

    await Supabase.initialize(
      url: url,
      publishableKey: key,
      debug: kDebugMode,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(
          storageKey: 'catat_uang_supabase_session',
        ),
        detectSessionInUri: true,
      ),
    );

    _isInitialized = true;
  }
}
