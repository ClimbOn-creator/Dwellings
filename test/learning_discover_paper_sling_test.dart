import 'dart:math' as math;

import 'package:dwelling_iq/services/discover_activity.dart';
import 'package:dwelling_iq/widgets/learning_discover_paper_sling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Offset? scoringPull(PaperSlingLevel level) {
  for (var angle = 20; angle <= 68; angle++) {
    final radians = angle * math.pi / 180;
    for (var power = 60; power <= 100; power++) {
      final pull =
          Offset(-math.cos(radians), math.sin(radians)) * power.toDouble();
      final shot = PaperSlingShot(level, pull);
      while (shot.result == PaperSlingResult.flying) {
        shot.step(1 / 120);
      }
      if (shot.result == PaperSlingResult.scored) return pull;
    }
  }
  return null;
}

void main() {
  test('Every one of the 15 progressively narrower levels is beatable', () {
    for (var number = 1; number <= PaperSlingLevel.count; number++) {
      final level = PaperSlingLevel(number);
      expect(scoringPull(level), isNotNull, reason: 'Level $number');
      if (number > 1) {
        expect(level.mouth, lessThan(PaperSlingLevel(number - 1).mouth));
      }
    }
    final gusty = PaperSlingLevel(15);
    expect(gusty.binX(0), isNot(gusty.binX(.5)));
    expect(gusty.gust(.5).sign, isNot(gusty.gust(1.3).sign));
  });

  testWidgets('A mouse or touch drag launches and advances to the next level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: DiscoverPaperSlingPage()));
    final stage = find.descendant(
      of: find.byType(AspectRatio),
      matching: find.byType(CustomPaint),
    );
    final size = tester.getSize(stage);
    final scale = size.width / 800;
    final origin = tester.getTopLeft(stage) + PaperSlingLevel.origin * scale;
    final pull = scoringPull(const PaperSlingLevel(1))!;
    final gesture = await tester.startGesture(origin);
    await gesture.moveBy(pull * scale);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 17));
    expect(find.text('In the bin!'), findsOneWidget);
    await tester.tap(find.text('Next level'));
    await tester.pump();
    expect(find.text('Level 2 / 15'), findsOneWidget);
  });

  test('Activity counts unique opens and keeps accounts separate', () async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      DiscoverActivity.recordForAccount(
        'a',
        DiscoverActivityKind.files,
        'file-1',
      ),
      DiscoverActivity.recordForAccount(
        'a',
        DiscoverActivityKind.files,
        'file-1',
      ),
      DiscoverActivity.recordForAccount(
        'a',
        DiscoverActivityKind.files,
        'file-2',
      ),
      DiscoverActivity.recordForAccount(
        'a',
        DiscoverActivityKind.deals,
        'deal-1',
      ),
      DiscoverActivity.recordForAccount(
        'b',
        DiscoverActivityKind.files,
        'file-1',
      ),
    ]);
    expect(await DiscoverActivity.count('a', DiscoverActivityKind.files), 2);
    expect(await DiscoverActivity.count('a', DiscoverActivityKind.deals), 1);
    expect(await DiscoverActivity.count('b', DiscoverActivityKind.files), 1);
    expect(await DiscoverActivity.count('b', DiscoverActivityKind.deals), 0);
  });
}
