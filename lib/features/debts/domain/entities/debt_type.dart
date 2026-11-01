enum DebtType {
  receivable('receivable', 'Piutang', 'Pelanggan'),
  payable('payable', 'Utang', 'Pemasok');

  const DebtType(this.storageValue, this.label, this.contactLabel);

  final String storageValue;
  final String label;
  final String contactLabel;

  bool get isReceivable => this == DebtType.receivable;

  static DebtType fromStorage(String value) {
    return DebtType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => DebtType.payable,
    );
  }
}
