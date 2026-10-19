import 'package:dwelling_iq/widgets/app_display_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop uses 80% sizing and keeps dialog hit targets aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Size? logicalSize;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => AppDisplayScale(child: child!),
        home: Builder(
          builder: (context) {
            logicalSize = MediaQuery.sizeOf(context);
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('Aligned dialog'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(logicalSize, const Size(1600, 1000));
    final button = find.byType(ElevatedButton);
    final topLeft = tester.getTopLeft(button);
    final bottomRight = tester.getBottomRight(button);
    expect(bottomRight.dx - topLeft.dx, closeTo(160, 0.01));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Aligned dialog'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Aligned dialog'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone keeps normal controls and accessibility text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Size? logicalSize;
    double? textSize;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AppDisplayScale(child: child!),
        ),
        home: Builder(
          builder: (context) {
            logicalSize = MediaQuery.sizeOf(context);
            textSize = MediaQuery.textScalerOf(context).scale(16);
            return const Scaffold(body: Text('Phone'));
          },
        ),
      ),
    );
    expect(logicalSize, const Size(390, 844));
    expect(textSize, 24);
    expect(tester.takeException(), isNull);
  });
}
