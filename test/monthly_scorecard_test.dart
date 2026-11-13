import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/core/models/monthly_scorecard_model.dart';
import 'package:mn_family_app/core/services/monthly_scorecard_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonthlyScorecardModel Tests', () {
    test('Calculates days in month dynamically for reel targets', () {
      final octScorecard = MonthlyScorecardModel(month: 10, year: 2026);
      expect(octScorecard.daysInMonth, 31);
      expect(octScorecard.instaContentReelTarget, 31);
      expect(octScorecard.instaProductReelTarget, 31);

      final novScorecard = MonthlyScorecardModel(month: 11, year: 2026);
      expect(novScorecard.daysInMonth, 30);
      expect(novScorecard.instaContentReelTarget, 30);
      expect(novScorecard.instaProductReelTarget, 30);

      final feb2024 = MonthlyScorecardModel(month: 2, year: 2024);
      expect(feb2024.daysInMonth, 29); // Leap year
      expect(feb2024.instaContentReelTarget, 29);

      final feb2025 = MonthlyScorecardModel(month: 2, year: 2025);
      expect(feb2025.daysInMonth, 28); // Non-leap year
      expect(feb2025.instaContentReelTarget, 28);
    });

    test('toJson and fromJson preserves all scorecard values correctly', () {
      final original = MonthlyScorecardModel(
        month: 10,
        year: 2026,
        totalSalesActual: 5000000,
        totalSalesTarget: 8333333,
        salesOrdersActual: 75,
        salesOrdersTarget: 100,
        schemeConversionsActual: 210.5,
        schemeConversionsTarget: 250.0,
        topPerformer: 'Kaaviya',
      );

      final json = original.toJson();
      final reconstructed = MonthlyScorecardModel.fromJson(json);

      expect(reconstructed.month, 10);
      expect(reconstructed.year, 2026);
      expect(reconstructed.totalSalesActual, 5000000);
      expect(reconstructed.salesOrdersActual, 75);
      expect(reconstructed.schemeConversionsActual, 210.5);
      expect(reconstructed.topPerformer, 'Kaaviya');
    });

    test('Category percentage calculations', () {
      final sample = MonthlyScorecardModel.createSample();
      expect(sample.instaPercentage, inInclusiveRange(0, 100));
      expect(sample.webPercentage, inInclusiveRange(0, 100));
      expect(sample.waPercentage, inInclusiveRange(0, 100));
      expect(sample.appPercentage, inInclusiveRange(0, 100));
      expect(sample.googlePercentage, inInclusiveRange(0, 100));
      expect(sample.osmPercentage, inInclusiveRange(0, 100));
    });

    test('Generates valid non-empty PDF bytes', () async {
      final model = MonthlyScorecardModel.createSample();
      final pdfBytes = await MonthlyScorecardPdfService.generatePdf(model);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF documents start with %PDF
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });
  });
}

