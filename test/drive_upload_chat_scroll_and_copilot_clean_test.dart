import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/google_drive_upload_service.dart';
import 'package:mn_family_app/models/family_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/mn_ai_copilot_service.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Drive Upload, Chat Scroll, Copilot & Family Activity Clean UI Tests', () {
    test('1. GoogleDriveUploadService mediaFolderId and mediaWebhookUrl match user configuration', () {
      expect(GoogleDriveUploadService.mediaFolderId, '1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2');
      expect(
        GoogleDriveUploadService.mediaWebhookUrl,
        'https://script.google.com/macros/s/AKfycbzCv4GGti_wzFZy5vilJjiuh-FxDRNQY0c7ENpkV9JYwzaLjDBh65MDbNhvFJl43jYw/exec',
      );
    });

    test('2. AI Copilot welcome message is clean, professional, and free of 5 Konar Books & personalized banner', () {
      final eco = EcosystemProvider();
      final welcome = MnAiCopilotService.buildWelcomeMessage(eco);

      // Verifies clean greeting with employee first name
      final firstName = MnAiCopilotService.extractFirstName(eco.currentEmployee.name);
      expect(welcome, contains('Hello **$firstName**!'));
      expect(welcome, contains("Today's Attendance:"));
      expect(welcome, contains('Active Tasks / To-Dos:'));
      expect(welcome, contains('Emergency Permissions:'));

      // Verifies removal of bulky preamble & 5 Konar Books
      expect(welcome, isNot(contains('5 Konar Books')));
      expect(welcome, isNot(contains('5 Official KONAR Books')));
      expect(welcome, isNot(contains('Personalized Copilot for')));
      expect(welcome, isNot(contains('I have analyzed your live employee profile')));
    });

    test('3. Family Pillar formatDuration produces clean duration strings without awkward plus signs', () {
      expect(formatDuration(0.75), equals('45 mins'));
      expect(formatDuration(1.25), equals('1 hr 15 mins'));
      expect(formatDuration(0.5), equals('30 mins'));
      expect(formatDuration(2.0), equals('2 hrs'));
      expect(formatDuration(1.0), equals('1 hr'));
    });

    test('4. Family Activity metrics calculation sums all logged activities across dates accurately', () {
      final activities = [
        FamilyActivityItem(
          id: 'act-1',
          activityName: 'frnds with work',
          category: 'Friends & Colleagues',
          subCategory: 'Casual Hangout',
          timestamp: DateTime(2026, 11, 19, 17, 30),
          timeString: '5:30 PM',
          hoursSpent: 0.75, // 45 mins
          notes: 'just frnd discuss and fun',
        ),
        FamilyActivityItem(
          id: 'act-2',
          activityName: 'today I visit me frnd shop',
          category: 'Friends & Colleagues',
          subCategory: 'Casual Hangout',
          timestamp: DateTime(2026, 11, 14, 16, 0),
          timeString: '4:00 PM',
          hoursSpent: 0.75, // 45 mins
        ),
        FamilyActivityItem(
          id: 'act-3',
          activityName: 'Family Dinner',
          category: 'Family',
          subCategory: 'Evening Meal',
          timestamp: DateTime(2026, 11, 14, 20, 0),
          timeString: '8:00 PM',
          hoursSpent: 0.5, // 30 mins
        ),
      ];

      final allFamilyHours = activities
          .where((a) => a.category == 'Family')
          .fold(0.0, (sum, a) => sum + a.hoursSpent);
      final allFriendsHours = activities
          .where((a) => a.category != 'Family')
          .fold(0.0, (sum, a) => sum + a.hoursSpent);
      final allTotalHours = allFamilyHours + allFriendsHours;

      expect(formatDuration(allFamilyHours), equals('30 mins'));
      expect(formatDuration(allFriendsHours), equals('1 hr 30 mins'));
      expect(formatDuration(allTotalHours), equals('2 hrs'));
      expect(activities.length, equals(3));
    });
  });
}
