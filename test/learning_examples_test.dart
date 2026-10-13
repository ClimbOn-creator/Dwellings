import 'package:dwelling_iq/services/learning_examples.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          find.widgetWithText(TextButton, '0 likes').first,
        );
        expect(like.onPressed, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
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
    expect(find.text('Example event'), findsNWidgets(4));
    expect(find.text('Reserve my place'), findsNothing);
    expect(find.text('Add to calendar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
