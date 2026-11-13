import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/auth/pillars_popup_dialog.dart';
import 'package:mn_family_app/views/employee/employee_portal_screen.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_screen.dart';
import 'package:mn_family_app/views/ceo/ceo_suite_screen.dart';
import 'package:mn_family_app/views/orders/online_orders_handler_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_subpages.dart';
import 'package:mn_family_app/views/hr/hr_employee_inspection_screen.dart';
import 'package:mn_family_app/views/hr/hr_biometric_punch_audit_screen.dart';
import 'package:mn_family_app/views/pillars/profile_pillar_screen.dart';
import 'package:mn_family_app/views/ceo/ceo_subpages.dart';
import 'package:mn_family_app/views/dept_head/dept_head_subpages.dart';
import 'package:mn_family_app/views/employee/employee_subpages.dart';

Widget wrapWithApp({required Widget child, EcosystemProvider? eco, double textScale = 1.0}) {
  return ChangeNotifierProvider<EcosystemProvider>.value(
    value: eco ?? EcosystemProvider(),
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> dismissPillarsPopupIfPresent(WidgetTester tester) async {
  if (find.byType(PillarsPopupDialog).evaluate().isNotEmpty) {
    final closeBtn = find.descendant(
      of: find.byType(PillarsPopupDialog),
      matching: find.byIcon(Icons.close),
    );
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mobileSizes = [
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
  ];

  for (final size in mobileSizes) {
    group('Mobile Display Overflow Audit at ${size.width}x${size.height}', () {
      testWidgets('HR Portal screen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-HR1001');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const HrPortalScreen(), eco: eco));
        await tester.pumpAndSettle();
        await dismissPillarsPopupIfPresent(tester);

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('CEO Suite screen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-CEO01');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const CeoSuiteScreen(), eco: eco));
        await tester.pumpAndSettle();
        await dismissPillarsPopupIfPresent(tester);

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('Team Lead (Dept Head) Portal screen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-TL1002');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const DeptHeadPortalScreen(), eco: eco));
        await tester.pumpAndSettle();
        await dismissPillarsPopupIfPresent(tester);

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('Employee Portal screen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-1003');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const EmployeePortalScreen(), eco: eco));
        await tester.pumpAndSettle();
        await dismissPillarsPopupIfPresent(tester);

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('Online Orders Handler Screen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-TL1002');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const OnlineOrdersHandlerScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('HrStaffDirectoryScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-HR1001');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const HrStaffDirectoryScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('HrAttendanceScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-HR1001');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const HrAttendanceScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('HrBiometricPunchAuditScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-HR1001');

        FlutterErrorDetails? caughtDetails;
        final origOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
          origOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(
          child: HrBiometricPunchAuditScreen(employee: eco.employees.first),
          eco: eco,
        ));
        await tester.pumpAndSettle();

        FlutterError.onError = origOnError;
        if (caughtDetails != null) {
          debugPrint('CAUGHT_DETAILS_SUMMARY: ${caughtDetails?.summary}');
          debugPrint('CAUGHT_DETAILS_CONTEXT: ${caughtDetails?.context}');
          debugPrint('CAUGHT_DETAILS_INFORMATION: ${caughtDetails?.informationCollector?.call().map((d) => d.toString()).join("\n")}');
        }

        final err = tester.takeException();
        expect(err, isNull);
      });

      testWidgets('HrEmployeeInspectionScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-HR1001');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(
          child: HrEmployeeInspectionScreen(employee: eco.employees.first),
          eco: eco,
        ));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('CeoStaffDossiersScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-CEO01');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const CeoStaffDossiersScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('CeoAttendanceScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-CEO01');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const CeoAttendanceScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('CeoRolesPrivilegesScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-CEO01');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const CeoRolesPrivilegesScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('TlTeamTasksScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-TL1002');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const TlTeamTasksScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('TlTeamAttendanceScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-TL1002');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const TlTeamAttendanceScreen(), eco: eco));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('EmployeeThingsToDoScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-1003');

        FlutterErrorDetails? caughtDetails;
        final origOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
          origOnError?.call(details);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const EmployeeThingsToDoScreen(), eco: eco));
        await tester.pumpAndSettle();

        FlutterError.onError = origOnError;
        if (caughtDetails != null) {
          debugPrint('EMPLOYEE_TODO_SUMMARY: ${caughtDetails?.summary}');
          debugPrint('EMPLOYEE_TODO_INFORMATION: ${caughtDetails?.informationCollector?.call().map((d) => d.toString()).join("\n")}');
        }

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint('OVERFLOW WIDGET TREE:\n${err.toStringDeep()}');
        } else if (err != null) {
          debugPrint('OVERFLOW ERROR DETAILS: $err');
        }
        expect(err, isNull);
      });

      testWidgets('ProfilePillarScreen does not overflow', (tester) async {
        final eco = EcosystemProvider();
        eco.setActiveEmpId('MN-1004');

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapWithApp(child: const ProfilePillarScreen(), eco: eco));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  }
}
