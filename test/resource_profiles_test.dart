import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1440.0]) {
    testWidgets('provider opens, searches a grant, and returns at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BuyerResourcesPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'WorkBC');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(TextButton, 'WorkBC'));
      await tester.tap(find.widgetWithText(TextButton, 'WorkBC'));
      await tester.pumpAndSettle();
      expect(find.byType(ResourceProviderPage), findsOneWidget);
      final search = find.widgetWithText(
        TextField,
        'Search grants and programs',
      );
      await tester.ensureVisible(search);
      await tester.enterText(search, 'wage');
      await tester.pumpAndSettle();
      expect(find.text('WorkBC Wage Subsidy'), findsOneWidget);
      expect(find.text('B.C. Employer Training Grant'), findsNothing);
      expect(
        find.byTooltip('Save WorkBC Wage Subsidy to profile'),
        findsOneWidget,
      );
      await tester.enterText(search, 'no matching grant');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No matching programs. Try another search or browse the official website.',
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ResourceProviderPage), findsNothing);
      expect(find.widgetWithText(TextButton, 'WorkBC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets('save confirmation swirl respects reduced motion=$reduced', (
      tester,
    ) async {
      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => ResourceSaveButton(
                  saved: saved,
                  busy: false,
                  name: 'Provider',
                  onPressed: () async => setState(() => saved = !saved),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Save Provider to profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('Saved · remove'), findsOneWidget);
      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.entry(0, 0), reduced ? 1.0 : isNot(1.0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('resource cards fit large text and provide a desktop preview', (
    tester,
  ) async {
    final capture = Platform.environment['CAPTURE_RESOURCE_PREVIEW'];
    if (capture != null) {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto')
          ..addFont(
            File(
              '/System/Library/Fonts/Supplemental/Arial.ttf',
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
    }
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BuyerResourcesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (capture != null) {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 1),
      ))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(
        () => File(capture).writeAsBytes(bytes!.buffer.asUint8List()),
      );
      image.dispose();
    }
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const BuyerResourcesPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
