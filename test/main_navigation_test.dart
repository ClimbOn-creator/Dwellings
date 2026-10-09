import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/screens/buyer_resources_page.dart';
import 'package:dwelling_iq/screens/transaction_learning_page.dart';
import 'package:dwelling_iq/services/nova_training_controller.dart';
import 'package:dwelling_iq/services/nova_training_service.dart';
import 'package:dwelling_iq/widgets/app_navigation_menu.dart';
import 'package:dwelling_iq/widgets/home_brand_button.dart';
import 'package:dwelling_iq/widgets/nova_training_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.buyer);
  });
  testWidgets('landing has no Pebble button or automatic introduction', (
    tester,
  ) async {
    final controller = NovaTrainingController(
      service: NovaTrainingService(accountId: () => null),
    )..currentPage = 'landing';
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => NovaTrainingHost(
          navigatorKey: navigator,
          controller: controller,
          child: child!,
        ),
        home: const AcquisitionSupportPage(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('pebble_page_help')), findsNothing);
    expect(find.text('Hi, I’m Pebble.'), findsNothing);
    expect(controller.active, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Resources keeps full main header at $width and room navigation is distinct',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BuyerResourcesPage(),
                    ),
                  ),
                  child: const Text('Open resources'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open resources'));
        await tester.pumpAndSettle();
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.automaticallyImplyLeading, isFalse);
        expect(bar.toolbarHeight, 82);
        expect(find.byType(HomeBrandButton), findsOneWidget);
        expect(find.byKey(const Key('pebble_page_help')), findsOneWidget);
        await tester.tap(find.byTooltip('Open navigation'));
        await tester.pumpAndSettle();
        expect(find.text('Pebble walkthrough'), findsNothing);
        await tester.tap(find.text('Transaction Room'));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionLearningPage), findsOneWidget);
        expect(find.text('The deal,\nmade clear.'), findsOneWidget);
        expect(find.text('Your pipeline'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
