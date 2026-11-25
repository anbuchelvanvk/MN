import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

/// Departments are created by the CEO; the CEO also hires here.
Future<EcosystemProvider> asHr() async {
  final eco = EcosystemProvider();
  await eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x');
  return eco;
}

String? hire(EcosystemProvider eco, String id, String name, String dept, {bool lead = false}) => eco.addNewEmployee(
      name: name,
      role: lead ? 'Team Lead' : 'Floor Staff',
      roleType: lead ? 'team_lead' : 'employee',
      dept: dept,
      phone: '9876500$id',
      email: '${name.toLowerCase().replaceAll(' ', '')}@mnj.com',
      experienceCategory: 'standard',
      experienceYears: '1',
      customEmpId: id,
      empNo: id,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a TL hired into a new department leads exactly that team', () async {
    final eco = await asHr();
    await eco.createNewDepartment('Showroom Floor');
    expect(hire(eco, '201', 'Ravi Kumar', 'Showroom Floor', lead: true), isNull);
    expect(hire(eco, '202', 'Meena S', 'Showroom Floor'), isNull);
    expect(hire(eco, '203', 'Arun P', 'Showroom Floor'), isNull);

    expect(eco.teamLeadOf('Showroom Floor')?.name, 'Ravi Kumar');
    final ravi = eco.employees.firstWhere((e) => e.id == '201');
    expect(ravi.isTeamLead, isTrue);

    // Signed in as Ravi: his team is exactly the two Showroom Floor staff
    eco.setActiveEmpId('201');
    expect(eco.myTeamMembers.map((e) => e.id).toSet(), {'202', '203'});

    // The online team lead's team does not include them
    eco.setActiveEmpId('MN-TL1002');
    expect(eco.myTeamMembers.any((e) => e.dept == 'Showroom Floor'), isFalse);
  });

  test('a second team lead for the same team is refused', () async {
    final eco = await asHr();
    await eco.createNewDepartment('Showroom Floor');
    expect(hire(eco, '201', 'Ravi Kumar', 'Showroom Floor', lead: true), isNull);
    final refused = hire(eco, '204', 'Kumar R', 'Showroom Floor', lead: true);
    expect(refused, contains('Ravi Kumar is already the team lead of Showroom Floor'));
    expect(eco.employees.any((e) => e.id == '204'), isFalse);

    // The online team already has Praveenkumar
    expect(hire(eco, '205', 'New Lead', 'Online Department', lead: true), contains('Praveenkumar'));

    // Promoting someone to TL of a team that has one is refused too
    expect(hire(eco, '206', 'Staff One', 'Showroom Floor'), isNull);
    final promo = await eco.allocateEmployeeRole(empId: '206', newRole: 'Team Lead', newDept: 'Showroom Floor');
    expect(promo, contains('already the team lead'));
    expect(eco.employees.firstWhere((e) => e.id == '206').isTeamLead, isFalse);
  });

  test('job titles with "lead" or "manager" do not make someone a team lead', () {
    expect(EcosystemProvider.roleTypeForTitle('Lead Videographer & Editor'), 'employee');
    expect(EcosystemProvider.roleTypeForTitle('Store Manager Assistant'), 'employee');
    expect(EcosystemProvider.roleTypeForTitle('Chief Photographer'), 'employee');
    expect(EcosystemProvider.roleTypeForTitle('Assistant Team Lead'), 'employee');
    expect(EcosystemProvider.roleTypeForTitle('Team Lead'), 'team_lead');
    expect(EcosystemProvider.roleTypeForTitle('Online Team Manager (OTM)'), 'team_lead');
    expect(EcosystemProvider.roleTypeForTitle('HR Manager'), 'hr');
  });

  test('the TL picks one Assistant TL from their own team', () async {
    final eco = await asHr();
    await eco.createNewDepartment('Showroom Floor');
    hire(eco, '201', 'Ravi Kumar', 'Showroom Floor', lead: true);
    hire(eco, '202', 'Meena S', 'Showroom Floor');
    hire(eco, '203', 'Arun P', 'Showroom Floor');
    eco.setActiveEmpId('201');

    expect(await eco.setAssistantLead('202'), isNull);
    expect(eco.assistantLeadOf('Showroom Floor')?.name, 'Meena S');
    expect(eco.isAssistantLead('202'), isTrue);

    // Changing it replaces, never two assistants
    expect(await eco.setAssistantLead('203'), isNull);
    expect(eco.isAssistantLead('202'), isFalse);
    expect(eco.isAssistantLead('203'), isTrue);

    // Someone from another team cannot be chosen
    expect(await eco.setAssistantLead('65'), contains('own team'));

    // Clear it
    expect(await eco.setAssistantLead(null), isNull);
    expect(eco.assistantLeadOf('Showroom Floor'), isNull);

    // A regular staff member cannot choose
    eco.setActiveEmpId('202');
    expect(await eco.setAssistantLead('203'), contains('Only the team lead'));
  });
}
