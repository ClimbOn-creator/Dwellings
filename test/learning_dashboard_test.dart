import 'package:dwelling_iq/models/learning_journey.dart';
import 'package:dwelling_iq/screens/member_overview_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';
import 'package:dwelling_iq/services/nova_page_guide.dart';
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
      expect(
        novaPageWalkthrough('learning-feed').first.target,
        'learning-feed.posts',
      );
      expect(
        novaPageWalkthrough('learning-map').first.target,
        'learning-map.canvas',
      );
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
    for (final view in [
      LearningView.feed,
      LearningView.seminars,
      LearningView.journey,
    ]) {
      testWidgets('$view fits $width with account gated publishing', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: LearningDashboardPage(
              initialView: view,
              loadPosts: () async => [
                LearningPost(
                  id: 'p',
                  authorId: 'a',
                  author: 'Approved educator',
                  title: 'Understanding earnings',
                  body: 'Revenue and earnings are different.',
                  topic: 'finance',
                  createdAt: DateTime(2026, 10, 12),
                ),
              ],
              loadSeminars: () async => [],
              loadPermissions: () async => const LearningPermissions(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Create a learning post'), findsNothing);
        if (view == LearningView.feed)
          expect(find.text('Understanding earnings'), findsOneWidget);
        if (width == 1440 && view == LearningView.feed) {
          expect(tester.getTopLeft(find.text('LEARNING')).dy, lessThan(160));
          expect(find.text('A place to learn, at your pace'), findsNothing);
        }
        if (view == LearningView.journey) {
          expect(find.byType(InteractiveViewer), findsNothing);
          await tester.ensureVisible(
            find.byKey(const ValueKey('journey-answer-0')),
          );
          await tester.tap(find.byKey(const ValueKey('journey-answer-0')));
          await tester.pumpAndSettle();
          expect(find.text('That’s right.'), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const Key('journey-mark-understood')),
          );
          await tester.tap(find.byKey(const Key('journey-mark-understood')));
          await tester.pumpAndSettle();
          expect(find.text('Understood · undo'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
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
  testWidgets('approved publishers see plus while contributor approvals stay removed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LearningDashboardPage(
          loadPosts: () async => [],
          loadPermissions: () async =>
              const LearningPermissions(canPublish: true, isOwner: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create a learning post'), findsNothing);
    expect(find.byKey(const Key('learning-create-post')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Contributor approvals'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'quiz is a visible dashboard tab with an embedded sign-in panel',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LearningDashboardPage(
            initialView: LearningView.quiz,
            loadPosts: () async => [],
            loadSeminars: () async => [],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Deal comparison quiz'), findsWidgets);
      expect(find.text('Sign in to start'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
