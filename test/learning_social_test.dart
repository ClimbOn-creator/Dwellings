import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/services/learning_area_service.dart';
import 'package:dwelling_iq/services/nova_training_controller.dart';
import 'package:dwelling_iq/services/nova_training_service.dart';
import 'package:dwelling_iq/widgets/nova_training_host.dart';
import 'package:dwelling_iq/widgets/learning_comments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('community positions are rounded before persistence or upload', () {
    expect(const LearningArea('Vancouver', 49.261111, -123.113889).toJson(), {
      'area_name': 'Vancouver',
      'latitude': 49.3,
      'longitude': -123.1,
    });
  });
  testWidgets('Pika floats at bottom left through scroll and X moves it away', (
    tester,
  ) async {
    final controller = NovaTrainingController(
      service: NovaTrainingService(accountId: () => null),
    )..currentPage = 'resources';
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        builder: (_, child) => NovaTrainingHost(
          navigatorKey: nav,
          controller: controller,
          autoStart: false,
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            children: List.generate(
              40,
              (i) => SizedBox(height: 100, child: Text('Row $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('pebble_floating_help'));
    final before = tester.getTopLeft(button);
    expect(before.dx, lessThan(30));
    expect(before.dy, greaterThan(500));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(button), before);
    await tester.tap(find.byKey(const Key('pebble_dismiss_dock')));
    await tester.pump();
    expect(button, findsNothing);
    expect(controller.docked, false);
    controller.restoreDock();
    await tester.pump();
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(controller.active, true);
    expect(controller.steps.every((s) => s.destination == 'resources'), true);
    controller.pause();
    await tester.pump();
    controller.currentPage = 'landing';
    await tester.pump();
    expect(button, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('Comment sheet displays expandable nested threads at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = LearningPost(
        id: 'p',
        authorId: 'a',
        author: 'Educator',
        title: 'Lesson',
        body: '',
        topic: 'both',
        createdAt: DateTime(2026),
      );
      final comments = [
        LearningComment(
          id: 'a',
          postId: 'p',
          authorId: 'a',
          author: 'Alex',
          body: 'Root question',
          createdAt: DateTime(2026),
        ),
        LearningComment(
          id: 'b',
          postId: 'p',
          authorId: 'b',
          author: 'Bea',
          body: 'Direct answer',
          parentId: 'a',
          depth: 1,
          createdAt: DateTime(2026),
        ),
        LearningComment(
          id: 'c',
          postId: 'p',
          authorId: 'c',
          author: 'Casey',
          body: 'Follow up',
          parentId: 'b',
          depth: 2,
          createdAt: DateTime(2026),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningComments(post: p, loadComments: () async => comments),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Root question'), findsOneWidget);
      expect(find.text('Direct answer'), findsNothing);
      await tester.tap(find.text('1 reply'));
      await tester.pump();
      expect(find.text('Direct answer'), findsOneWidget);
      await tester.tap(find.text('1 reply'));
      await tester.pump();
      expect(find.text('Follow up'), findsOneWidget);
      await tester.tap(find.text('Reply').last);
      await tester.pump();
      expect(find.text('Replying to Casey'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
