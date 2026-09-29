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
      await tester.tap(find.byTooltip('Pause parallax'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enable parallax'), findsOneWidget);
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
}
