import 'package:dwelling_iq/screens/bulletin_listing_pages.dart';
import 'package:dwelling_iq/services/business_sale_bulletin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'listing details show financial, property and operation sections on phones',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final b = BusinessSaleBulletin.fromJson({
        'id': 'example',
        'title': 'Example business',
        'details': {
          'revenue': r'$900,000',
          'cash_flow': r'$180,000',
          'real_estate': 'Lease',
          'reason_for_selling': 'Retirement',
        },
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BulletinListingBody(bulletin: b),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$900,000'), findsOneWidget);
      expect(find.text('Property information'), findsOneWidget);
      expect(find.text('Retirement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('editor retains existing fields and validates before preview', (
    tester,
  ) async {
    final b = BusinessSaleBulletin.fromJson({
      'id': 'example',
      'title': 'Example business',
      'summary': 'An established business with repeat clients.',
      'details': {'revenue': r'$900,000'},
    });
    await tester.pumpWidget(
      MaterialApp(home: BulletinListingEditor(initial: b)),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Example business'),
      findsOneWidget,
    );
    final preview = find.text('Preview listing');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.text('About the business'), findsOneWidget);
    expect(find.text(r'$900,000'), findsOneWidget);
    expect(find.text('Back to editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
