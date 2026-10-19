import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/dashboard_showcase_page.dart';
import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:dwelling_iq/widgets/dashboard_greeting.dart';
import 'package:dwelling_iq/widgets/buyer_greeting.dart';
import 'package:dwelling_iq/widgets/membership_footer.dart';
import 'package:dwelling_iq/widgets/pika_introduction.dart';
import 'package:dwelling_iq/widgets/home_brand_button.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('greeting uses the same local time periods as Buyer', () {
    for (final (hour, expected) in [
      (2, 'Working late'),
      (9, 'Good morning'),
      (14, 'Good afternoon'),
      (19, 'Good evening'),
      (23, 'Working late'),
    ]) {
      expect(dashboardSalutation(DateTime(2026, 10, 18, hour)), expected);
    }
  });
  testWidgets('shared greeting replays the Buyer reveal when reopened', (
    tester,
  ) async {
    Widget page() => const MaterialApp(
      home: Scaffold(body: DashboardGreeting(summary: 'Your next step')),
    );
    await tester.pumpWidget(page());
    final clip = find.byKey(const ValueKey('buyer-greeting-visible-reveal'));
    double width() => tester
        .widget<ClipRect>(clip)
        .clipper!
        .getClip(tester.getSize(clip))
        .width;
    expect(find.byType(BuyerGreeting), findsOneWidget);
    expect(width(), 0);
    await tester.pump(const Duration(milliseconds: 900));
    expect(width(), greaterThan(0));
    expect(width(), lessThan(tester.getSize(clip).width));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(page());
    expect(width(), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Dashboard tab opens the public showcase and Member entry still requires sign-in at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AppNavigationMenu(guidePage: 'landing')),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        expect(find.byType(DashboardShowcasePage), findsOneWidget);
        if (width < 700) {
          final logo = tester.getRect(find.byType(HomeBrandButton));
          final bar = tester.getRect(
            find.byKey(const Key('affinity-navigation-bar')),
          );
          expect(logo.right, lessThan(bar.left));
        }
        expect(find.byType(MembershipFooter), findsNothing);
        expect(find.byType(PikaIntroduction), findsOneWidget);
        expect(
          find.text('Big decisions.\nA clearer way forward.'),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('showcase-tab-preview-1')),
        );
        await tester.tap(find.byKey(const ValueKey('showcase-tab-preview-1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final member = find.text('Open Member dashboard').first;
        await Scrollable.ensureVisible(tester.element(member), alignment: .3);
        await tester.pumpAndSettle();
        await tester.tap(member);
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
