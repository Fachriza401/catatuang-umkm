import 'package:catat_uang/features/calculator/domain/rupiah_calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RupiahCalculatorEngine', () {
    test('memakai nilai awal dan menerima input angka', () {
      final engine = RupiahCalculatorEngine(initialValue: 1500);
      expect(engine.value, 1500);

      engine.press('0');
      engine.press('0');
      expect(engine.value, 150000);
    });

    test('menghitung penjumlahan, pengurangan, perkalian, dan pembagian', () {
      final engine = RupiahCalculatorEngine();

      engine.press('5');
      engine.press('0');
      engine.press('0');
      engine.press('0');
      engine.press('+');
      engine.press('2');
      engine.press('5');
      engine.press('0');
      engine.press('0');
      engine.press('=');
      expect(engine.value, 7500);

      engine.press('AC');
      engine.press('1');
      engine.press('0');
      engine.press('0');
      engine.press('−');
      engine.press('4');
      engine.press('0');
      engine.press('=');
      expect(engine.value, 60);

      engine.press('AC');
      engine.press('1');
      engine.press('2');
      engine.press('×');
      engine.press('3');
      engine.press('=');
      expect(engine.value, 36);

      engine.press('AC');
      engine.press('9');
      engine.press('÷');
      engine.press('4');
      engine.press('=');
      expect(engine.value, 2);
    });

    test('menolak pembagian dengan nol dan menonaktifkan submit', () {
      final engine = RupiahCalculatorEngine();

      engine.press('8');
      engine.press('÷');
      engine.press('0');
      engine.press('=');

      expect(engine.value, 0);
      expect(engine.errorMessage, 'Tidak dapat membagi dengan nol.');
      expect(engine.canSubmit, isFalse);
    });

    test('menghitung persentase dan menghapus digit terakhir', () {
      final engine = RupiahCalculatorEngine(initialValue: 20000);

      engine.press('%');
      expect(engine.value, 200);

      engine.press('AC');
      engine.press('1');
      engine.press('2');
      engine.press('3');
      engine.press('⌫');
      expect(engine.value, 12);
    });

    test('tidak melebihi batas nominal dan digit maksimum', () {
      final engine = RupiahCalculatorEngine();

      for (var index = 0; index < 13; index++) {
        engine.press('9');
      }

      expect(engine.value, 999999999999);
      expect(engine.value, lessThanOrEqualTo(RupiahCalculatorEngine.maxAmount));
    });

    test('reset mengembalikan seluruh state', () {
      final engine = RupiahCalculatorEngine();

      engine.press('5');
      engine.press('+');
      engine.press('2');
      engine.press('AC');

      expect(engine.value, 0);
      expect(engine.storedValue, isNull);
      expect(engine.pendingOperator, isNull);
      expect(engine.errorMessage, isNull);
    });
  });
}
