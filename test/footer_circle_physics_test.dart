import 'package:dwelling_iq/widgets/membership_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/widgets/footer_circle_physics.dart';

void main() {
  testWidgets(
    'animated footer is opt-in and the floor sits just below copyright',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: MembershipFooter()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveCircleFooter), findsNothing);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MembershipFooter(animateCircles: true),
              ),
            ),
          ),
        );
        // Geometry is ready after layout; gravity is tested separately below.
        await tester.pump();
        final floor = tester
            .getBottomRight(find.byType(InteractiveCircleFooter))
            .dy;
        final copyright = tester
            .getBottomRight(find.textContaining('© 2026 AFFINITY'))
            .dy;
        expect(floor - copyright, inInclusiveRange(0, 48));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  test(
    'circles fall, collide with each other, and stay within floor and walls',
    () {
      final world = FooterCircleWorld(const Size(900, 700));
      for (var frame = 0; frame < 1200; frame++) world.step(1 / 120);
      expect(world.balls, hasLength(36));
      for (final ball in world.balls) {
        expect(
          ball.position.dx,
          inInclusiveRange(ball.radius - .1, 900 - ball.radius + .1),
        );
        expect(ball.position.dy, lessThanOrEqualTo(700 - ball.radius + .1));
      }
      for (var i = 0; i < world.balls.length; i++) {
        for (var j = i + 1; j < world.balls.length; j++) {
          final a = world.balls[i], b = world.balls[j];
          expect(
            (a.position - b.position).distance,
            greaterThan(a.radius + b.radius - 4),
          );
        }
      }
    },
  );
  test('throwing preserves momentum and the top is open', () {
    final world = FooterCircleWorld(const Size(500, 500), count: 1)
      ..step(1 / 60);
    world.hold(0, const Offset(250, 10));
    world.release(0, const Offset(300, -1200));
    world.step(.1);
    expect(world.balls.first.position.dy, lessThan(0));
    expect(world.balls.first.position.dx, greaterThan(250));
    expect(world.balls.first.held, isFalse);
    for (var i = 0; i < 500; i++) world.step(1 / 120);
    expect(
      world.balls.first.position.dy,
      lessThanOrEqualTo(500 - world.balls.first.radius),
    );
  });
  testWidgets('circles can be dragged while footer links remain clickable', (
    tester,
  ) async {
    var clicks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveCircleFooter(
            child: SizedBox(
              height: 200,
              child: Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () => clicks++,
                  child: const Text('Footer link'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 160; i++)
      await tester.pump(const Duration(milliseconds: 25));
    final circle = find.byKey(const ValueKey('footer-circle-0'));
    final before = tester.getCenter(circle);
    final pointer = await tester.startGesture(before);
    await pointer.moveBy(const Offset(0, -30));
    await pointer.moveBy(const Offset(60, -90));
    await tester.pump();
    expect(tester.getCenter(circle).dy, lessThan(before.dy - 50));
    await pointer.up();
    await tester.tap(find.text('Footer link'));
    expect(clicks, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
