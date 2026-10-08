import 'package:dwelling_iq/widgets/site_image.dart';
import 'package:dwelling_iq/services/site_content_service.dart';
import 'package:dwelling_iq/screens/assistant_workspace_page.dart';
import 'package:dwelling_iq/widgets/site_parallax_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('consulting editorial layout and calendar fit $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: PersonalizedConsultingPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Founder-led acquisition consulting'), findsOneWidget);
      expect(find.byType(SiteParallaxImage), findsWidgets);
      expect(find.text('Hide section'), findsNothing);
      final calendar = find.byKey(const Key('consulting_calendar'));
      await tester.scrollUntilVisible(
        calendar,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(calendar, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Pause parallax'), findsNothing);
      expect(find.byTooltip('Enable parallax'), findsNothing);
    });
  }
  testWidgets('consulting booking retains date picker and time selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: ConsultingBookingPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CHOOSE A DATE'));
    await tester.tap(find.text('CHOOSE A DATE'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE A DATE'), findsNothing);
    expect(find.text('9:00 AM Pacific'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'consulting motion stays enabled and editing still stabilizes photos',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => SiteContentService.editing.value = false);
      Widget page() => const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1440, 900), disableAnimations: true),
          child: PersonalizedConsultingPage(),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enable parallax'), findsNothing);
      final photo = find.byWidgetPredicate(
        (w) =>
            w is SiteParallaxImage &&
            w.contentKey == 'image.assistant.consulting.background',
      );
      double translation() {
        final image = tester.renderObject<RenderBox>(
          find.descendant(of: photo, matching: find.byType(SiteImage)),
        );
        final flow = tester.renderObject<RenderBox>(
          find.descendant(of: photo, matching: find.byType(Flow)),
        );
        return image.getTransformTo(flow).storage[13];
      }

      final start = translation();
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      scroll.jumpTo(180);
      await tester.pump();
      expect((translation() - start).abs(), greaterThan(60));
      SiteContentService.editing.value = true;
      await tester.pump();
      expect(translation(), -160);
      SiteContentService.editing.value = false;
      await tester.pump();
      expect(find.byTooltip('Pause parallax'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enable parallax'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
