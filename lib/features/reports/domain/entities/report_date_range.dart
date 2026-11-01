import 'report_period.dart';

class ReportDateRange {
  const ReportDateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  DateTime get endInclusive => endExclusive.subtract(const Duration(days: 1));

  String get label => start.year == endInclusive.year &&
          start.month == endInclusive.month &&
          start.day == endInclusive.day
      ? _format(start)
      : '${_format(start)} s/d ${_format(endInclusive)}';

  factory ReportDateRange.forPeriod({
    required ReportPeriod period,
    required DateTime anchor,
    ReportDateRange? customRange,
  }) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (period) {
      ReportPeriod.daily => ReportDateRange(
          start: day,
          endExclusive: day.add(const Duration(days: 1)),
        ),
      ReportPeriod.weekly => _weekRange(day),
      ReportPeriod.monthly => ReportDateRange(
          start: DateTime(day.year, day.month),
          endExclusive: DateTime(day.year, day.month + 1),
        ),
      ReportPeriod.yearly => ReportDateRange(
          start: DateTime(day.year),
          endExclusive: DateTime(day.year + 1),
        ),
      ReportPeriod.custom => customRange ??
          ReportDateRange(
            start: day,
            endExclusive: day.add(const Duration(days: 1)),
          ),
    };
  }

  ReportDateRange shift(int periods, ReportPeriod period) {
    if (period == ReportPeriod.custom) {
      final duration = endExclusive.difference(start);
      final shiftedStart = start.add(Duration(days: duration.inDays * periods));
      return ReportDateRange(
        start: shiftedStart,
        endExclusive: shiftedStart.add(duration),
      );
    }

    final shiftedAnchor = switch (period) {
      ReportPeriod.daily => start.add(Duration(days: periods)),
      ReportPeriod.weekly => start.add(Duration(days: periods * 7)),
      ReportPeriod.monthly => DateTime(start.year, start.month + periods),
      ReportPeriod.yearly => DateTime(start.year + periods, start.month),
      ReportPeriod.custom => start,
    };
    return ReportDateRange.forPeriod(period: period, anchor: shiftedAnchor);
  }

  static ReportDateRange _weekRange(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return ReportDateRange(
      start: monday,
      endExclusive: monday.add(const Duration(days: 7)),
    );
  }

  static String _format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
