import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Hire Gender & Birthday Tests', () {
    late EcosystemProvider eco;

    setUp(() {
      eco = EcosystemProvider();
    });

    test('addNewEmployee registers male staff with birthday and allocates male grooming checklist', () {
      eco.setActiveRole('HR');
      eco.setActiveEmpId('MN-HR1001');

      eco.addNewEmployee(
        name: 'Karthik Raja',
        role: 'Catalog & Inventory Specialist',
        roleType: 'employee',
        dept: 'Operations',
        phone: '+91 98450 11111',
        email: 'karthik@mnj.com',
        experienceCategory: 'standard',
        experienceYears: '1 Year',
        dob: '14-07-1999',
        gender: 'Male',
      );

      final added = eco.employees.firstWhere((e) => e.email == 'karthik@mnj.com');
      expect(added.name, 'Karthik Raja');
      expect(added.dob, '14-07-1999');
      expect(added.gender, 'Male');
      expect(added.isFemale, isFalse);
      expect(added.genderDisplay, 'Male');

      // Check allocated grooming checklist
      final maleChecklist = EcosystemProvider.getMaleGroomingChecklist();
      expect(maleChecklist, contains('Shirt tucked in neatly'));
      expect(maleChecklist, contains('Full hand (full sleeve) formal shirt'));
      expect(maleChecklist, contains('Clean shave / neat beard trim'));
      expect(maleChecklist, contains('Company ID card visibly worn & formal shoes'));
      expect(maleChecklist.length, 5);
    });

    test('addNewEmployee registers female staff with birthday and allocates female saree grooming checklist', () {
      eco.setActiveRole('HR');
      eco.setActiveEmpId('MN-HR1001');

      eco.addNewEmployee(
        name: 'Ananya Sundaram',
        role: 'Customer Care Executive',
        roleType: 'employee',
        dept: 'Operations',
        phone: '+91 98450 22222',
        email: 'ananya@mnj.com',
        experienceCategory: 'standard',
        experienceYears: '2 Years',
        dob: '22-09-2001',
        gender: 'Female',
      );

      final added = eco.employees.firstWhere((e) => e.email == 'ananya@mnj.com');
      expect(added.name, 'Ananya Sundaram');
      expect(added.dob, '22-09-2001');
      expect(added.gender, 'Female');
      expect(added.isFemale, isTrue);
      expect(added.genderDisplay, 'Female');

      // Check allocated female grooming checklist
      final femaleChecklist = EcosystemProvider.getFemaleGroomingChecklist();
      expect(femaleChecklist, contains('Uniform saree properly draped & pinned'));
      expect(femaleChecklist, contains('Neat hairstyle (tied / pinned back)'));
      expect(femaleChecklist, contains('Company ID card visibly worn'));
      expect(femaleChecklist, contains('Formal footwear / closed sandals'));
      expect(femaleChecklist, contains('Professional grooming & minimal jewelry'));
      expect(femaleChecklist.length, 5);
    });

    test('CEO can also register staff with birthday and gender segregation', () {
      eco.setActiveRole('CEO');
      eco.setActiveEmpId('MN-CEO01');

      eco.addNewEmployee(
        name: 'Deepa Lakshmi',
        role: 'Media Production Assistant',
        roleType: 'employee',
        dept: 'Media',
        phone: '+91 98450 33333',
        email: 'deepa@mnjewelpark.com',
        experienceCategory: 'experienced',
        experienceYears: '3+ yrs in Corporate',
        dob: '05-12-1997',
        gender: 'Female',
      );

      final added = eco.employees.firstWhere((e) => e.email == 'deepa@mnjewelpark.com');
      expect(added.name, 'Deepa Lakshmi');
      expect(added.dob, '05-12-1997');
      expect(added.gender, 'Female');
      expect(added.isFemale, isTrue);
    });
  });
}
