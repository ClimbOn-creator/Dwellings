import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/widgets/team_member_portrait.dart';

MarketplaceProvider member(String id, String name, ProviderCategory category) =>
    MarketplaceProvider(
      id: id,
      name: name,
      category: category,
      company: 'Example Advisory',
      specialty: 'Acquisitions',
      verified: false,
      sponsored: false,
      reviewScore: 0,
      reviewCount: 0,
      experience: 5,
      jobTitle: 'Adviser',
      isExample: false,
    );
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('signed-out team content is centered at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      final entry = width < 800 ? find.text('Manage') : find.text('My team');
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      final signIn = find.text('Sign in to build your acquisition team');
      expect(
        tester.getCenter(signIn).dx,
        closeTo(width < 800 ? width / 2 : (width + 213) / 2, 2),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'profession bubbles filter compact results and disable filled roles at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final providers = [
          member('saved', 'Saved accountant', ProviderCategory.accountant),
          member(
            'other',
            'Other accountant',
            ProviderCategory.qualityOfEarnings,
          ),
          member('law', 'Suggested lawyer', ProviderCategory.maLawyer),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: DealRoomsPage(
              loadTeamProviders: () async => (providers, {'saved'}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = width < 800 ? find.text('Manage') : find.text('My team');
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.byType(TeamMemberPortrait), findsOneWidget);
        expect(find.text('Other accountant'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (w) =>
                      w is IconButton &&
                      w.tooltip == 'Profession already filled',
                ),
              )
              .onPressed,
          isNull,
        );
        final lawyer = find.widgetWithText(ChoiceChip, 'Add a lawyer');
        await tester.ensureVisible(lawyer);
        await tester.tap(lawyer);
        await tester.pumpAndSettle();
        expect(find.text('Suggested lawyer'), findsOneWidget);
        expect(find.text('Other accountant'), findsNothing);
        expect(find.byType(TeamMemberPortrait), findsOneWidget);
        expect(
          find.byTooltip('Add Suggested lawyer to My Team'),
          findsOneWidget,
        );
        final search = find.widgetWithText(TextField, 'Search professionals');
        await tester.ensureVisible(search);
        await tester.enterText(search, 'not found');
        await tester.pumpAndSettle();
        expect(find.text('Suggested lawyer'), findsNothing);
        final all = find.widgetWithText(ChoiceChip, 'All professions');
        await tester.ensureVisible(all);
        await tester.tap(all);
        await tester.pumpAndSettle();
        expect(find.text('Other accountant'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('related provider categories share one profession slot', () {
    expect(
      ProviderCategory.maLawyer.teamProfession,
      ProviderCategory.lawyer.teamProfession,
    );
    expect(
      ProviderCategory.accountant.teamProfession,
      ProviderCategory.qualityOfEarnings.teamProfession,
    );
    expect(
      ProviderCategory.lender.teamProfession,
      ProviderCategory.commercialLender.teamProfession,
    );
  });
}
