import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/auth/login_screen.dart';
import 'package:mn_family_app/views/ceo/ceo_suite_screen.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_screen.dart';
import 'package:mn_family_app/views/employee/employee_portal_screen.dart';
import 'package:mn_family_app/views/employee/employee_profile_screen.dart';
import 'package:mn_family_app/views/orders/online_orders_handler_screen.dart';
import 'package:mn_family_app/core/widgets/export_audit_modal.dart';
import 'package:mn_family_app/views/pillars/health_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/attendance_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/profile_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/social_cause_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/tier_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/work_pillar_screen.dart';
import 'package:mn_family_app/views/auth/pillars_popup_dialog.dart';

void main() {
  // Key Display Specifications:
  // • Screen Size: 6.83 inches (17.35 cm)
  // • Resolution: 1.5K (2800 x 1272 pixels)
  // • Aspect Ratio: 19.8:9
  // • Pixel Density: 450 ppi (~2.8125x devicePixelRatio)
  const Size targetPhysicalSize = Size(1272, 2800);
  const double targetPixelRatio = 2.8125;

  Widget createTestApp(Widget child, EcosystemProvider eco) {
    return ChangeNotifierProvider<EcosystemProvider>.value(
      value: eco,
      child: MaterialApp(
        theme: AppThemes.burgundySandTheme,
        home: child,
      ),
    );
  }

  void configureDisplay(WidgetTester tester, {Size physicalSize = targetPhysicalSize, double ratio = targetPixelRatio}) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = ratio;
  }

  group('1.5K 19.8:9 Display Specifications Verification (2800x1272 @ 450ppi)', () {
    testWidgets('LoginScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const LoginScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('CeoSuiteScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();
      eco.setActiveRole('ceo');
      eco.setActiveEmployee('MN-CEO01');

      await tester.pumpWidget(createTestApp(const CeoSuiteScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CeoSuiteScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('DeptHeadPortalScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();
      eco.setActiveRole('dept_head');
      eco.setActiveEmployee('MN-TL1002');

      await tester.pumpWidget(createTestApp(const DeptHeadPortalScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DeptHeadPortalScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('HrPortalScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();
      eco.setActiveRole('hr');
      eco.setActiveEmployee('MN-HR1001');

      await tester.pumpWidget(createTestApp(const HrPortalScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HrPortalScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('EmployeePortalScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmployee('MN-1007');

      await tester.pumpWidget(createTestApp(const EmployeePortalScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EmployeePortalScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('EmployeeProfileScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmployee('MN-1007');

      await tester.pumpWidget(createTestApp(const EmployeeProfileScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EmployeeProfileScreen), findsOneWidget);
      final err = tester.takeException();
      expect(err, isNull);
    });

    testWidgets('OnlineOrdersHandlerScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const OnlineOrdersHandlerScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OnlineOrdersHandlerScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('ExportAuditModal renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const Scaffold(body: ExportAuditModal()), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExportAuditModal), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('HealthPillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const HealthPillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HealthPillarScreen), findsOneWidget);
      final weightCard = find.text('Weight / Height');
      if (weightCard.evaluate().isNotEmpty) {
        await tester.tap(weightCard.first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Save BMI'), findsOneWidget);
      }
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('FamilyPillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const FamilyPillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FamilyPillarScreen), findsOneWidget);
      expect(find.text('Friends & Peers'), findsWidgets);
    });

    testWidgets('AttendancePillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const AttendancePillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AttendancePillarScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('ProfilePillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const ProfilePillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ProfilePillarScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('SocialCausePillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const SocialCausePillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SocialCausePillarScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('TierPillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      final oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('FLUTTER_ERROR_DETAILS: ${details.toString()}');
        oldHandler?.call(details);
      };

      await tester.pumpWidget(createTestApp(const TierPillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      FlutterError.onError = oldHandler;

      expect(find.byType(TierPillarScreen), findsOneWidget);
      final err = tester.takeException();
      expect(err, isNull);
    });

    testWidgets('WorkPillarScreen renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const WorkPillarScreen(), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WorkPillarScreen), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });

    testWidgets('PillarsPopupDialog renders without overflow on 1.5K display', (tester) async {
      configureDisplay(tester);
      final eco = EcosystemProvider();

      await tester.pumpWidget(createTestApp(const Scaffold(body: PillarsPopupDialog()), eco));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PillarsPopupDialog), findsOneWidget);
      final err = tester.takeException();

      expect(err, isNull);
    });
  });
}
