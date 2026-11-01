import 'package:catat_uang/features/debts/domain/entities/debt_status.dart';
import 'package:catat_uang/features/debts/domain/services/debt_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebtCalculator.remaining', () {
    test('tagihan baru memiliki sisa sebesar nominal awal', () {
      expect(DebtCalculator.remaining(amount: 500000, paidAmount: 0), 500000);
    });

    test('mengurangi total pembayaran yang telah diterima atau dilakukan', () {
      expect(
        DebtCalculator.remaining(amount: 500000, paidAmount: 125000),
        375000,
      );
    });

    test('tagihan lunas memiliki sisa nol', () {
      expect(DebtCalculator.remaining(amount: 500000, paidAmount: 500000), 0);
    });

    test('menolak nilai tagihan yang tidak valid', () {
      expect(
        () => DebtCalculator.remaining(amount: 0, paidAmount: 0),
        throwsArgumentError,
      );
      expect(
        () => DebtCalculator.remaining(amount: 100, paidAmount: -1),
        throwsArgumentError,
      );
      expect(
        () => DebtCalculator.remaining(amount: 100, paidAmount: 101),
        throwsArgumentError,
      );
    });
  });

  group('DebtCalculator.status', () {
    test('status belum dibayar untuk tagihan baru', () {
      expect(
        DebtCalculator.status(amount: 500000, paidAmount: 0),
        DebtStatus.unpaid,
      );
    });

    test('status sebagian untuk pembayaran parsial', () {
      expect(
        DebtCalculator.status(amount: 500000, paidAmount: 200000),
        DebtStatus.partial,
      );
    });

    test('status lunas setelah dibayar penuh', () {
      expect(
        DebtCalculator.status(amount: 500000, paidAmount: 500000),
        DebtStatus.paid,
      );
    });
  });

  group('DebtCalculator.applyPayment', () {
    test('mengakumulasi pembayaran sebagian', () {
      expect(
        DebtCalculator.applyPayment(
          amount: 500000,
          paidAmount: 100000,
          paymentAmount: 150000,
        ),
        250000,
      );
    });

    test('menerima pembayaran tepat sebesar sisa tagihan', () {
      expect(
        DebtCalculator.applyPayment(
          amount: 500000,
          paidAmount: 100000,
          paymentAmount: 400000,
        ),
        500000,
      );
    });

    test('menolak pembayaran nol atau negatif', () {
      for (final paymentAmount in [0, -1]) {
        expect(
          () => DebtCalculator.applyPayment(
            amount: 500000,
            paidAmount: 100000,
            paymentAmount: paymentAmount,
          ),
          throwsArgumentError,
        );
      }
    });

    test('menolak pembayaran melebihi sisa tagihan', () {
      expect(
        () => DebtCalculator.applyPayment(
          amount: 500000,
          paidAmount: 100000,
          paymentAmount: 400001,
        ),
        throwsArgumentError,
      );
    });
  });
}
