enum DebtStatus {
  unpaid('Belum dibayar'),
  partial('Sebagian'),
  paid('Lunas');

  const DebtStatus(this.label);

  final String label;
}
