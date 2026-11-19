import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/konar_tasks_catalog.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Primary To-Dos Role Code & SOP Verification', () {
    test('All 12 workforce members resolve to their exact role code', () {
      final roleExpectations = {
        'CEO': KonarTaskCatalog.resolveRoleCode(
          'Managing Director & CEO',
          'ceoofmn@mnjpark.com',
          'MN-CEO01',
        ),
        'HR': KonarTaskCatalog.resolveRoleCode(
          'HR Manager & Operations Custodian',
          'hr@mnj.com',
          '7',
        ),
        'OTM': KonarTaskCatalog.resolveRoleCode(
          'Online Team Manager & Video Editor',
          'praveenkumarotm@mnj.com',
          'MN-TL1002',
        ),
        'OSH': KonarTaskCatalog.resolveRoleCode(
          'Online Sales Head',
          'gokulosh@mnj.com',
          '6',
        ),
        'ASS.VPE': KonarTaskCatalog.resolveRoleCode(
          'Assistant Photographer',
          'mithraassvpe@mnj.com',
          '33',
        ),
        'VPE': KonarTaskCatalog.resolveRoleCode(
          'Chief Photographer & Video Editor',
          'aravindvpe@mnj.com',
          'EXT-VPE',
        ),
        'OS1': KonarTaskCatalog.resolveRoleCode(
          'Online Sales Person 1',
          'kaaviyaos1@mnj.com',
          '65',
        ),
        'OS2': KonarTaskCatalog.resolveRoleCode(
          'Online Sales Person 2',
          'nishaos2@mnj.com',
          '67',
        ),
        'AC': KonarTaskCatalog.resolveRoleCode(
          'Analytical Consultant',
          'midhunac@mnj.com',
          'EXT-AC',
        ),
        'OSS': KonarTaskCatalog.resolveRoleCode(
          'Online Support and Strategist',
          'subashoss@mnj.com',
          'EXT-OSS',
        ),
        'DVP': KonarTaskCatalog.resolveRoleCode(
          'Developer',
          'kbeshwar@mnj.com',
          'EXT-DVP',
        ),
        'CC': KonarTaskCatalog.resolveRoleCode(
          'Content Creator',
          'samroycc@mnj.com',
          'EXT-CC',
        ),
      };

      for (final entry in roleExpectations.entries) {
        expect(entry.value, entry.key, reason: 'Role code for ${entry.key} must match exactly');
      }
    });

    test('All 12 employees in EcosystemProvider have guaranteed standard SOP tasks', () {
      final provider = EcosystemProvider();
      final employees = provider.employees;
      expect(employees.length, greaterThanOrEqualTo(12));

      for (final emp in employees) {
        final tasks = provider.getTasksForEmployee(emp.id);
        expect(
          tasks,
          isNotEmpty,
          reason: 'Employee ${emp.name} (${emp.id}, ${emp.role}) must have standard SOP tasks',
        );
        expect(
          tasks.any((t) => t.isDefaultSop),
          isTrue,
          reason: 'Employee ${emp.name} must have isDefaultSop == true tasks',
        );
      }
    });

    test('Mohankumar G (HR Admin) has guaranteed tasks under all alias IDs', () {
      final provider = EcosystemProvider();

      // Check with ID '7'
      provider.setActiveEmpId('7');
      final tasks7 = provider.currentEmployeeTasks;
      expect(tasks7.length, greaterThanOrEqualTo(4));
      expect(tasks7.any((t) => t.id == 'KONAR-HR-01'), isTrue);

      // Check with alias 'MN-HR1001'
      provider.setActiveEmpId('MN-HR1001');
      final tasksHr1001 = provider.currentEmployeeTasks;
      expect(tasksHr1001.length, greaterThanOrEqualTo(4));
      expect(tasksHr1001.any((t) => t.id == 'KONAR-HR-01'), isTrue);

      // Check with alias 'MN-HR001'
      final tasksHr001 = provider.getTasksForEmployee('MN-HR001');
      expect(tasksHr001.length, greaterThanOrEqualTo(4));
      expect(tasksHr001.any((t) => t.id == 'KONAR-HR-01'), isTrue);
    });

    test('Mithra M (ASS.VPE) correctly receives ASS.VPE tasks and NOT HR tasks', () {
      final provider = EcosystemProvider();
      final mithraTasks = provider.getTasksForEmployee('33');

      expect(mithraTasks.any((t) => t.id.startsWith('KONAR-AVPE')), isTrue);
      expect(mithraTasks.any((t) => t.id.startsWith('KONAR-HR')), isFalse);
    });

    test('Work Pillar badge count matches currentEmployeeTasks pending count', () {
      final provider = EcosystemProvider();
      provider.setActiveEmpId('7');

      final pendingCount = provider.currentEmployeeTasks.where((t) => t.status != 'completed').length;
      expect(provider.workPillarBadgeCount, equals(pendingCount));
      expect(provider.todayPendingTodosCount, equals(pendingCount));
    });
  });
}
