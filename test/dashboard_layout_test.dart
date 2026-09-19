import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('buyer dashboard fits ${width.toInt()}px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Your pipeline'), findsOneWidget);
      expect(find.text('Detailed view'), findsNothing);
      expect(
        find.textContaining(
          RegExp(r'Good morning|Good afternoon|Good evening|Working late'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('member dashboard fits ${width.toInt()}px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: MemberDealMarketplacePage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your opportunity board'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('buyer deal screen is embedded in the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal screen').first);
    await tester.pumpAndSettle();
    expect(find.text('Initial deal screen'), findsOneWidget);
    expect(find.text('Run initial screen'), findsOneWidget);
    expect(find.text('Your pipeline'), findsNothing);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '1200000');
    await tester.enterText(fields.at(2), '1800000');
    await tester.enterText(fields.at(3), '260000');
    await tester.tap(find.text('Run initial screen'));
    await tester.pumpAndSettle();
    expect(find.text('INITIAL ACQUISITION SCREEN'), findsOneWidget);
    expect(find.text('Price / EBITDA'), findsOneWidget);
    expect(find.text('Create deal room'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
