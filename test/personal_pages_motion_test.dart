import 'package:dwelling_iq/widgets/flowing_color_banner.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/widgets/personal_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'portfolio color cover moves continuously and stops for reduced motion',
    (tester) async {
      Widget banner(bool reduced) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const SizedBox(
            width: 800,
            height: 200,
            child: FlowingColorBanner(),
          ),
        ),
      );
      await tester.pumpWidget(banner(false));
      final first = tester
          .widget<CustomPaint>(find.byType(CustomPaint).last)
          .painter!;
      await tester.pump(const Duration(seconds: 2));
      final moving = tester
          .widget<CustomPaint>(find.byType(CustomPaint).last)
          .painter!;
      expect(moving.shouldRepaint(first), isTrue);
      await tester.pumpWidget(banner(true));
      final stopped = tester
          .widget<CustomPaint>(find.byType(CustomPaint).last)
          .painter!;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<CustomPaint>(find.byType(CustomPaint).last)
            .painter!
            .shouldRepaint(stopped),
        isFalse,
      );
    },
  );

  testWidgets('Blueprint navigation retains typed answers on a phone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'affinity.landing.motion': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: AcquisitionBlueprintPage()),
    );
    await tester.pumpAndSettle();
    final next = find.text('CONTINUE');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Victoria');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    final back = find.text('Back');
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Victoria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'explicit motion choice overrides system reduction and persists',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: PersonalMotion(
              builder: (context, scroll, toggle) => Scaffold(
                appBar: AppBar(actions: [toggle]),
                body: Text(
                  MediaQuery.disableAnimationsOf(context) ? 'still' : 'moving',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('still'), findsOneWidget);
      await tester.tap(find.byTooltip('Enable motion'));
      await tester.pumpAndSettle();
      expect(find.text('moving'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'affinity.landing.motion',
        ),
        isTrue,
      );
    },
  );
}
