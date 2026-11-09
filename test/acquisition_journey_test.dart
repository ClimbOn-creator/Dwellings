import 'package:dwelling_iq/models/acquisition_journey.dart';
import 'package:dwelling_iq/services/transaction_learning.dart';
import 'package:dwelling_iq/widgets/transaction_room_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'all five stages have a supported decision and cover all document guides',
    () {
      expect(acquisitionJourneyStages.length, 5);
      expect(
        acquisitionJourneyStages.expand((s) => s.documentIds).toSet(),
        transactionLessons.map((l) => l.id).toSet(),
      );
      for (final stage in acquisitionJourneyStages) {
        expect(stage.phase.explanation, isNotEmpty);
        expect(
          stage.phase.correct,
          inInclusiveRange(0, stage.phase.choices.length - 1),
        );
        expect(stage.documentIds, isNotEmpty);
      }
    },
  );
  testWidgets(
    'document search selects a specific guide and retains explicit empty results',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TransactionRoomPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('room-document-search')),
        'funding',
      );
      await tester.pumpAndSettle();
      final funding = find.byKey(const ValueKey('room-select-funding'));
      await tester.ensureVisible(funding);
      await tester.pumpAndSettle();
      await tester.tap(funding);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TransactionDocumentGuide>(
              find.byType(TransactionDocumentGuide),
            )
            .lesson
            .id,
        'funding',
      );
      await tester.ensureVisible(find.byKey(const Key('room-document-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('room-document-search')),
        'no-matching-document',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No matching documents. Try another search.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
