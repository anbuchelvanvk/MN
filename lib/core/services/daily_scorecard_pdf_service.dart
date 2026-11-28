import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/daily_scorecard_model.dart';

/// Builds the Daily Scorecard in the team's template (same layout as the
/// "25th Nov ScoreCard" PDF): title, gauge with the day's score, one block
/// per channel with done/target circles, and the design feedback banner.
class DailyScorecardPdfService {
  static const _red = PdfColor.fromInt(0xFFE8232F);
  static const _green = PdfColor.fromInt(0xFF16794A);
  static const _greenBright = PdfColor.fromInt(0xFF22A04B);
  static const _blue = PdfColor.fromInt(0xFF27358C);
  static const _orange = PdfColor.fromInt(0xFFF29A2E);
  static const _ink = PdfColor.fromInt(0xFF111111);
  static const _muted = PdfColor.fromInt(0xFF555555);
  static const _panel = PdfColor.fromInt(0xFFF6F7F6);

  static const _icons = {
    'instagram': 'assets/scorecard/instagram.png',
    'listing': 'assets/scorecard/listing.png',
    'whatsapp': 'assets/scorecard/whatsapp.png',
    'mobileApp': 'assets/scorecard/mobile_app.png',
    'google': 'assets/scorecard/google.png',
    'otherSocial': 'assets/scorecard/other_social.png',
  };

