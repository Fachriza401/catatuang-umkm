import '../../../transactions/domain/entities/money_transaction.dart';
import '../entities/dashboard_data.dart';
import '../entities/dashboard_period.dart';

abstract final class DashboardCalculator {
  static DashboardData build({
    required List<MoneyTransaction> transactions,
    required DashboardPeriod period,
    DateTime? now,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) {
    if ((startDate == null) != (endDateExclusive == null)) {
      throw ArgumentError('Rentang tanggal harus memiliki awal dan akhir.');
    }
    if (startDate != null && !startDate.isBefore(endDateExclusive!)) {
      throw ArgumentError('Tanggal akhir harus setelah tanggal awal.');
    }

    final current = now ?? DateTime.now();
    final active = transactions.where((transaction) => !transaction.isDeleted);

    var cashBalance = 0;
    for (final transaction in active) {
      cashBalance += transaction.signedAmount;
    }

    final summaryRange = startDate == null
        ? _summaryRange(period, current)
        : _DateRange(startDate, endDateExclusive!);
    var income = 0;
    var expense = 0;
    for (final transaction in active) {
      if (_isInside(transaction.transactionDate, summaryRange)) {
        if (transaction.isIncome) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }
    }

    final buckets = startDate == null
        ? _chartBuckets(period, current)
        : _chartBucketsForRange(startDate, endDateExclusive!);
    final chartPoints = <DashboardChartPoint>[];
    for (final bucket in buckets) {
      var bucketIncome = 0;
      var bucketExpense = 0;
      for (final transaction in active) {
        if (!_isInside(transaction.transactionDate, bucket)) continue;
        if (transaction.isIncome) {
          bucketIncome += transaction.amount;
        } else {
          bucketExpense += transaction.amount;
        }
      }
      chartPoints.add(
        DashboardChartPoint(
          bucketStart: bucket.start,
          income: bucketIncome,
          expense: bucketExpense,
        ),
      );
    }

    final recent = active.toList()
      ..sort((a, b) {
        final dateComparison = b.transactionDate.compareTo(a.transactionDate);
        if (dateComparison != 0) return dateComparison;
        return b.createdAt.compareTo(a.createdAt);
      });

    return DashboardData(
      period: period,
      cashBalance: cashBalance,
      summary: DashboardSummary(income: income, expense: expense),
      chartPoints: chartPoints,
      recentTransactions: recent.take(5).toList(growable: false),
    );
  }

  static bool _isInside(DateTime date, _DateRange range) {
    return !date.isBefore(range.start) && date.isBefore(range.end);
  }

  static _DateRange _summaryRange(DashboardPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      DashboardPeriod.daily => _DateRange(
          today,
          today.add(const Duration(days: 1)),
        ),
      DashboardPeriod.weekly => _DateRange(
          _startOfWeek(today),
          _startOfWeek(today).add(const Duration(days: 7)),
        ),
      DashboardPeriod.monthly => _DateRange(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        ),
      DashboardPeriod.yearly => _DateRange(
          DateTime(now.year),
          DateTime(now.year + 1),
        ),
    };
  }

  static List<_DateRange> _chartBuckets(DashboardPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      DashboardPeriod.daily => List.generate(7, (index) {
          final start = today.subtract(Duration(days: 6 - index));
          return _DateRange(start, start.add(const Duration(days: 1)));
        }),
      DashboardPeriod.weekly => List.generate(6, (index) {
          final start = _startOfWeek(
            today,
          ).subtract(Duration(days: (5 - index) * 7));
          return _DateRange(start, start.add(const Duration(days: 7)));
        }),
      DashboardPeriod.monthly => List.generate(6, (index) {
          final start = DateTime(now.year, now.month - 5 + index);
          return _DateRange(start, DateTime(start.year, start.month + 1));
        }),
      DashboardPeriod.yearly => List.generate(12, (index) {
          final start = DateTime(now.year, now.month - 11 + index);
          return _DateRange(start, DateTime(start.year, start.month + 1));
        }),
    };
  }

  static List<_DateRange> _chartBucketsForRange(
    DateTime start,
    DateTime endExclusive,
  ) {
    final duration = endExclusive.difference(start);
    if (duration <= const Duration(days: 1)) {
      return _fixedBuckets(start, endExclusive, const Duration(hours: 1));
    }
    if (duration.inDays <= 45) {
      return _fixedBuckets(start, endExclusive, const Duration(days: 1));
    }
    if (duration.inDays <= 140) {
      return _fixedBuckets(start, endExclusive, const Duration(days: 7));
    }

    final buckets = <_DateRange>[];
    var monthStart = DateTime(start.year, start.month);
    while (monthStart.isBefore(endExclusive)) {
      final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
      buckets.add(
        _DateRange(
          monthStart.isBefore(start) ? start : monthStart,
          nextMonth.isAfter(endExclusive) ? endExclusive : nextMonth,
        ),
      );
      monthStart = nextMonth;
    }
    return buckets;
  }

  static List<_DateRange> _fixedBuckets(
    DateTime start,
    DateTime endExclusive,
    Duration interval,
  ) {
    final buckets = <_DateRange>[];
    for (var bucketStart = start;
        bucketStart.isBefore(endExclusive);
        bucketStart = bucketStart.add(interval)) {
      final bucketEnd = bucketStart.add(interval);
      buckets.add(
        _DateRange(
          bucketStart,
          bucketEnd.isAfter(endExclusive) ? endExclusive : bucketEnd,
        ),
      );
    }
    return buckets;
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
