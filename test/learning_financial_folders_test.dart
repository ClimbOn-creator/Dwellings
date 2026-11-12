import 'dart:ui' show PointerDeviceKind;

import 'package:dwelling_iq/widgets/learning_financial_folders.dart';
import 'package:dwelling_iq/widgets/site_copy_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Financial folder order, editable tabs and opening at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: LearningFinancialFolders()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rear = find.text('Financial statements');
      final right = find.text('Revenue');
      final rightTitle = find.widgetWithText(SiteCopyText, 'Revenue');
      expect(
        tester.widget<SiteCopyText>(rightTitle).contentKey,
        'learning.financial.revenue.title',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SiteCopyText &&
              widget.contentKey.startsWith('learning.financial.'),
        ),
        findsNWidgets(10),
      );
      if (width >= 900) {
        expect(
          tester.getTopLeft(right).dx,
          greaterThan(tester.getTopLeft(rear).dx),
        );
        expect(
          tester.getCenter(right).dy,
          closeTo(tester.getCenter(rear).dy, 1),
        );
      } else {
        expect(
          tester.getTopLeft(right).dy,
          greaterThan(tester.getTopLeft(rear).dy),
        );
      }
      final front = find.text('Cash flow');
      final rearBefore = tester.getCenter(rear);
      final frontBefore = tester.getCenter(front);
      expect(frontBefore.dx, greaterThan(rearBefore.dx));
      expect(frontBefore.dy, greaterThan(rearBefore.dy));
      expect(
        tester
            .widget<SiteCopyText>(
              find.widgetWithText(SiteCopyText, 'Financial statements'),
            )
            .contentKey,
        'learning.financial.statements.title',
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(rearBefore);
      await tester.pumpAndSettle();
      expect(tester.getCenter(rear).dy, closeTo(rearBefore.dy - 7, .1));
      expect(tester.getCenter(front), frontBefore);

      await tester.tapAt(rearBefore);
      await tester.pump();
      final flap = find.byKey(const Key('financial-open-flap'));
      final closedAngle = tester.widget<Transform>(flap).transform.entry(1, 1);
      await tester.pumpAndSettle();
      final openAngle = tester.widget<Transform>(flap).transform.entry(1, 1);
      expect(openAngle, lessThan(closedAngle));
      expect(
        find.descendant(of: find.byType(Dialog), matching: rear),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close folder'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await mouse.removePointer();

      await tester.ensureVisible(right);
      await tester.pumpAndSettle();
      await tester.tap(right);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Dialog), matching: right),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close folder'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
