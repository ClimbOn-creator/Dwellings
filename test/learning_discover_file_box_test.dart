import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (view, reducedMotion) in [
    (LearningView.discover, false),
    (LearningView.discover, true),
    (LearningView.search, false),
  ]) {
    final cabinet = view == LearningView.discover;
    testWidgets(
      '${view.label} animates zoom and opening with reduced motion: $reducedMotion',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reducedMotion);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final semantics = tester.ensureSemantics();
        const window = Size(1440, 900);
        tester.view.physicalSize = window;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(home: LearningDashboardPage(initialView: view)),
        );
        await tester.pumpAndSettle();

        final overview = cabinet
            ? find.bySemanticsLabel('Open filing cabinet')
            : find.widgetWithText(TextButton, 'Explore the file box');
        final tabs = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(r'^File \d\d$').hasMatch(widget.data ?? ''),
        );
        final office = find.byKey(const ValueKey('discover-office'));
        expect(office, cabinet ? findsOneWidget : findsNothing);
        expect(tabs, findsNothing);
        await tester.tapAt(tester.getTopLeft(overview) + const Offset(28, 36));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tabs, findsNothing);
        if (cabinet) {
          expect(office, findsOneWidget);
          expect(
            find.byKey(const ValueKey('learning-folder-collection')),
            findsOneWidget,
          );
        }
        await tester.pumpAndSettle();
        expect(tabs, findsNWidgets(15));
        expect(
          find.text('Click on any file that interests you'),
          cabinet ? findsOneWidget : findsNothing,
        );
        expect(office, findsNothing);

        final left = find.byKey(const ValueKey('discover-Text-pane'));
        final right = find.byKey(const ValueKey('discover-Video-pane'));
        await tester.tap(find.text('File 15'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        expect(left, findsNothing);
        await tester.pump(const Duration(milliseconds: 205));
        expect(left, findsOneWidget);
        expect(right, findsNothing);
        await tester.pump(const Duration(milliseconds: 500));
        expect(right, findsOneWidget);
        expect(tester.getSize(left).width, lessThan(window.width / 2));
        await tester.pumpAndSettle();

        expect(tester.getRect(left), const Rect.fromLTWH(0, 0, 720, 900));
        expect(tester.getRect(right), const Rect.fromLTWH(720, 0, 720, 900));
        expect(find.text('Text'), findsOneWidget);
        expect(find.text('Video'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(left, findsNothing);
        expect(tabs, findsNWidgets(15));
        await tester.tap(
          find.byTooltip(
            cabinet ? 'Close filing cabinet' : 'Zoom out of the file box',
          ),
        );
        await tester.pumpAndSettle();
        expect(overview, findsOneWidget);
        expect(office, cabinet ? findsOneWidget : findsNothing);
        semantics.dispose();
      },
    );
  }
}
