import 'package:dwelling_iq/services/deal_room_service.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('buyer dashboard fits ${width.toInt()}px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Your acquisitions'), findsOneWidget);
      expect(find.text('My personal team'), findsOneWidget);
      expect(find.text('Detailed view'), findsNothing);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Add a deal'), findsNothing);
      expect(find.text('New deal room'), findsNothing);
      expect(
        find.textContaining(
          RegExp(r'Good morning|Good afternoon|Good evening|Working late'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('member dashboard fits ${width.toInt()}px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: MemberDealMarketplacePage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your opportunity board'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('populated transaction renders all phases at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final room = DealRoom(
        id: 'fixture',
        userId: 'buyer',
        title: 'Test acquisition',
        address: '',
        city: 'Victoria',
        purchasePrice: 1000000,
        timeline: '',
        goals: '',
        status: 'active',
        propertySnapshot: {},
        riskSnapshot: {},
        sharingPreferences: {},
        updatedAt: DateTime(2026),
        transactionType: 'business',
        dealKind: 'business',
        totalTaskCount: 18,
      );
      final templates = DealRoomService.templatesFor('business');
      final bundle = DealRoomBundle(
        room: room,
        tasks: [
          for (var i = 0; i < templates.length; i++)
            DealRoomTask(
              id: '$i',
              title: templates[i].title,
              category: templates[i].category,
              completed: false,
              position: i,
              stage: templates[i].stage,
              details: templates[i].details,
            ),
        ],
        notes: [],
        members: [],
        documents: [],
        documentEvents: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DealRoomsPage(loadTransactionBundles: () async => [bundle]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Transaction plan').first);
      await tester.tap(find.text('Transaction plan').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Checkbox), findsNWidgets(18));
      for (final task in templates) {
        expect(find.text(task.title), findsOneWidget);
        expect(tester.getSize(find.text(task.title)).height, greaterThan(0));
      }
      await tester.ensureVisible(
        find.text('Close transition and measure thesis'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('buyer deal screen is embedded in the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Deal screen').first);
    await tester.tap(find.text('Deal screen').first);
    await tester.pumpAndSettle();
    expect(find.text('Business price estimate'), findsOneWidget);
    expect(find.text('Asset value'), findsOneWidget);
    expect(find.text('Commercial real estate'), findsOneWidget);
    expect(find.text('Your acquisitions'), findsNothing);
    expect(find.text('UNDERWRITE THE OPPORTUNITY'), findsNothing);
    expect(
      find.text('One decision workspace. Three ways to value a deal.'),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const Key('deal_inputs'))).width,
      greaterThan(tester.getSize(find.byKey(const Key('deal_results'))).width),
    );
    final askingField = tester.widget<TextField>(
      find.byKey(const Key('field_businessAsk')),
    );
    expect(askingField.controller!.text, isEmpty);
    expect(askingField.decoration!.hintText, 'Example → 1,200,000');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('info_businessAsk'))),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(
        'The seller’s requested price for the business, before deal adjustments.',
      ),
      findsOneWidget,
    );
    await mouse.removePointer();
    await tester.enterText(
      find.byKey(const Key('field_businessAsk')),
      '1200000',
    );
    await tester.enterText(
      find.byKey(const Key('field_businessRevenue')),
      '1800000',
    );
    await tester.enterText(
      find.byKey(const Key('field_businessEbitda')),
      '260000',
    );
    expect(find.text('INDICATIVE ENTERPRISE VALUE'), findsNothing);
    await tester.enterText(find.byKey(const Key('field_multipleLow')), '3');
    await tester.enterText(find.byKey(const Key('field_multipleHigh')), '5');
    await tester.enterText(find.byKey(const Key('field_businessDown')), '25');
    await tester.enterText(
      find.byKey(const Key('field_businessInterest')),
      '7',
    );
    await tester.enterText(find.byKey(const Key('field_businessYears')), '7');
    await tester.pumpAndSettle();
    expect(find.text('INDICATIVE ENTERPRISE VALUE'), findsOneWidget);
    expect(find.text('Asking multiple'), findsOneWidget);
    expect(find.text('Create business deal room'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('mode_realEstate')));
    await tester.tap(find.byKey(const Key('mode_realEstate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('field_creRent')), findsOneWidget);
    expect(find.byKey(const Key('info_creAsk')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('field_creAsk')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byKey(const Key('field_creAsk')), '5000000');
    await tester.enterText(find.byKey(const Key('field_creRent')), '480000');
    await tester.enterText(find.byKey(const Key('field_creVacancy')), '5');
    await tester.enterText(
      find.byKey(const Key('field_creExpenses')),
      '140000',
    );
    await tester.enterText(find.byKey(const Key('field_creReserve')), '20000');
    await tester.enterText(find.byKey(const Key('field_creCap')), '6');
    await tester.enterText(find.byKey(const Key('field_creDown')), '30');
    await tester.enterText(find.byKey(const Key('field_creInterest')), '6.5');
    await tester.enterText(find.byKey(const Key('field_creYears')), '25');
    await tester.enterText(find.byKey(const Key('field_creHold')), '5');
    await tester.enterText(find.byKey(const Key('field_creGrowth')), '2');
    await tester.enterText(find.byKey(const Key('field_creExitCap')), '6.5');
    await tester.pumpAndSettle();
    expect(find.text('INCOME APPROACH VALUE'), findsOneWidget);
    expect(find.text('Commercial scorecard'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('mode_assets')));
    await tester.tap(find.byKey(const Key('mode_assets')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('info_assetAsk')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deal examples and help fit on a phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Deal screen').first);
    await tester.tap(find.text('Deal screen').first);
    await tester.pumpAndSettle();
    final revenue = tester.widget<TextField>(
      find.byKey(const Key('field_businessRevenue')),
    );
    expect(revenue.controller!.text, isEmpty);
    expect(revenue.decoration!.hintText, 'Example → 1,800,000');
    expect(find.byKey(const Key('info_businessRevenue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('info_businessRevenue')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Total sales generated by the business in a typical year, before expenses.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('business listings are removed and transaction plan stays', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Businesses for sale'), findsNothing);
    await tester.tap(find.text('My team').first);
    await tester.pumpAndSettle();
    expect(find.text('My team'), findsNWidgets(2));
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byTooltip('Back to dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaction plan').first);
    await tester.pumpAndSettle();
    expect(find.text('Transaction plan 📅'), findsOneWidget);
    expect(find.text('Your acquisition, step by step.'), findsNothing);
    expect(find.text('Open full room'), findsNothing);
    expect(find.text('Your acquisition roadmap'), findsOneWidget);
    expect(find.text('Sign in to save your plan'), findsOneWidget);
    expect(find.text('Execute 100-day transition plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
