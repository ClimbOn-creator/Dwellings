import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const _world = Size(800, 430);
const _ground = 395.0;
const _anchor = Offset(118, 306);

class PaperSlingLevel {
  const PaperSlingLevel(this.number);

  static const count = 15;
  static const maxPull = 100.0;
  static const origin = _anchor;
  final int number;

  double get mouth => 98 - (number - 1) * 3.8;
  double get rim => 352 - ((number - 1) % 5) * 10 - (number >= 10 ? 12 : 0);
  double get wind =>
      number < 4 ? 0 : (44 + (number - 4) * 13) * (number.isEven ? 1 : -1);
  Rect get windZone => const Rect.fromLTWH(294, 44, 252, 304);

  double binX(double time) =>
      553 +
      number * 6.0 +
      (number < 9
          ? 0
          : math.sin(time * (1.9 + number * .09)) * (number - 7) * 5);

  double gust(double time) =>
      number < 12 ? wind : wind * (.45 + .75 * math.sin(time * 3.6));

  Offset launch(Offset pull) {
    final constrained = pull.distance > maxPull
        ? pull / pull.distance * maxPull
        : pull;
    return -constrained * 6.1;
  }
}

enum PaperSlingResult { flying, scored, missed }

class PaperSlingShot {
  PaperSlingShot(this.level, Offset pull) : velocity = level.launch(pull);

  final PaperSlingLevel level;
  Offset position = PaperSlingLevel.origin;
  Offset velocity;
  double time = 0;
  PaperSlingResult result = PaperSlingResult.flying;

  void step(double seconds) {
    if (result != PaperSlingResult.flying) return;
    final previous = position;
    time += seconds;
    final wind = level.windZone.contains(position) ? level.gust(time) : 0.0;
    velocity += Offset(wind, 470) * seconds;
    position += velocity * seconds;
    if (previous.dy <= level.rim &&
        position.dy > level.rim &&
        velocity.dy > 0) {
      final fraction = (level.rim - previous.dy) / (position.dy - previous.dy);
      final x = previous.dx + (position.dx - previous.dx) * fraction;
      final bin = level.binX(time - seconds * (1 - fraction));
      if ((x - bin).abs() <= level.mouth / 2 - 7) {
        position = Offset(x, level.rim + 7);
        result = PaperSlingResult.scored;
        return;
      }
    }
    if (position.dy >= _ground - 7 ||
        position.dx < -30 ||
        position.dx > _world.width + 30 ||
        time > 5) {
      result = PaperSlingResult.missed;
    }
  }
}

class DiscoverPaperSlingPage extends StatefulWidget {
  const DiscoverPaperSlingPage({super.key});

  @override
  State<DiscoverPaperSlingPage> createState() => _DiscoverPaperSlingPageState();
}

