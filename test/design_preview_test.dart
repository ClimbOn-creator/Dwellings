import 'package:dwelling_iq/widgets/site_copy_text.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/design_preview_page.dart';
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

  testWidgets('landing preview tab opens an independent public page', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AcquisitionSupportPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('organizer-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byType(DesignPreviewPage), findsOneWidget);
    expect(find.text('A shared purpose.'), findsOneWidget);
    for (final key in [
      'about.story.purpose.body',
      'about.story.pledge.body',
      'about.story.team.0.name',
      'footer.page.approach.intro',
    ]) {
      expect(
        find.byWidgetPredicate((w) => w is SiteCopyText && w.contentKey == key),
        findsOneWidget,
      );
    }
    expect(find.text('Moose'), findsOneWidget);
    expect(find.text('Karl'), findsOneWidget);
    expect(find.text('Potato'), findsOneWidget);
    expect(pikaAllowedOnPage('design-preview'), isFalse);
    expect(find.byKey(const Key('pebble_page_help')), findsNothing);
    Navigator.of(tester.element(find.byType(DesignPreviewPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AcquisitionSupportPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'preview motion is always on despite the platform motion flag, with no controls',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AppDisplayScale(child: child!),
          ),
          home: const DesignPreviewPage(),
        ),
      );
      double titleOpacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('A shared purpose.'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(titleOpacity(), 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final firstFrame = titleOpacity();
      expect(firstFrame, greaterThan(0));
      expect(firstFrame, lessThan(1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(titleOpacity(), greaterThan(firstFrame));
      expect(titleOpacity(), lessThan(1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('preview-toggle-motion')), findsNothing);
      expect(find.byKey(const Key('preview-replay-motion')), findsNothing);
      expect(find.text('Pause motion'), findsNothing);
      expect(find.text('Play motion'), findsNothing);
      expect(find.text('Replay animations'), findsNothing);
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.text('A shared purpose.')),
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final width in [390.0, 851.0, 1440.0, 1441.0]) {
    testWidgets('preview scrolls through gallery without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: width != 1441),
            child: AppDisplayScale(child: child!),
          ),
          home: const DesignPreviewPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What’s next'), findsNWidgets(2));
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byType(SingleChildScrollView).first,
          )
          .controller!;
      for (
        var offset = 0.0;
        offset < scroll.position.maxScrollExtent;
        offset += 650
      ) {
        scroll.jumpTo(offset);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      if (width == 1441) {
        scroll.jumpTo(scroll.position.maxScrollExtent * .65);
        await tester.pumpAndSettle();
        expect(find.text('What’s next').last.hitTestable(), findsOneWidget);
      }
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Back to top').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Back to top'));
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
