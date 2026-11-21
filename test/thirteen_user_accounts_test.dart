import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Master Audit: All 13 Official User Accounts Authentication & Routing', () {
    final accountConfigs = [
      {
        'roleCode': 'CEO',
        'title': 'Managing Director & CEO',
        'email': 'ceoofmn@mnjpark.com',
        'password': 'adminnaandhan',
        'dept': 'Executive Board',
        'expectedRoleType': 'ceo',
        'expectedEmpId': 'MN-CEO01',
      },
      {
        'roleCode': 'HR',
        'title': 'Head of Human Resources',
        'email': 'hr@mnj.com',
        'password': 'hr@mnj123',
        'dept': 'HR & People Ops',
        'expectedRoleType': 'hr',
        'expectedEmpId': '7',
      },
      {
        'roleCode': 'OTM',
        'title': 'Team Lead',
        'email': 'praveenkumarotm@mnj.com',
        'password': 'praveen@mnj123',
        'dept': 'Operations',
        'expectedRoleType': 'dept_head',
        'expectedEmpId': 'MN-TL1002',
      },
      {
        'roleCode': 'OSH',
        'title': 'Online Sale Head',
        'email': 'gokulakrishnanosh@mnj.com',
        'password': 'gokul@mnj123',
        'dept': 'Sales',
        'expectedRoleType': 'employee',
        'expectedEmpId': '6',
      },
      {
        'roleCode': 'VPE',
        'title': 'Chief Photographer & Video Editor',
        'email': 'aravindasamyvpe@mnj.com',
        'password': 'aravind@mnj123',
        'dept': 'Media',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-VPE',
      },
      {
        'roleCode': 'Ass.VPE',
        'title': 'Assistant Photographer & Videographer',
        'email': 'mithraassvpe@mnj.com',
        'password': 'mithra@mnj123',
        'dept': 'Media',
        'expectedRoleType': 'employee',
        'expectedEmpId': '33',
      },
      {
        'roleCode': 'ECE',
        'title': 'E-Commerce Executive',
        'email': 'ece@mnj.com',
        'password': 'ece@mnj123',
        'dept': 'Technology',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-ECE',
      },
      {
        'roleCode': 'OS1',
        'title': 'Online Sale Person 1',
        'email': 'kaaviyaos1@mnj.com',
        'password': 'kaaviya@mnj123',
        'dept': 'Sales',
        'expectedRoleType': 'employee',
        'expectedEmpId': '65',
      },
      {
        'roleCode': 'OS2',
        'title': 'Online Sale Person 2',
        'email': 'nishaos2@mnj.com',
        'password': 'nisha@mnj123',
        'dept': 'Sales',
        'expectedRoleType': 'employee',
        'expectedEmpId': '67',
      },
      {
        'roleCode': 'AC',
        'title': 'Online Analytical Consultant',
        'email': 'midhunkumarac@mnj.com',
        'password': 'midhun@mnj123',
        'dept': 'Accounts',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-AC',
      },
      {
        'roleCode': 'OSS',
        'title': 'Online Support & Strategist',
        'email': 'subashoss@mnj.com',
        'password': 'subash@mnj123',
        'dept': 'Operations',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-OSS',
      },
      {
        'roleCode': 'DVP',
        'title': 'Developer',
        'email': 'eshwardvp@mnj.com',
        'password': 'eshwar@mnj123',
        'dept': 'Technology',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-DVP',
      },
      {
        'roleCode': 'CC',
        'title': 'Content Creator',
        'email': 'samroycc@mnj.com',
        'password': 'samroy@mnj123',
        'dept': 'Media',
        'expectedRoleType': 'employee',
        'expectedEmpId': 'EXT-CC',
      },
    ];

    for (final acc in accountConfigs) {
      test('Account ${acc['roleCode']} (${acc['email']}) logs in successfully and resolves corporate profile', () async {
        final eco = EcosystemProvider();
        final role = await eco.loginWithFirebase(
          email: acc['email']!,
          password: acc['password']!,
        );

        expect(role, equals(acc['expectedRoleType']));
        expect(eco.activeEmpId, equals(acc['expectedEmpId']));

        final emp = eco.currentEmployee;
        expect(emp.id, equals(acc['expectedEmpId']));
        expect(emp.roleCode, equals(acc['roleCode']));

        // Verify correct granular permissions
        if (acc['roleCode'] == 'CEO') {
          expect(emp.canAccessCeoSuite, isTrue);
          expect(emp.canManageRoles, isTrue);
          expect(emp.canExportAudit, isTrue);
        } else if (acc['roleCode'] == 'HR') {
          expect(emp.canAccessHrPortal, isTrue);
          expect(emp.canAssignTasksToOthers, isTrue);
          expect(emp.canAccessCeoSuite, isFalse);
        } else if (acc['roleCode'] == 'OTM') {
          expect(emp.canAccessDeptHeadPortal, isTrue);
          expect(emp.canManageOrders, isTrue);
          expect(emp.canAccessCeoSuite, isFalse);
        } else if (['OSH', 'OS1', 'OS2', 'ECE'].contains(acc['roleCode'])) {
          expect(emp.canManageOrders, isTrue);
          expect(emp.canAccessCeoSuite, isFalse);
        }

        // All accounts have access to 7 pillars by default
        expect(emp.canAccessAttendancePillar, isTrue);
        expect(emp.canAccessHealthPillar, isTrue);
        expect(emp.canAccessFamilyPillar, isTrue);
        expect(emp.canAccessProfilePillar, isTrue);
        expect(emp.canAccessSocialCausePillar, isTrue);
        expect(emp.canAccessTierPillar, isTrue);
        expect(emp.canAccessWorkPillar, isTrue);
      });
    }

    test('Corporate Registry includes all 13 accounts and their aliases', () {
      final reg = EcosystemProvider.corporateRegistry;

      for (final acc in accountConfigs) {
        final email = acc['email']!.toLowerCase();
        expect(reg.containsKey(email), isTrue,
            reason: 'Missing email in registry: $email');
        expect(reg[email]!.empId, equals(acc['expectedEmpId']));
        expect(reg[email]!.roleType, equals(acc['expectedRoleType']));
      }
    });
  });
}
