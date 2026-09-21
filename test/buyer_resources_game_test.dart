import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';
import 'package:dwelling_iq/screens/spot_mistake_page.dart';
import 'package:dwelling_iq/services/buyer_resources.dart';
import 'package:dwelling_iq/services/spot_mistake_lessons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('buyer Resources stays inside dashboard at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
      await tester.pumpAndSettle();
      final entry = width < 800
          ? find.text('Resources — grants & community support')
          : find.text('Resources');
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerResourcesPanel), findsOneWidget);
      expect(find.byType(DealRoomsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('regular menu opens resources and game', (tester) async {
    for (final label in ['Resources', 'Spot the mistake']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [AppNavigationMenu(dark: false)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        label == 'Resources'
            ? find.byType(BuyerResourcesPage)
            : find.byType(SpotMistakePage),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('resources filter without signing in on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BuyerResourcesPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Community Futures');
    await tester.pumpAndSettle();
    expect(find.text('Community Futures BC'), findsOneWidget);
    expect(find.text('BDC business purchase financing'), findsNothing);
    expect(find.byTooltip('Save Community Futures BC to profile'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no such resource');
    await tester.pumpAndSettle();
    expect(
      find.text('No matching resources. Try another search or category.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('game completes, locks answers, and reviews mistakes on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: SpotMistakePage()));
    await tester.pumpAndSettle();
    for (var i = 0; i < mistakeLessons.length; i++) {
      final lesson = mistakeLessons[i];
      final answer = i == 0 ? (lesson.answer + 1) % 3 : lesson.answer;
      final choice = find.text(lesson.claims[answer]);
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      final buttons = tester.widgetList<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(buttons.every((b) => b.onPressed == null), isTrue);
      expect(find.text(lesson.explanation), findsOneWidget);
      final next = find.text(
        i == mistakeLessons.length - 1 ? 'See results' : 'Next scenario',
      );
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('7 of 8 spotted'), findsOneWidget);
    final review = find.text('Practice missed scenarios');
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.text(mistakeLessons.first.title), findsOneWidget);
    final correct = find.text(
      mistakeLessons.first.claims[mistakeLessons.first.answer],
    );
    await tester.ensureVisible(correct);
    await tester.tap(correct);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('See results'));
    await tester.tap(find.text('See results'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 spotted'), findsOneWidget);
    await tester.ensureVisible(find.text('Play again'));
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('Scenario 1 of 8 · Cash flow · Score 0'), findsOneWidget);
  });
  test('catalog has distinct account keys and official HTTPS links', () {
    expect(
      buyerResources.map((r) => BuyerResourceTeam.key(r.id)).toSet().length,
      buyerResources.length,
    );
    expect(
      buyerResources.every((r) => Uri.parse(r.url).scheme == 'https'),
      isTrue,
    );
  });
}
