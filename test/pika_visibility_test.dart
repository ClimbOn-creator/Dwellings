import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/services/pika_visibility.dart';
import 'package:dwelling_iq/services/nova_training_controller.dart';
import 'package:dwelling_iq/services/nova_training_service.dart';
import 'package:dwelling_iq/widgets/nova_training_host.dart';
import 'package:dwelling_iq/widgets/nova_character.dart';
import 'package:dwelling_iq/widgets/pika_introduction.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/dashboard_showcase_page.dart';
import 'package:dwelling_iq/screens/footer_information_page.dart';
import 'package:dwelling_iq/screens/member_overview_page.dart';
import 'package:dwelling_iq/models/footer_page_content.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('only individual workspaces and their tools permit Pika', () {
    for (final page in [
      'landing',
      'about-us',
      'dashboards',
      'member/overview',
      'auth',
      'consulting',
      'page:AboutPage',
    ]) {
      expect(pikaAllowedOnPage(page), isFalse, reason: page);
    }
    for (final page in [
      'buyer/home',
      'seller/overview',
      'member/home',
      'learning-home',
      'learning-map',
      'comparison',
      'resources',
      'room/documents',
    ]) {
      expect(pikaAllowedOnPage(page), isTrue, reason: page);
    }
  });
  for (final width in [390.0, 1440.0]) {
    for (final (page, body) in <(String, Widget)>[
      ('landing', const AcquisitionSupportPage()),
      ('about-us', const FooterInformationPage(topic: FooterTopic.approach)),
      ('dashboards', const DashboardShowcasePage()),
      ('member/overview', const MemberOverviewPage()),
    ]) {
      testWidgets(
        '$page has no dock, header Pika, introduction or automatic guide at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = NovaTrainingController(
            service: NovaTrainingService(accountId: () => null),
          )..currentPage = page;
          final nav = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: nav,
              builder: (_, child) => NovaTrainingHost(
                navigatorKey: nav,
                controller: controller,
                child: child!,
              ),
              home: body,
            ),
          );
          await tester.pumpAndSettle();
          void absent() {
            expect(find.byType(NovaCharacter), findsNothing);
            expect(find.byType(PikaIntroduction), findsNothing);
            expect(find.byType(NovaTourCard), findsNothing);
            expect(find.byKey(const Key('pebble_page_help')), findsNothing);
            expect(find.byKey(const Key('pebble_floating_help')), findsNothing);
          }

          absent();
          expect(controller.active, isFalse);
          controller.dismissDock();
          NovaTrainingController.instance.dismissDock();
          await tester.pumpAndSettle();
          absent();
          controller.startPage(page);
          await tester.pumpAndSettle();
          absent();
          expect(controller.active, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          NovaTrainingController.instance.restoreDock();
          controller.dispose();
        },
      );
    }
  }
  testWidgets(
    'leaving a workspace stops its guide and returning restores its dock',
    (tester) async {
      final controller = NovaTrainingController(
        service: NovaTrainingService(accountId: () => null),
      )..currentPage = 'buyer/home';
      final nav = GlobalKey<NavigatorState>();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: nav,
            controller: controller,
            autoStart: false,
            child: child!,
          ),
          home: Scaffold(
            body: TextButton(
              onPressed: () => taps++,
              child: const Text('Page action'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pebble_floating_help')), findsOneWidget);
      controller.startPage('buyer/home');
      await tester.pumpAndSettle();
      expect(find.byType(NovaTourCard), findsOneWidget);
      controller.currentPage = 'about-us';
      await tester.pumpAndSettle();
      expect(controller.active, isFalse);
      expect(find.byType(NovaCharacter), findsNothing);
      await tester.tap(find.text('Page action'));
      expect(taps, 1);
      controller.currentPage = 'learning-home';
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pebble_floating_help')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
