import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/konar_book_model.dart';

class KonarPdfService {
  /// Generate the complete official branded PDF document for a KONAR Book
  static Future<Uint8List> generateKonarPdf(KonarBookModel book) async {
    // If the book already has an uploaded binary/base64 PDF, return it directly
    if (book.pdfBase64 != null && book.pdfBase64!.isNotEmpty) {
      try {
        final commaIdx = book.pdfBase64!.indexOf(',');
        final base64Clean = commaIdx != -1 ? book.pdfBase64!.substring(commaIdx + 1) : book.pdfBase64!;
        return base64Decode(base64Clean);
      } catch (_) {}
    }

    final pdf = pw.Document();

    // Load fonts safely or use built-in standard font
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/GoogleSans-Regular.ttf');
      regularFont = pw.Font.ttf(fontData);
      final boldData = await rootBundle.load('assets/fonts/GoogleSans-Bold.ttf');
      boldFont = pw.Font.ttf(boldData);
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MN JEWEL PARK',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF831843), // Burgundy
                      ),
                    ),
                    pw.Text(
                      'OFFICIAL STANDARD OPERATING PROCEDURES',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFDF2F8),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFFBCFE8)),
                  ),
                  child: pw.Text(
                    '${book.departmentCode} • ${book.version}',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF9D174D),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CONFIDENTIAL • MN JEWEL PARK INTERNAL WORKFORCE',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // Title Header Banner
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFFBEB), // Soft warm cream
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFFDE68A)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    book.title.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF78350F),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    book.description,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Department: ${book.department}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        'Authorized By: ${book.updatedByName} (${book.updatedByRole})',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chapters List
            ...book.sections.map((sec) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 18),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      sec.title,
                      style: pw.TextStyle(
                        fontSize: 12.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF831843),
                      ),
                    ),
                    if (sec.subtitle.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        sec.subtitle,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColor.fromInt(0xFF0F766E),
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Text(
                      sec.content,
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.grey800,
                        height: 1.4,
                      ),
                    ),
                    if (sec.keyRules.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'MANDATORY OPERATIONAL RULES & SLAS:',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF475569),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            ...sec.keyRules.map((r) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 2.5),
                                  child: pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF831843))),
                                      pw.Expanded(
                                        child: pw.Text(
                                          r,
                                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900, height: 1.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Saves the KONAR Book PDF directly into the device's public Downloads directory
  static Future<File> saveKonarPdfLocally(KonarBookModel book) async {
    final pdfBytes = await generateKonarPdf(book);
    final fileName = '${book.department.replaceAll(' ', '_')}_KONAR_Book_${book.version}.pdf';

    Directory? targetDir;
    final publicDownloads = Directory('/storage/emulated/0/Download');
    if (await publicDownloads.exists()) {
      targetDir = publicDownloads;
    } else {
      targetDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    }

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  /// In-app preview and print using system PDF print spooler
  static Future<void> viewOrPrintKonarPdf(KonarBookModel book) async {
    final pdfBytes = await generateKonarPdf(book);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: '${book.department}_KONAR_Book',
    );
  }
}
