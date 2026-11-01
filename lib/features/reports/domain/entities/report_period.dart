enum ReportPeriod {
  daily('Harian'),
  weekly('Mingguan'),
  monthly('Bulanan'),
  yearly('Tahunan'),
  custom('Rentang');

  const ReportPeriod(this.label);

  final String label;
}
