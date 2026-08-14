import 'package:dwelling_iq/screens/connection_brief_page.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const provider = MarketplaceProvider(
    id: 'example-lawyer',
    category: ProviderCategory.lawyer,
    name: 'Jamie Park',
    company: 'Threshold Law',
    specialty: 'Property purchase and conveyancing',
    verified: true,
    sponsored: false,
    reviewScore: 4.9,
    reviewCount: 42,
    experience: 12,
    jobTitle: 'Property lawyer',
    isExample: true,
  );

  testWidgets('connection brief starts with an outcome and consented steps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ConnectionBriefPage(provider: provider)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Make the first conversation count.'), findsOneWidget);
    expect(find.text('What outcome do you need?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Property or financing details'), findsNothing);
  });
}
