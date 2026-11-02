import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BalanceLockService {
  BalanceLockService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'catat_uang'),
          );

  static const _pinKey = 'catat_uang_balance_lock_pin';
  static const _lockedKey = 'catat_uang_balance_lock_locked';

  final FlutterSecureStorage _storage;

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> isLocked() async {
    return await _storage.read(key: _lockedKey) == 'true';
  }

  Future<void> setLocked(bool value) {
    return _storage.write(key: _lockedKey, value: value ? 'true' : 'false');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  Future<void> setPin(String pin) {
    return _storage.write(key: _pinKey, value: pin);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _lockedKey);
  }
}