  static String _ordinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) { 1 => '${d}st', 2 => '${d}nd', 3 => '${d}rd', _ => '${d}th' };
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String two(int v) => v < 10 && v >= 0 ? '0$v' : '$v';

  static Future<pw.Font> _font(String path, pw.Font fallback) async {
    try {
      return pw.Font.ttf(await rootBundle.load(path));
    } catch (_) {
      return fallback;
    }
  }

  static Future<pw.MemoryImage?> _image(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> generatePdf(DailyScorecardModel m) async {
    final regular = await _font('assets/google_fonts/Outfit-Regular.ttf', pw.Font.helvetica());
    final bold = await _font('assets/google_fonts/Outfit-Bold.ttf', pw.Font.helveticaBold());
    final black = await _font('assets/google_fonts/Outfit-Black.ttf', bold);
    final icons = <String, pw.MemoryImage?>{
      for (final e in _icons.entries) e.key: await _image(e.value),
    };

    final doc = pw.Document(title: 'Daily Scorecard ${m.id}', author: 'MN Family');
    const width = 595.28;
    final height = 420.0 + m.channels.length * 178.0 + 110.0;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height, marginAll: 0),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (ctx) => pw.Container(
          color: PdfColors.white,
          width: width,
          height: height,
          padding: const pw.EdgeInsets.fromLTRB(36, 30, 36, 24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(m, black),
              pw.SizedBox(height: 14),
              for (final c in m.channels) ...[
                _channel(c, icons[c.key], bold),
                pw.SizedBox(height: 18),
              ],
              _feedback(m, black, bold),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _header(DailyScorecardModel m, pw.Font black) {
    final score = m.totalScore;
    return pw.Column(
      children: [
        pw.Text('Daily Scorecard', style: pw.TextStyle(font: black, fontSize: 44, color: _red)),
        pw.SizedBox(height: 2),
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '${_ordinal(m.date.day)} ${_months[m.date.month - 1]} ${m.date.year}, ',
                style: const pw.TextStyle(fontSize: 13, color: _ink)),
            const pw.TextSpan(text: "Today's Total Score", style: pw.TextStyle(fontSize: 13, color: _ink)),
          ]),
        ),
        pw.SizedBox(height: 10),
        pw.SizedBox(
          width: 380,
          height: 230,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Positioned.fill(child: pw.CustomPaint(painter: (canvas, size) => _gauge(canvas, size, score))),
              pw.Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: pw.Column(
                  children: [
                    pw.SizedBox(
                      width: 70,
                      height: 22,
                      child: pw.CustomPaint(painter: (canvas, size) {
                        _star(canvas, 12, 7, 6);
                        _star(canvas, 35, 12, 8);
                        _star(canvas, 58, 7, 6);
                      }),
                    ),
                    pw.Text('$score', style: pw.TextStyle(font: black, fontSize: 92, color: _red, height: 1)),
                    pw.Text('/100 ${m.grade}', style: const pw.TextStyle(fontSize: 12, color: _ink)),
                    pw.Text(m.effectiveRemark, style: const pw.TextStyle(fontSize: 12, color: _ink)),
                  ],
                ),
              ),
              pw.Positioned(bottom: 18, left: 18, child: pw.Text('0', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(bottom: 18, right: 10, child: pw.Text('100', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),
      ],
    );
  }

  static void _star(PdfGraphics canvas, double cx, double cy, double r) {
    canvas.setFillColor(_red);
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = math.pi / 2 + i * math.pi / 5;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    canvas
      ..closePath()
      ..fillPath();
  }

  /// Half-circle gauge: red, orange, green, with a ring marker at [score].
  static void _gauge(PdfGraphics canvas, PdfPoint size, int score) {
    final cx = size.x / 2;
    final cy = 40.0; // PDF y goes up from the bottom of the box
    final r = math.min(size.x / 2 - 20, size.y - 60);
    void arc(double fromPct, double toPct, PdfColor color) {
      canvas
        ..setStrokeColor(color)
        ..setLineWidth(13)
        ..setLineCap(PdfLineCap.round);
      const steps = 40;
      for (var i = 0; i <= steps; i++) {
        final pct = fromPct + (toPct - fromPct) * i / steps;
        final a = math.pi * (1 - pct); // 0% at left, 100% at right
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);
        if (i == 0) {
          canvas.moveTo(x, y);
        } else {
          canvas.lineTo(x, y);
        }
      }
      canvas.strokePath();
    }

    arc(0.0, 0.58, _red);
    arc(0.62, 0.78, _orange);
    arc(0.82, 1.0, _greenBright);
    final a = math.pi * (1 - score.clamp(0, 100) / 100);
    final mx = cx + r * math.cos(a);
    final my = cy + r * math.sin(a);
    canvas
      ..setFillColor(PdfColors.white)
      ..drawEllipse(mx, my, 11, 11)
      ..fillPath()
      ..setStrokeColor(const PdfColor.fromInt(0xFF3B82C4))
      ..setLineWidth(4)
      ..drawEllipse(mx, my, 11, 11)
      ..strokePath();
  }

  static pw.Widget _pill(String text, PdfColor color, pw.Font bold) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
        child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.white)),
      );

  static pw.Widget _channel(ScoreChannel c, pw.MemoryImage? icon, pw.Font bold) {
    final full = c.score >= c.weight;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: pw.BoxDecoration(color: _panel, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 60,
                height: 60,
                child: icon != null ? pw.Image(icon, fit: pw.BoxFit.contain) : pw.SizedBox(),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(c.name, style: pw.TextStyle(font: bold, fontSize: 26, color: _ink)),
                        pw.SizedBox(width: 8),
                        _pill('${two(c.score)}%', full ? _green : _red, bold),
                        pw.SizedBox(width: 4),
                        pw.Text('Out of', style: pw.TextStyle(font: bold, fontSize: 12, color: _ink)),
                        pw.SizedBox(width: 4),
                        _pill('${two(c.weight)}%', _green, bold),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Target/day: ${c.targetText}', style: const pw.TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            for (final i in c.items) ...[
              _circle(i, bold),
              if (i != c.items.last) pw.SizedBox(width: 14),
            ],
          ],
        ),
      ],
    );
  }

  /// Ring per item: green when met, blue when over target, red when short.
  static pw.Widget _circle(ScoreItem i, pw.Font bold) {
    final color = i.done > i.target ? _blue : (i.met ? _green : _red);
    return pw.Container(
      width: 76,
      height: 76,
      decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 6)),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(two(i.done), style: pw.TextStyle(font: bold, fontSize: 24, color: color, height: 1)),
          pw.Container(width: 40, height: 1.5, color: color, margin: const pw.EdgeInsets.symmetric(vertical: 1)),
          pw.Text(two(i.target), style: pw.TextStyle(font: bold, fontSize: 10, color: color)),
          pw.Text(i.label, style: const pw.TextStyle(fontSize: 5.5, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _feedback(DailyScorecardModel m, pw.Font black, pw.Font bold) {
    pw.Widget chip(String t, bool on) => pw.Container(
          margin: const pw.EdgeInsets.only(right: 5),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            color: on ? const PdfColor.fromInt(0xFFDDEFE2) : const PdfColor.fromInt(0xFF4D7F63),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: on ? _green : PdfColors.white)),
        );
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: pw.BoxDecoration(color: _green, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        children: [
          pw.Text('${m.feedbackRating}%', style: pw.TextStyle(font: black, fontSize: 54, color: PdfColors.white)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Feed Back Rating', style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColors.white)),
                pw.Text('In Design we need to get the customer or Concern team',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.white)),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  chip('On Time', m.onTime),
                  chip('Quality Design', m.qualityDesign),
                  chip('Design Perfection', m.designPerfection),
                ]),
              ],
            ),
          ),
          pw.Container(
            width: 84,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF7DD),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(children: [
              pw.Text(two(m.feedbackResponses), style: pw.TextStyle(font: black, fontSize: 40, color: _green, height: 1)),
              pw.Text('Response', style: const pw.TextStyle(fontSize: 7, color: _green)),
            ]),
          ),
        ],
      ),
    );
  }

  /// The first page as a PNG, for sharing the scorecard as an image.
  static Future<Uint8List> toPng(Uint8List pdfBytes, {double dpi = 144}) async {
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: dpi)) {
      return page.toPng();
    }
    throw StateError('Could not render the scorecard image.');
  }
}
