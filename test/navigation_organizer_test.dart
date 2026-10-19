import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:dwelling_iq/widgets/affinity_cinematic.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/footer_information_page.dart';
import 'package:dwelling_iq/models/footer_page_content.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0, 2560.0]) {
    testWidgets(
      'organizer stays centred over the edge-to-edge landing photo at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: AcquisitionSupportPage()),
        );
        await tester.pumpAndSettle();
        final bar = tester.getRect(
          find.byKey(const Key('affinity-navigation-bar')),
        );
        expect(bar.center.dx, closeTo(width / 2, .5));
        expect(bar.width, lessThanOrEqualTo(336));
        expect(find.byType(SliverAppBar), findsNothing);
        final photo = tester.getRect(find.byType(AffinityCinemaHero));
        expect(photo.left, 0);
        expect(photo.top, 0);
        expect(photo.width, width);
        expect(photo.height, 1000);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('About us'), findsOneWidget);
        expect(find.byType(AppNavigationPill), findsNothing);
        await tester.tap(find.byKey(const Key('dashboard-menu-toggle')));
        await tester.pumpAndSettle();
        expect(find.byType(AppNavigationPill), findsNWidgets(4));
        await tester.tapAt(const Offset(5, 500));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dashboard-navigation-panel')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'grey hover highlight slides between tabs and Escape closes the menu',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppNavigationMenu(guidePage: 'landing', dark: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final highlight = find.byKey(const Key('navigation-hover-highlight'));
      final start = tester.getTopLeft(highlight).dx;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('organizer-tab-1'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final middle = tester.getTopLeft(highlight).dx;
      await tester.pumpAndSettle();
      final finish = tester.getTopLeft(highlight).dx;
      expect(middle, greaterThan(start));
      expect(middle, lessThan(finish));
      await tester.tap(find.byKey(const Key('dashboard-menu-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dashboard-navigation-panel')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-navigation-panel')), findsNothing);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('About us opens the company introduction', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppNavigationMenu(guidePage: 'landing', dark: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About us'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FooterInformationPage>(find.byType(FooterInformationPage))
          .topic,
      FooterTopic.approach,
    );
    expect(tester.takeException(), isNull);
  });
}
