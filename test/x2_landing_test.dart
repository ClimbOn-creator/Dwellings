import 'package:dwelling_iq/screens/x2_landing_page.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/services/pika_visibility.dart';
import 'package:dwelling_iq/widgets/app_display_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.landing);
  });
  testWidgets(
    'public X2 pill opens its own page and remains outside Pika workspaces',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AcquisitionSupportPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('X2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('organizer-tab-3')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(X2LandingPage), findsOneWidget);
      expect(pikaAllowedOnPage('x2'), isFalse);
      expect(find.byKey(const Key('pebble_page_help')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final width in [390.0, 850.0, 1440.0]) {
    testWidgets(
      'X2 content and animations fit $width through the complete page',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => AppDisplayScale(child: child!),
            home: const X2LandingPage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final headline = find.text(
          'Business ownership.\nA clearer way forward.',
        );
        final opacity = tester
            .widget<Opacity>(
              find.ancestor(of: headline, matching: find.byType(Opacity)).first,
            )
            .opacity;
        expect(opacity, greaterThan(0));
        expect(opacity, lessThan(1));
        final scroll = tester
            .widget<SingleChildScrollView>(
              find.byType(SingleChildScrollView).first,
            )
            .controller!;
        for (
          double offset = 0;
          offset < scroll.position.maxScrollExtent;
          offset += 600
        ) {
          scroll.jumpTo(offset);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1200));
          expect(
            tester.takeException(),
            isNull,
            reason: 'width=$width offset=$offset',
          );
        }
        final ownerTab = find.byKey(const ValueKey('x2-workflow-tab-1'));
        await Scrollable.ensureVisible(
          tester.element(ownerTab),
          alignment: .25,
        );
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.tap(ownerTab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.text('Plan a thoughtful\nnext chapter.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await Scrollable.ensureVisible(
          tester.element(find.byTooltip('Next perspective')),
          alignment: .7,
        );
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.tap(find.byTooltip('Next perspective'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
