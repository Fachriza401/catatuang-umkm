import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.storageKey, FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'catat_uang'),
          );

  final String storageKey;
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: storageKey);

  @override
  Future<String?> accessToken() => _storage.read(key: storageKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: storageKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: storageKey, value: persistSessionString);
}
