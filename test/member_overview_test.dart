import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/member_overview_page.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/widgets/pika_introduction.dart';
import 'package:dwelling_iq/widgets/affinity_cinematic.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('Member overview contains moved choices and Pika at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: MemberOverviewPage()));
      await tester.pumpAndSettle();
      expect(find.byType(AffinityEntryChoices), findsOneWidget);
      expect(find.byType(PikaIntroduction), findsOneWidget);
      expect(find.text('I WANT TO BUY A BUSINESS'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Home removes Pika, the hero choices and the consulting promotion',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AcquisitionSupportPage()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PikaIntroduction), findsNothing);
      expect(find.byType(AffinityEntryChoices), findsNothing);
      expect(find.text('I WANT TO BUY A BUSINESS'), findsNothing);
      expect(find.text('Explore personal consulting'), findsNothing);
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('navigation-memberStudio')));
      await tester.pumpAndSettle();
      expect(find.byType(MemberOverviewPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
