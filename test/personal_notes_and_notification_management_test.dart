import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Personal Notes - Confidentiality & CRUD Tests', () {
    test('Personal notes are strictly private to the active employee ID', () {
      final eco = EcosystemProvider();

      // Switch to Employee A (e.g. TL Praveenkumar)
      eco.setActiveRole('dept_head');
      eco.setActiveEmpId('MN-TL1002');
      expect(eco.myPersonalNotes, isEmpty);

      // Add a note as Praveenkumar
      eco.addPersonalNote(
        title: 'TL Private Ideas',
        content: 'Confidential strategy for online sales campaign.',
        colorIndex: 1,
      );

      expect(eco.myPersonalNotes.length, 1);
      expect(eco.myPersonalNotes.first.title, 'TL Private Ideas');
      expect(eco.myPersonalNotes.first.ownerEmpId, 'MN-TL1002');

      // Now switch to CEO (MN-CEO01)
      eco.setActiveRole('ceo');
      eco.setActiveEmpId('MN-CEO01');
      // CEO MUST NOT see Praveenkumar's personal notes!
      expect(eco.myPersonalNotes, isEmpty);

      // CEO adds their own private note
      eco.addPersonalNote(
        title: 'Executive Thoughts',
        content: 'Quarterly review notes and expansions.',
        colorIndex: 2,
        isPinned: true,
      );
      expect(eco.myPersonalNotes.length, 1);
      expect(eco.myPersonalNotes.first.title, 'Executive Thoughts');
      expect(eco.myPersonalNotes.first.ownerEmpId, 'MN-CEO01');

      // Switch to HR (MN-HR1001)
      eco.setActiveRole('hr');
      eco.setActiveEmpId('MN-HR1001');
      expect(eco.myPersonalNotes, isEmpty);

      // Switch back to TL (MN-TL1002) - notes are safely intact!
      eco.setActiveRole('dept_head');
      eco.setActiveEmpId('MN-TL1002');
      expect(eco.myPersonalNotes.length, 1);
      expect(eco.myPersonalNotes.first.title, 'TL Private Ideas');
    });

    test('Personal notes update, toggle pin, and delete workflow', () {
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmpId('MN-EMP001');

      eco.addPersonalNote(title: 'Note 1', content: 'First content');
      final noteId = eco.myPersonalNotes.first.id;

      // Update
      eco.updatePersonalNote(
        noteId: noteId,
        title: 'Note 1 Updated',
        content: 'Modified content',
        colorIndex: 3,
      );
      expect(eco.myPersonalNotes.first.title, 'Note 1 Updated');
      expect(eco.myPersonalNotes.first.content, 'Modified content');
      expect(eco.myPersonalNotes.first.colorIndex, 3);
      expect(eco.myPersonalNotes.first.isPinned, false);

      // Toggle pin
      eco.togglePinPersonalNote(noteId);
      expect(eco.myPersonalNotes.first.isPinned, true);

      // Delete
      eco.deletePersonalNote(noteId);
      expect(eco.myPersonalNotes, isEmpty);
    });
  });

  group('Notification Read & Dismissal Management Tests', () {
    test('Notification read and per-user dismissal logic', () {
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmpId('MN-EMP001');

      // Post a broadcast notification
      eco.postBroadcastNotification(
        title: 'Store Annual Gathering',
        content: 'All staff are cordially invited.',
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
      );

      final notif = eco.companyNotifications.firstWhere((n) => n.title == 'Store Annual Gathering');
      expect(notif.isReadBy('MN-EMP001'), false);
      expect(notif.isDismissedBy('MN-EMP001'), false);
      expect(eco.unreadNotificationCount, greaterThanOrEqualTo(1));

      // Mark as Read for MN-EMP001
      eco.markNotificationAsRead(notif.id);

      final readNotif = eco.companyNotifications.firstWhere((n) => n.id == notif.id);
      expect(readNotif.isReadBy('MN-EMP001'), true);
      // Other staff (MN-TL1002) has not read it
      expect(readNotif.isReadBy('MN-TL1002'), false);

      // Dismiss notification for MN-EMP001
      eco.dismissNotification(notif.id);

      final dismissedNotif = eco.companyNotifications.firstWhere((n) => n.id == notif.id);
      expect(dismissedNotif.isDismissedBy('MN-EMP001'), true);
      // Crucial: not dismissed for other users!
      expect(dismissedNotif.isDismissedBy('MN-TL1002'), false);

      // Active notifications for MN-EMP001 excludes this dismissed notification
      expect(eco.activeCompanyNotifications.any((n) => n.id == notif.id), false);

      // But for MN-TL1002, when switching role, it is STILL active!
      eco.setActiveRole('dept_head');
      eco.setActiveEmpId('MN-TL1002');
      expect(eco.activeCompanyNotifications.any((n) => n.id == notif.id), true);
    });

    test('Clear all read alerts dismisses only read notifications and keeps unread', () {
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmpId('MN-EMP001');

      eco.postBroadcastNotification(
        title: 'Notice Alpha',
        content: 'Alpha details',
        senderName: 'HR',
        senderRole: 'HR Manager',
      );
      eco.postBroadcastNotification(
        title: 'Notice Beta',
        content: 'Beta details',
        senderName: 'HR',
        senderRole: 'HR Manager',
      );

      final notifA = eco.companyNotifications.firstWhere((n) => n.title == 'Notice Alpha');
      final notifB = eco.companyNotifications.firstWhere((n) => n.title == 'Notice Beta');

      // Only mark Notice Alpha as Read
      eco.markNotificationAsRead(notifA.id);

      // Notice Alpha is read, Notice Beta is unread
      expect(eco.companyNotifications.firstWhere((n) => n.id == notifA.id).isReadBy('MN-EMP001'), true);
      expect(eco.companyNotifications.firstWhere((n) => n.id == notifB.id).isReadBy('MN-EMP001'), false);

      // Call clearAllReadNotifications
      eco.clearAllReadNotifications();

      // Notice Alpha was read, so it is now dismissed for MN-EMP001
      expect(eco.activeCompanyNotifications.any((n) => n.id == notifA.id), false);

      // Notice Beta was UNREAD, so it is KEPT!
      expect(eco.activeCompanyNotifications.any((n) => n.id == notifB.id), true);
    });

    test('Mark all as read marks all notifications as read for current user in one go', () {
      final eco = EcosystemProvider();
      eco.setActiveRole('employee');
      eco.setActiveEmpId('MN-EMP002');

      eco.postBroadcastNotification(
        title: 'Broadcast 1',
        senderName: 'CEO',
        senderRole: 'Managing Director & CEO',
      );
      eco.postBroadcastNotification(
        title: 'Broadcast 2',
        senderName: 'CEO',
        senderRole: 'Managing Director & CEO',
      );

      expect(eco.unreadNotificationCount, greaterThanOrEqualTo(2));

      eco.markAllNotificationsAsRead();

      expect(eco.unreadNotificationCount, 0);
      for (final n in eco.activeCompanyNotifications) {
        expect(n.isReadBy('MN-EMP002'), true);
      }
    });
  });
}
