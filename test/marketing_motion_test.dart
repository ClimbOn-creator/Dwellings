import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/widgets/marketing_motion.dart';
import 'package:dwelling_iq/widgets/ambient_video.dart';
import 'package:dwelling_iq/services/site_content_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    SiteContentService.editing.value = false;
  });
  testWidgets(
    'marketing motion starts on with reduced motion and a previously disabled preference',
    (tester) async {
      SharedPreferences.setMockInitialValues({'pact.marketingMotion': false});
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MarketingMotionScope(
              child: Builder(
                builder: (context) => Text(
                  MediaQuery.disableAnimationsOf(context)
                      ? 'Still page'
                      : 'Moving page',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Moving page'), findsOneWidget);
      expect(find.text('Enable page motion'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'entrance keeps its full duration even when the system requests reduced motion',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: MarketingMotionScope(
            child: Scaffold(
              body: SingleChildScrollView(
                controller: scroll,
                child: MarketingReveal(
                  controller: scroll,
                  child: const SizedBox(
                    height: 300,
                    child: Text('Full animation'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final fade = find.descendant(
        of: find.byType(MarketingReveal),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(fade).opacity, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      scroll.dispose();
    },
  );
  testWidgets(
    'section entrance is visible in time and replays after returning',
    (tester) async {
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  MarketingReveal(
                    controller: scroll,
                    child: const SizedBox(
                      height: 300,
                      child: Text('Animated section'),
                    ),
                  ),
                  const SizedBox(height: 1400),
                ],
              ),
            ),
          ),
        ),
      );
      final fade = find.descendant(
        of: find.byType(MarketingReveal),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade).opacity, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(fade).opacity, 1);
      scroll.jumpTo(900);
      await tester.pump();
      await tester.pump();
      scroll.jumpTo(0);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      scroll.dispose();
    },
  );
  testWidgets(
    'background footage starts automatically without controls and pauses for editing',
    (tester) async {
      final scroll = ScrollController();
      Widget page({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: MarketingFilm(
              controller: scroll,
              contentKey: 'image.motion.fixture',
              imageAsset: 'assets/images/pact-watershed.jpg',
              videoAsset: 'assets/product_tours/pact-river.mp4',
              height: 400,
            ),
          ),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(
        tester.widget<AmbientVideo>(find.byType(AmbientVideo)).paused,
        isFalse,
      );
      expect(find.text('Pause motion'), findsNothing);
      expect(find.text('Play motion'), findsNothing);
      SiteContentService.editing.value = true;
      await tester.pumpAndSettle();
      expect(find.byType(AmbientVideo), findsNothing);
      expect(find.text('Edit background'), findsOneWidget);
      SiteContentService.editing.value = false;
      await tester.pumpWidget(page(reduced: true));
      await tester.pumpAndSettle();
      expect(find.byType(AmbientVideo), findsNothing);
      expect(find.text('Pause motion'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      scroll.dispose();
    },
  );
}
