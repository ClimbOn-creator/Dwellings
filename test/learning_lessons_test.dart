import 'package:dwelling_iq/models/learning_creative_content.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/services/site_copy_catalog.dart';
import 'package:dwelling_iq/widgets/learning_evaluate_cover_flow.dart';
import 'package:dwelling_iq/widgets/learning_lesson_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.learning);
  });

  testWidgets(
    'a Roadmap search destination opens its permanent stage in view',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningLessonPage(
              lesson: LearningLesson.roadmap,
              initialStageId: 'diligence',
              onOpen: (_) {},
              onSearchResult: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final stage = find.byKey(const ValueKey('journey-stage-3'));
      expect(tester.getTopLeft(stage).dy, inInclusiveRange(0, 600));
      expect(
        find.text(siteCopyCatalog['learning.journey.diligence.body']!),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1440.0]) {
    Future<void> open(WidgetTester tester, LearningView view) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: width == 390);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(home: LearningDashboardPage(initialView: view)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> tapTwice(WidgetTester tester, Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Trail reveals landmarks through scrolling and opens a lesson at $width',
      (tester) async {
        await open(tester, LearningView.roadmap);
        expect(find.text('1 of 8 landmarks reached'), findsOneWidget);
        final last = find.byKey(const ValueKey('trail-stop-7'));
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(find.text('8 of 8 landmarks reached'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('trail-stop-0')));
        expect(
          tester
              .widget<LearningLessonPage>(find.byType(LearningLessonPage))
              .lesson,
          LearningLesson.discover,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Two Saturdays reveals consequences, results and resets at $width',
      (tester) async {
        await open(tester, LearningView.discover);
        await tap(tester, find.byKey(const ValueKey('saturday-pick-operator')));
        for (var i = 0; i < 3; i++) {
          await tapTwice(
            tester,
            find.byKey(ValueKey('saturday-choice-${i == 2 ? 1 : 0}')),
          );
          expect(
            find.text(
              learningCreativeCopy['learning.creative.discover.outcome.$i.${i == 2 ? 1 : 0}']!,
            ),
            findsOneWidget,
          );
          await tapTwice(
            tester,
            find.byKey(const ValueKey('saturday-continue')),
          );
        }
        expect(find.byKey(const ValueKey('saturday-result')), findsOneWidget);
        expect(find.text('Your choices lean owner-operator'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('saturday-restart')));
        expect(find.byKey(const ValueKey('saturday-result')), findsNothing);
        expect(find.text('Alex’s investor Saturday'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('lesson-discover-next')));
        expect(
          tester
              .widget<LearningLessonPage>(find.byType(LearningLessonPage))
              .lesson,
          LearningLesson.search,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Listings accept gestures, keyboard and buttons then summarize five choices at $width',
      (tester) async {
        await open(tester, LearningView.search);
        final card = find.byKey(const ValueKey('listing-swipe-card'));
        await tester.ensureVisible(card);
        await tester.drag(card, const Offset(160, 0));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('listing-back-maple')),
          findsOneWidget,
        );
        expect(find.text('Here is the clue to revisit'), findsOneWidget);
        // A second vote during the reveal must not add another answer.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tapTwice(tester, find.byKey(const ValueKey('listing-next')));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('listing-back-cedar')),
          findsOneWidget,
        );
        await tapTwice(tester, find.byKey(const ValueKey('listing-next')));
        for (final green in [false, true, false]) {
          await tap(
            tester,
            find.byKey(ValueKey(green ? 'listing-green' : 'listing-red')),
          );
          await tapTwice(tester, find.byKey(const ValueKey('listing-next')));
        }
        expect(find.byKey(const ValueKey('listing-results')), findsOneWidget);
        expect(find.text('You spotted 4 of 5 teaching clues'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('listing-restart')));
        expect(
          find.byKey(const ValueKey('listing-front-maple')),
          findsOneWidget,
        );
        expect(find.text('Listing 1 of 5'), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('lesson-search-next')));
        expect(find.byType(LearningEvaluateCoverFlow), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
