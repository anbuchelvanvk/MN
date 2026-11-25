import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/data_vault_service.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/data_vault_screen.dart';

final sample = <String, dynamic>{
  'format': 'mn-family-backup',
  'version': 1,
  'createdAt': '2026-11-25T08:00:00.000Z',
  'createdBy': 'ceoofmn@mnjpark.com',
  'counts': {'social_causes': 2, 'company_notifications': 1, 'online_department_employees': 1},
  'collections': {
    'social_causes': [
      {
        'id': 'S1',
        'data': {
          'title': 'Food for elders',
          'amountSpent': 500,
          'status': 'approved',
          'date': {'__type': 'timestamp', 'value': '2026-11-20T10:00:00.000Z'},
        },
      },
      {'id': 'S2', 'data': {'title': 'Blood donation', 'amountSpent': 0}},
    ],
    'company_notifications': [
      {'id': 'N1', 'data': {'title': 'November 22nd Attendance Update'}},
    ],
    'online_department_employees': [
      {'id': 'E1', 'data': {'name': 'Kaaviya', 'fourPillars': {'health': {'steps': 4000}}}},
    ],
  },
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses a backup file and rejects other files', () {
    final parsed = DataVaultService.parseFile(utf8.encode(jsonEncode(sample)));
    expect(DataVaultService.totalDocs(parsed), 4);
    expect(() => DataVaultService.parseFile(utf8.encode('{"hello":1}')), throwsA(isA<DataVaultException>()));
    expect(() => DataVaultService.parseFile(utf8.encode('not json')), throwsA(isA<DataVaultException>()));
  });

  test('readable labels and dates', () {
    expect(collectionLabel('social_causes'), 'Social causes');
    expect(collectionLabel('online_department_employees'), 'Staff – Online department');
    expect(readableValue({'__type': 'timestamp', 'value': '2026-11-20T10:00:00.000Z'}), contains('Nov 2026'));
  });

  testWidgets('backup viewer shows sections, records and details', (tester) async {
    final eco = EcosystemProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        theme: AppThemes.whiteMagentaTheme,
        home: BackupViewerScreen(backup: sample, fileName: 'MN-Family-backup.json'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('4 records'), findsOneWidget);
    expect(find.text('Social causes'), findsOneWidget);
    expect(find.text('Restore this backup'), findsOneWidget);

    await tester.tap(find.text('Social causes'));
    await tester.pumpAndSettle();
    expect(find.text('Food for elders'), findsOneWidget);
    expect(find.text('Blood donation'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'blood');
    await tester.pumpAndSettle();
    expect(find.text('Food for elders'), findsNothing);

    await tester.tap(find.text('Blood donation'));
    await tester.pumpAndSettle();
    expect(find.text('amountSpent'), findsOneWidget);
  });

  testWidgets('data vault screen shows backup, open and delete', (tester) async {
    final eco = EcosystemProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(theme: AppThemes.whiteMagentaTheme, home: const DataVaultScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Download backup'), findsOneWidget);
    expect(find.text('Choose backup file'), findsOneWidget);
    expect(find.text('Delete everything…'), findsOneWidget);

    await tester.ensureVisible(find.text('Delete everything…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete everything…'));
    await tester.pumpAndSettle();
    final deleteBtn = find.widgetWithText(FilledButton, 'Delete');
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNull); // locked until DELETE typed
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
