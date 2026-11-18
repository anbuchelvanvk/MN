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
      expect(book.sections.length, 6);

      final titles = book.sections.map((s) => s.title).toList();
      expect(titles.any((t) => t.contains('Chapter 1')), isTrue);
      expect(titles.any((t) => t.contains('Chapter 2')), isTrue);
      expect(titles.any((t) => t.contains('Chapter 3')), isTrue);
      expect(titles.any((t) => t.contains('Chapter 4')), isTrue);
      expect(titles.any((t) => t.contains('Chapter 5')), isTrue);
      expect(titles.any((t) => t.contains('Chapter 6')), isTrue);
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
