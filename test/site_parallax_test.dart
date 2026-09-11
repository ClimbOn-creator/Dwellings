import 'package:flutter/material.dart';
import 'package:dwelling_iq/widgets/site_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/widgets/site_parallax_image.dart';
import 'package:dwelling_iq/services/site_content_service.dart';

void main() {
  testWidgets(
    'scroll moves the photo; reduced motion and editing stop movement',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(() => SiteContentService.editing.value = false);
      Future<void> mount({bool reduced = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(800, 600),
                disableAnimations: reduced,
              ),
              child: Scaffold(
                body: ListView(
                  controller: controller,
                  children: [
                    SiteParallaxImage(
                      controller: controller,
                      contentKey: 'image.test',
                      asset: 'assets/images/affinity-city-hero.jpg',
                      child: const SizedBox(
                        height: 360,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 1600),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      double translation() {
        final image = tester.renderObject<RenderBox>(find.byType(SiteImage));
        final flow = tester.renderObject<RenderBox>(find.byType(Flow));
        return image.getTransformTo(flow).storage[13] + 64;
      }

      await mount();
      final initial = translation();
      controller.jumpTo(180);
      await tester.pump();
      expect(translation(), isNot(initial));
      expect(translation().abs(), lessThanOrEqualTo(54));
      SiteContentService.editing.value = true;
      await tester.pump();
      expect(translation(), 0);
      expect(find.text('Edit background'), findsOneWidget);
      SiteContentService.editing.value = false;
      await mount(reduced: true);
      controller.jumpTo(120);
      await tester.pump();
      expect(translation(), 0);
      expect(tester.takeException(), isNull);
    },
  );
}
