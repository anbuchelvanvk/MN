import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/monthly_scorecard_model.dart';

class MonthlyScorecardPdfService {
  static final NumberFormat _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
  static final NumberFormat _numFmt = NumberFormat('#,##,###');

  static String _formatCurrency(double val) {
    return _currFmt.format(val).replaceAll('Rs.', 'Rs. ');
  }

  static String _formatNum(num val) {
    return _numFmt.format(val);
  }

  static String _formatValue(num val) {
    if (val >= 10000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    } else if (val >= 1000) {
      if (val % 1000 == 0) return '${(val / 1000).toStringAsFixed(0)}k';
      return '${(val / 1000).toStringAsFixed(1)}k';
    } else if (val >= 0 && val < 10 && val == val.roundToDouble()) {
      return '0${val.toInt()}';
    }
    return val.toString();
  }

  /// Generates the complete PDF using the authentic template from the user
  /// with exact aspect ratio (595.276 x 2229.74 pt), authentic icons, zero extra space,
  /// and dynamic data overlay.
  static Future<Uint8List> generatePdf(MonthlyScorecardModel model) async {
    Uint8List bgBytes;
    try {
      final data = await rootBundle.load('assets/scorecard_template_bg.png');
      bgBytes = data.buffer.asUint8List();
    } catch (_) {
      final file = File('assets/scorecard_template_bg.png');
      if (file.existsSync()) {
        bgBytes = file.readAsBytesSync();
      } else {
        bgBytes = Uint8List(0);
      }
    }

    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      final regData = await rootBundle.load('assets/fonts/GoogleSans-Regular.ttf');
      ttfRegular = pw.Font.ttf(regData);
      final boldData = await rootBundle.load('assets/fonts/GoogleSans-Bold.ttf');
      ttfBold = pw.Font.ttf(boldData);
    } catch (_) {
      try {
        final regFile = File('assets/fonts/GoogleSans-Regular.ttf');
        final boldFile = File('assets/fonts/GoogleSans-Bold.ttf');
        if (regFile.existsSync() && boldFile.existsSync()) {
          ttfRegular = pw.Font.ttf(regFile.readAsBytesSync().buffer.asByteData());
          ttfBold = pw.Font.ttf(boldFile.readAsBytesSync().buffer.asByteData());
        }
      } catch (_) {}
    }

    final pdf = pw.Document(
      theme: (ttfRegular != null && ttfBold != null)
          ? pw.ThemeData.withFont(
              base: ttfRegular,
              bold: ttfBold,
            )
          : null,
    );
    final customFormat = const PdfPageFormat(595.276, 2229.74, marginAll: 0);

    final redColor = PdfColor.fromHex('#DC2626');
    final greenColor = PdfColor.fromHex('#047857');
    final blueColor = PdfColor.fromHex('#1D4ED8');
    final orangeColor = PdfColor.fromHex('#EA580C');

