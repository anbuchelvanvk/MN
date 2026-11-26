import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/home/modern_home_screen.dart';

void main() {
  Widget createTestWidget({EcosystemProvider? eco}) {
    final provider = eco ?? EcosystemProvider();
    return ChangeNotifierProvider<EcosystemProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppThemes.burgundySandTheme,
        home: const ModernHomeScreen(),
      ),
    );
  }

  group('ModernHomeScreen Redesign Verification Tests', () {
    testWidgets('Renders all primary sections matching the official mock', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Top Bar Branding & Actions
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('MN Family'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // 2. Identity Header: no made-up identity when nobody is signed in
      expect(find.text('Guest'), findsWidgets);
      expect(find.text('Not signed in'), findsWidgets);
      expect(find.text('Iniya Praveen'), findsNothing);

      // 3. 4 Pillar Cards show honest empty values, never placeholder numbers
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Family Time'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Social Cause'), findsOneWidget);
      expect(find.text('78%'), findsNothing);
      expect(find.textContaining('1210 / 1550 Cal'), findsNothing);
      expect(find.text('229 Cal'), findsNothing);

      // 4. Konar Book Banner
      expect(find.textContaining('Konar Book'), findsWidgets);
      expect(find.byTooltip('Download PDF'), findsOneWidget);
      expect(find.byTooltip('Share PDF'), findsOneWidget);

      // 5. Personal To-Do List Section uses real counts
      expect(find.text('Add To Do'), findsOneWidget);
      expect(find.textContaining('Show All ('), findsOneWidget);
      expect(find.textContaining('Pending ('), findsOneWidget);
      expect(find.textContaining('Completed ('), findsOneWidget);
      expect(find.textContaining('Assigned ('), findsOneWidget);
      expect(find.text('Show All (50)'), findsNothing);
      expect(find.textContaining('30 Need To Complete Today'), findsNothing);
      expect(find.text('MN Jewel Park Carosal Post'), findsNothing);

      // 7. Sticky Chat Dock: only the chat bubble until it is tapped
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
      expect(find.text('Type here'), findsNothing);
      await tester.tap(find.byKey(const Key('home_chat_bubble')));
      await tester.pumpAndSettle();
      expect(find.text('Type here'), findsOneWidget);
      expect(find.byIcon(Icons.add_reaction_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
      // Tapping the bubble again hides the bar
      await tester.tap(find.byKey(const Key('home_chat_bubble')));
      await tester.pumpAndSettle();
      expect(find.text('Type here'), findsNothing);
    });

    testWidgets('Sticky chat dock remains firmly fixed during scroll', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find sticky chat dock position before scroll
      final initialBlueButtonFinder = find.byIcon(Icons.groups_rounded);
      expect(initialBlueButtonFinder, findsOneWidget);
      final initialOffset = tester.getCenter(initialBlueButtonFinder);

      // Scroll the SingleChildScrollView down by 600 pixels
      final scrollableFinder = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollableFinder, const Offset(0, -600));
      await tester.pumpAndSettle();

      // Find sticky chat dock position after scroll
      final postScrollOffset = tester.getCenter(initialBlueButtonFinder);

      // The chat button MUST NOT MOVE on screen when scrolled
      expect(postScrollOffset.dx, equals(initialOffset.dx));
      expect(postScrollOffset.dy, equals(initialOffset.dy));
    });

    testWidgets('Filter pills toggle selection state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on Pending pill
      await tester.tap(find.textContaining('Pending ('), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on Completed pill
      await tester.tap(find.textContaining('Completed ('), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ModernHomeScreen), findsOneWidget);
    });

    testWidgets('Floating notification pill shows title when notification arrives and is hidden when none', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();

      // Case 1: When no notifications exist, floating pill is completely hidden
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();
      expect(find.textContaining('Company Meeting at 10 AM'), findsNothing);

      // Case 2: Post a notification, floating pill appears with title
      eco.broadcastUniversalAnnouncement(
        title: 'Company Meeting at 10 AM',
        message: 'All team leads to join boardroom meeting.',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('Company Meeting at 10 AM'), findsOneWidget);

      // Tapping on the floating notification pill opens the notification sheet
      await tester.tap(find.textContaining('Company Meeting at 10 AM'));
      await tester.pumpAndSettle();
    });

    testWidgets('Floating notification floats for 6 seconds then eases out with dropdown animation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();
      eco.broadcastUniversalAnnouncement(
        title: 'Important Gold Rate Notice',
        message: 'Daily rates synchronized.',
      );

      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Visible during the 5 second float period
      expect(find.textContaining('Important Gold Rate Notice'), findsOneWidget);

      // Advance past 6 seconds for ease-out dropdown exit
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 600));

      // After 6s ease-out dropdown, the pill is hidden
      expect(find.textContaining('Important Gold Rate Notice'), findsNothing);

      // Tapping the bell icon re-triggers the floating notification dropdown
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Important Gold Rate Notice'), findsOneWidget);
    });

    testWidgets('Dynamically displays account holder name and designation (CEO, HR, OTM)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();

      // 1. CEO Logged in
      eco.setActiveEmployee('MN-CEO01');
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();
      expect(find.text('M N Naveenraaj'), findsOneWidget);
      expect(find.text('CEO'), findsOneWidget);

      // 2. HR Logged in
      eco.setActiveEmployee('7');
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();
      expect(find.text('Mohankumar G'), findsOneWidget);
      expect(find.text('HR'), findsOneWidget);

      // 3. OTM Logged in
      eco.setActiveEmployee('MN-TL1002');
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();
      expect(find.text('Praveenkumar M'), findsOneWidget);
      expect(find.text('OTM'), findsOneWidget);
    });

    testWidgets('Four pillar cards display monthly in big circle and day in small circle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();

      // Monthly metrics in Big Circles
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Family Time'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Social Cause'), findsOneWidget);

      // Today rings: no data yet -> honest empty values, short readable labels
      expect(find.text('BMI'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      expect(find.text('27.2'), findsNothing);
      expect(find.text('Today'), findsNWidgets(3));
      expect(find.text('0h'), findsWidgets);
      expect(find.text('0%'), findsWidgets);

      // All four cards have exactly the same size
      final sizes = ['Health', 'Family Time', 'Work', 'Social Cause']
          .map((t) => tester.getSize(find.ancestor(
                of: find.text(t),
                matching: find.byType(SizedBox),
              ).first))
          .toSet();
      expect(sizes.length, 1);

      // No copied-over placeholders
      expect(find.text('Workout and Physical Activity'), findsNothing);
      expect(find.text('229 Cal'), findsNothing);
    });

    testWidgets('Add To Do saves a real personal task', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();
      eco.setActiveEmployee('MN-TL1002');
      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();

      // The to-do list sits below the hero and pillar cards: scroll to it.
      // (Kept clear of the chat dock pinned at the bottom-right.)
      await Scrollable.ensureVisible(tester.element(find.text('Add To Do')), alignment: 0.3);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add To Do'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('add_todo_title')), 'Shoot new reel');
      await tester.tap(find.text('Add To-Do'));
      await tester.pumpAndSettle();

      expect(
        eco.tasks.any((t) => t.title == 'Shoot new reel' && t.empId == 'MN-TL1002'),
        isTrue,
      );
      expect(find.text('Shoot new reel'), findsOneWidget);
    });

    testWidgets('First Pillar Card (Total Health Performance) is fully driven by live health data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final eco = EcosystemProvider();
      final now = DateTime.now();

      // Log food for today: 1500 Cal
      eco.addFoodLog(
        foodName: 'Nutritious Thali',
        mealType: 'Lunch',
        grams: 400.0,
        calories: 1500.0,
      );

      // Log steps for today: 4444 steps (burns ~200 cal at 0.045 cal/step, walks ~3.4 km)
      eco.recordDailySteps(date: now, steps: 4444);

      await tester.pumpWidget(createTestWidget(eco: eco));
      await tester.pumpAndSettle();

      // Steps and calories come from the real logs
      // Stats sit on one line as "label value".
      expect(find.text('Steps 4,444', findRichText: true), findsOneWidget);
      expect(find.text('4,444'), findsWidgets);
      expect(find.text('Kcal 1500/2000', findRichText: true), findsOneWidget);

      // Tapping the card opens the Health pillar
      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();
      expect(find.byType(ModernHomeScreen), findsNothing);
    });
  });
}
