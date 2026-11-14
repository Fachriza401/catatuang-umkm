import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../business_profile/domain/entities/business_profile.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/transaction_category.dart';
import '../../domain/entities/financial_report.dart';

enum ReportPdfFormat {
  thermal58,
  thermal80,
  a4;

  String get label => switch (this) {
    thermal58 => 'Struk 58 mm',
    thermal80 => 'Struk 80 mm',
    a4 => 'A4',
  };
}

class ReportPdfService {
  Future<Uint8List> build({
    required FinancialReport report,
    BusinessProfile? businessProfile,
    ReportPdfFormat format = ReportPdfFormat.a4,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-400.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-700.ttf'),
    );
    final document = pw.Document();
    if (format != ReportPdfFormat.a4) {
      document.addPage(
        _receiptPage(report, businessProfile, regularFont, boldFont, format),
      );
      return document.save();
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 82, 36, 54),
        maxPages: 100,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (_) => _pageHeader(boldFont),
        footer: (context) => _pageFooter(context, report.generatedAt),
        build: (context) => [
          _businessIdentity(report, businessProfile, boldFont),
          pw.SizedBox(height: 16),
          _sectionTitle('Ringkasan keuangan', boldFont),
          pw.SizedBox(height: 8),
          _summaryTable(report),
          pw.SizedBox(height: 18),
          _sectionTitle('Detail pemasukan', boldFont),
          pw.SizedBox(height: 7),
          _transactionTable(
            report.transactions
                .where((transaction) => transaction.isIncome)
                .toList(),
            boldFont,
            emptyLabel: 'Tidak ada pemasukan pada periode ini.',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Detail pengeluaran', boldFont),
          pw.SizedBox(height: 7),
          _transactionTable(
            report.transactions
                .where((transaction) => transaction.isExpense)
                .toList(),
            boldFont,
            emptyLabel: 'Tidak ada pengeluaran pada periode ini.',
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Laba/rugi sederhana: ${CurrencyFormatter.format(report.net)}',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
        ],
      ),
    );
    return document.save();
  }

  PdfPageFormat pageFormatFor(FinancialReport report, ReportPdfFormat format) {
    if (format == ReportPdfFormat.a4) return PdfPageFormat.a4;
    final width = format == ReportPdfFormat.thermal58 ? 58.0 : 80.0;
    final charactersPerLine = format == ReportPdfFormat.thermal58 ? 25 : 39;
    final transactionHeight = report.transactions.fold<double>(0, (
      height,
      transaction,
    ) {
      final descriptionLines =
          (transaction.description.length / charactersPerLine).ceil().clamp(
            1,
            20,
          );
      final category =
          TransactionCategory.byId(transaction.categoryId)?.label ??
          transaction.categoryId;
      final categoryLines = (category.length / charactersPerLine).ceil().clamp(
        1,
        10,
      );
      return height + 27 + descriptionLines * 9 + categoryLines * 8;
    });
    final height = 92 + transactionHeight;
    return PdfPageFormat(
      width * PdfPageFormat.mm,
      height * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );
  }

