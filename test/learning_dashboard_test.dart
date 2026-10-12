import 'package:dwelling_iq/models/learning_journey.dart';
import 'package:dwelling_iq/screens/acquisition_support_page.dart';
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
  testWidgets('boxed landing learning action opens the independent workspace', (
    tester,
  ) async {
    AppTunnelController.select(AppTunnel.landing);
    await tester.pumpWidget(const MaterialApp(home: AcquisitionSupportPage()));
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
  });
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
        'learning-feed.filters',
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
      LearningView.map,
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
          expect(
            tester.getTopLeft(find.text('A place to learn, at your pace')).dy,
            lessThan(160),
          );
        }
        if (view == LearningView.map) {
          expect(find.byType(InteractiveViewer), findsOneWidget);
          await tester.ensureVisible(
            find.text('Your budget, preferred business and owner role'),
          );
          await tester.tap(
            find.text('Your budget, preferred business and owner role'),
          );
          await tester.pump();
          expect(find.text('That’s right.'), findsOneWidget);
          await tester.ensureVisible(find.text('Mark this stage understood'));
          await tester.tap(find.text('Mark this stage understood'));
          await tester.pumpAndSettle();
          expect(find.text('Understood • unmark'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('approved publishers can access composer and creator approvals', (
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
    expect(find.text('Create a learning post'), findsOneWidget);
    expect(find.text('Contributor approvals'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
