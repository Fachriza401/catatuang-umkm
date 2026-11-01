import '../entities/debt_status.dart';

abstract final class DebtCalculator {
  static int remaining({required int amount, required int paidAmount}) {
    if (amount <= 0 || paidAmount < 0 || paidAmount > amount) {
      throw ArgumentError('Nilai tagihan atau pembayaran tidak valid.');
    }
    return amount - paidAmount;
  }

  static DebtStatus status({required int amount, required int paidAmount}) {
    final remainingAmount = remaining(amount: amount, paidAmount: paidAmount);
    if (remainingAmount == 0) return DebtStatus.paid;
    if (paidAmount > 0) return DebtStatus.partial;
    return DebtStatus.unpaid;
  }

  static int applyPayment({
    required int amount,
    required int paidAmount,
    required int paymentAmount,
  }) {
    final outstanding = remaining(amount: amount, paidAmount: paidAmount);
    if (paymentAmount <= 0) {
      throw ArgumentError('Pembayaran harus lebih dari Rp 0.');
    }
    if (paymentAmount > outstanding) {
      throw ArgumentError('Pembayaran melebihi sisa tagihan.');
    }
    return paidAmount + paymentAmount;
  }
}
