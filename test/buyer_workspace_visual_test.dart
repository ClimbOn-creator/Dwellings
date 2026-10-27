import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('PactInter')..addFont(
          File(
            'assets/fonts/Inter.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(
            File(
              '$fonts/${entry.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('buyer monochrome workspace and resources at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
          home: const DealRoomsPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/buyer_workspace_${width.toInt()}.png'),
      );
      final resources = width < 800
          ? find.text('Resources — grants & community support')
          : find.text('Resources').last;
      await tester.ensureVisible(resources);
      await tester.tap(resources);
      await tester.pumpAndSettle();
      expect(find.byType(BuyerResourcesPanel), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Community Futures');
      await tester.pumpAndSettle();
      expect(find.text('Community Futures BC'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/buyer_resources_${width.toInt()}.png'),
      );
    });
  }
}
