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
    marketingMotionPreference.value = null;
  });
  testWidgets(
    'page motion can explicitly override reduced motion and remembers the choice',
    (tester) async {
      Widget page() => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MarketingMotionScope(
            child: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    const MarketingMotionToggle(),
                    Text(
                      MediaQuery.disableAnimationsOf(context)
                          ? 'Still page'
                          : 'Moving page',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Still page'), findsOneWidget);
      await tester.tap(find.text('Enable page motion'));
      await tester.pumpAndSettle();
      expect(find.text('Moving page'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('pact.marketingMotion'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      marketingMotionPreference.value = null;
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Moving page'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
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
    'ambient footage has working pause and respects editing and reduced motion',
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
      await tester.tap(find.text('Pause motion'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AmbientVideo>(find.byType(AmbientVideo)).paused,
        isTrue,
      );
      await tester.tap(find.text('Play motion'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AmbientVideo>(find.byType(AmbientVideo)).paused,
        isFalse,
      );
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
