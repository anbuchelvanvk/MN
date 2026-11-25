import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/chat_message_model.dart';
import 'package:mn_family_app/models/company_notification_models.dart';
import 'package:mn_family_app/models/employee_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<EcosystemProvider> ceoWithNewHire() async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x');
    // Older company-wide notice and an older group chat message
    eco.companyNotifications.insert(
      0,
      CompanyNotification(
        id: 'OLD-1',
        title: 'Old notice',
        content: 'From last week',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        senderName: 'HR',
        senderRole: 'HR',
      ),
    );
    eco.chatMessages.add(ChatMessage(
      id: 'OLD-MSG',
      senderId: '65',
      senderName: 'Kaaviya',
      senderRole: 'OS1',
      receiverId: 'ALL_HANDS',
      text: 'Old group message',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
      readBy: const [],
      likedBy: const [],
    ));
    expect(
      eco.addNewEmployee(
        name: 'Ravi Kumar',
        role: 'Online Sale Person 3',
        dept: 'Online Department',
        phone: '9876512345',
        email: 'ravikumar@mnj.com',
        experienceCategory: 'standard',
        experienceYears: '1',
        customEmpId: '401',
        empNo: '401',
      ),
      isNull,
    );
    return eco;
  }

  test('new hire gets a join date and a real date of joining', () async {
    final eco = await ceoWithNewHire();
    final ravi = eco.employees.firstWhere((e) => e.id == '401');
    expect(ravi.joinedAt, isNotNull);
    expect(ravi.doj, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    // joinedAt survives a save/load round trip
    final back = Employee.fromMap(ravi.toMap(), ravi.id);
    expect(back.joinedAt?.millisecondsSinceEpoch, ravi.joinedAt!.millisecondsSinceEpoch);
  });

  test('a welcome line is posted in the group chat', () async {
    final eco = await ceoWithNewHire();
    final line = eco.chatMessages.lastWhere((m) => m.senderId == EcosystemProvider.familyBotId);
    expect(line.receiverId, 'ALL_HANDS');
    expect(line.text, startsWith('Ravi Kumar : '));
    expect(line.text, endsWith('has been added to the group and is now a part of MN Family!'));
  });

  test('the new person sees no older notices but does see the group chat history', () async {
    final eco = await ceoWithNewHire();
    expect(eco.activeCompanyNotifications.any((n) => n.id == 'OLD-1'), isTrue, reason: 'the CEO sees it');

    eco.setActiveEmpId('401'); // Ravi signs in
    expect(eco.activeCompanyNotifications.any((n) => n.id == 'OLD-1'), isFalse);
    // Old group message is still in the conversation…
    expect(eco.getConversation('ALL_HANDS').any((m) => m.id == 'OLD-MSG'), isTrue);
    // …but does not count as unread for him
    expect(eco.getUnreadChatCountFor('ALL_HANDS'), 1, reason: 'only the welcome line after joining');

    // A notice after joining reaches him
    eco.postBroadcastNotification(title: 'New notice', content: 'Today', senderName: 'HR', senderRole: 'HR');
    expect(eco.activeCompanyNotifications.any((n) => n.title == 'New notice'), isTrue);
  });

  test('staff without a recorded join date still see everything', () async {
    final eco = await ceoWithNewHire();
    eco.setActiveEmpId('65');
    expect(eco.currentEmployee.joinedAt, isNull);
    expect(eco.activeCompanyNotifications.any((n) => n.id == 'OLD-1'), isTrue);
  });

  test('relieving posts the farewell line', () async {
    final eco = await ceoWithNewHire();
    eco.tasks.removeWhere((t) => t.empId == '401');
    expect(eco.relieveEmployee('401'), isTrue);
    final line = eco.chatMessages.lastWhere((m) => m.senderId == EcosystemProvider.familyBotId);
    expect(line.text, startsWith('Ravi Kumar : '));
    expect(line.text, endsWith('has officially relieved from MN Jewel Park, but forever a part of our family!'));
  });
}
