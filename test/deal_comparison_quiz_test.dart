import 'dart:convert';

import 'package:dwelling_iq/screens/deal_comparison_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
      expect(find.text('I would choose business B'), findsOneWidget);
      expect(find.text('BUSINESS A'), findsOneWidget);
      expect(find.text('BUSINESS B'), findsOneWidget);
      final choice = find.text('I would choose business A');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Your buying preferences, defined.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('acquisition_foundation_v1')!);
    expect(stored['blueprint']['comparisonProfile'], {
      'goal': 'Long-term profit and independence',
      'role': 'Run it myself',
      'horizon': 'Long term · 10+ years',
      'weeklyTime': 'Active oversight · 15–30 hours',
      'minimumCashFlow': r'$100,000',
      'minimumReturn': '15%',
      'riskTolerance': 'Stable and proven only',
      'nonNegotiables': 'Recurring or repeat revenue',
    });
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
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
