import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/widgets/learning_discover_calendar.dart';
import 'package:dwelling_iq/widgets/canada_event_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Discover lamp, atlas, calendar and Buyer workspace work from the desk',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => CanadaMapGeometry.asset);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            initialView: LearningView.discover,
            loadSeminars: () async => [],
            locate: () async => (latitude: 43.6532, longitude: -79.3832),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Turn lamp off'));
      await tester.pump();
      expect(find.byTooltip('Turn lamp on'), findsOneWidget);
      await tester.tap(find.byTooltip('Turn lamp on'));
      await tester.pump();
      expect(find.byTooltip('Turn lamp off'), findsOneWidget);

      await tester.tap(find.byTooltip('Open desk globe'));
      await tester.pumpAndSettle();
      expect(find.text('Discover atlas'), findsOneWidget);
      expect(
        tester
            .widget<CanadaEventMap>(find.byType(CanadaEventMap))
            .region
            ?.latitude,
        closeTo(49.28, .01),
      );
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CanadaEventMap>(find.byType(CanadaEventMap))
            .region
            ?.radiusKm,
        700,
      );
      expect(
        tester
            .widget<CanadaEventMap>(find.byType(CanadaEventMap))
            .region
            ?.latitude,
        closeTo(43.65, .01),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open Discover calendar'));
      await tester.pumpAndSettle();
      expect(find.text('In-person meetings'), findsOneWidget);
      expect(find.text('Resource meetings'), findsOneWidget);
      expect(
        tester
            .widget<CanadaEventMap>(find.byType(CanadaEventMap))
            .region
            ?.radiusKm,
        700,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zoom into pinboard'));
      await tester.pumpAndSettle();
      for (var note = 1; note <= 7; note++) {
        expect(find.text('Note $note'), findsOneWidget);
      }
      await tester.tap(find.text('Note 7'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close note'), findsOneWidget);
      await tester.tap(find.byTooltip('Close note'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Enter Buyer Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Your pipeline'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Open Discover calendar'), findsOneWidget);
    },
  );

  testWidgets(
    'Calendar redraws the current day and crossed-out dates after rollover',
    (tester) async {
      final today = ValueNotifier(DateTime(2026, 11, 10));
      addTearDown(today.dispose);
      final semantics = tester.ensureSemantics();
      LearningSeminar meeting(
        String title,
        String mode, {
        String status = 'scheduled',
      }) => LearningSeminar(
        id: title,
        hostId: 'host',
        title: title,
        description: '',
        startsAt: DateTime(2026, 11, 12, 10),
        duration: 45,
        joinUrl: '',
        kind: 'meeting',
        mode: mode,
        status: status,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DiscoverCalendarPage(
            today: today,
            loadEvents: () async => [
              for (var i = 1; i <= 10; i++)
                meeting('Office meetup $i', 'in_person'),
              meeting('Resource discussion', 'online'),
              meeting('Cancelled meetup', 'in_person', status: 'cancelled'),
            ],
            openEvent: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('November 10, 2026, today'), findsOneWidget);
      expect(find.bySemanticsLabel('November 9, 2026, passed'), findsOneWidget);
      for (var i = 1; i <= 10; i++) {
        expect(find.byTooltip('Office meetup $i'), findsOneWidget);
      }
      expect(find.text('Resource discussion'), findsOneWidget);
      expect(find.text('Cancelled meetup'), findsNothing);

      today.value = DateTime(2026, 11, 11);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('November 10, 2026, passed'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('November 11, 2026, today'), findsOneWidget);
      semantics.dispose();
    },
  );
}
