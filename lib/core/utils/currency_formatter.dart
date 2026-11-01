import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _decimal = NumberFormat.decimalPattern('id_ID');

  static String format(int amount) => _currency.format(amount);

  static String input(int amount) => _decimal.format(amount);

  static int? parse(String? text) {
    if (text == null) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}
