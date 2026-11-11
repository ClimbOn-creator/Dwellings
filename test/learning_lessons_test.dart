import 'package:dwelling_iq/models/learning_lesson_content.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/services/site_copy_catalog.dart';
import 'package:dwelling_iq/widgets/learning_evaluate_cover_flow.dart';
import 'package:dwelling_iq/widgets/learning_lesson_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.learning);
  });

  testWidgets(
    'a Roadmap search destination opens the expanded checkpoints in view',
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
    for (final view in [
      LearningView.roadmap,
      LearningView.discover,
      LearningView.search,
    ]) {
      testWidgets('${view.label} lesson teaches and navigates at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(home: LearningDashboardPage(initialView: view)),
        );
        await tester.pumpAndSettle();
        final text = tester.getRect(
          find.byKey(ValueKey('lesson-${view.name}-text')),
        );
        final video = tester.getRect(
          find.byKey(ValueKey('lesson-${view.name}-video')),
        );
        if (width < 980) {
          expect(video.bottom, lessThan(text.top));
        } else {
          expect(video.left, greaterThan(text.right));
        }
        final chapter = find.byKey(const ValueKey('lesson-chapter-0'));
        await tester.ensureVisible(chapter);
        await tester.tap(chapter);
        await tester.pumpAndSettle();
        final core = find.text('The core idea');
        expect(tester.getTopLeft(core).dy, inInclusiveRange(0, 1000));

        final prefix = 'learning.lesson.${view.name}';
        final question = find.text(learningLessonCopy['$prefix.question.0']!);
        await tester.ensureVisible(question);
        await tester.tap(question);
        await tester.pumpAndSettle();
        expect(
          find.text(learningLessonCopy['$prefix.answer.0']!),
          findsOneWidget,
        );
        final next = find.byKey(ValueKey('lesson-${view.name}-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        if (view == LearningView.search) {
          expect(find.byType(LearningEvaluateCoverFlow), findsOneWidget);
        } else {
          final lesson = tester.widget<LearningLessonPage>(
            find.byType(LearningLessonPage),
          );
          expect(
            lesson.lesson,
            view == LearningView.roadmap
                ? LearningLesson.discover
                : LearningLesson.search,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
