import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Discover zooms into 15 tabs and opens a full-window split', (
    tester,
  ) async {
    const window = Size(1440, 900);
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningDashboardPage(initialView: LearningView.discover),
      ),
    );
    await tester.pumpAndSettle();

    final overview = find.widgetWithText(TextButton, 'Explore the file box');
    final tabs = find.byWidgetPredicate(
      (widget) =>
          widget is Text && RegExp(r'^File \d\d$').hasMatch(widget.data ?? ''),
    );
    expect(tabs, findsNothing);
    await tester.tapAt(tester.getTopLeft(overview) + const Offset(28, 36));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tabs, findsNothing);
    await tester.pumpAndSettle();
    expect(tabs, findsNWidgets(15));

    final left = find.byKey(const ValueKey('discover-Text-pane'));
    final right = find.byKey(const ValueKey('discover-Video-pane'));
    await tester.tap(find.text('File 15'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(left, findsNothing);
    await tester.pump(const Duration(milliseconds: 580));
    expect(tester.getSize(left).width, lessThan(window.width / 2));
    await tester.pumpAndSettle();

    expect(tester.getRect(left), const Rect.fromLTWH(0, 0, 720, 900));
    expect(tester.getRect(right), const Rect.fromLTWH(720, 0, 720, 900));
    expect(find.text('Text'), findsNothing);
    expect(find.text('Video'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(left, findsNothing);
    expect(tabs, findsNWidgets(15));
    await tester.tap(find.byTooltip('Zoom out of the file box'));
    await tester.pumpAndSettle();
    expect(overview, findsOneWidget);
  });
}
