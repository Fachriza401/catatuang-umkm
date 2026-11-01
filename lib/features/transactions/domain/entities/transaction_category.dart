import 'transaction_type.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final TransactionType type;

  static const all = <TransactionCategory>[
    TransactionCategory(
      id: 'sales',
      label: 'Penjualan',
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'capital',
      label: 'Modal Usaha',
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'other_income',
      label: 'Pemasukan Lain',
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'ingredients',
      label: 'Bahan Baku',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'operations',
      label: 'Operasional',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'salary',
      label: 'Gaji Karyawan',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'rent',
      label: 'Sewa Tempat',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'transport',
      label: 'Transportasi',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'marketing',
      label: 'Pemasaran',
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'other_expense',
      label: 'Pengeluaran Lain',
      type: TransactionType.expense,
    ),
  ];

  static List<TransactionCategory> forType(TransactionType type) {
    return all.where((category) => category.type == type).toList();
  }

  static TransactionCategory? byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }

  static TransactionCategory fallbackFor(TransactionType type) {
    return forType(type).first;
  }
}
