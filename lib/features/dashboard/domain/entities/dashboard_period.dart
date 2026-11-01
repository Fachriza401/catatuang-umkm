enum DashboardPeriod {
  daily('Harian', 'Hari ini', '7 hari terakhir'),
  weekly('Mingguan', 'Minggu ini', '6 minggu terakhir'),
  monthly('Bulanan', 'Bulan ini', '6 bulan terakhir'),
  yearly('Tahunan', 'Tahun ini', '12 bulan terakhir');

  const DashboardPeriod(this.label, this.summaryLabel, this.chartLabel);

  final String label;
  final String summaryLabel;
  final String chartLabel;
}
