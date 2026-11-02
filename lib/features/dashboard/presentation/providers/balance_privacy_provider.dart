import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/balance_lock_service.dart';

class BalancePrivacyState {
  const BalancePrivacyState({required this.isLocked, required this.hasPin});

  final bool isLocked;
  final bool hasPin;

  BalancePrivacyState copyWith({bool? isLocked, bool? hasPin}) {
    return BalancePrivacyState(
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

final balanceLockServiceProvider = Provider<BalanceLockService>((ref) {
  return BalanceLockService();
});

class BalancePrivacyController extends AsyncNotifier<BalancePrivacyState> {
  BalanceLockService get _service => ref.read(balanceLockServiceProvider);

  @override
  Future<BalancePrivacyState> build() async {
    final service = ref.watch(balanceLockServiceProvider);
    final hasPin = await service.hasPin();
    final locked = hasPin && await service.isLocked();
    return BalancePrivacyState(isLocked: locked, hasPin: hasPin);
  }

  Future<void> lock() async {
    final current = state.value;
    if (current == null) return;
    await _service.setLocked(true);
    state = AsyncData(current.copyWith(isLocked: true));
  }

  Future<bool> unlockWithPin(String pin) async {
    final current = state.value;
    if (current == null) return false;
    final valid = await _service.verifyPin(pin);
    if (!valid) return false;
    await _service.setLocked(false);
    state = AsyncData(current.copyWith(isLocked: false, hasPin: true));
    return true;
  }

  Future<void> createPinAndUnlock(String pin) async {
    final current = state.value;
    final next =
        current ?? const BalancePrivacyState(isLocked: true, hasPin: false);
    await _service.setPin(pin);
    await _service.setLocked(false);
    state = AsyncData(next.copyWith(isLocked: false, hasPin: true));
  }

  Future<void> clearPinAndUnlock() async {
    final current = state.value;
    final next =
        current ?? const BalancePrivacyState(isLocked: true, hasPin: false);
    await _service.clearPin();
    state = AsyncData(next.copyWith(isLocked: false, hasPin: false));
  }
}

final balancePrivacyProvider =
    AsyncNotifierProvider<BalancePrivacyController, BalancePrivacyState>(
      BalancePrivacyController.new,
    );
