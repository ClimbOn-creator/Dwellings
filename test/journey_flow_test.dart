import 'package:dwelling_iq/screens/journey_page.dart';
import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('direct routes retain each dashboard', () {
    expect(journeyDashboard(JourneyRole.buyer), isA<DealRoomsPage>());
    expect(journeyDashboard(JourneyRole.seller), isA<SellerDashboardPage>());
    expect(
      journeyDashboard(JourneyRole.member),
      isA<MemberDealMarketplacePage>(),
    );
  });
  for (final role in JourneyRole.values) {
    testWidgets('${role.name} learner route requires authentication', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: JourneyChoicePage(role: role)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'buyer next steps include search, private intake and quiz on mobile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: JourneyNextPage(role: JourneyRole.buyer)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search businesses'), findsOneWidget);
      expect(find.text('Enter a private deal'), findsOneWidget);
      expect(find.text('Deal comparison quiz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
