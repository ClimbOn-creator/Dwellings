import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/widgets/private_deal_entry.dart';
import 'package:dwelling_iq/widgets/buyer_greeting.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/services/deal_room_service.dart';
import 'buyer_command_centre_test.dart' as data;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'greeting types Unicode safely, keeps its height, and replays when reopened',
    (tester) async {
      Widget page() => const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: BuyerGreeting(
              greeting: 'Good morning, Will 👋',
              summary: '2 active acquisitions · 0 actions need attention',
            ),
          ),
        ),
      );
      await tester.pumpWidget(page());
      final visible = find.byKey(const ValueKey('buyer-greeting-visible'));
      expect(tester.widget<Text>(visible).data, isEmpty);
      final height = tester.getSize(find.byType(BuyerGreeting)).height;
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<Text>(visible).data, startsWith('Good'));
      expect(tester.widget<Text>(visible).data, isNot('Good morning, Will 👋'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(visible).data, 'Good morning, Will 👋');
      expect(tester.getSize(find.byType(BuyerGreeting)).height, height);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page());
      expect(tester.widget<Text>(visible).data, isEmpty);
      await tester.pumpAndSettle();
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'private deal entry validates, retains failures, saves once and offers Home at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var attempts = 0;
        var home = false;
        DealIntakeDetails? captured;
        final pending = Completer<DealRoom>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrivateDealEntry(
                onSave: (details) async {
                  attempts++;
                  captured = details;
                  if (attempts == 1) throw StateError('Network failure');
                  return pending.future;
                },
                onHome: () => home = true,
                onOpen: (_) {},
              ),
            ),
          ),
        );
        Future<void> save() async {
          final button = find.text('Save private deal');
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }

        await save();
        expect(attempts, 0);
        expect(
          find.text('Enter a business name or a short deal title.'),
          findsOneWidget,
        );
        final title = find.byKey(const ValueKey('private-deal-title'));
        final source = find.byKey(const ValueKey('private-deal-source_url'));
        await tester.ensureVisible(title);
        await tester.enterText(title, 'Island HVAC');
        await tester.ensureVisible(source);
        await tester.enterText(source, 'javascript:alert(1)');
        await save();
        expect(attempts, 0);
        await tester.ensureVisible(source);
        await tester.enterText(source, 'https://example.com/listing/123');
        await save();
        expect(attempts, 1);
        expect(tester.widget<TextField>(title).controller!.text, 'Island HVAC');
        expect(
          find.textContaining('Your entries are still here'),
          findsOneWidget,
        );
        final button = find.text('Save private deal');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(attempts, 2);
        expect(find.text('Saving private deal…'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.ancestor(
                  of: find.text('Saving private deal…'),
                  matching: find.byType(FilledButton),
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          captured!.profileSnapshot['source_url'],
          'https://example.com/listing/123',
        );
        expect(captured!.profileSnapshot['currency'], 'CAD');
        expect(
          captured!.profileSnapshot.containsKey('annual_revenue'),
          isFalse,
        );
        pending.complete(data.island);
        await tester.pumpAndSettle();
        expect(find.text('Saved to your private deals'), findsOneWidget);
        await tester.ensureVisible(find.text('View on Home'));
        await tester.tap(find.text('View on Home'));
        expect(home, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
