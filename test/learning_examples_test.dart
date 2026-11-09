import 'package:dwelling_iq/services/learning_examples.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
