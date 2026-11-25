import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/widgets/learning_track_lesson.dart';
import 'package:dwelling_iq/models/learning_track_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Roadmap through FAQ show track lessons in alternating panes at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(
            home: LearningDashboardPage(initialView: LearningView.roadmap),
          ),
        );
        await tester.pumpAndSettle();
        final pages = LearningView.values
            .where(
              (view) =>
                  view.index >= LearningView.roadmap.index &&
                  view.index <= LearningView.faq.index,
            )
            .toList();
        expect(pages.length, 9);
        for (var i = 0; i < pages.length; i++) {
          if (i > 0) {
            final tab = find.text(pages[i].label);
            await tester.ensureVisible(tab);
            await tester.tap(tab);
            await tester.pumpAndSettle();
          }
          final layout = find.byType(LearningTrackLesson);
          expect(layout, findsOneWidget);
          expect(
            find.text(
              learningTrackCopy['learning.track.buying.${pages[i].name}.body']!,
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: layout, matching: find.text('Text')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: layout, matching: find.text('Video')),
            findsOneWidget,
          );
          final text = tester.getRect(
            find.byKey(const ValueKey('learning-text-pane')),
          );
          final video = tester.getRect(
            find.byKey(const ValueKey('learning-video-pane')),
          );
          expect(text.width, closeTo(video.width, .01));
          expect(text.height, video.height);
          expect(text.top, video.top);
          expect(text.height, greaterThan(600));
          expect(text.left < video.left, i.isEven);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets('switching tracks updates every section and survives remounting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> open(LearningView view) async {
      await tester.tap(find.text(view.label));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const MaterialApp(home: LearningDashboardPage()));
    await tester.pumpAndSettle();
    for (final track in LearningTrack.values) {
      await tester.tap(
        find.byKey(ValueKey('learning-home-topic-${track.name}')),
      );
      await tester.pumpAndSettle();
      for (final section in LearningView.values.where(
        (v) =>
            v.index >= LearningView.roadmap.index &&
            v.index <= LearningView.faq.index,
      )) {
        await open(section);
        expect(
          tester
              .widget<LearningTrackLesson>(find.byType(LearningTrackLesson))
              .track,
          track,
        );
        expect(
          find.text(
            learningTrackCopy['learning.track.${track.name}.${section.name}.body']!,
          ),
          findsOneWidget,
        );
      }
      await open(LearningView.home);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningDashboardPage(initialView: LearningView.roadmap),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LearningTrackLesson>(find.byType(LearningTrackLesson))
          .track,
      LearningTrack.transfer,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
