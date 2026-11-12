import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Learning Resources opens profiles and the save flow at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: LearningDashboardPage()),
        );
        await tester.pumpAndSettle();
        final resources = find.text('Resources');
        await tester.ensureVisible(resources);
        await tester.tap(resources);
        await tester.pumpAndSettle();
        expect(find.byType(BuyerResourcesPanel), findsOneWidget);
        expect(find.byType(LearningDashboardPage), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Community Futures');
        await tester.pumpAndSettle();
        final provider = find.text('Community Futures BC');
        expect(provider, findsOneWidget);
        await tester.ensureVisible(provider);
        await tester.tap(provider);
        await tester.pumpAndSettle();
        expect(find.byType(ResourceProviderPage), findsOneWidget);
        final save = find.byTooltip('Save Community Futures BC to profile').first;
        expect(save, findsOneWidget);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(BuyerResourcesPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
