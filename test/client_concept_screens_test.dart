import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/client_concept/concept_home_welcome_screen.dart';
import 'package:mn_family_app/views/client_concept/concept_signup_screen.dart';
import 'package:mn_family_app/views/client_concept/concept_access_screen.dart';
import 'package:mn_family_app/views/client_concept/concept_login_screen.dart';
import 'package:mn_family_app/views/client_concept/concept_employee_home_screen.dart';

Widget wrapWithApp({required Widget child, EcosystemProvider? eco}) {
  return ChangeNotifierProvider<EcosystemProvider>.value(
    value: eco ?? EcosystemProvider(),
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Client Concept UI (Champagne & Wine) Screen Tests', () {
    testWidgets('1. ConceptHomeWelcomeScreen renders all required elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(child: const ConceptHomeWelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MN JEWEL PARK'), findsOneWidget);
      expect(find.text('Where Precision Meets Brilliance'), findsOneWidget);
      expect(find.text('ENTER ECOSYSTEM'), findsOneWidget);
      expect(find.text('PEOPLE'), findsOneWidget);
      expect(find.text('PROCESS'), findsOneWidget);
      expect(find.text('PRECIOUS FUTURE'), findsOneWidget);

      // Tap ENTER ECOSYSTEM to navigate to Access Screen
      await tester.tap(find.text('ENTER ECOSYSTEM'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT YOUR ACCESS'), findsOneWidget);
    });

    testWidgets('2. ConceptSignUpScreen renders 6 pill fields and Sign Up button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(child: const ConceptSignUpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SIGN UP'), findsWidgets);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('3. ConceptAccessScreen renders 4 access cards and navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(child: const ConceptAccessScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SELECT YOUR ACCESS'), findsOneWidget);
      expect(find.text('UNLOCK YOUR BRILLIANCE'), findsOneWidget);
      expect(find.text('Employee'), findsOneWidget);
      expect(find.text('Department Lead'), findsOneWidget);
      expect(find.text('Hr Admin'), findsOneWidget);
      expect(find.text('CEO Command'), findsOneWidget);

      // Tap Employee to navigate to Concept Login
      await tester.tap(find.text('Employee'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsWidgets);
    });

    testWidgets('4. ConceptLoginScreen renders inputs, biometric and signs in', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithApp(child: const ConceptLoginScreen(defaultRole: 'employee')));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN'), findsWidgets);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Or'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);

      // Tap LOGIN to proceed to Employee Home
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('On track'), findsOneWidget);
      expect(find.text('Gold Hallmarking & Quality Training'), findsOneWidget);
    });

    testWidgets('5. ConceptEmployeeHomeScreen renders progress, actions, and 6 focus cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      await tester.pumpWidget(wrapWithApp(
        child: const ConceptEmployeeHomeScreen(
          employeeId: 'MN-1024',
          roleKey: 'employee',
        ),
        eco: eco,
      ));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('MN JEWEL PARK'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
      expect(find.textContaining('Hi, '), findsOneWidget);

      // Verify Progress Card
      expect(find.text('Gold Hallmarking & Quality Training'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Step 3 of 4: Hallmark Verification'), findsOneWidget);

      // Verify 4 Quick Action Buttons
      expect(find.text('Work List'), findsOneWidget);
      expect(find.text('Growth Hub'), findsOneWidget);
      expect(find.text('Away Desk'), findsOneWidget);
      expect(find.text('Business Brief'), findsOneWidget);

      // Verify Today's Prime Focus (6)
      expect(find.text("Today's Prime Focus (6)"), findsOneWidget);
      expect(find.text('+ Add Focus'), findsOneWidget);

      // Verify all 6 cards exactly matching user design
      expect(find.text('Dawn Of Excellence'), findsOneWidget);
      expect(find.text('Due 11:00 AM'), findsOneWidget);
      expect(find.text('GoldGuard Reconciliation'), findsOneWidget);
      expect(find.text('Due 12.00 PM'), findsOneWidget);
      expect(find.text('KaratSure Quality Gate'), findsOneWidget);
      expect(find.text('Due 1:00 PM'), findsOneWidget);
      expect(find.text('Artisan Craftline'), findsOneWidget);
      expect(find.text('Due 2:00 PM'), findsOneWidget);
      expect(find.text('StockFlow & Order Fulfilment'), findsOneWidget);
      expect(find.text('Due 3:00 PM'), findsOneWidget);
      expect(find.text('Golden Seal Closure'), findsOneWidget);
      expect(find.text('Due 6:00 PM'), findsOneWidget);
    });
  });
}
