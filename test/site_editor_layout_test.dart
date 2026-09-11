import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/services/site_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fontPath = Platform.environment['EDITOR_FONT_PATH'];
  setUpAll(() async {
    if (fontPath != null) {
      final loader = FontLoader('EditorPreview');
      loader.addFont(
        File(
          fontPath,
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    }
  });
  for (final width in [1280.0, 390.0]) {
    testWidgets('visual editor landing and dialog fit ${width.toInt()}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => SiteContentService.editing.value = false);
      SiteContentService.editing.value = true;
      const boundary = ValueKey('page-preview');
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: fontPath == null ? null : 'EditorPreview',
            ),
            home: const AcquisitionSupportPage(),
          ),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final title = find.text(
        'Don’t just find a business.\nKnow what you’re buying into.',
      );
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
      final output = Platform.environment['EDITOR_SCREENSHOT_DIR'];
      if (output != null) {
        final render = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundary),
        );
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/editor-${width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  }
}
