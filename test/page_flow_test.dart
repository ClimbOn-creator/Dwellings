import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/screens/page_flow.dart';
import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/models/platform_side.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'buyer next action changes the existing page from calculator to resources to dashboard',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DealRoomsPage(
            initialSide: PlatformSide.business,
            initialView: BuyerDashboardView.dealScreen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next: resources'));
      await tester.tap(find.text('Next: resources'));
      await tester.pumpAndSettle();
      expect(find.byType(DealRoomsPage), findsOneWidget);
      await tester.ensureVisible(find.text('Continue to buyer dashboard'));
      await tester.tap(find.text('Continue to buyer dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Your pipeline'), findsOneWidget);
      expect(find.text('Search businesses'), findsOneWidget);
      expect(find.text('Enter a private deal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cancelling account setup stays on the originating page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => startBuyerLearning(context),
              child: const Text('Learn'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(AuthPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AcquisitionBlueprintPage), findsNothing);
    expect(find.text('Learn'), findsOneWidget);
  });
  testWidgets(
    'seller pricing continues to deal pack within the same dashboard',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerDashboardPage(initialView: SellerDashboardView.value),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Next: prepare deal pack'),
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Next: prepare deal pack'));
      await tester.pumpAndSettle();
      expect(find.byType(SellerDashboardPage), findsOneWidget);
      expect(find.text('Next: create business listing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
