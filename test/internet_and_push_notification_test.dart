import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/core/services/network_connectivity_service.dart';
import 'package:mn_family_app/core/services/push_notification_service.dart';
import 'package:mn_family_app/core/widgets/internet_connection_banner.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  setUp(() {
    PushNotificationService.clearTestLogs();
  });

  group('Feature 1: Internet Connection Check and Warning Banner', () {
    testWidgets('Shows "Check your Internet Connection" and X fa fa symbol when offline', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final networkService = NetworkConnectivityService();
      // Simulate offline state
      networkService.setOnlineForTesting(false);

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: Center(child: Text('App Content')),
          ),
          builder: (context, child) => InternetConnectionBanner(child: child!),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the warning text and FontAwesome X symbol appear at the top
      expect(find.text('Check your Internet Connection'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify tapping Retry triggers check
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Now simulate online state
      networkService.setOnlineForTesting(true);
      await tester.pumpAndSettle();

      // Verify banner is hidden
      expect(find.text('Check your Internet Connection'), findsNothing);
    });
  });

  group('Feature 2: Bell Notifications Pushed to Phone (Even if Locked)', () {
    test('Broadcast notifications push to phone and log correctly', () async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-1007'); // Kaaviya

      eco.postBroadcastNotification(
        title: 'Emergency Store Meeting at 06:00 PM',
        content: 'All showroom and online staff mandatory attendance.',
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
      );

      expect(PushNotificationService.testNotificationLog.isNotEmpty, isTrue);
      final lastPush = PushNotificationService.testNotificationLog.last;
      expect(lastPush['title'], 'Emergency Store Meeting at 06:00 PM');
      expect(lastPush['body'], 'All showroom and online staff mandatory attendance.');
    });

    test('To-Do Reminder notification pushes to phone', () async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-1007');

      eco.notifyAllPendingToDosReminder(
        senderName: 'Mohankumar G',
        senderRole: 'HR Manager',
      );

      final reminderPush = PushNotificationService.testNotificationLog.firstWhere(
        (p) => p['title']!.contains('Complete Today\'s To-Do List'),
      );
      expect(reminderPush, isNotNull);
      expect(reminderPush['body'], contains('HR Manager'));
    });

    test('Task allocation pushes direct notification to phone', () async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002');

      eco.assignTask(
        empId: 'MN-1007',
        title: 'Audit Hallmarking Registry Trays',
        category: 'Vault Audit',
        priority: 'Critical SLA',
        due: '05:00 PM',
        assignedByRole: 'Online Team Manager',
        assignedByName: 'Praveenkumar M',
      );

      final taskPush = PushNotificationService.testNotificationLog.firstWhere(
        (p) => p['title']!.contains('Audit Hallmarking Registry Trays'),
      );
      expect(taskPush, isNotNull);
      expect(taskPush['body'], contains('Critical SLA'));
    });
  });
}
