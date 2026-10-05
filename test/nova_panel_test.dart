import 'package:dwelling_iq/services/nova_service.dart';
import 'package:dwelling_iq/services/nova_learning.dart';
import 'package:dwelling_iq/widgets/nova_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> acceptContext(WidgetTester tester) async {
  final control = find.byType(CheckboxListTile);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('Nova tour and lessons fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NovaPanel(
                context: const NovaContext(
                  area: 'seller',
                  label: 'Seller workspace',
                ),
                tourRole: 'seller',
                initiallyOpen: true,
                onTourNavigate: (value) => destination = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show me around'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Home'));
      expect(destination, 'overview');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Open Deal screen'), findsOneWidget);
      await tester.tap(find.text('Learn with Nova'));
      await tester.pumpAndSettle();
      expect(find.textContaining('family succession'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('curriculum covers every transaction document and all roles', () {
    expect(novaLessons.map((l) => l.id).toSet().length, novaLessons.length);
    expect(novaLessons.where((l) => l.id.startsWith('document-')).length, 11);
    for (final role in ['buyer', 'seller', 'member']) {
      expect(novaTour(role).length, greaterThanOrEqualTo(4));
    }
  });
  testWidgets(
    'follow-ups use conversation; switching deals discards old context',
    (tester) async {
      final requests = <(String?, String, int)>[];
      Future<NovaAnswer> load(
        NovaContext context,
        String question,
        List<Map<String, String>> history,
        String evidence,
      ) async {
        requests.add((context.dealId, question, history.length));
        return NovaAnswer('${context.label}: answer ${requests.length}', [
          'Saved deal record',
        ]);
      }

      Widget page(String id) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NovaPanel(
              context: NovaContext(
                area: 'financials',
                label: 'Deal $id',
                dealId: id,
              ),
              initiallyOpen: true,
              answerLoader: load,
            ),
          ),
        ),
      );
      await tester.pumpWidget(page('one'));
      await tester.pumpAndSettle();
      await acceptContext(tester);
      await tester.ensureVisible(find.text('Why did EBITDA decrease?'));
      await tester.tap(find.text('Why did EBITDA decrease?'));
      await tester.pumpAndSettle();
      expect(find.text('Deal one: answer 1'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        'What would you verify first?',
      );
      await tester.ensureVisible(find.byTooltip('Send to Nova'));
      await tester.tap(find.byTooltip('Send to Nova'));
      await tester.pumpAndSettle();
      expect(requests.last, ('one', 'What would you verify first?', 2));
      await tester.pumpWidget(page('two'));
      await tester.pumpAndSettle();
      expect(find.text('Deal one: answer 1'), findsNothing);
      await acceptContext(tester);
      await tester.ensureVisible(
        find.text('How much debt could this business support?'),
      );
      await tester.tap(find.text('How much debt could this business support?'));
      await tester.pumpAndSettle();
      expect(requests.last.$1, 'two');
      expect(requests.last.$3, 0);
    },
  );
  test(
    'service blocks missing consent before authentication or network',
    () async {
      await expectLater(
        NovaService.ask(
          const NovaContext(area: 'buyer', label: 'Dashboard'),
          'Help',
          [],
        ),
        throwsA(
          isA<NovaUnavailable>().having(
            (e) => e.message,
            'message',
            contains('share context'),
          ),
        ),
      );
      await expectLater(
        NovaService.ask(
          const NovaContext(area: 'buyer', label: 'Dashboard'),
          'Help',
          [],
          consentToShare: true,
        ),
        throwsA(
          isA<NovaUnavailable>().having(
            (e) => e.message,
            'message',
            contains('Sign in'),
          ),
        ),
      );
    },
  );
  testWidgets('Nova makes no live request without sharing consent', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NovaPanel(
              context: const NovaContext(area: 'financials', label: 'Deal'),
              initiallyOpen: true,
              answerLoader: (_, __, ___, ____) async {
                requests++;
                return const NovaAnswer('Answer', []);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Why did EBITDA decrease?'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
  });
  testWidgets(
    'unavailable AI retains question and does not fabricate a response',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NovaPanel(
                context: const NovaContext(
                  area: 'financials',
                  label: 'Example deal',
                ),
                initiallyOpen: true,
                answerLoader: (_, __, ___, ____) async =>
                    throw const NovaUnavailable('Service not connected'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await acceptContext(tester);
      await tester.ensureVisible(find.text('Why did EBITDA decrease?'));
      await tester.tap(find.text('Why did EBITDA decrease?'));
      await tester.pumpAndSettle();
      expect(find.text('Service not connected'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'Why did EBITDA decrease?',
      );
      expect(find.textContaining('For the MVP'), findsNothing);
    },
  );
}

// Consent is intentionally reset on deal changes; no provider requests occur before it.
