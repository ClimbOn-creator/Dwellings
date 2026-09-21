import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/widgets/team_member_portrait.dart';

const person = MarketplaceProvider(
  id: 'test-member',
  category: ProviderCategory.accountant,
  name: 'Alex Morgan',
  company: 'Example Advisory',
  specialty: 'Acquisitions',
  verified: false,
  sponsored: false,
  reviewScore: 0,
  reviewCount: 0,
  experience: 5,
  jobTitle: 'Acquisition adviser',
  isExample: false,
);
void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'team portraits precede visible member search and resources at $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: DealRoomsPage(
              loadTeamProviders: () async => ([person], {'test-member'}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = width < 800 ? find.text('Manage') : find.text('My team');
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await tester.pumpAndSettle();
        expect(find.text('Alex Morgan'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Search professionals'),
          findsOneWidget,
        );
        final teamY = tester.getTopLeft(find.byType(TeamMemberPortrait)).dy;
        final searchY = tester.getTopLeft(find.text('Find professionals')).dy;
        final resourcesY = tester
            .getTopLeft(find.text('Your saved resources'))
            .dy;
        expect(teamY, lessThan(searchY));
        expect(searchY, lessThan(resourcesY));
        expect(find.text('Team members'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'desktop portrait reveals action on hover; photo toggles and name opens profile',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = true;
      var toggles = 0;
      var profiles = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                child: StatefulBuilder(
                  builder: (context, setState) => TeamMemberPortrait(
                    provider: person,
                    selected: selected,
                    busy: false,
                    onProfile: () => profiles++,
                    onToggle: () => setState(() {
                      selected = !selected;
                      toggles++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(InkWell).first));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      expect(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.text('Remove from My Team'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(toggles, 1);
      expect(profiles, 0);
      expect(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.text('Add to My Team'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Alex Morgan'));
      expect(profiles, 1);
      await mouse.removePointer();
    },
  );
  testWidgets('phone offers explicit action and disables saves while busy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var toggles = 0;
    Widget page(bool busy) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 145,
            child: TeamMemberPortrait(
              provider: person,
              selected: false,
              busy: busy,
              onProfile: () {},
              onToggle: busy ? null : () => toggles++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(page(false));
    await tester.tap(find.widgetWithText(TextButton, 'Add to My Team'));
    expect(toggles, 1);
    await tester.pumpWidget(page(true));
    expect(tester.widget<InkWell>(find.byType(InkWell).first).onTap, isNull);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Saving…'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
