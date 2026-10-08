import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/services/business_sale_bulletin_service.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:dwelling_iq/widgets/home_brand_button.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/tunnel_pages.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.landing);
  });
  test('direct links select the right path and retired routes return home', () {
    expect(AppTunnelController.forModule('seller-posts'), AppTunnel.seller);
    expect(
      AppTunnelController.forModule('seller-transaction-room'),
      AppTunnel.seller,
    );
    expect(AppTunnelController.forModule('member-pricing'), AppTunnel.member);
    expect(
      AppTunnelController.forModule('businesses-for-sale'),
      AppTunnel.buyer,
    );
    for (final module in ['spot-mistake', 'network', 'property-calculator']) {
      expect(AppTunnelController.forModule(module), AppTunnel.landing);
    }
  });
  for (final (tunnel, destinations) in [
    (
      AppTunnel.buyer,
      [
        'buyerDashboard',
        'resources',
        'profile',
        'transactionRoom',
        'businessesForSale',
      ],
    ),
    (
      AppTunnel.seller,
      ['sellerDashboard', 'transactionRoom', 'sellerPosts', 'profile'],
    ),
    (
      AppTunnel.member,
      ['memberPricing', 'memberStudio', 'profile', 'memberMarketing'],
    ),
  ]) {
    testWidgets('$tunnel menu contains only its permitted destinations', (
      tester,
    ) async {
      AppTunnelController.select(tunnel);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: AppNavigationMenu(guidePage: 'profile', dark: false),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      final actual = tester
          .widgetList<PopupMenuItem<AppNavigationDestination>>(
            find.byType(PopupMenuItem<AppNavigationDestination>),
          )
          .map((item) => item.value!.name)
          .toList();
      expect(actual, destinations);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('logo resets the path and returns to the main landing', (
    tester,
  ) async {
    AppTunnelController.select(AppTunnel.seller);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeBrandButton())),
    );
    await tester.tap(find.byType(HomeBrandButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(AppTunnelController.current.value, AppTunnel.landing);
    expect(find.byType(AcquisitionSupportPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('new member pages fit a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppTunnelController.select(AppTunnel.member);
    for (final page in [
      const MemberPricingPage(),
      const MemberMarketingPage(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      expect(find.byType(HomeBrandButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'seller analytics use real saves and status from owned-post fixtures',
    (tester) async {
      AppTunnelController.select(AppTunnel.seller);
      final owned = SellerPostStats.fromJson({
        'id': 'owned-id',
        'title': 'My HVAC business',
        'status': 'active',
        'save_count': 8,
      });
      await tester.pumpWidget(
        MaterialApp(home: SellerPostsPage(loadPosts: () async => [owned])),
      );
      await tester.pumpAndSettle();
      expect(find.text('My HVAC business'), findsOneWidget);
      expect(find.text('8 buyer saves'), findsOneWidget);
      expect(find.text('Create a business post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
