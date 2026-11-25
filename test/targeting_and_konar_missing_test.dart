import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/models/online_order_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/konar/konar_book_detail_screen.dart';

OnlineOrderModel order(String id, {String handler = '65'}) => OnlineOrderModel(
      orderId: id,
      customerName: 'Test',
      salesChannel: 'WhatsApp',
      handledByEmpId: handler,
      handledByName: 'Kaaviya',
      brand: 'MN Jewel Park',
      expectedDeliveryDate: '',
      createdAt: '2026-11-25',
      stages: OnlineOrderModel.createDefaultStages(),
      checklist: OnlineOrderModel.createDefaultChecklist(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('team lead nudge reaches only their own team', () async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    final team = eco.myTeamMembers.map((e) => e.id).toSet();
    expect(team, isNotEmpty);
    final sent = eco.nudgeMyTeam('Please upload your proofs');
    expect(sent, team.length);
    final n = eco.companyNotifications.first;
    expect(n.targetEmpIds.toSet(), team);
    expect(n.isTargetedFor('MN-CEO01'), isFalse);
    expect(n.isTargetedFor('7'), isFalse, reason: 'HR is not on the team');
    expect(n.isTargetedFor('MN-TL1002'), isFalse, reason: 'the sender does not get their own nudge');
    for (final id in team) {
      expect(n.isTargetedFor(id), isTrue);
    }
  });

  test('online team lead team holds no leadership or other department', () async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    for (final e in eco.myTeamMembers) {
      expect(e.isCeo || e.isHr, isFalse, reason: e.name);
    }
    expect(eco.myTeamMembers.any((e) => e.id == '33'), isTrue);
    // The CEO moves Mithra to a separately created department: she leaves the online team.
    await eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x');
    await eco.createNewDepartment('Showroom Floor');
    await eco.allocateEmployeeRole(empId: '33', newRole: 'Floor Staff', newDept: 'Showroom Floor');
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    expect(eco.myTeamMembers.any((e) => e.id == '33'), isFalse);
  });

  test('order notices go to the people on the order, not the whole company', () async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    final o = order('T-300');
    eco.createOnlineOrder(o);
    eco.requestOrderReassignment(o);
    final req = eco.companyNotifications.first;
    expect(req.targetEmpIds, isNotEmpty);
    expect(req.isTargetedFor('MN-CEO01'), isTrue);
    expect(req.isTargetedFor('33'), isFalse);

    eco.reassignOnlineOrder(orderId: 'T-300', newEmpId: '67', newEmpName: 'Nisha', authorizedBy: 'Praveenkumar M');
    final moved = eco.companyNotifications.first;
    expect(moved.isTargetedFor('67'), isTrue);
    expect(moved.isTargetedFor('65'), isTrue);
    expect(moved.isTargetedFor('33'), isFalse);
  });

  test('company-wide notice without targets still reaches everyone', () {
    final eco = EcosystemProvider();
    eco.postBroadcastNotification(title: 'Diwali timings', content: 'Open till 10 pm', senderName: 'HR', senderRole: 'HR');
    expect(eco.companyNotifications.first.isTargetedFor('33'), isTrue);
  });

  test('a department without a Konar Book has none (no fallback to Online)', () {
    final eco = EcosystemProvider();
    expect(eco.konarBookForDept('Online Department'), isNotNull);
    expect(eco.konarBookForDept('Administration'), isNull);
  });

  testWidgets('staff of a department without a book see the "not uploaded" message', (tester) async {
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        theme: AppThemes.whiteMagentaTheme,
        home: const KonarBookDetailScreen(department: 'Administration'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      find.text('Konar book for your department Administration, has to be uploaded by your TL or CEO. '
          "You'll be notified once it is added."),
      findsOneWidget,
    );
    expect(find.text('Start this Konar Book'), findsNothing, reason: 'HR cannot start it');
  });
}
