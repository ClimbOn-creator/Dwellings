import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/widgets/affinity_button_gradients.dart';

void main() {
  Widget page(Widget child) => MaterialApp(
    theme: AffinityButtonGradients.apply(
      ThemeData(
        colorScheme: const ColorScheme.light(primary: Color(0xFF252525)),
      ),
    ),
    home: Scaffold(body: Center(child: child)),
  );
  LinearGradient gradient(WidgetTester tester) =>
      (tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration)
              .gradient!
          as LinearGradient;

  testWidgets(
    'black gradient slides, returns on pointer exit and keeps clicks',
    (tester) async {
      var clicks = 0;
      await tester.pumpWidget(
        page(
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () => clicks++,
            child: const Text('Continue'),
          ),
        ),
      );
      final shape =
          (tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration)
              .shape;
      expect(shape, isA<RoundedRectangleBorder>());
      expect(
        (shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(18),
      );
      final idle = gradient(tester);
      expect(idle.colors.first, const Color(0xFF151A18));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(FilledButton)));
      await tester.pumpAndSettle();
      expect(gradient(tester).begin, isNot(idle.begin));
      expect(gradient(tester).colors, idle.colors);
      await tester.tap(find.text('Continue'));
      expect(clicks, 1);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(gradient(tester).begin, idle.begin);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local green styles use muted colours and retain readable labels',
    (tester) async {
      for (final (background, foreground) in [
        (const Color(0xFF164F3D), Colors.white),
        (const Color(0xFFD6F185), const Color(0xFF164F3D)),
      ]) {
        await tester.pumpWidget(
          page(
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
              ),
              onPressed: () {},
              child: const Text('Membership'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final color in gradient(tester).colors) {
          final a = color.computeLuminance(), b = foreground.computeLuminance();
          final contrast =
              (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        }
      }
    },
  );

  testWidgets('explicit filled outlines and elevated actions get gradients', (
    tester,
  ) async {
    const style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Color(0xFF164F3D)),
    );
    await tester.pumpWidget(
      page(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: style,
              onPressed: () {},
              child: const Text('Elevated'),
            ),
            OutlinedButton(
              style: style,
              onPressed: () {},
              child: const Text('Outlined'),
            ),
            TextButton(
              style: style,
              onPressed: () {},
              child: const Text('Text'),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(Ink), findsNWidgets(3));
  });

  testWidgets(
    'disabled, blue, destructive and transparent buttons retain their styles',
    (tester) async {
      await tester.pumpWidget(
        page(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FilledButton(onPressed: null, child: Text('Disabled')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {},
                child: const Text('Blue'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {},
                child: const Text('Delete'),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Outline')),
            ],
          ),
        ),
      );
      expect(find.byType(Ink), findsNothing);
    },
  );
}
