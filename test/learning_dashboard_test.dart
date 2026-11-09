import 'package:dwelling_iq/widgets/canada_event_map.dart';
import 'package:dwelling_iq/widgets/transaction_room_panel.dart';
import 'package:dwelling_iq/models/learning_journey.dart';
import 'package:dwelling_iq/screens/member_overview_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTunnelController.select(AppTunnel.learning);
  });
  testWidgets(
    'moved Member overview learning action opens the independent workspace',
    (tester) async {
      AppTunnelController.select(AppTunnel.landing);
      await tester.pumpWidget(const MaterialApp(home: MemberOverviewPage()));
      await tester.pump(const Duration(seconds: 1));
      final button = find.text('I want to learn');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LearningDashboardPage), findsOneWidget);
      expect(AppTunnelController.current.value, AppTunnel.learning);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'buyer and seller lessons are distinct and checks have valid answers',
    () {
      final phases = [...buyerLearningJourney, ...sellerLearningJourney];
      expect(phases.map((p) => p.id).toSet().length, 16);
      for (final p in phases) {
        expect(p.choices.length, 3);
        expect(p.correct, inInclusiveRange(0, 2));
        expect(p.feedback, isNotEmpty);
        expect(p.documents, isNotEmpty);
      }
    },
  );
  test('seminars join only during the session or explicit live status', () {
    final start = DateTime.utc(2026, 10, 20, 18);
    LearningSeminar session(String status) => LearningSeminar(
      id: 's',
      hostId: 'h',
      title: 'Finance',
      description: '',
      startsAt: start,
      duration: 60,
      joinUrl: 'https://example.com/meet',
      status: status,
    );
    expect(
      session('scheduled').canJoin(start.subtract(const Duration(minutes: 1))),
      false,
    );
    expect(session('scheduled').canJoin(start), true);
    expect(
      session('scheduled').canJoin(start.add(const Duration(hours: 1))),
      false,
    );
    expect(session('cancelled').canJoin(start), false);
    expect(session('ended').canJoin(start), false);
    expect(LearningSeminar.validUrl('javascript:alert(1)'), false);
    expect(LearningSeminar.validUrl('https://example.com/meet'), true);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('Learning tabs and quiz fit at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            loadSeminars: () async => [],
            loadPermissions: () async =>
                const LearningPermissions(canPublish: true, isOwner: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final tab in [
        'First steps',
        'Roadmap',
        'Discover',
        'Search',
        'Evaluate',
        'Financial',
        'Documents',
        'Deal Structure',
        'Transition',
        'FAQ',
        'Seminars',
        'Resources',
      ]) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.text('Learning feed'), findsNothing);
      expect(find.text('Pact examples'), findsNothing);
      expect(find.byKey(const Key('learning-create-post')), findsNothing);
      expect(find.text('Deal comparison quiz'), findsNothing);
      final quiz = find.byTooltip('Deal comparison quiz');
      expect(
        tester.getRect(quiz).right,
        lessThanOrEqualTo(tester.getRect(find.byTooltip('Sign in')).left),
      );
      await tester.tap(find.text('Roadmap'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('learning-workspace-roadmap-')),
        findsOneWidget,
      );
      await tester.tap(quiz);
      await tester.pumpAndSettle();
      expect(find.text('Roadmap'), findsNothing);
      expect(find.text('Sign in to start'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to Learning dashboard'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('learning-workspace-roadmap-')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Seminars requests location on demand and switches map scope', (
    tester,
  ) async {
    var requests = 0;
    LearningSeminar seminar(String id, double lat, double lon) =>
        LearningSeminar(
          id: id,
          hostId: 'host',
          title: id,
          description: '',
          startsAt: DateTime.now().add(const Duration(days: 1)),
          duration: 60,
          joinUrl: '',
          latitude: lat,
          longitude: lon,
          status: 'scheduled',
        );
    await tester.pumpWidget(
      MaterialApp(
        home: LearningDashboardPage(
          initialView: LearningView.seminars,
          locate: () async {
            requests++;
            if (requests == 1) throw StateError('Permission denied');
            return (latitude: 48.4, longitude: -123.4);
          },
          loadSeminars: () async => [
            seminar('within-500', 52.8, -123.4),
            seminar('outside-500', 53.0, -123.4),
            seminar('halifax', 44.6, -63.6),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    CanadaEventMap map() => tester.widget(find.byType(CanadaEventMap));
    Iterable<String> eventIds() => map().events.map((event) => event.id);
    expect(requests, 0);
    expect(eventIds(), contains('halifax'));

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Location is blocked'), findsOneWidget);
    expect(map().region, isNull);

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(map().region, isNotNull);
    expect(eventIds(), contains('within-500'));
    expect(eventIds(), isNot(contains('outside-500')));
    expect(eventIds(), isNot(contains('halifax')));

    await tester.tap(find.text('Show full map'));
    await tester.pumpAndSettle();
    expect(map().region, isNull);
    expect(eventIds(), contains('halifax'));
    await tester.tap(find.text('Show nearby'));
    await tester.pumpAndSettle();
    expect(map().region, isNotNull);
    expect(requests, 2);

    await tester.tap(find.text('Choose a city'));
    await tester.pumpAndSettle();
    final victoria = find.text('Victoria, BC');
    await tester.ensureVisible(victoria);
    await tester.tap(victoria);
    await tester.pumpAndSettle();
    expect(find.text('Events within 500 km of Victoria, BC'), findsOneWidget);
    expect(eventIds(), isNot(contains('halifax')));
    expect(requests, 2);
  });

  testWidgets('Roadmap saves a completed stage and opens its document', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LearningDashboardPage(initialView: LearningView.roadmap),
      ),
    );
    await tester.pumpAndSettle();
    final firstStage = find.byKey(const ValueKey('journey-stage-0'));
    final secondStage = find.byKey(const ValueKey('journey-stage-1'));
    final arrow = find.descendant(
      of: firstStage,
      matching: find.byType(AnimatedRotation),
    );
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
    expect(find.byKey(const ValueKey('journey-answer-0')), findsNothing);
    await tester.tap(firstStage);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedRotation>(arrow).turns, .5);
    await tester.ensureVisible(secondStage);
    await tester.tap(secondStage);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
    await tester.ensureVisible(firstStage);
    await tester.tap(firstStage);
    await tester.pumpAndSettle();
    final answer = find.byKey(const ValueKey('journey-answer-0'));
    await tester.ensureVisible(answer);
    await tester.tap(answer);
    await tester.pumpAndSettle();
    final mark = find.byKey(const Key('journey-mark-understood'));
    await tester.ensureVisible(mark);
    await tester.tap(mark);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('learning.progress.guest'),
      contains('buyer-search'),
    );
    final doc = find.widgetWithText(TextButton, 'Deal brief & buyer criteria');
    await tester.ensureVisible(doc);
    await tester.tap(doc);
    await tester.pumpAndSettle();
    final panel = tester.widget<TransactionRoomPanel>(
      find.byType(TransactionRoomPanel),
    );
    expect(panel.initialDocumentId, isNotNull);
    expect(find.text('DOWNLOAD EDITABLE TEMPLATE'), findsOneWidget);
  });

  testWidgets('open Canada map refreshes published and cancelled events', (
    tester,
  ) async {
    var cancelled = false;
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LearningDashboardPage(
          initialView: LearningView.seminars,
          loadPermissions: () async => const LearningPermissions(),
          loadSeminars: () async {
            requests++;
            return [
              LearningSeminar(
                id: 'refresh',
                hostId: 'host',
                title: 'Succession workshop',
                description: '',
                startsAt: DateTime.now().add(const Duration(days: 1)),
                duration: 60,
                joinUrl: '',
                websiteUrl: 'https://example.com/workshop',
                latitude: 49.3,
                longitude: -123.1,
                status: cancelled ? 'cancelled' : 'scheduled',
              ),
            ];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.byKey(const ValueKey('event-pin-refresh')), findsOneWidget);
    cancelled = true;
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.byKey(const ValueKey('event-pin-refresh')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
