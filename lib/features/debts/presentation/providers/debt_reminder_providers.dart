import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/debt.dart';
import 'debt_providers.dart';

final debtReminderTickProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield 0;
  yield* Stream<int>.periodic(const Duration(minutes: 1), (tick) => tick + 1);
});

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isDebtDue(Debt debt, {DateTime? now}) {
  if (debt.remainingAmount <= 0) return false;
  final today = dateOnly(now ?? DateTime.now());
  return !dateOnly(debt.dueDate).isAfter(today);
}

bool isDebtDueSoon(Debt debt, {DateTime? now}) {
  if (debt.remainingAmount <= 0) return false;
  final today = dateOnly(now ?? DateTime.now());
  final due = dateOnly(debt.dueDate);
  return due.difference(today).inDays <= 3;
}

int overdueDays(Debt debt, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final due = dateOnly(debt.dueDate);
  final difference = today.difference(due).inDays;
  return difference > 0 ? difference : 0;
}

List<Debt> dueDebts(List<Debt> debts, {DateTime? now}) {
  final result = debts.where((debt) => isDebtDue(debt, now: now)).toList();
  result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return result;
}

List<Debt> dueSoonDebts(List<Debt> debts, {DateTime? now}) {
  final result = debts.where((debt) {
    if (debt.remainingAmount <= 0) return false;
    final today = dateOnly(now ?? DateTime.now());
    final due = dateOnly(debt.dueDate);
    final difference = due.difference(today).inDays;
    return difference >= 0 && difference <= 3;
  }).toList();
  result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return result;
}

final dueDebtsProvider = Provider.autoDispose
    .family<AsyncValue<List<Debt>>, String>((ref, businessId) {
      ref.watch(debtReminderTickProvider);
      return ref
          .watch(debtsProvider(businessId))
          .whenData((debts) => dueDebts(debts));
    });

final dueSoonDebtsProvider = Provider.autoDispose
    .family<AsyncValue<List<Debt>>, String>((ref, businessId) {
      ref.watch(debtReminderTickProvider);
      return ref
          .watch(debtsProvider(businessId))
          .whenData((debts) => dueSoonDebts(debts));
    });
