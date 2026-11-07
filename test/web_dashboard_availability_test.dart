@TestOn('browser')
library;

import 'package:dwelling_iq/screens/dashboard_showcase_page.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web dashboard entry points show the holding page', (
    tester,
  ) async {
    for (final (page, title) in const [
      (
        DealRoomsPage(initialView: BuyerDashboardView.pipeline),
        'Buyer dashboard',
      ),
      (SellerDashboardPage(learning: true), 'Seller dashboard'),
      (
        MemberDashboardPage(initialView: MemberDashboardView.roi),
        'Member dashboard',
      ),
    ]) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('Coming soon!'), findsOneWidget);
      expect(find.text('Open Learning dashboard'), findsOneWidget);
    }
  });

  testWidgets('web dashboard picker only opens Learning', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: DashboardShowcasePage(openDashboardMenu: true)),
    );
    await tester.pumpAndSettle();
    final panel = find.byKey(const Key('dashboard-navigation-panel'));
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('Coming soon!')),
      findsNWidgets(2),
    );
    for (final name in ['buyerDashboard', 'sellerDashboard']) {
      final button = find.byKey(ValueKey('navigation-$name'));
      expect(tester.widget<InkWell>(button).onTap, isNull);
    }
    expect(find.byKey(const ValueKey('navigation-memberStudio')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('navigation-learningDashboard')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LearningDashboardPage), findsOneWidget);
  });
}
