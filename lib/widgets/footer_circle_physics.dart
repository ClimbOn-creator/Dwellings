import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FooterBall {
  FooterBall(this.position, this.velocity, this.radius, this.color);
  Offset position, velocity;
  final double radius;
  final Color color;
  bool held = false;
}

/// Small deterministic rigid-circle simulation: side walls, a floor, no ceiling.
class FooterCircleWorld {
  FooterCircleWorld(this.size, {this.count = 36});
  Size size;
  final int count;
  final balls = <FooterBall>[];
  final _random = math.Random(41);
  double _time = 0;
  static const palette = [
    Color(0xFF9EBD87),
    Color(0xFFC4CD8F),
    Color(0xFFBEDDDF),
    Color(0xFFD1B6CB),
    Color(0xFF426A52),
    Color(0xFFE1C9A4),
  ];

  void step(double dt) {
    final steps = math.max(1, (dt / (1 / 120)).ceil());
    final h = dt / steps;
    for (var s = 0; s < steps; s++) {
      _time += h;
      while (balls.length < count && _time >= balls.length * .085) {
        final r = size.width < 600
            ? 16 + _random.nextDouble() * 12
            : 24 + _random.nextDouble() * 22;
        balls.add(
          FooterBall(
            Offset(
              r + _random.nextDouble() * math.max(0, size.width - r * 2),
              -r * 2,
            ),
            Offset((_random.nextDouble() - .5) * 160, 50),
            r,
            palette[balls.length % palette.length],
          ),
        );
      }
      for (final b in balls) {
        if (b.held) continue;
        b.velocity += Offset(0, 920 * h);
        b.position += b.velocity * h;
      }
      for (var iteration = 0; iteration < 4; iteration++) {
        for (var i = 0; i < balls.length; i++) {
          final a = balls[i];
          for (var j = i + 1; j < balls.length; j++) {
            final b = balls[j];
            var delta = b.position - a.position;
            final distance = delta.distance;
            final overlap = a.radius + b.radius - distance;
            if (overlap <= 0) continue;
            final normal = distance > .001
                ? delta / distance
                : const Offset(1, 0);
            final ia = a.held ? 0.0 : 1 / (a.radius * a.radius);
            final ib = b.held ? 0.0 : 1 / (b.radius * b.radius);
            if (ia + ib == 0) continue;
            a.position -= normal * overlap * ia / (ia + ib);
            b.position += normal * overlap * ib / (ia + ib);
            final closing =
                (b.velocity - a.velocity).dx * normal.dx +
                (b.velocity - a.velocity).dy * normal.dy;
            if (closing < 0) {
              final impulse = -(1.55) * closing / (ia + ib);
              a.velocity -= normal * impulse * ia;
              b.velocity += normal * impulse * ib;
            }
          }
        }
        for (final b in balls) {
          if (b.held) continue;
          if (b.position.dx < b.radius) {
            b.position = Offset(b.radius, b.position.dy);
            if (b.velocity.dx < 0)
              b.velocity = Offset(-b.velocity.dx * .65, b.velocity.dy);
          }
          if (b.position.dx > size.width - b.radius) {
            b.position = Offset(size.width - b.radius, b.position.dy);
            if (b.velocity.dx > 0)
              b.velocity = Offset(-b.velocity.dx * .65, b.velocity.dy);
          }
          if (b.position.dy > size.height - b.radius) {
            b.position = Offset(b.position.dx, size.height - b.radius);
            if (b.velocity.dy > 0)
              b.velocity = Offset(
                b.velocity.dx * .96,
                b.velocity.dy > 35 ? -b.velocity.dy * .55 : 0,
              );
          }
        }
      }
      for (final b in balls) {
        if (!b.held) b.velocity *= math.pow(.94, h * 60).toDouble();
      }
    }
  }

  void hold(int index, Offset position) {
    balls[index]
      ..held = true
      ..position = position
      ..velocity = Offset.zero;
  }

  void release(int index, Offset velocity) {
    final v = velocity.distance > 1800
        ? velocity / velocity.distance * 1800
        : velocity;
    balls[index]
      ..held = false
      ..velocity = v;
  }
}

/// White footer with a transparent physics layer. Only circles capture drags;
/// the surrounding space scrolls normally and existing footer links stay live.
class InteractiveCircleFooter extends StatefulWidget {
  const InteractiveCircleFooter({super.key, required this.child});
  final Widget child;
  @override
  State<InteractiveCircleFooter> createState() =>
      _InteractiveCircleFooterState();
}

class _InteractiveCircleFooterState extends State<InteractiveCircleFooter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  ScrollPosition? _scroll;
  FooterCircleWorld? _world;
  Duration? _last;
  double _running = 0;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_visibility);
      _scroll = next;
      _scroll?.addListener(_visibility);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _visibility());
  }

  void _visibility() {
    if (!mounted || _world == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final visible = rect.overlaps(Offset.zero & MediaQuery.sizeOf(context));
    if (visible && !_started) {
      _started = true;
      _wake();
    }
    if (!visible && _ticker.isActive) {
      _ticker.stop();
      _last = null;
    }
    if (visible && _started && _running < 12 && !_ticker.isActive) _wake();
  }

  void _wake() {
    _last = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 1 / 60
        : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.0, .035);
    _last = elapsed;
    _running += dt;
    setState(() => _world!.step(dt));
    if (_running >= 12 && !_world!.balls.any((b) => b.held)) _ticker.stop();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_visibility);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return ColoredBox(
        color: Colors.white,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  if (_world == null) {
                    _world = FooterCircleWorld(size);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _visibility(),
                    );
                  } else if (_world!.size != size) {
                    final old = _world!.size;
                    for (final b in _world!.balls) {
                      b.position = Offset(
                        b.position.dx * size.width / old.width,
                        b.position.dy + size.height - old.height,
                      );
                    }
                    _world!.size = size;
                    _running = 0;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _wake();
                    });
                  }
                  return Stack(
                    children: [
                      for (var i = 0; i < _world!.balls.length; i++)
                        Positioned(
                          left:
                              _world!.balls[i].position.dx -
                              _world!.balls[i].radius,
                          top:
                              _world!.balls[i].position.dy -
                              _world!.balls[i].radius,
                          width: _world!.balls[i].radius * 2,
                          height: _world!.balls[i].radius * 2,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: ClipOval(
                              child: GestureDetector(
                                key: ValueKey('footer-circle-$i'),
                                onPanDown: (_) {
                                  _running = 0;
                                  _world!.hold(i, _world!.balls[i].position);
                                  _wake();
                                },
                                onPanStart: (_) {
                                  _running = 0;
                                  _world!.hold(i, _world!.balls[i].position);
                                  _wake();
                                },
                                onPanUpdate: (details) => setState(() {
                                  final b = _world!.balls[i];
                                  final next = b.position + details.delta;
                                  b.position = Offset(
                                    next.dx.clamp(
                                      b.radius,
                                      size.width - b.radius,
                                    ),
                                    math.min(next.dy, size.height - b.radius),
                                  );
                                }),
                                onPanEnd: (details) {
                                  _world!.release(
                                    i,
                                    details.velocity.pixelsPerSecond,
                                  );
                                  _running = 0;
                                  _wake();
                                },
                                onPanCancel: () {
                                  _world!.release(i, Offset.zero);
                                  _running = 0;
                                  _wake();
                                },
                                child: ColoredBox(
                                  color: _world!.balls[i].color,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            widget.child,
          ],
        ),
      );
    },
  );
}
