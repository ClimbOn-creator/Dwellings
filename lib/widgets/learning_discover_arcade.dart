import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const _screenSize = Size(86, 108);
const _shipY = 96.0;
const _phosphor = Color(0xffa8ef82);

class DiscoverArcade extends StatefulWidget {
  const DiscoverArcade({super.key});

  @override
  State<DiscoverArcade> createState() => _DiscoverArcadeState();
}

class _DiscoverArcadeState extends State<DiscoverArcade> {
  final _demo = _ArcadeDemo();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _demo.step(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(child: CustomPaint(painter: _ArcadePainter(_demo))),
  );
}

class _ArcadeDemo extends ChangeNotifier {
  _ArcadeDemo() {
    _spawnWave();
  }

  final _random = math.Random();
  final _enemies = <({double lane, double delay, double sway, double phase})>[];
  final _shots = <Offset>[];
  final _hostile = <Offset>[];
  final _bursts = <({Offset center, int frame})>[];
  int frame = 0;
  int _waveStart = 0;
  int score = 0;
  double shipX = _screenSize.width / 2;

  void _spawnWave() {
    _waveStart = frame;
    _enemies.clear();
    final pattern = _random.nextDouble() * math.pi * 2;
    for (var i = 0; i < 8; i++) {
      _enemies.add((
        lane: 16.0 + (i % 4) * 17,
        delay: 1.0 + i ~/ 4 * 15 + _random.nextDouble() * 12,
        sway: 8 + _random.nextDouble() * 16,
        phase: pattern + i * .43,
      ));
    }
  }

  Iterable<Offset> get enemies => _enemies.map(_position);

  Offset _position(
    ({double lane, double delay, double sway, double phase}) enemy,
  ) {
    final time = frame - _waveStart - enemy.delay;
    return Offset(
      (enemy.lane + math.sin(time * .12 + enemy.phase) * enemy.sway).clamp(
        6.0,
        _screenSize.width - 6,
      ),
      14 + time * .68,
    );
  }

  void step() {
    frame++;
    _enemies.removeWhere(
      (enemy) => _position(enemy).dy > _screenSize.height + 6,
    );
    if (_enemies.isEmpty) _spawnWave();

    final target = enemies
        .where((enemy) => enemy.dy >= 14 && enemy.dy < _shipY - 9)
        .fold<Offset?>(
          null,
          (best, enemy) => best == null || enemy.dy > best.dy ? enemy : best,
        );
    var aim = target?.dx ?? 43 + math.sin(frame * .12) * 24;
    for (final shot in _hostile) {
      if (shot.dy > 72 && (shot.dx - shipX).abs() < 10) {
        aim = shipX + (shot.dx > shipX ? -18 : 18);
        break;
      }
    }
    shipX = (shipX + (aim - shipX).clamp(-3.5, 3.5)).clamp(
      6.0,
      _screenSize.width - 6,
    );

    if (frame % 5 == 0) _shots.add(Offset(shipX, _shipY - 6));
    if (target != null && frame % 17 == 0) _hostile.add(target);
    for (var i = _shots.length - 1; i >= 0; i--) {
      final shot = _shots[i].translate(0, -5.2);
      final hit = _enemies.indexWhere((enemy) {
        final position = _position(enemy);
        return position.dy >= 13 && (position - shot).distanceSquared < 28;
      });
      if (hit >= 0) {
        _bursts.add((center: _position(_enemies.removeAt(hit)), frame: frame));
        _shots.removeAt(i);
        score += 50;
      } else if (shot.dy < 11) {
        _shots.removeAt(i);
      } else {
        _shots[i] = shot;
      }
    }
    for (var i = _hostile.length - 1; i >= 0; i--) {
      final shot = _hostile[i].translate(0, 2.2);
      if ((shot - Offset(shipX, _shipY)).distanceSquared < 14) {
        _bursts.add((center: Offset(shipX, _shipY), frame: frame));
        _hostile.removeAt(i);
      } else if (shot.dy > 105) {
        _hostile.removeAt(i);
      } else {
        _hostile[i] = shot;
      }
    }
    _bursts.removeWhere((burst) => frame - burst.frame > 8);
    notifyListeners();
  }
}

class _ArcadePainter extends CustomPainter {
  _ArcadePainter(this.demo) : super(repaint: demo);

  final _ArcadeDemo demo;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / _screenSize.width,
      size.height / _screenSize.height,
    );
    final bounds = Offset.zero & _screenSize;
    final glass = RRect.fromRectAndRadius(bounds, const Radius.circular(6));
    canvas.clipRRect(glass);
    final paint = Paint();
    canvas.drawRect(bounds, paint..color = const Color(0xff16271b));
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(1, 13, 84, 93));
    for (var i = 0; i < 26; i++) {
      final x = (i * 29 + i * i * 7) % 83 + 1.0;
      final y = (i * 43 + demo.frame * (i.isEven ? .38 : .6)) % 94 + 13;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 1, 1),
        paint
          ..color = i % 4 == 0
              ? const Color(0xff74aa66)
              : const Color(0xff36583a),
      );
    }
    for (final enemy in demo.enemies) {
      final x = enemy.dx.roundToDouble();
      final y = enemy.dy.roundToDouble();
      canvas.drawPath(
        Path()..addPolygon([
          Offset(x - 5, y - 2),
          Offset(x - 2, y + 1),
          Offset(x, y - 2),
          Offset(x + 2, y + 1),
          Offset(x + 5, y - 2),
          Offset(x + 4, y + 3),
          Offset(x, y + 4),
          Offset(x - 4, y + 3),
        ], true),
        paint..color = const Color(0xff76ce64),
      );
    }
    for (final shot in demo._shots) {
      canvas.drawRect(
        Rect.fromCenter(center: shot, width: 1.5, height: 4),
        paint..color = _phosphor,
      );
    }
    for (final shot in demo._hostile) {
      canvas.drawRect(
        Rect.fromCenter(center: shot, width: 1.5, height: 2),
        paint..color = const Color(0xff83b66a),
      );
    }
    for (final burst in demo._bursts) {
      final age = demo.frame - burst.frame;
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final position =
            burst.center +
            Offset(math.cos(angle), math.sin(angle)) * (2 + age * .85);
        canvas.drawRect(
          Rect.fromCenter(center: position, width: 1.6, height: 1.6),
          paint..color = _phosphor.withValues(alpha: 1 - age / 10),
        );
      }
    }
    final ship = demo.shipX.roundToDouble();
    canvas.drawPath(
      Path()..addPolygon([
        Offset(ship, _shipY - 5),
        Offset(ship + 2, _shipY),
        Offset(ship + 4, _shipY + 2),
        Offset(ship + 4, _shipY + 4),
        Offset(ship - 4, _shipY + 4),
        Offset(ship - 4, _shipY + 2),
        Offset(ship - 2, _shipY),
      ], true),
      paint..color = _phosphor,
    );
    canvas.restore();

    final score = TextPainter(
      text: TextSpan(
        text: '1UP   ${(demo.score % 1000000).toString().padLeft(6, '0')}',
        style: const TextStyle(
          fontSize: 6.5,
          fontFamily: 'monospace',
          color: _phosphor,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    score.paint(canvas, const Offset(6, 3));
    score.dispose();
    for (var y = 1.0; y < bounds.height; y += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, bounds.width, .45),
        paint..color = const Color(0x30101a13),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArcadePainter oldDelegate) => demo != oldDelegate.demo;
}
