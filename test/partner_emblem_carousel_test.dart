import 'package:dwelling_iq/services/site_content_service.dart';
import 'package:dwelling_iq/widgets/partner_emblem_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'partner loop moves seamlessly and pauses for editing at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 1100),
                    PartnerEmblemCarousel(controller: scroll),
                    const SizedBox(height: 1000),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final track = find.byKey(const Key('partner-carousel-track'));
        double offset() =>
            tester.widget<Transform>(track).transform.storage[12];
        expect(partnerPreviewNames.toSet().length, 6);
        scroll.jumpTo(1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(seconds: 1));
        expect(offset(), lessThan(0));
        SiteContentService.editing.value = true;
        await tester.pump();
        final stopped = offset();
        await tester.pump(const Duration(seconds: 2));
        expect(offset(), stopped);
        SiteContentService.editing.value = false;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(seconds: 1));
        expect(offset(), lessThan(stopped));
        scroll.jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        scroll.dispose();
      },
    );
  }
}
