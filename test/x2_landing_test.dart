import 'package:dwelling_iq/screens/acquisition_support_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('public navigation no longer offers X2', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.landing);
    await tester.pumpWidget(const MaterialApp(home: AcquisitionSupportPage()));
    await tester.pumpAndSettle();
    expect(find.text('X2'), findsNothing);
    expect(find.byKey(const ValueKey('organizer-tab-3')), findsNothing);
    expect(find.byKey(const ValueKey('organizer-tab-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
