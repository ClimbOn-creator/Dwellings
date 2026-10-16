import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/deal_comparison_page.dart';
import 'package:dwelling_iq/screens/member_profile_page.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/widgets/team_member_portrait.dart';
import 'package:dwelling_iq/widgets/profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const member = MarketplaceProvider(
  id: 'member',
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
    testWidgets('buyer dashboard identifies itself and has no quiz at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Buyer dash'), findsOneWidget);
      expect(find.text('Deal comparison quiz'), findsNothing);
      expect(find.text('Compare what fits me'), findsNothing);
      expect(find.byType(DealComparisonPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('member profile hides all messaging actions at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MemberProfilePage(provider: member, onMessage: () async {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MESSAGE'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'buyer showcase renders all selected members with seller-style portraits',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: DealRoomsPage(
            loadTeamProviders: () async => (List.filled(7, member), {'member'}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeamMemberPortrait), findsNWidgets(7));
      expect(find.text('Acquisition adviser'), findsNWidgets(7));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'shared circular portraits are slightly smaller and retain names and professions',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              child: TeamMemberPortrait(
                provider: member,
                selected: true,
                busy: false,
                onProfile: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.widget<ProfilePhoto>(find.byType(ProfilePhoto)).size, 88);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Acquisition adviser'), findsOneWidget);
    },
  );
}
