import 'package:dwelling_iq/screens/member_overview_page.dart';
import 'package:dwelling_iq/screens/footer_information_page.dart';
import 'package:dwelling_iq/models/footer_page_content.dart';
import 'package:dwelling_iq/screens/become_member_page.dart';
import 'package:dwelling_iq/services/membership_service.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/tunnel_pages.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/screens/assistant_workspace_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:dwelling_iq/widgets/site_parallax_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.landing);
  });
  testWidgets(
    'new professional applications offer only the confirmed Member plan',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BecomeMemberPage(
            initialType: MemberType.businessBroker,
            onHome: () {},
            onAbout: () {},
            onTeam: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final plan = find.text(r'Professional membership · $149 CAD / month');
      await tester.scrollUntilVisible(
        plan,
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(plan, findsOneWidget);
      expect(find.text('Free member'), findsNothing);
      expect(find.text('Featured'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(
              find.ancestor(of: plan, matching: find.byType(ChoiceChip)),
            )
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('Member footer opens the overview from every app area', () {
    for (final role in AppTunnel.values) {
      AppTunnelController.select(role);
      expect(
        footerDestination(FooterTopic.memberStudio),
        isA<MemberOverviewPage>(),
      );
      expect(AppTunnelController.current.value, AppTunnel.member);
    }
  });
  for (final width in [360.0, 768.0, 1440.0]) {
    testWidgets(
      'pricing shows five benefits per plan without overflow at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MaterialApp(home: MemberPricingPage()));
        await tester.pumpAndSettle();
        for (final id in ['professional', 'free_access']) {
          final card = find.byKey(ValueKey('pricing-card-$id'));
          expect(
            find.descendant(
              of: card,
              matching: find.byIcon(Icons.check_rounded),
            ),
            findsNWidgets(5),
          );
        }
        expect(find.text(r'$149 CAD / month'), findsOneWidget);
        expect(find.text('Free'), findsOneWidget);
        final free = tester.getRect(
          find.byKey(const ValueKey('pricing-card-free_access')),
        );
        final member = tester.getRect(
          find.byKey(const ValueKey('pricing-card-professional')),
        );
        if (width >= 1000) {
          expect(member.top, free.top);
          expect(member.height, free.height);
        } else {
          expect(member.top, greaterThan(free.bottom));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Member overview professional entry keeps pricing before the workspace at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const MaterialApp(home: MemberOverviewPage()));
        await tester.pump(const Duration(seconds: 1));
        final button = find.text('I PROVIDE PROFESSIONAL SERVICES');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(MemberPricingPage), findsOneWidget);
        expect(find.byType(MemberDealMarketplacePage), findsNothing);
        expect(find.text(r'$149 CAD / month'), findsOneWidget);
        expect(find.text('Buyer, Seller & Learning'), findsOneWidget);
        expect(find.text('Free member'), findsNothing);
        expect(find.text('Featured'), findsNothing);
        final next = find.byKey(const Key('member-pricing-continue'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.byType(MemberDealMarketplacePage), findsOneWidget);
        expect(AppTunnelController.current.value, AppTunnel.member);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      'Home keeps pricing and removes the consulting promotion at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: AcquisitionSupportPage()),
        );
        await tester.pump(const Duration(seconds: 1));
        final pricing = find.text('View membership pricing');
        await tester.scrollUntilVisible(
          pricing,
          700,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(MembershipPlanCards), findsOneWidget);
        expect(find.text(r'$149 CAD / month'), findsOneWidget);
        expect(find.text('Buyer, Seller & Learning'), findsOneWidget);
        expect(find.text('Free member'), findsNothing);
        expect(find.text('Featured'), findsNothing);
        expect(find.text('Explore personal consulting'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      'consulting photos grow without changing permanent slots at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: PersonalizedConsultingPage()),
        );
        await tester.pumpAndSettle();
        final hero = find.byKey(
          const ValueKey(
            'consulting-photo-image.assistant.consulting.background',
          ),
        );
        expect(tester.getSize(hero).height, width < 800 ? 460 : 720);
        expect(
          tester.getSize(hero).width,
          greaterThan(width < 800 ? 380 : 700),
        );
        final conversationPhoto = find.byKey(
          const ValueKey('consulting-photo-image.assistant_workspace_page.m2'),
        );
        await tester.scrollUntilVisible(
          conversationPhoto,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(conversationPhoto).height,
          width < 800 ? 440 : 640,
        );
        expect(
          tester.getSize(conversationPhoto).width,
          greaterThan(width < 800 ? 340 : 650),
        );
        expect(
          tester.getSize(conversationPhoto).width,
          lessThan(width < 800 ? 390 : 900),
        );
        expect(
          tester
              .widgetList<SiteParallaxImage>(find.byType(SiteParallaxImage))
              .first
              .maxTravel,
          150,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final role in AppTunnel.values) {
    testWidgets(
      'organizer groups dashboard tools without consulting links for $role',
      (tester) async {
        AppTunnelController.select(role);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppNavigationMenu(guidePage: 'profile')),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Personal consulting'), findsNothing);
        expect(find.byType(AppNavigationPill), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
