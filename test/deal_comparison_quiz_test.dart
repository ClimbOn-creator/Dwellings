import 'dart:convert';
import 'package:dwelling_iq/models/deal_quiz.dart';

import 'package:dwelling_iq/screens/deal_comparison_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
  testWidgets('eight binary document choices persist the buyer profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealComparisonPage()));
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
    final stored = jsonDecode(prefs.getString('acquisition_foundation_v1')!);
    expect(
      stored['blueprint']['comparisonProfile'],
      quizBusinesses.first.traits,
    );
    expect(stored['blueprint']['comparisonQuiz']['winner'], 'A');
    expect(stored['blueprint']['comparisonQuiz']['choices'], hasLength(8));
  });

  testWidgets('phone reports fit and a choice advances without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealComparisonPage()));
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
