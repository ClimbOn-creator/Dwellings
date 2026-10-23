import 'package:dwelling_iq/services/learning_examples.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/widgets/learning_example_cover.dart';
import 'package:dwelling_iq/widgets/canada_event_map.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('four matching sample lessons and upcoming map events', () {
    final posts = LearningExamples.posts, events = LearningExamples.events;
    expect(posts.length, 4);
    expect(events.length, 4);
    expect(events.map((e) => e.areaName).toSet().length, 4);
    for (var i = 0; i < 4; i++) {
      expect(posts[i].title, events[i].title);
      expect(events[i].visibleOnMap(DateTime.now()), true);
      expect(events[i].canJoin(events[i].startsAt), false);
      expect(posts[i].exampleIndex, i);
    }
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'empty feed shows four labelled examples without hero wording at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: LearningDashboardPage(
              loadPosts: () async => [],
              loadPermissions: () async => const LearningPermissions(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Example'), findsNWidgets(4));
        expect(find.text('A place to learn, at your pace'), findsNothing);
        expect(find.textContaining('No following list.'), findsNothing);
        final like = tester.widget<TextButton>(
          find.widgetWithText(TextButton, '12 likes').first,
        );
        expect(like.onPressed, isNotNull);
        for (final label in [
          'Choose your area',
          'For you',
          'Newest',
          'All topics',
          'Buyer',
          'Seller',
          'Finance',
          'Legal',
        ]) {
          expect(find.text(label), findsNothing);
        }
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.textContaining('Good morning'), findsNothing);
        final first = tester.getTopLeft(
          find.byKey(ValueKey('learning-post-${LearningExamples.posts[0].id}')),
        );
        final second = tester.getTopLeft(
          find.byKey(ValueKey('learning-post-${LearningExamples.posts[1].id}')),
        );
        if (width >= 900) {
          expect(second.dy, first.dy);
          expect(second.dx, greaterThan(first.dx));
        } else {
          expect(second.dy, greaterThan(first.dy));
        }

        expect(
          tester.getSize(find.byType(LearningExampleCover).first).height,
          greaterThanOrEqualTo(260),
        );
        expect(
          tester.getTopLeft(find.text('12 likes')).dy,
          lessThan(
            tester
                .getTopLeft(find.byKey(const ValueKey('learning-example-0')))
                .dy,
          ),
        );

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'example likes and replies work without an account or database writes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            loadPosts: () async => [],
            loadPermissions: () async => const LearningPermissions(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final like = find.text('12 likes');
      await tester.ensureVisible(like);
      await tester.tap(like);
      await tester.pump();
      expect(find.text('13 likes'), findsOneWidget);
      final comments = find.text('4 comments').first;
      await tester.ensureVisible(comments);
      await tester.tap(comments);
      await tester.pumpAndSettle();
      expect(find.text('Alex (example)'), findsOneWidget);
      await tester.tap(find.text('1 reply'));
      await tester.pumpAndSettle();
      expect(find.text('Pact (example)'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Reply').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'My preview reply');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();
      expect(find.text('My preview reply'), findsOneWidget);
      await tester.tap(find.byTooltip('Close comments'));
      await tester.pumpAndSettle();
      expect(find.text('5 comments'), findsOneWidget);
      await tester.ensureVisible(find.text('5 comments'));
      await tester.tap(find.text('5 comments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 replies'));
      await tester.pumpAndSettle();
      expect(find.text('My preview reply'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('real posts replace example cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LearningDashboardPage(
          loadPosts: () async => [
            LearningPost(
              id: 'real',
              authorId: 'host',
              author: 'Host',
              title: 'Published lesson',
              body: '',
              topic: 'buyer',
              createdAt: DateTime.now(),
            ),
          ],
          loadPermissions: () async => const LearningPermissions(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Published lesson'), findsOneWidget);
    expect(find.text('Example'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('map has sample events without the removed filter row', (
    tester,
  ) async {
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
    expect(find.text('All events'), findsNothing);
    expect(find.text('Near my community'), findsNothing);
    expect(find.text('Example event'), findsNothing);
    expect(
      tester.widget<CanadaEventMap>(find.byType(CanadaEventMap)).events.length,
      4,
    );
    expect(find.text('Reserve my place'), findsNothing);
    expect(find.text('Add to calendar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
