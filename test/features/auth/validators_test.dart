import 'package:catat_uang/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.verificationCode', () {
    test('menerima kode 6 digit', () {
      expect(Validators.verificationCode('123456'), isNull);
      expect(Validators.verificationCode(' 654321 '), isNull);
    });

    test('menolak kode kosong', () {
      expect(Validators.verificationCode(null), isNotNull);
      expect(Validators.verificationCode('   '), isNotNull);
    });

    test('menolak kode yang bukan 6 digit angka', () {
      expect(Validators.verificationCode('12345'), isNotNull);
      expect(Validators.verificationCode('1234567'), isNotNull);
      expect(Validators.verificationCode('12a456'), isNotNull);
    });
  });
}
