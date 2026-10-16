import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/widgets/pika_introduction.dart';
import 'package:dwelling_iq/services/nova_training_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NovaTrainingController.instance.pause();
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Pika preview changes answers and opens the real guide at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() => NovaTrainingController.instance.pause());
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PikaIntroduction()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Meet Pika.'), findsOneWidget);
        expect(find.textContaining('Choose Buyer if'), findsOneWidget);
        final compare = find.byKey(const ValueKey('pika-question-1'));
        await tester.ensureVisible(compare);
        await tester.tap(compare);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Start with the deal comparison quiz'),
          findsOneWidget,
        );
        expect(find.textContaining('Choose Buyer if'), findsNothing);
        final numbers = find.byKey(const ValueKey('pika-question-2'));
        await tester.ensureVisible(numbers);
        await tester.tap(numbers);
        await tester.pumpAndSettle();
        expect(find.textContaining('Open Deal screen'), findsOneWidget);
        final tour = find.byKey(const Key('pika-preview-tour'));
        await tester.ensureVisible(tour);
        await tester.tap(tour);
        await tester.pumpAndSettle();
        expect(NovaTrainingController.instance.active, isTrue);
        expect(NovaTrainingController.instance.pageOnly, isTrue);
        expect(NovaTrainingController.instance.step.destination, 'landing');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
