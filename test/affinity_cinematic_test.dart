import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/widgets/affinity_cinematic.dart';
import 'package:dwelling_iq/services/site_content_service.dart';

void main() {
  testWidgets('explicit motion choice overrides reduced motion and survives reopening', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget page() => const MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: Size(1280, 900), disableAnimations: true),
      child: AcquisitionSupportPage()));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.byType(AffinityCinemaHero), findsNothing);
    await tester.tap(find.text('Enable motion'));
    await tester.pumpAndSettle();
    expect(find.byType(AffinityCinemaHero), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('affinity.landing.motion'), true);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Motion on'), findsOneWidget);
    expect(find.byType(AffinityCinemaHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'scroll scrubs and holds the cinema; editing removes the extended scene',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(() => SiteContentService.editing.value = false);
      double progress = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                AffinityScrollScene(
                  controller: controller,
                  startOffset: 0,
                  screens: 3,
                  fallback: const Text('Editable layout'),
                  builder: (context, p, height) {
                    progress = p;
                    return const ColoredBox(
                      color: Colors.black,
                      child: Text('Scene'),
                    );
                  },
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(progress, 0);
      controller.jumpTo(300);
      await tester.pump();
      expect(progress, greaterThan(.2));
      expect(tester.getTopLeft(find.text('Scene')).dy, closeTo(0, .01));
      SiteContentService.editing.value = true;
      await tester.pump();
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Editable layout'), findsOneWidget);
      expect(find.text('Scene'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets('cinematic hero and all chapters fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final progress in [0.0, .6, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 818,
                child: AffinityCinemaHero(
                  progress: progress,
                  height: 818,
                  onBuyer: () {},
                  onMember: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      for (var i = 0; i < 4; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 818,
                child: AffinityCinemaChapters(progress: i / 3.75),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
