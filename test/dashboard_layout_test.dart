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
}
