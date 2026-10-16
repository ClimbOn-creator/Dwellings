import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/widgets/canada_event_map.dart';
import 'package:dwelling_iq/widgets/private_deal_entry.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0, 2560.0]) {
    testWidgets('role labels stay in the top bar at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final (page, label) in <(Widget, String)>[
        (const DealRoomsPage(), 'Buyer dash'),
        (const SellerDashboardPage(), 'Seller dash'),
        (const MemberDealMarketplacePage(), 'Member dash'),
      ]) {
        await tester.pumpWidget(MaterialApp(home: page));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(tester.getTopLeft(find.text(label)).dy, lessThan(72));
        expect(tester.getSize(find.text(label)).height, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
    testWidgets('pipeline form uses the available dashboard width at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: DealRoomsPage(initialView: BuyerDashboardView.pipeline),
        ),
      );
      await tester.pumpAndSettle();
      final workspace = tester.getSize(find.byType(PrivateDealEntry));
      final field = tester.getSize(
        find.byKey(const ValueKey('private-deal-source_url')),
      );
      expect(field.width, greaterThan(workspace.width - 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      'seminar map fills the dashboard without a meeting list at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: LearningDashboardPage(
              initialView: LearningView.seminars,
              loadSeminars: () async => [],
              loadPermissions: () async => const LearningPermissions(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final map = tester.getSize(find.byType(CanadaEventMap));
        expect(map.height, greaterThan(800));
        expect(map.width, greaterThan(width - (width >= 900 ? 250 : 25)));
        expect(find.text('Learning dash'), findsOneWidget);
        expect(find.text('Example event'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Reserve my place'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
