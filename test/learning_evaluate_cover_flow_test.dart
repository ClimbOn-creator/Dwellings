import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/widgets/transaction_room_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Evaluate scrolls, lifts a file, and opens its guide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningDashboardPage(initialView: LearningView.evaluate),
      ),
    );
    await tester.pumpAndSettle();
    final stage = find.byKey(const Key('evaluation-cover-flow'));
    final first = find.byKey(const ValueKey('evaluate-file-deal-brief'));
    final slide = find.descendant(
      of: first,
      matching: find.byType(AnimatedSlide),
    );
    expect(find.text('1 / 7'), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(first));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedSlide>(slide).offset.dy, lessThan(0));
    await mouse.removePointer();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('7 / 7'), findsOneWidget);
    await tester.tap(find.byTooltip('Next file'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 7'), findsOneWidget);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(stage),
        scrollDelta: const Offset(166, 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 7'), findsOneWidget);
    final selected = find.byKey(const ValueKey('evaluate-file-nda-brief'));
    await tester.tap(selected);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TransactionRoomPanel>(find.byType(TransactionRoomPanel))
          .initialDocumentId,
      'nda-brief',
    );
  });

  testWidgets('Evaluate responds to a horizontal swipe on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningDashboardPage(initialView: LearningView.evaluate),
      ),
    );
    await tester.pumpAndSettle();
    final stage = find.byKey(const Key('evaluation-cover-flow'));
    await tester.drag(stage, const Offset(-95, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