class _DiscoverPaperSlingPageState extends State<DiscoverPaperSlingPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _accumulator = 0;
  int _number = 1;
  int _attempts = 0;
  Offset? _drag;
  PaperSlingShot? _shot;
  double _angle = 42;
  double _power = 70;

  PaperSlingLevel get _level => PaperSlingLevel(_number);
  bool get _flying => _shot?.result == PaperSlingResult.flying;
  bool get _scored => _shot?.result == PaperSlingResult.scored;
  Offset get _aim {
    final angle = _angle * math.pi / 180;
    return Offset(-math.cos(angle), math.sin(angle)) * _power;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _accumulator += math.min(
      .07,
      (elapsed - _lastTick).inMicroseconds / 1000000,
    );
    _lastTick = elapsed;
    const step = 1 / 120;
    while (_accumulator >= step && _flying) {
      _shot!.step(step);
      _accumulator -= step;
    }
    if (!_flying) _ticker.stop();
    setState(() {});
  }

  void _launch(Offset pull) {
    if (_flying || _scored || pull.dx >= -7 || pull.distance < 12) return;
    setState(() {
      _shot = PaperSlingShot(_level, pull);
      _drag = null;
      _attempts++;
      _accumulator = 0;
      _lastTick = Duration.zero;
    });
    _ticker.start();
  }

  void _next() => setState(() {
    if (_number == PaperSlingLevel.count) {
      _number = 1;
      _attempts = 0;
    } else {
      _number++;
    }
    _shot = null;
  });

  void _adjust({double angle = 0, double power = 0}) {
    if (_flying || _scored) return;
    setState(() {
      _angle = (_angle + angle).clamp(8.0, 78.0);
      _power = (_power + power).clamp(20.0, PaperSlingLevel.maxPull);
      _shot = null;
    });
  }

  String get _status {
    if (_scored && _number == PaperSlingLevel.count)
      return 'All 15 levels cleared in $_attempts throws!';
    if (_scored) return 'In the bin!';
    if (_flying) return 'Paper in flight…';
    if (_shot?.result == PaperSlingResult.missed)
      return 'Missed. Pull back and try again.';
    if (_number >= 12) return 'Gusts change direction and the bin is moving.';
    if (_number >= 9) return 'The bin is moving. Lead the shot.';
    if (_level.wind != 0)
      return 'The fan pushes the paper ${_level.wind > 0 ? 'right' : 'left'}.';
    return 'Drag the paper back, then release.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff3ecdc),
    appBar: AppBar(
      backgroundColor: const Color(0xfff3ecdc),
      title: const Text('Paper Sling'),
    ),
    body: SafeArea(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _adjust(angle: 3),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _adjust(angle: -3),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _adjust(power: -3),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _adjust(power: 3),
          const SingleActivator(LogicalKeyboardKey.space): () => _launch(_aim),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, bounds) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Level $_number / ${PaperSlingLevel.count}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(_status, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: _world.aspectRatio,
                        child: LayoutBuilder(
                          builder: (context, stage) {
                            final scale = stage.maxWidth / _world.width;
                            Offset world(Offset local) => local / scale;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              dragStartBehavior: DragStartBehavior.down,
                              onPanStart: (details) {
                                if (_flying ||
                                    _scored ||
                                    (world(details.localPosition) - _anchor)
                                            .distance >
                                        42)
                                  return;
                                setState(() {
                                  _drag = Offset.zero;
                                  _shot = null;
                                });
                              },
                              onPanUpdate: (details) {
                                if (_drag == null) return;
                                var pull =
                                    world(details.localPosition) - _anchor;
                                pull = Offset(math.min(pull.dx, 0), pull.dy);
                                if (pull.distance > PaperSlingLevel.maxPull) {
                                  pull =
                                      pull /
                                      pull.distance *
                                      PaperSlingLevel.maxPull;
                                }
                                setState(() => _drag = pull);
                              },
                              onPanCancel: () => setState(() => _drag = null),
                              onPanEnd: (_) {
                                final pull = _drag;
                                if (pull == null) return;
                                setState(() => _drag = null);
                                _launch(pull);
                              },
                              child: CustomPaint(
                                painter: _PaperSlingPainter(
                                  _level,
                                  _shot,
                                  _drag ?? _aim,
                                  _drag != null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_scored)
                        FilledButton(
                          onPressed: _next,
                          child: Text(
                            _number == PaperSlingLevel.count
                                ? 'Play again'
                                : 'Next level',
                          ),
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Aim lower',
                              onPressed: _flying
                                  ? null
                                  : () => _adjust(angle: -3),
                              icon: const Icon(Icons.keyboard_arrow_down),
                            ),
                            Text('Angle ${_angle.toInt()}°'),
                            IconButton(
                              tooltip: 'Aim higher',
                              onPressed: _flying
                                  ? null
                                  : () => _adjust(angle: 3),
                              icon: const Icon(Icons.keyboard_arrow_up),
                            ),
                            IconButton(
                              tooltip: 'Less power',
                              onPressed: _flying
                                  ? null
                                  : () => _adjust(power: -3),
                              icon: const Icon(Icons.remove),
                            ),
                            Text('Power ${_power.toInt()}%'),
                            IconButton(
                              tooltip: 'More power',
                              onPressed: _flying
                                  ? null
                                  : () => _adjust(power: 3),
                              icon: const Icon(Icons.add),
                            ),
                            FilledButton(
                              onPressed: _flying ? null : () => _launch(_aim),
                              child: const Text('Launch'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drag the ball to aim, or use the arrow keys and Space.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PaperSlingPainter extends CustomPainter {
  const _PaperSlingPainter(this.level, this.shot, this.pull, this.dragging);

  final PaperSlingLevel level;
  final PaperSlingShot? shot;
  final Offset pull;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _world.width, size.height / _world.height);
    final paint = Paint();
    canvas.drawRect(
      Offset.zero & _world,
      paint..color = const Color(0xffeee4d1),
    );
    canvas.drawRect(
      const Rect.fromLTRB(0, _ground, 800, 430),
      paint..color = const Color(0xffccbba0),
    );
    canvas.drawLine(
      const Offset(0, _ground),
      const Offset(800, _ground),
      paint
        ..color = const Color(0xffa28d70)
        ..strokeWidth = 2,
    );
    final time = shot?.time ?? 0;
    if (level.wind != 0) _fan(canvas, time);
    final x = level.binX(time);
    final rim = level.rim;
    final mouth = level.mouth / 2;
    canvas.drawOval(
      Rect.fromLTWH(x - mouth - 8, _ground - 4, mouth * 2 + 16, 13),
      paint..color = const Color(0xffb5a184),
    );
    canvas.drawPath(
      Path()..addPolygon([
        Offset(x - mouth, rim),
        Offset(x + mouth, rim),
        Offset(x + mouth * .78, _ground),
        Offset(x - mouth * .78, _ground),
      ], true),
      paint..color = const Color(0xff777468),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, rim), width: level.mouth, height: 15),
      paint..color = const Color(0xff3f4037),
    );
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(x + i * mouth * .28, rim + 13),
        Offset(x + i * mouth * .22, _ground - 5),
        paint
          ..color = const Color(0xff939080)
          ..strokeWidth = 2,
      );
    }
    const leftFork = Offset(108, 290);
    const rightFork = Offset(132, 289);
    canvas.drawPath(
      Path()
        ..moveTo(120, 371)
        ..lineTo(120, 323)
        ..lineTo(leftFork.dx, leftFork.dy)
        ..moveTo(120, 323)
        ..lineTo(rightFork.dx, rightFork.dy),
      paint
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8
        ..color = const Color(0xff835e42),
    );
    paint.style = PaintingStyle.fill;
    final loaded = dragging ? _anchor + pull : _anchor;
    if (shot == null || dragging) {
      canvas.drawLine(
        leftFork,
        loaded,
        paint
          ..strokeWidth = 2.8
          ..color = const Color(0xff655241),
      );
      canvas.drawLine(rightFork, loaded, paint);
      if (pull.dx < -7) {
        final guide = PaperSlingShot(level, pull);
        for (var i = 0; i < 10; i++) {
          guide.step(.032);
          canvas.drawCircle(
            guide.position,
            2,
            paint..color = const Color(0xffa18a67),
          );
        }
      }
    }
    if (shot?.result != PaperSlingResult.scored)
      _ball(canvas, shot?.position ?? loaded);
    canvas.restore();
  }

  void _fan(Canvas canvas, double time) {
    final gust = level.gust(time);
    final right = gust >= 0;
    final x = right ? level.windZone.left : level.windZone.right;
    final fan = Offset(x, 282);
    final paint = Paint()..color = const Color(0xff777c72);
    canvas.drawRect(Rect.fromLTWH(x - 5, fan.dy, 10, _ground - fan.dy), paint);
    canvas.drawCircle(fan, 26, paint);
    canvas.drawCircle(fan, 22, paint..color = const Color(0xffa6a696));
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3 + time * 16;
      final end = fan + Offset(math.cos(angle), math.sin(angle)) * 16;
      canvas.drawLine(
        fan,
        end,
        paint
          ..color = const Color(0xff626961)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6,
      );
    }
    for (var i = 0; i < 7; i++) {
      final distance = (i * 36 + time * 140) % level.windZone.width;
      final start = Offset(x + (right ? distance : -distance), 110.0 + i * 26);
      canvas.drawLine(
        start,
        start.translate(right ? 21 : -21, 0),
        paint
          ..color = const Color(0x776c908b)
          ..strokeWidth = 2,
      );
    }
  }

  void _ball(Canvas canvas, Offset center) {
    final points = const [
      Offset(-7, 1),
      Offset(-5, -5),
      Offset(1, -8),
      Offset(7, -4),
      Offset(8, 2),
      Offset(3, 7),
      Offset(-4, 6),
    ].map((point) => center + point).toList();
    canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()..color = const Color(0xfffff6e1),
    );
    final crease = Paint()
      ..color = const Color(0xffa99677)
      ..strokeWidth = 1;
    canvas.drawLine(center.translate(-4, -3), center.translate(4, 4), crease);
    canvas.drawLine(center.translate(-3, 3), center.translate(2, -2), crease);
  }

  @override
  bool shouldRepaint(_PaperSlingPainter oldDelegate) => true;
}
