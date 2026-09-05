import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/models/deal_quiz.dart';

import 'package:dwelling_iq/screens/deal_comparison_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('public quiz route requires sign-in before showing any deals', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: DealComparisonPage()));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(BusinessComparisonQuiz), findsNothing);
    expect(find.text('BUSINESS A'), findsNothing);
  });

  testWidgets(
    'full motion shrinks the loser then slides in a challenger even with system reduced motion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(1440, 1400),
              disableAnimations: true,
            ),
            child: BusinessComparisonQuiz(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gentle motion'));
      await tester.pumpAndSettle();
      final choice = find.text('I would choose business A');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('Selected'), findsOneWidget);
      final loser = tester.widget<Transform>(
        find.byKey(const ValueKey('scale-B')),
      );
      expect(loser.transform.entry(0, 0), lessThan(.8));
      expect(loser.transform.entry(0, 0), greaterThan(.01));
      expect(find.text('BUSINESS C'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      final arriving = tester.widget<Transform>(
        find.byKey(const ValueKey('slide-C')),
      );
      expect(arriving.transform.entry(0, 3), greaterThan(0));
      expect(find.text('BUSINESS A'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('slide-C')))
            .transform
            .entry(0, 3),
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'preference inference uses the choice history, not just the final winner',
    () {
      final choices = [
        QuizChoice(quizBusinesses[0], quizBusinesses[1], quizBusinesses[0]),
        QuizChoice(quizBusinesses[0], quizBusinesses[2], quizBusinesses[0]),
        QuizChoice(quizBusinesses[0], quizBusinesses[3], quizBusinesses[0]),
        QuizChoice(quizBusinesses[0], quizBusinesses[4], quizBusinesses[4]),
      ];
      final profile = inferQuizProfile(choices);
      expect(profile.goal, 'Long-term profit and independence');
      expect(profile.riskTolerance, 'Stable and proven only');
      expect(profile.minimumCashFlow, '200000');
      expect(inferQuizProfile([]).answeredCount, 0);
      for (final business in quizBusinesses) {
        expect(business.traits.length, 8);
        expect(
          business.cash,
          business.revenue - business.expenses - business.salary,
        );
      }
    },
  );
  testWidgets('eight choices complete and refuse saving after sign-out', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BusinessComparisonQuiz()));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    for (var step = 0; step < 8; step++) {
      expect(find.text('I would choose business A'), findsOneWidget);
      final challenger = String.fromCharCode(66 + step);
      expect(find.text('I would choose business $challenger'), findsOneWidget);
      expect(find.text('BUSINESS A'), findsOneWidget);
      expect(find.text('BUSINESS $challenger'), findsOneWidget);
      final choice = find.text('I would choose business A');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(
      find.text('Your preferences, learned from your choices.'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('acquisition_foundation_v1'), isNull);
    expect(find.text('Retry saving'), findsOneWidget);
  });

  testWidgets('phone reports fit and a choice advances without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BusinessComparisonQuiz()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('I would choose business B'));
    await tester.tap(find.text('I would choose business B'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.text('BUSINESS B'), findsOneWidget);
    expect(find.text('BUSINESS C'), findsOneWidget);
    expect(find.text('BUSINESS A'), findsNothing);
    await tester.ensureVisible(find.text('Previous comparison'));
    await tester.tap(find.text('Previous comparison'));
    await tester.pumpAndSettle();
    expect(find.text('BUSINESS A'), findsOneWidget);
    expect(find.text('BUSINESS B'), findsOneWidget);
    expect(find.text('BUSINESS C'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