  pw.Page _receiptPage(
    FinancialReport report,
    BusinessProfile? profile,
    pw.Font regularFont,
    pw.Font boldFont,
    ReportPdfFormat format,
  ) {
    final pageFormat = pageFormatFor(report, format);
    final width =
        pageFormat.width - pageFormat.marginLeft - pageFormat.marginRight;
    final businessName = profile?.businessName.trim();
    final rows = <List<String>>[
      ['Pemasukan', CurrencyFormatter.format(report.income)],
      ['Pengeluaran', CurrencyFormatter.format(report.expense)],
      ['Arus kas bersih', CurrencyFormatter.format(report.net)],
      ['Saldo saat ini', CurrencyFormatter.format(report.cashBalance)],
      ['Sisa piutang', CurrencyFormatter.format(report.receivableOutstanding)],
      ['Sisa utang', CurrencyFormatter.format(report.payableOutstanding)],
    ];

    return pw.Page(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'CatatUang',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          if (businessName?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                businessName!,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: boldFont, fontSize: 8),
              ),
            ),
          pw.SizedBox(height: 3),
          pw.Text(
            'LAPORAN KEUANGAN',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: boldFont, fontSize: 8),
          ),
          pw.Text(
            '${report.period.label} | ${report.range.label}',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6.5),
          ),
          pw.Divider(height: 10, thickness: 0.6),
          for (final row in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(
                    width: width * 0.48,
                    child: pw.Text(
                      row[0],
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                  pw.SizedBox(
                    width: width * 0.48,
                    child: pw.Text(
                      row[1],
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: boldFont, fontSize: 7),
                    ),
                  ),
                ],
              ),
            ),
          pw.Divider(height: 10, thickness: 0.6),
          pw.Text(
            'RINCIAN TRANSAKSI (${report.transactions.length})',
            style: pw.TextStyle(font: boldFont, fontSize: 7.5),
          ),
          pw.SizedBox(height: 4),
          if (report.transactions.isEmpty)
            pw.Text(
              'Tidak ada transaksi pada periode ini.',
              style: const pw.TextStyle(fontSize: 7),
            )
          else
            for (final transaction in report.transactions) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  '${AppDateFormat.fullDate(transaction.transactionDate)} | ${transaction.type.label}',
                  style: pw.TextStyle(font: boldFont, fontSize: 6.5),
                ),
              ),
              pw.Text(
                transaction.description.trim().isEmpty
                    ? transaction.type.label
                    : transaction.description,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      TransactionCategory.byId(transaction.categoryId)?.label ??
                          transaction.categoryId,
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                  ),
                  pw.Text(
                    '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                  ),
                ],
              ),
              pw.Divider(height: 7, thickness: 0.3),
            ],
          pw.SizedBox(height: 4),
          pw.Text(
            'Dicetak ${AppDateFormat.fullDate(report.generatedAt)}',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageHeader(pw.Font boldFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 34,
          height: 34,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'C',
            style: pw.TextStyle(
              font: boldFont,
              color: PdfColors.white,
              fontSize: 21,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CatatUang',
              style: pw.TextStyle(font: boldFont, fontSize: 15),
            ),
            pw.Text(
              'Laporan keuangan usaha',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pageFooter(pw.Context context, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dibuat ${AppDateFormat.fullDate(generatedAt)}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _businessIdentity(
    FinancialReport report,
    BusinessProfile? profile,
    pw.Font boldFont,
  ) {
    final businessName = profile?.businessName.trim();
    final identity = <String>[
      if (profile?.ownerName.trim().isNotEmpty == true)
        'Pemilik: ${profile!.ownerName}',
      if (profile?.businessType.trim().isNotEmpty == true)
        'Bidang usaha: ${profile!.businessType}',
      if (profile?.phone.trim().isNotEmpty == true)
        'Telepon: ${profile!.phone}',
      if (profile?.address.trim().isNotEmpty == true)
        'Alamat: ${profile!.address}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          businessName?.isNotEmpty == true ? businessName! : 'CatatUang',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        if (identity.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          for (final line in identity)
            pw.Text(line, style: const pw.TextStyle(fontSize: 8)),
        ],
        pw.SizedBox(height: 7),
        pw.Text(
          'Periode: ${report.period.label} | ${report.range.label}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 11));
  }

  pw.Widget _summaryTable(FinancialReport report) {
    final rows = <List<String>>[
      ['Pemasukan', CurrencyFormatter.format(report.income)],
      ['Pengeluaran', CurrencyFormatter.format(report.expense)],
      ['Arus kas bersih', CurrencyFormatter.format(report.net)],
      ['Saldo saat ini', CurrencyFormatter.format(report.cashBalance)],
      ['Sisa piutang', CurrencyFormatter.format(report.receivableOutstanding)],
      ['Sisa utang', CurrencyFormatter.format(report.payableOutstanding)],
    ];
    return pw.TableHelper.fromTextArray(
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {1: pw.Alignment.centerRight},
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _transactionTable(
    List<MoneyTransaction> transactions,
    pw.Font boldFont, {
    required String emptyLabel,
  }) {
    if (transactions.isEmpty) {
      return pw.Text(
        emptyLabel,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: const ['Tanggal', 'Keterangan', 'Kategori', 'Nominal'],
      data: transactions.map(_transactionRow).toList(growable: false),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      headerStyle: pw.TextStyle(
        font: boldFont,
        color: PdfColors.white,
        fontSize: 8,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      cellAlignments: {3: pw.Alignment.centerRight},
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(
          color: PdfColors.grey300,
          width: 0.4,
        ),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(64),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FixedColumnWidth(92),
      },
    );
  }

  List<String> _transactionRow(MoneyTransaction transaction) {
    final category =
        TransactionCategory.byId(transaction.categoryId)?.label ??
        transaction.categoryId;
    return [
      AppDateFormat.fullDate(transaction.transactionDate),
      transaction.description.trim().isEmpty
          ? transaction.type.label
          : transaction.description,
      category,
      CurrencyFormatter.format(transaction.amount),
    ];
  }
}
