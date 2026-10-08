import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/models/footer_page_content.dart';
import 'package:dwelling_iq/screens/footer_information_page.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/widgets/membership_footer.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.landing);
  });
  testWidgets('only the four Affinity links open dedicated pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: MembershipFooter())),
      ),
    );
    expect(find.byKey(const Key('footer-link-directory')), findsNothing);
    expect(find.byKey(const Key('footer-link-buyer-leads')), findsNothing);
    for (final topic in FooterTopic.values.where(
      (topic) => topic.isInformationPage,
    )) {
      final link = find.byKey(Key('footer-link-${topic.slug}'));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FooterInformationPage>(find.byType(FooterInformationPage))
            .topic,
        topic,
      );
      expect(find.text(topic.content.headline), findsOneWidget);
      expect(tester.takeException(), isNull, reason: topic.name);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(FooterInformationPage), findsNothing);
    }
  });
  testWidgets(
    'every footer page fits a phone and section links scroll to content',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final topic in FooterTopic.values.where(
        (topic) => topic.isInformationPage,
      )) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(topic),
            home: FooterInformationPage(topic: topic),
          ),
        );
        await tester.pumpAndSettle();
        final section = find.byKey(const Key('footer-section-1'));
        await tester.scrollUntilVisible(
          section,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(section);
        await tester.pumpAndSettle();
        final target = find.text(topic.content.sections[1].body);
        expect(tester.getTopLeft(target).dy, lessThan(844));
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: topic.name);
      }
    },
  );
  testWidgets(
    'footer-only topics are absent from dropdown and company email starts unpublished',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FooterInformationPage(topic: FooterTopic.contact),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Company email coming soon'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Company email coming soon'), findsOneWidget);
      expect(find.text('Email Affinity'), findsNothing);
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, 6000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      final popup = find.byType(PopupMenuItem<AppNavigationDestination>);
      for (final label in [
        'Blueprint',
        'Buyer readiness',
        'Expert directory',
        'Buyer leads',
        'Our approach',
        'Privacy',
        'Terms',
        'Contact',
      ]) {
        expect(
          find.descendant(of: popup, matching: find.text(label)),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('six tool links bypass the introduction pages', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const topics = [
      FooterTopic.blueprint,
      FooterTopic.readiness,
      FooterTopic.dealScreen,
      FooterTopic.pipeline,
      FooterTopic.memberStudio,
      FooterTopic.consulting,
    ];
    for (final topic in topics) {
      AppTunnelController.select(AppTunnel.landing);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(topic),
          home: const Scaffold(
            body: SingleChildScrollView(child: MembershipFooter()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('footer-link-${topic.slug}')));
      await tester.pumpAndSettle();
      expect(
        find.byType(FooterInformationPage),
        findsNothing,
        reason: topic.name,
      );
      expect(
        find.byType(footerDestination(topic).runtimeType),
        findsOneWidget,
        reason: topic.name,
      );
      expect(tester.takeException(), isNull, reason: topic.name);
    }
  });
  test(
    'acquisition and professional destinations route directly to existing tools',
    () {
      expect(
        footerDestination(FooterTopic.blueprint),
        isA<AcquisitionBlueprintPage>(),
      );
      expect(
        footerDestination(FooterTopic.readiness),
        isA<BuyerReadinessPage>(),
      );
      expect(
        (footerDestination(FooterTopic.dealScreen) as DealRoomsPage)
            .initialView,
        BuyerDashboardView.dealScreen,
      );
      expect(
        footerToolDestination(FooterTopic.directory),
        isA<MemberDealMarketplacePage>(),
      );
      expect(
        (footerToolDestination(FooterTopic.buyerLeads)
                as MemberDealMarketplacePage)
            .initialView,
        MemberDashboardView.opportunities,
      );
      expect(
        footerDestination(FooterTopic.memberStudio),
        isA<MemberDealMarketplacePage>(),
      );
      expect(footerDestination(FooterTopic.pipeline), isA<DealRoomsPage>());
      for (final topic in FooterTopic.values) {
        expect(FooterTopic.fromModule('footer-${topic.slug}'), topic);
      }
      expect(FooterTopic.fromModule('buyer-dashboard'), isNull);
    },
  );
}
