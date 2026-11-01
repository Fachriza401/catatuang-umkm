import 'currency_formatter.dart';

abstract final class Validators {
  static final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final _namePattern = RegExp(r"^[A-Za-z.'\-\s]+$");
  static final _phonePattern = RegExp(r'^\+?[0-9\s\-()]{9,20}$');

  static String? required(String? value, {String label = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, label: 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, label: 'Password');
    if (requiredError != null) return requiredError;
    final password = value!;
    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus mengandung huruf besar.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password harus mengandung huruf kecil.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password harus mengandung angka.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = required(value, label: 'Konfirmasi password');
    if (requiredError != null) return requiredError;
    if (value != password) {
      return 'Konfirmasi password tidak sama.';
    }
    return null;
  }

  static String? verificationCode(String? value) {
    final requiredError = required(value, label: 'Kode verifikasi');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^\d{6}$').hasMatch(value!.trim())) {
      return 'Kode verifikasi harus 6 digit.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = required(value, label: 'Nama lengkap');
    if (requiredError != null) return requiredError;
    final name = value!.trim();
    if (name.length < 3) {
      return 'Nama minimal 3 karakter.';
    }
    if (!_namePattern.hasMatch(name)) {
      return 'Nama hanya boleh berisi huruf dan spasi.';
    }
    return null;
  }

  static String? businessName(String? value) {
    final requiredError = required(value, label: 'Nama usaha');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 3) {
      return 'Nama usaha minimal 3 karakter.';
    }
    return null;
  }

  static String? businessType(String? value) {
    return required(value, label: 'Jenis usaha');
  }

  static String? phone(String? value) {
    final requiredError = required(value, label: 'Nomor telepon');
    if (requiredError != null) return requiredError;
    if (!_phonePattern.hasMatch(value!.trim())) {
      return 'Nomor telepon tidak valid.';
    }
    return null;
  }

  static String? address(String? value) {
    final requiredError = required(value, label: 'Alamat usaha');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 5) {
      return 'Alamat minimal 5 karakter.';
    }
    return null;
  }

  static String? transactionAmount(String? value) {
    final amount = CurrencyFormatter.parse(value);
    if (amount == null) {
      return 'Nominal wajib diisi.';
    }
    if (amount <= 0) {
      return 'Nominal harus lebih dari Rp0.';
    }
    if (amount > 999999999999) {
      return 'Nominal melebihi batas maksimal transaksi.';
    }
    return null;
  }
}
