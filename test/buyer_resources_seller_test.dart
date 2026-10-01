import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';
import 'package:dwelling_iq/services/buyer_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('buyer Resources stays inside dashboard at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      final entry = width < 800
          ? find.text('Resources — grants & community support')
          : find.text('Resources');
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerResourcesPanel), findsOneWidget);
      expect(find.byType(DealRoomsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('regular menu opens resources and seller dashboard', (
    tester,
  ) async {
    for (final label in ['Resources', 'Seller dashboard']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [AppNavigationMenu(dark: false)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        label == 'Resources'
            ? find.byType(BuyerResourcesPage)
            : find.byType(SellerDashboardPage),
        findsOneWidget,
      );
      expect(find.text('Spot the mistake'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('resources filter without signing in on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BuyerResourcesPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Community Futures');
    await tester.pumpAndSettle();
    expect(find.text('Community Futures BC'), findsOneWidget);
    expect(find.text('BDC business purchase financing'), findsNothing);
    expect(
      find.byTooltip('Save Community Futures BC to profile'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'no such resource');
    await tester.pumpAndSettle();
    expect(
      find.text('No matching resources. Try another search or category.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'seller workspace personalizes a plan and retains a draft on phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: SellerDashboardPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.byKey(const Key('seller_business_name')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('seller_tab_plan')));
      await tester.tap(find.byKey(const Key('seller_tab_plan')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('seller_business_name')),
        'Harbour Company',
      );
      await tester.tap(find.byKey(const Key('seller_transfer_path')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Management buyout').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('seller_tab_overview')));
      await tester.tap(find.byKey(const Key('seller_tab_overview')));
      await tester.pumpAndSettle();
      expect(find.text('Harbour Company'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('seller_pipeline_search')),
        'unmatched',
      );
      await tester.pumpAndSettle();
      expect(find.text('Harbour Company'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('seller_pipeline_search')),
        'Harbour',
      );
      await tester.pumpAndSettle();
      expect(find.text('Harbour Company'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('seller_tab_plan')));
      await tester.tap(find.byKey(const Key('seller_tab_plan')));
      await tester.pumpAndSettle();
      expect(find.textContaining('management buyout'), findsWidgets);
      expect(
        find.text('Test management interest and capacity'),
        findsOneWidget,
      );
      expect(find.text('Align family expectations'), findsNothing);
      final task = find.byKey(const Key('seller_task_goals'));
      await tester.ensureVisible(task);
      await tester.tap(task);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(task).value, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: SellerDashboardPage()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('seller_tab_plan')));
      await tester.tap(find.byKey(const Key('seller_tab_plan')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('seller_business_name')))
            .controller!
            .text,
        'Harbour Company',
      );
      expect(find.text('Management buyout'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('seller calculators and supporting tabs work on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: SellerDashboardPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('seller_tab_value')));
    await tester.pumpAndSettle();
    expect(find.text('Seller calculators'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('seller_ebitda')))
          .controller!
          .text,
      isEmpty,
    );
    for (final entry in <String, String>{
      'ebitda': '260000',
      'addbacks': '20000',
      'ownerPay': '80000',
      'replacementSalary': '95000',
      'lowMultiple': '3',
      'highMultiple': '5',
    }.entries) {
      await tester.enterText(
        find.byKey(Key('seller_${entry.key}')),
        entry.value,
      );
    }
    await tester.pumpAndSettle();
    expect(find.textContaining(r'$795,000'), findsOneWidget);
    expect(find.textContaining(r'$1,325,000'), findsOneWidget);
    for (final tab in ['plan', 'team', 'resources']) {
      final target = find.byKey(Key('seller_tab_$tab'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(BuyerResourcesPanel), findsOneWidget);
    expect(find.text('Community Futures BC'), findsOneWidget);
    expect(find.text('Amelia Foster'), findsNothing);
    expect(find.text('Transfer profile'), findsNothing);
    expect(find.text('Deal pack'), findsNothing);
  });
  testWidgets(
    'seller resources use government programs and filter without sign-in',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: SellerDashboardPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seller_tab_resources')));
      await tester.pumpAndSettle();
      expect(find.byType(BuyerResourcesPanel), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Community Futures');
      await tester.pumpAndSettle();
      expect(find.text('Community Futures BC'), findsOneWidget);
      expect(find.text('BDC business purchase financing'), findsNothing);
      expect(
        find.byTooltip('Save Community Futures BC to profile'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('catalog has distinct account keys and official HTTPS links', () {
    expect(
      buyerResources.map((r) => BuyerResourceTeam.key(r.id)).toSet().length,
      buyerResources.length,
    );
    expect(
      buyerResources.every((r) => Uri.parse(r.url).scheme == 'https'),
      isTrue,
    );
  });
}
