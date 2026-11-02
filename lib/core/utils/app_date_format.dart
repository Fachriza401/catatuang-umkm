abstract final class AppDateFormat {
  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String shortDate(DateTime date) {
    return '${date.day} ${_monthsShort[date.month - 1]}';
  }

  static String monthShort(DateTime date) => _monthsShort[date.month - 1];

  static String weekdayShort(DateTime date) => _daysShort[date.weekday - 1];

  static String fullDate(DateTime date) {
    return '${date.day} ${_monthsLong[date.month - 1]} ${date.year}';
  }

  static String greeting(DateTime now) {
    if (now.hour < 11) return 'Selamat pagi';
    if (now.hour < 15) return 'Selamat siang';
    if (now.hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  static String greetingEmoji(DateTime now) {
    if (now.hour < 11) return '🌅';
    if (now.hour < 15) return '☀️';
    if (now.hour < 18) return '🌇';
    return '🌙';
  }
}
