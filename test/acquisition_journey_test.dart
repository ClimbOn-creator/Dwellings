import 'package:dwelling_iq/models/acquisition_journey.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/services/transaction_learning.dart';
import 'package:dwelling_iq/widgets/acquisition_journey_panel.dart';
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
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'journey saves understanding and opens a related guide inside Learning at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: LearningDashboardPage(
              initialView: LearningView.journey,
              loadPosts: () async => [],
              loadPermissions: () async => const LearningPermissions(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Buying & selling map'), findsNothing);
        expect(find.text('Contributor approvals'), findsNothing);
        expect(find.text('Pipeline'), findsNothing);
        final mark = find.byKey(const Key('journey-mark-understood'));
        expect(tester.widget<FilledButton>(mark).onPressed, isNull);
        final wrong = find.byKey(const ValueKey('journey-answer-1'));
        await tester.ensureVisible(wrong);
        await tester.pumpAndSettle();
        await tester.tap(wrong);
        await tester.pumpAndSettle();
        expect(find.text('Try another approach.'), findsOneWidget);
        expect(tester.widget<FilledButton>(mark).onPressed, isNull);
        final correct = find.byKey(const ValueKey('journey-answer-0'));
        await tester.ensureVisible(correct);
        await tester.pumpAndSettle();
        await tester.tap(correct);
        await tester.pumpAndSettle();
        await tester.ensureVisible(mark);
        await tester.pumpAndSettle();
        await tester.tap(mark);
        await tester.pumpAndSettle();
        expect(find.text('1 of 5 stages understood'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('learning.progress.guest'),
          contains('buyer-search'),
        );
        final doc = find.widgetWithText(
          TextButton,
          'Deal brief & buyer criteria',
        );
        await tester.ensureVisible(doc);
        await tester.pumpAndSettle();
        await tester.tap(doc);
        await tester.pumpAndSettle();
        expect(find.byType(TransactionRoomPanel), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('YOUR DOCUMENT WORKSPACE')).dy,
          greaterThanOrEqualTo(72),
        );
        expect(find.byType(AcquisitionJourneyPanel), findsNothing);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('DOWNLOAD EDITABLE TEMPLATE'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
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
