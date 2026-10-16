import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/widgets/site_copy_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'buyer_command_centre_test.dart' as data;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('pipeline links preserve the correct dashboard context', () {
    expect(AppTunnelController.forModule('buyer-pipeline'), AppTunnel.buyer);
    expect(
      AppTunnelController.forModule('learning-pipeline'),
      AppTunnel.learning,
    );
  });
  testWidgets(
    'landing learn button has clearer typography and removes Start my path',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: AcquisitionSupportPage()),
      );
      await tester.pump(const Duration(seconds: 1));
      final learn = tester.widget<SiteCopyText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SiteCopyText &&
              widget.contentKey == 'home.learn.action',
        ),
      );
      for (final id in [
        'copy.acquisition_support_page.2',
        'copy.acquisition_support_page.3',
        'home.seller.action',
      ]) {
        final button = tester.widget<SiteCopyText>(
          find.byWidgetPredicate(
            (widget) => widget is SiteCopyText && widget.contentKey == id,
          ),
        );
        expect(learn.style, button.style);
      }
      expect(find.text('START MY PATH'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [390.0, 1440.0]) {
    for (final embedded in [false, true]) {
      testWidgets(
        'pipeline is a private online deal entry form at $width embedded=$embedded',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final page = DealRoomsPage(
            initialView: BuyerDashboardView.pipeline,
            embeddedPipeline: embedded,
            loadTransactionBundles: () async => data.fixtures,
            loadTeamProviders: () async =>
                (<MarketplaceProvider>[], <String>{}),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: embedded
                  ? Scaffold(body: SingleChildScrollView(child: page))
                  : page,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.text('Add a deal you found online'), findsOneWidget);
          expect(find.text('Your pipeline'), findsNothing);
          expect(find.text('My personal team'), findsNothing);
          expect(find.text('ABC Plumbing'), findsNothing);
          expect(find.text('Save private deal'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    testWidgets('learning pipeline stays inside its dashboard at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            initialView: LearningView.pipeline,
            loadPosts: () async => [],
            loadSeminars: () async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Add a deal you found online'), findsOneWidget);
      expect(find.text('Your pipeline'), findsNothing);
      expect(find.text('No deals here yet'), findsNothing);
      expect(find.text('My personal team'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
