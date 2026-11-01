import 'dart:convert';

import 'package:catat_uang/features/debts/domain/entities/debt.dart';
import 'package:catat_uang/features/reports/data/services/report_pdf_service.dart';
import 'package:catat_uang/features/reports/domain/entities/report_date_range.dart';
import 'package:catat_uang/features/reports/domain/entities/report_period.dart';
import 'package:catat_uang/features/reports/domain/services/financial_report_calculator.dart';
import 'package:catat_uang/features/transactions/domain/entities/money_transaction.dart';
import 'package:catat_uang/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pdfService = ReportPdfService();
  final range = ReportDateRange(
    start: DateTime(2026, 1, 1),
    endExclusive: DateTime(2027, 1, 1),
  );

  for (final count in [0, 1, 350]) {
    test('PDF valid dengan $count transaksi', () async {
      final transactions = List.generate(count, (index) => _transaction(index));
      final report = FinancialReportCalculator.build(
        transactions: transactions,
        debts: const <Debt>[],
        period: ReportPeriod.yearly,
        range: range,
        generatedAt: DateTime(2027, 1, 1),
      );

      final bytes = await pdfService.build(report: report);
      final text = latin1.decode(bytes);
      final pageCount = RegExp(r'/Type\s*/Page\b').allMatches(text).length;

      expect(bytes, isNotEmpty);
      expect(text, startsWith('%PDF-'));
      expect(pageCount, greaterThan(0));
      if (count == 350) expect(pageCount, greaterThan(1));
    });
  }
}

MoneyTransaction _transaction(int index) {
  final date = DateTime(2026, 1, 1).add(Duration(days: index % 365));
  final type = index.isEven ? TransactionType.income : TransactionType.expense;
  return MoneyTransaction(
    id: 'transaction-$index',
    userId: 'user-1',
    type: type,
    amount: 10000 + index,
    categoryId: type.isIncome ? 'sales' : 'ingredients',
    paymentMethodId: 'cash',
    transactionDate: date,
    description: 'Contoh transaksi nomor $index',
    createdAt: date,
    updatedAt: date,
  );
}
