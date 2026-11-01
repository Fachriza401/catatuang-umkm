class PaymentMethod {
  const PaymentMethod({required this.id, required this.label});

  final String id;
  final String label;

  static const all = <PaymentMethod>[
    PaymentMethod(id: 'cash', label: 'Tunai'),
    PaymentMethod(id: 'bank_transfer', label: 'Transfer Bank'),
    PaymentMethod(id: 'qris', label: 'QRIS'),
    PaymentMethod(id: 'ewallet', label: 'E-Wallet'),
    PaymentMethod(id: 'other', label: 'Lainnya'),
  ];

  static PaymentMethod? byId(String id) {
    for (final method in all) {
      if (method.id == id) return method;
    }
    return null;
  }

  static PaymentMethod get fallback => all.first;
}
