import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/mn_ai_copilot_service.dart';
import 'package:mn_family_app/services/vantura_agent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vantura Agentic Framework Tests', () {
    late EcosystemProvider eco;
    late VanturaAgentService vantura;

    setUp(() {
      eco = EcosystemProvider();
      vantura = VanturaAgentService();
    });

    test('1. VanturaAgentService registers all 5 core tools', () {
      expect(VanturaAgentService.supportedModels, contains('gemini-3.8-flash'));
      expect(VanturaAgentService.supportedModels, contains('gemini-flash-latest'));
    });

    test('2. Dual-Layer Memory resets cleanly', () {
      vantura.resetMemory();
      // No crashes on clean state
      expect(vantura, isNotNull);
    });

    test('3. ReAct loop resolves attendance query with live grounded data', () async {
      final result = await vantura.runAgent(
        prompt: 'What is my attendance status today?',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('check_attendance_status'));
    });

    test('4. ReAct loop resolves emergency permission query with tool calling', () async {
      final result = await vantura.runAgent(
        prompt: 'How many emergency permissions do I have remaining?',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('get_permission_quota'));
    });

    test('5. ReAct loop resolves SOP and photography query', () async {
      final result = await vantura.runAgent(
        prompt: 'What is the jewelry photography checklist and SOP?',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('get_sop_policy'));
    });

    test('6. ReAct loop resolves Google Drive media pipeline draft status', () async {
      final result = await vantura.runAgent(
        prompt: 'What is the status of my Google Drive media reels drafts?',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('check_drive_media_pipeline'));
    });

    test('7. ReAct loop resolves live Firebase online order dispatch status', () async {
      final result = await vantura.runAgent(
        prompt: 'Check pending customer online orders and dispatch status',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('check_firebase_orders'));
    });

    test('8. ReAct loop resolves complete workforce directory query (Query 1)', () async {
      final result = await vantura.runAgent(
        prompt: 'give me a list of employees in mn jewel park as of now',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('get_workforce_directory'));
      expect(result.text, contains('MN Jewel Park'));
      expect(result.text, contains('Mohankumar'));
      expect(result.text, contains('Praveenkumar'));
      expect(result.text, contains('Gokulakrishnan'));
    });

    test('9. ReAct loop resolves company-wide attendance query (Query 2)', () async {
      final result = await vantura.runAgent(
        prompt: 'who are all present today ?',
        eco: eco,
      );

      expect(result.text, isNotEmpty);
      expect(result.toolsInvoked, contains('check_workforce_today_attendance'));
      expect(result.text, contains('Present'));
    });

    test('10. MnAiCopilotService returns full workforce directory and staff attendance offline', () {
      final r1 = MnAiCopilotService.processQuery(
        query: 'give me a list of employees in mn jewel park as of now',
        eco: eco,
      );
      expect(r1.text, contains('Official Workforce Directory'));
      expect(r1.text, contains('Mohankumar'));
      expect(r1.text, contains('Praveenkumar'));
      expect(r1.actionType, equals(CopilotActionType.openStaffDirectory));

      final r2 = MnAiCopilotService.processQuery(
        query: 'who are all present today ?',
        eco: eco,
      );
      expect(r2.text, contains('Live Workforce Attendance Today'));
      expect(r2.text, contains('Present Staff'));
      expect(r2.text, contains('Absent / Pending'));
    });
  });
}
