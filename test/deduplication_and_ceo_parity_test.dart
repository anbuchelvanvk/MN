import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/konar_book_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Staff Deduplication & Live Roster Tests', () {
    test('EcosystemProvider deduplicates duplicate staff records by normalized name', () {
      final eco = EcosystemProvider();

      // Verify that no duplicate names exist in the initial employees list
      final names = <String>{};
      for (final emp in eco.employees) {
        final norm = emp.name.trim().toLowerCase();
        expect(names.contains(norm), isFalse, reason: 'Duplicate employee found: ${emp.name}');
        names.add(norm);
      }
    });

    test('Online Department KONAR Book strictly contains exactly the 5 authentic architectures', () {
      final book = KonarBookModel.defaultOnlineDepartment();
      expect(book.sections.length, equals(5));

      final sectionTitles = book.sections.map((s) => s.title).toList();
      expect(sectionTitles[0], equals('01 PURPOSE'));
      expect(sectionTitles[1], equals('02 GOALS'));
      expect(sectionTitles[2], equals('03 PROCESS'));
      expect(sectionTitles[3], equals('04 STRUCTURE'));
      expect(sectionTitles[4], equals('05 SYSTEM'));

      final eco = EcosystemProvider();
      final onlineBook = eco.onlineDeptKonarBook;
      expect(onlineBook.sections.length, equals(5));
      expect(onlineBook.sections.first.title, contains('01 PURPOSE'));
    });

    test('EcosystemProvider allows relieving an employee and removes them from active directory', () {
      final eco = EcosystemProvider();
      final initialCount = eco.employees.length;

      // Find an employee to relieve (e.g., someone with roleType employee)
      final empToRelieve = eco.employees.firstWhere((e) => !e.isCeo && !e.isHr);
      final success = eco.relieveEmployee(empToRelieve.id);

      expect(success, isTrue);
      expect(eco.employees.length, equals(initialCount - 1));
      expect(eco.employees.any((e) => e.id == empToRelieve.id), isFalse);
    });

    test('EcosystemProvider toggleEmployeeAbsent toggles absence status', () {
      final eco = EcosystemProvider();
      final targetEmp = eco.employees.firstWhere((e) => e.hasAttendanceAndGrooming);
      final testEmpId = targetEmp.id;

      final wasAbsent = eco.isEmployeeAbsent(testEmpId);
      eco.toggleEmployeeAbsent(testEmpId);
      expect(eco.isEmployeeAbsent(testEmpId), equals(!wasAbsent));

      eco.toggleEmployeeAbsent(testEmpId);
      expect(eco.isEmployeeAbsent(testEmpId), equals(wasAbsent));
    });
  });
}