    pw.Widget buildCircleActual(double cx, double top, num actual, num target, {bool isSpecialAmber = false, double fontSize = 14}) {
      PdfColor color;
      if (isSpecialAmber) {
        color = orangeColor;
      } else if (actual < target) {
        color = redColor;
      } else if (actual == target) {
        color = greenColor;
      } else {
        color = blueColor;
      }

      return pw.Positioned(
        left: cx - 28,
        top: top,
        child: pw.SizedBox(
          width: 56,
          child: pw.Center(
            child: pw.Text(
              _formatValue(actual),
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      );
    }

    pw.Widget buildPill(double left, double top, int percentage) {
      // Sector percentage colors:
      // >= 95% is Green, 50% to < 95% is Orange, < 50% is Red
      final color = percentage >= 95
          ? greenColor
          : (percentage >= 50 ? orangeColor : redColor);
      return pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: 40,
          height: 18,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3.5)),
          ),
          child: pw.Center(
            child: pw.Text(
              '$percentage%',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: customFormat,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Template Background with Authentic Icons & Design Layout
              if (bgBytes.isNotEmpty)
                pw.Positioned.fill(
                  child: pw.Image(
                    pw.MemoryImage(bgBytes),
                    fit: pw.BoxFit.fill,
                  ),
                ),

              // 2. Date Range Subtitle
              pw.Positioned(
                left: 0,
                right: 0,
                top: 98,
                child: pw.Center(
                  child: pw.Text(
                    model.dateRangeTitle,
                    style: pw.TextStyle(
                      fontSize: 13.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1E293B'),
                    ),
                  ),
                ),
              ),

              // 3. Top 4 Summary Cards Actual Values
              pw.Positioned(
                left: 44.5,
                top: 172,
                child: pw.Text(
                  _formatNum(model.totalSalesActual),
                  style: pw.TextStyle(fontSize: 27, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
              pw.Positioned(
                left: 354.2,
                top: 168,
                child: pw.Text(
                  '${model.salesOrdersActual}',
                  style: pw.TextStyle(fontSize: 29, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
              pw.Positioned(
                left: 44.1,
                top: 295,
                child: pw.Text(
                  '${model.schemeConversionsActual.toStringAsFixed(3)}G',
                  style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
              pw.Positioned(
                left: 298.2,
                top: 295,
                child: pw.Text(
                  _formatNum(model.monthlySchemeActual),
                  style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),

              // 4. Category Percentage Pills
              buildPill(252, 406, model.instaPercentage),
              buildPill(242, 634, model.webPercentage),
              buildPill(268, 852, model.waPercentage),
              buildPill(278, 1056, model.appPercentage),
              buildPill(228, 1261, model.googlePercentage),
              buildPill(385, 1471, model.osmPercentage),
              buildPill(266, 1698, model.designFeedbackRating),

              // 5. Instagram Metrics
              buildCircleActual(75, 498, model.instaContentReelActual, model.instaContentReelTarget),
              buildCircleActual(162, 498, model.instaProductReelActual, model.instaProductReelTarget),
              buildCircleActual(250, 498, model.instaStoriesActual, model.instaStoriesTarget),
              buildCircleActual(337, 498, model.instaCarouselActual, model.instaCarouselTarget),
              buildCircleActual(425, 498, model.instaCampaignActual, model.instaCampaignTarget),
              buildCircleActual(512, 498, model.instaInfluencerActual, model.instaInfluencerTarget),

              // 6. Website Metrics
              buildCircleActual(195, 730, model.webMnListingActual, model.webMnListingTarget),
              buildCircleActual(304, 730, model.webVadivamListingActual, model.webVadivamListingTarget),
              buildCircleActual(412, 730, model.webCampaignActual, model.webCampaignTarget),

              // 7. WhatsApp Metrics
              buildCircleActual(159, 938, model.waStoriesActual, model.waStoriesTarget),
              buildCircleActual(260, 938, model.waChannelsActual, model.waChannelsTarget),
              buildCircleActual(357, 938, model.waCampaignActual, model.waCampaignTarget),
              buildCircleActual(463, 938, model.waBroadcastActual, model.waBroadcastTarget),

              // 8. Mobile App Metrics
              buildCircleActual(147, 1142, model.appMnListingActual, model.appMnListingTarget),
              buildCircleActual(256, 1142, model.appVadivamListingActual, model.appVadivamListingTarget),
              buildCircleActual(370, 1142, model.appCampaignActual, model.appCampaignTarget),
              buildCircleActual(484, 1142, model.appNotificationActual, model.appNotificationTarget),

              // 9. Google Metrics
              buildCircleActual(191, 1354, model.googleBlogsActual, model.googleBlogsTarget, isSpecialAmber: true),
              buildCircleActual(319, 1354, model.googleListingActual, model.googleListingTarget),
              buildCircleActual(442, 1354, model.googleCampaignActual, model.googleCampaignTarget),

              // 10. Other Social Media Metrics
              buildCircleActual(119, 1563, model.osmSnapchatActual, model.osmSnapchatTarget),
              buildCircleActual(207, 1563, model.osmPinterestActual, model.osmPinterestTarget),
              buildCircleActual(297, 1563, model.osmShortsActual, model.osmShortsTarget),
              buildCircleActual(384, 1563, model.osmLinkedinActual, model.osmLinkedinTarget),
              buildCircleActual(477, 1563, model.osmXPostActual, model.osmXPostTarget),

              // 11. Designing Response (Placed inside the green box at left: 65.86, top: 1774, width: 88.8)
              pw.Positioned(
                left: 65.86,
                top: 1774,
                child: pw.SizedBox(
                  width: 88.8,
                  child: pw.Center(
                    child: pw.Text(
                      '${model.designResponse}',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // 12. Other Targets (5 Bottom Circles)
              buildCircleActual(84, 1898, model.downloadsMnActual, model.downloadsMnTarget, fontSize: 15),
              buildCircleActual(192, 1898, model.downloadsVadivamActual, model.downloadsVadivamTarget, fontSize: 15),
              buildCircleActual(300, 1898, model.followersMnActual, model.followersMnTarget, fontSize: 15),
              buildCircleActual(412, 1898, model.followersVadivamActual, model.followersVadivamTarget, fontSize: 15),
              buildCircleActual(521, 1898, model.googleReviewsActual, model.googleReviewsTarget, fontSize: 15),

              // 13. Performance Section
              // Top performer name inside green circle
              pw.Positioned(
                left: 450,
                top: 2088,
                child: pw.SizedBox(
                  width: 100,
                  child: pw.Center(
                    child: pw.Text(
                      model.topPerformer.isNotEmpty
                          ? model.topPerformer[0].toUpperCase() + model.topPerformer.substring(1)
                          : 'Gokul',
                      style: pw.TextStyle(fontSize: 14.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ),
                ),
              ),

              // Member Stats
              // Gokul
              _buildMemberStatPdf(53.9, 2146, model.gokulSales, model.gokulSchemes, model.gokulGold, isTop: model.topPerformer.toLowerCase() == 'gokul'),
              // Kaaviya
              _buildMemberStatPdf(164.2, 2146, model.kaaviyaSales, model.kaaviyaSchemes, model.kaaviyaGold, isTop: model.topPerformer.toLowerCase() == 'kaaviya'),
              // Nisha
              _buildMemberStatPdf(274.6, 2146, model.nishaSales, model.nishaSchemes, model.nishaGold, isTop: model.topPerformer.toLowerCase() == 'nisha'),
              // Asha
              _buildMemberStatPdf(384.6, 2146, model.ashaSales, model.ashaSchemes, model.ashaGold, isTop: model.topPerformer.toLowerCase() == 'asha'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMemberStatPdf(
    double left,
    double top,
    double sales,
    double schemes,
    double gold, {
    required bool isTop,
  }) {
    final statusColor = isTop ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#DC2626');
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _formatCurrency(sales),
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: statusColor),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            _formatCurrency(schemes),
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            gold > 0 ? '${gold.toStringAsFixed(3)}g' : '0g',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }
}
