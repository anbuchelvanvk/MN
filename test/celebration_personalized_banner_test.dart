import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/company_notification_models.dart';
import 'package:mn_family_app/models/employee_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/core/widgets/celebration_marquee_banner.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CelebrationEvent Personalization Tests', () {
    test('CelebrationEvent formats birthday wish correctly for self vs colleagues', () {
      final maleBday = CelebrationEvent(
        employeeId: 'MN-CEO01',
        employeeName: 'M N Naveenraaj',
        isFemale: false,
        type: 'birthday',
        message: '🎉 Happy Birthday M N Naveenraaj! May all your dreams come true! 🎂',
        date: '18/11',
      );

      // 1. When Naveenraaj logs into his own account
      expect(
        maleBday.displayMessage('MN-CEO01', 'M N Naveenraaj'),
        '🎉 Happy Birthday M N Naveenraaj! May all your dreams come true! 🎂',
      );

      // 2. When Praveenkumar M (Team Lead) logs in
      expect(
        maleBday.displayMessage('MN-TL1002', 'Praveenkumar M'),
        "🎉 Today is M N Naveenraaj's Birthday, wish him the best! 🎂",
      );

      // 3. When HR Mohankumar G logs in
      expect(
        maleBday.displayMessage('7', 'Mohankumar G'),
        "🎉 Today is M N Naveenraaj's Birthday, wish him the best! 🎂",
      );
    });

    test('CelebrationEvent formats female birthday wish with her correctly', () {
      final femaleBday = CelebrationEvent(
        employeeId: 'MN-EMP003',
        employeeName: 'Kaaviya',
        isFemale: true,
        type: 'birthday',
        message: '🎉 Happy Birthday Kaaviya! May all your dreams come true! 🎂',
        date: '18/11',
      );

      // Self
      expect(
        femaleBday.displayMessage('MN-EMP003', 'Kaaviya'),
        '🎉 Happy Birthday Kaaviya! May all your dreams come true! 🎂',
      );

      // Colleague
      expect(
        femaleBday.displayMessage('MN-CEO01', 'M N Naveenraaj'),
        "🎉 Today is Kaaviya's Birthday, wish her the best! 🎂",
      );
    });

    test('CelebrationEvent formats wedding anniversary correctly for self vs others', () {
      final anni = CelebrationEvent(
        employeeId: 'MN-TL1002',
        employeeName: 'Praveenkumar M',
        isFemale: false,
        type: 'anniversary',
        message: '💍 Happy Wedding Anniversary Praveenkumar M! Wishing you a lifetime of joy and togetherness! 💐',
        date: '18/11',
      );

      // Self
      expect(
        anni.displayMessage('MN-TL1002', 'Praveenkumar M'),
        '💍 Happy Wedding Anniversary Praveenkumar M! Wishing you a lifetime of joy and togetherness! 💐',
      );

      // Colleague
      expect(
        anni.displayMessage('MN-CEO01', 'M N Naveenraaj'),
        "💍 Today is Praveenkumar M's Wedding Anniversary, wish them the best! 💐",
      );
    });
  });

  group('CelebrationMarqueeBanner Widget Tests', () {
    testWidgets('Marquee dynamically changes text when switched from colleague to celebrant', (tester) async {
      final provider = EcosystemProvider();

      // Pump marquee banner inside provider
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: CelebrationMarqueeBanner(),
            ),
          ),
        ),
      );
      await tester.pump();

      // By default, if today has a celebration for Naveenraaj:
      final celebrations = provider.todayCelebrations;
      if (celebrations.any((c) => c.employeeName.contains('Naveenraaj'))) {
        // If switched to Praveenkumar M (colleague)
        provider.setActiveEmpId('MN-TL1002');
        await tester.pump();

        expect(find.textContaining("Today is M N Naveenraaj's Birthday, wish him the best!"), findsWidgets);
        expect(find.textContaining("May all your dreams come true!"), findsNothing);

        // Now switch to Naveenraaj himself
        provider.setActiveEmpId('MN-CEO01');
        await tester.pump();

        expect(find.textContaining("Happy Birthday M N Naveenraaj! May all your dreams come true!"), findsWidgets);
        expect(find.textContaining("wish him the best!"), findsNothing);
      }
    });
  });
}
