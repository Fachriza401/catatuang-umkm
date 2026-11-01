class RupiahCalculatorEngine {
  RupiahCalculatorEngine({int initialValue = 0})
    : _display = initialValue <= 0 ? '0' : initialValue.toString();

  static const maxAmount = 999999999999;
  static const maxDigits = 12;
  static const operatorKeys = <String>['+', '−', '×', '÷'];

  String _display;
  int? _storedValue;
  String? _pendingOperator;
  bool _replaceNext = false;
  String? _errorMessage;

  String get display => _display;
  int get value => int.tryParse(_display) ?? 0;
  int? get storedValue => _storedValue;
  String? get pendingOperator => _pendingOperator;
  String? get errorMessage => _errorMessage;
  bool get canSubmit => _errorMessage == null && value > 0;

  void reset() {
    _display = '0';
    _storedValue = null;
    _pendingOperator = null;
    _replaceNext = false;
    _errorMessage = null;
  }

  void press(String key) {
    _errorMessage = null;
    switch (key) {
      case 'AC':
        reset();
      case '⌫':
        _backspace();
      case '%':
        _percent();
      case '=':
        _calculate();
      case '+':
      case '−':
      case '×':
      case '÷':
        _operator(key);
      default:
        _append(key);
    }
  }

  void _backspace() {
    if (_replaceNext) {
      _display = '0';
      _replaceNext = false;
      return;
    }
    _display = _display.length <= 1
        ? '0'
        : _display.substring(0, _display.length - 1);
  }

  void _percent() {
    _display = '${(value / 100).round()}';
    _replaceNext = true;
  }

  void _operator(String operator) {
    if (_pendingOperator != null && !_replaceNext) {
      _calculate();
      if (_errorMessage != null) return;
    }
    _storedValue = value;
    _pendingOperator = operator;
    _replaceNext = true;
  }

  void _append(String key) {
    final digits = key.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final combined = _replaceNext || _display == '0'
        ? digits
        : '$_display$digits';
    final normalized = combined.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (normalized.length > maxDigits) return;
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed > maxAmount) return;
    _display = normalized;
    _replaceNext = false;
  }

  void _calculate() {
    final left = _storedValue;
    final operator = _pendingOperator;
    if (left == null || operator == null) return;
    final right = value;
    late final double result;
    switch (operator) {
      case '+':
        result = (left + right).toDouble();
      case '−':
        result = (left - right).toDouble();
      case '×':
        result = (left * right).toDouble();
      case '÷':
        if (right == 0) {
          _fail('Tidak dapat membagi dengan nol.');
          return;
        }
        result = left / right;
      default:
        return;
    }
    if (!result.isFinite || result < 0 || result > maxAmount) {
      _fail('Hasil harus antara Rp0 dan batas nominal.');
      return;
    }
    _display = '${result.round()}';
    _storedValue = null;
    _pendingOperator = null;
    _replaceNext = true;
  }

  void _fail(String message) {
    _errorMessage = message;
    _storedValue = null;
    _pendingOperator = null;
    _display = '0';
    _replaceNext = true;
  }
}
