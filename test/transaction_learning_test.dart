import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/services/deal_intake_fields.dart';
import 'package:dwelling_iq/services/transaction_learning.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/transaction_learning_page.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';

void main() {
  test(
    'intake accepts external deals and unknown figures, validates unsafe values',
    () {
      const valid = {
        'country': 'United Kingdom',
        'currency': 'gbp',
        'source_url': 'https://example.com/business/123',
      };
      expect(validateDealIntake(valid, ['', '', '-1250', '50,000']), isNull);
      expect(
        validateDealIntake({...valid, 'source_url': 'javascript:alert(1)'}, []),
        isNotNull,
      );
      expect(
        validateDealIntake({...valid, 'currency': 'dollars'}, []),
        isNotNull,
      );
      expect(validateDealIntake({...valid, 'country': ''}, []), isNotNull);
      for (final amounts in [
        ['-1', '', '', ''],
        ['', '-1', '', ''],
        ['', '', '', '-1'],
        ['NaN'],
        ['Infinity'],
        ['oops'],
      ]) {
        expect(validateDealIntake(valid, amounts), isNotNull);
      }
    },
  );
  test(
    'each learning document offers separate blank and fictional versions',
    () {
      expect(transactionLessons.length, 11);
      expect(transactionLessons.map((e) => e.id).toSet().length, 11);
      for (final lesson in transactionLessons) {
        expect(lesson.document(filled: false), contains('[Deal name]'));
        expect(
          lesson.document(filled: false),
          isNot(contains('FICTIONAL WORKED EXAMPLE')),
        );
        expect(
          lesson.document(filled: true),
          contains('FICTIONAL WORKED EXAMPLE'),
        );
        expect(lesson.document(filled: true), contains(lesson.example));
        expect(
          lesson.document(filled: false),
          contains('not an agreement to sign'),
        );
      }
      expect(
        AppNavigationDestination.values.last,
        AppNavigationDestination.bulletinBoard,
      );
    },
  );
  testWidgets(
    'phone intake retry preserves facts and produces complete private snapshot',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = DealIntakeDetails(
        title: 'External services deal',
        kind: 'business',
        location: 'London',
        purchasePrice: 250000,
        goals: 'Operate the business',
        targetCloseDate: null,
        profileSnapshot: {
          'deal_details':
              'Established service company with recurring customers and a small operating team.',
          'country': 'United Kingdom',
          'currency': 'gbp',
          'source_url': 'https://example.com/123',
          'source_name': 'Independent broker',
          'financial_period': '2025, seller reported',
          'annual_revenue': null,
          'reported_ebitda': -1000,
          'decision_gaps': 'Verify customer contracts',
        },
      );
      DealIntakeDetails? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<DealIntakeDetails>(
                    context: context,
                    builder: (_) => DealIntakeDialog(
                      initialKind: 'business',
                      initialDetails: draft,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('https://example.com/123'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('CONTINUE'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('CREATE PRIVATE DEAL'));
      await tester.pumpAndSettle();
      expect(result?.profileSnapshot['currency'], 'GBP');
      expect(result?.profileSnapshot['source_url'], 'https://example.com/123');
      expect(result?.profileSnapshot['annual_revenue'], isNull);
      expect(result?.profileSnapshot['reported_ebitda'], -1000);
      expect(
        result?.profileSnapshot['decision_gaps'],
        'Verify customer contracts',
      );
      expect(result?.purchasePrice, 250000);
    },
  );
  testWidgets(
    'buyer dashboard offers learning and external intake on a phone',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Add a deal from any source'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('learning library opens a worked example at phone width', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: TransactionLearningPage()));
    await tester.pumpAndSettle();
    final example = find.text('View worked example').first;
    await tester.ensureVisible(example);
    await tester.tap(example);
    await tester.pumpAndSettle();
    expect(find.textContaining('FICTIONAL WORKED EXAMPLE'), findsOneWidget);
    expect(find.text('Download .md'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
