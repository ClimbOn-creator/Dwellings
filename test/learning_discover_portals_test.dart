import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/widgets/learning_discover_calendar.dart';
import 'package:dwelling_iq/widgets/canada_event_map.dart';
import 'package:dwelling_iq/widgets/learning_discover_portal.dart';
import 'package:dwelling_iq/screens/pact_web_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'First steps lamp, atlas, calendar and Buyer workspace work from the desk',
    (tester) async {
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => CanadaMapGeometry.asset);
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            initialView: LearningView.firstSteps,
            loadSeminars: () async => [
              LearningSeminar(
                id: 'halifax',
                hostId: 'host',
                title: 'Halifax meetup',
                description: '',
                startsAt: DateTime.now().add(const Duration(days: 1)),
                duration: 45,
                joinUrl: '',
                latitude: 44.65,
                longitude: -63.57,
              ),
            ],
            locate: () async => (latitude: 43.6532, longitude: -79.3832),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Turn lamp off'), findsNothing);
      expect(find.byTooltip('Open Paper Sling'), findsNothing);
      expect(find.text('Click here for Learning Dash'), findsOneWidget);
      expect(find.text('Click here for Buyer Dash'), findsOneWidget);
      expect(find.text('Click here for Headlines'), findsOneWidget);
      expect(
        find.text('Click here for more learning opportunities'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Turn lamp off'));
      await tester.pump();
      expect(find.bySemanticsLabel('Turn lamp on'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Turn lamp on'));
      await tester.pump();
      expect(find.bySemanticsLabel('Turn lamp off'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Open desk globe'));
      await tester.pumpAndSettle();
      expect(find.text('Discover atlas'), findsOneWidget);
      expect(
        tester
            .widget<CanadaEventMap>(find.byType(CanadaEventMap))
            .region
            ?.latitude,
        closeTo(49.28, .01),
      );
      final map = tester.widget<CanadaEventMap>(find.byType(CanadaEventMap));
      expect(map.showRegionOutline, isFalse);
      expect(map.events.single.id, 'halifax');
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

      await tester.tap(find.text('Click here for more learning opportunities'));
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

      await tester.tap(find.text('Click here for Headlines'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.textContaining('▏'), findsWidgets);
      await tester.pumpAndSettle();
      for (final note in [
        'Files opened',
        'Deals viewed',
        'My team',
        'Best 5 files',
        'Concepts completed',
        'Upcoming RSVPs',
        'Saved listings',
        'Active deal rooms',
        'Deal tasks done',
        'Blocked tasks',
        'Next target close',
        'Pending introductions',
      ]) {
        expect(find.text(note), findsOneWidget);
      }
      await tester.tap(find.text('Best 5 files'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your starter-file recommendations are coming soon.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My team'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close note'), findsOneWidget);
      await tester.tap(find.byTooltip('Close note'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click here for My Team'));
      await tester.pumpAndSettle();
      expect(find.text('My team'), findsOneWidget);
      expect(find.text('?'), findsNWidgets(4));
      await tester.tap(find.text('Add professional').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Sign in to build your acquisition team'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Open Paper Sling'));
      await tester.pumpAndSettle();
      expect(find.text('Level 1 / 15'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click here for Buyer Dash'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter.runtimeType.toString() == '_ArcadeTunnel',
        ),
        findsOneWidget,
      );
      final comingSoon = find.text('Coming soon');
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: comingSoon, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0);
      expect(
        ModalRoute.of(tester.element(comingSoon)),
        isA<DiscoverPortalRoute>(),
      );
      await tester.pumpAndSettle();
      expect(comingSoon, findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Open Messenger'));
      await tester.pumpAndSettle();
      expect(find.byType(PactWebMessages), findsOneWidget);
      expect(find.text('Sign in to Messages'), findsOneWidget);
      expect(
        tester.widget<PactWebMessages>(find.byType(PactWebMessages)).workspace,
        'learning',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Open Discover calendar'), findsOneWidget);
      semantics.dispose();
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
