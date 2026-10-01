import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/member_profile_page.dart';
import 'package:dwelling_iq/widgets/personal_experience_editor.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';

const example = MarketplaceProvider(
  id: 'demo-review',
  category: ProviderCategory.businessBroker,
  name: 'Amelia Example',
  company: 'Example Advisory',
  specialty: 'Business sales',
  verified: false,
  sponsored: false,
  reviewScore: 0,
  reviewCount: 0,
  experience: 8,
  jobTitle: 'Broker',
  isExample: true,
  personalExperience:
      'I help owners plan a thoughtful transition and prepare for buyer conversations.',
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'example review can be created and updated without publishing a real rating',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: MemberProfilePage(provider: example)),
      );
      await tester.pumpAndSettle();
      expect(find.text('BUILD A CONNECTION BRIEF'), findsNothing);
      expect(find.text(example.personalExperience), findsOneWidget);
      await tester.ensureVisible(find.text('RATE & REVIEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RATE & REVIEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('3 stars'));
      await tester.enterText(
        find.byType(TextField),
        'A clear and thoughtful example review.',
      );
      await tester.pump();
      await tester.tap(find.text('Save preview review'));
      await tester.pumpAndSettle();
      expect(
        find.text('A clear and thoughtful example review.'),
        findsOneWidget,
      );
      expect(find.text('Preview reviews · 1 · 3.0 / 5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        const MaterialApp(home: MemberProfilePage(provider: example)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('A clear and thoughtful example review.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('RATE & REVIEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RATE & REVIEW'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'A clear and thoughtful example review.',
      );
      await tester.enterText(
        find.byType(TextField),
        'Updated preview experience.',
      );
      await tester.pump();
      await tester.tap(find.text('Save preview review'));
      await tester.pumpAndSettle();
      expect(find.text('Updated preview experience.'), findsOneWidget);
      expect(find.text('A clear and thoughtful example review.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('experience editor keeps over-limit draft and blocks saving', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalExperienceEditor(provider: example, onSaved: () {}),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('member_personal_experience')),
      List.filled(201, 'word').join(' '),
    );
    await tester.tap(find.text('Save personal experience'));
    await tester.pump();
    expect(find.text('Keep your write-up to 200 words.'), findsOneWidget);
    expect(find.text('201 / 200 words'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text
          .split(' ')
          .length,
      201,
    );
  });
}
