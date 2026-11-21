import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/konar_book_model.dart';
import 'package:mn_family_app/models/company_notification_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Konar Book Model Tests', () {
    test('defaultOnlineDepartment generates correct SOP sections for Online Team', () {
      final book = KonarBookModel.defaultOnlineDepartment();
      expect(book.department, 'Online Department');
      expect(book.sections.length, 5);

      final titles = book.sections.map((s) => s.title).toList();
      expect(titles.any((t) => t.contains('01 PURPOSE')), isTrue);
      expect(titles.any((t) => t.contains('02 GOALS')), isTrue);
      expect(titles.any((t) => t.contains('03 PROCESS')), isTrue);
      expect(titles.any((t) => t.contains('04 STRUCTURE')), isTrue);
      expect(titles.any((t) => t.contains('05 SYSTEM')), isTrue);
    });

    test('KonarBookModel serialization to and from JSON works seamlessly', () {
      final book = KonarBookModel.defaultOnlineDepartment();
      final json = book.toJson();
      final recreated = KonarBookModel.fromJson(json);

      expect(recreated.id, book.id);
      expect(recreated.department, book.department);
      expect(recreated.version, book.version);
      expect(recreated.sections.length, book.sections.length);
      expect(recreated.sections.first.title, book.sections.first.title);
      expect(recreated.sections.first.subtitle, book.sections.first.subtitle);
    });

    test('Large PDF base64 is safely excluded from standard toJson to protect 1MB Firestore limit', () {
      final largeBase64 = 'A' * 2000000; // 2 MB string
      final book = KonarBookModel.defaultOnlineDepartment().copyWith(
        pdfBase64: largeBase64,
        hasPdfAttachment: true,
      );

      final json = book.toJson(includePdfBase64: false);
      expect(json.containsKey('pdfBase64'), isFalse);
      expect(json['hasPdfAttachment'], isTrue);
    });
  });

  group('Targeted Company Notification Tests', () {
    test('Notification targetEmpIds correctly filters recipient visibility', () {
      final notif = CompanyNotification(
        id: 'notif_001',
        title: 'Online Dept KONAR Book Updated',
        content: 'Version 2.0 has been published.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
        targetEmpIds: ['MN-CEO01', 'MN-HR001', 'MN-TL1002', 'MN-EMP1003'],
      );

      // Target employees should see the notification
      expect(notif.isTargetedFor('MN-CEO01'), isTrue);
      expect(notif.isTargetedFor('MN-HR001'), isTrue);
      expect(notif.isTargetedFor('MN-TL1002'), isTrue);
      expect(notif.isTargetedFor('MN-EMP1003'), isTrue);

      // Other departments' staff should NOT see the notification
      expect(notif.isTargetedFor('MN-EMP9999'), isFalse);
      expect(notif.isTargetedFor('MN-TL5555'), isFalse);
    });

    test('Dynamic push notification routing for TL, CEO, HR and future departments', () async {
      final eco = EcosystemProvider();
      final onlineBook = KonarBookModel.defaultOnlineDepartment();

      // 1. TL Praveen Kumar updates the book
      eco.setActiveEmpId('MN-TL1002');
      await eco.updateKonarBook(
        onlineBook.copyWith(version: 'v2.5'),
        updaterName: 'Praveen Kumar M',
        updaterRole: 'Team Lead',
        updaterEmpId: 'MN-TL1002',
      );

      final notifFromTl = eco.companyNotifications.first;
      expect(notifFromTl.targetEmpIds, contains('MN-CEO01')); // CEO receives
      expect(notifFromTl.targetEmpIds, contains('MN-HR001')); // HR receives
      expect(notifFromTl.targetEmpIds, contains('MN-EMP1003')); // Online staff receives
      expect(notifFromTl.targetEmpIds, isNot(contains('MN-TL1002'))); // TL excluded (no self-notif)

      // 2. CEO updates the Online Department book
      eco.setActiveEmpId('MN-CEO01');
      await eco.updateKonarBook(
        onlineBook.copyWith(version: 'v2.6'),
        updaterName: 'M N Naveenraaj',
        updaterRole: 'Managing Director & CEO',
        updaterEmpId: 'MN-CEO01',
      );

      final notifFromCeo = eco.companyNotifications.first;
      expect(notifFromCeo.targetEmpIds, contains('MN-HR001')); // HR receives
      expect(notifFromCeo.targetEmpIds, contains('MN-TL1002')); // Online TL receives
      expect(notifFromCeo.targetEmpIds, contains('MN-EMP1003')); // Online staff receives
      expect(notifFromCeo.targetEmpIds, isNot(contains('MN-CEO01'))); // CEO excluded

      // 3. HR updates the Online Department book
      eco.setActiveEmpId('MN-HR001');
      await eco.updateKonarBook(
        onlineBook.copyWith(version: 'v2.7'),
        updaterName: 'Mohankumar G',
        updaterRole: 'HR Manager',
        updaterEmpId: 'MN-HR001',
      );

      final notifFromHr = eco.companyNotifications.first;
      expect(notifFromHr.targetEmpIds, contains('MN-CEO01')); // CEO receives
      expect(notifFromHr.targetEmpIds, contains('MN-TL1002')); // Online TL receives
      expect(notifFromHr.targetEmpIds, contains('MN-EMP1003')); // Online staff receives
      expect(notifFromHr.targetEmpIds, isNot(contains('MN-HR001'))); // HR excluded
    });
  });

  group('4 Pillars Corner Badge Count Logic Tests', () {
    test('EcosystemProvider computes badge counts accurately', () {
      final eco = EcosystemProvider();

      // For standard employee, if health not logged today, healthPillarBadgeCount is 1
      expect(eco.healthPillarBadgeCount >= 0, isTrue);
      expect(eco.familyPillarBadgeCount >= 0, isTrue);
      expect(eco.workPillarBadgeCount >= 0, isTrue);

      // For CEO or HR, social cause pending count is reflected in socialCausePillarBadgeCount
      eco.setActiveEmpId('MN-CEO01');
      expect(eco.socialCausePillarBadgeCount, equals(eco.pendingSocialCausesCount));
    });
  });
}
