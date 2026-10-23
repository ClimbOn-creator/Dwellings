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
    'greeting reveals left to right even with reduced motion and replays on return',
    (tester) async {
      Widget page() => const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 300,
              child: BuyerGreeting(
                greeting: 'Good morning, Will 👋',
                summary: '2 active acquisitions · 0 actions need attention',
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page());
      final visible = find.byKey(const ValueKey('buyer-greeting-visible'));
      final reveal = find.byKey(
        const ValueKey('buyer-greeting-visible-reveal'),
      );
      Rect clip() => tester
          .widget<ClipRect>(reveal)
          .clipper!
          .getClip(tester.getSize(reveal));
      expect(clip().width, 0);
      final height = tester.getSize(find.byType(BuyerGreeting)).height;
      await tester.pump(const Duration(milliseconds: 900));
      expect(clip().left, 0);
      expect(clip().width, greaterThan(0));
      expect(clip().width, lessThan(tester.getSize(reveal).width));
      expect(tester.widget<Text>(visible).data, 'Good morning, Will 👋');
      await tester.pumpAndSettle();
      expect(clip().width, tester.getSize(reveal).width);
      expect(tester.getSize(find.byType(BuyerGreeting)).height, height);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page());
      expect(clip().width, 0);
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
          await tester.pumpAndSettle();
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
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
        final close = find.byKey(
          const ValueKey('private-deal-target_close_date'),
        );
        await tester.ensureVisible(close);
        await tester.enterText(close, '2030-02-31');
        await save();
        expect(attempts, 0);
        expect(
          find.textContaining('Enter a valid target close date'),
          findsOneWidget,
        );
        await tester.ensureVisible(close);
        await tester.enterText(close, '2030-06-15');
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
        expect(captured!.targetCloseDate, DateTime(2030, 6, 15));
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
