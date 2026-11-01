enum TransactionType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  const TransactionType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;

  static TransactionType fromStorage(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => TransactionType.expense,
    );
  }
}
