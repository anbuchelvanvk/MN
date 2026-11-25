import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/core/widgets/birthday_crown.dart';

void main() {
  test('birthday is matched on day and month, either date format', () {
    final now = DateTime(2026, 11, 25);
    expect(isBirthdayToday('1999-11-25', now: now), isTrue);
    expect(isBirthdayToday('25-11-1999', now: now), isTrue);
    expect(isBirthdayToday('25/11/1999', now: now), isTrue);
    expect(isBirthdayToday('1999-11-24', now: now), isFalse);
    expect(isBirthdayToday('', now: now), isFalse);
    expect(isBirthdayToday('2000-02-29', now: DateTime(2027, 2, 28)), isTrue, reason: 'leap-day birthday in a normal year');
    expect(isBirthdayToday('2000-02-29', now: DateTime(2028, 2, 28)), isFalse);
  });

  testWidgets('crown shows only on the birthday', (tester) async {
    Widget host(bool show) => MaterialApp(
          home: Center(
            child: BirthdayCrown(
              show: show,
              size: 74,
              child: const CircleAvatar(radius: 37, child: Text('K')),
            ),
          ),
        );
    await tester.pumpWidget(host(false));
    expect(find.byKey(const Key('birthday_crown')), findsNothing);
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('birthday_crown')), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
  });
}
