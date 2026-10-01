import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/widgets/team_workspace.dart';
import 'package:dwelling_iq/widgets/team_member_portrait.dart';
import 'package:dwelling_iq/widgets/affinity_cinematic.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'team_professions_test.dart' show member;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('seller team uses the shared buyer workspace at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerDashboardPage(initialView: SellerDashboardView.team),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeamWorkspace), findsOneWidget);
      expect(find.text('Sign in to build your transfer team'), findsOneWidget);
      expect(find.text('Adviser or lead name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'seller shared team has portraits and prevents adding a second member in a filled profession',
    (tester) async {
      final providers = [
        member('saved', 'Saved accountant', ProviderCategory.accountant),
        member('other', 'Other accountant', ProviderCategory.qualityOfEarnings),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamWorkspace(
              seller: true,
              loadTeamProviders: () async => (providers, {'saved'}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeamMemberPortrait), findsOneWidget);
      expect(find.text('Saved accountant'), findsOneWidget);
      expect(
        find.text('Profession filled — remove your current member to switch.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Profession already filled',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'landing advances exactly one slide every seven seconds and pause stops it',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AffinityTimedChapters()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      PageController controller() =>
          tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(controller().page, 0);
      await tester.pump(const Duration(seconds: 6));
      expect(controller().page, 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 700));
      expect(controller().page, 1);
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 700));
      expect(controller().page, 2);
      await tester.tap(find.byTooltip('Pause automatic slides'));
      await tester.pump(const Duration(seconds: 14));
      expect(controller().page, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
