import 'dart:math' as math;
import 'package:flutter/material.dart';

class DiscoverPortalRoute extends PageRouteBuilder<void> {
  DiscoverPortalRoute({
    required WidgetBuilder destination,
    required Rect source,
    required bool arcade,
    Widget? calendarPage,
  }) : super(
         transitionDuration: Duration(milliseconds: arcade ? 1340 : 860),
         reverseTransitionDuration: const Duration(milliseconds: 640),
         pageBuilder: (context, _, _) => destination(context),
         transitionsBuilder: (context, animation, _, child) => AnimatedBuilder(
           animation: animation,
           child: child,
           builder: (context, child) {
             final time = animation.value;
             final reveal = Interval(
               arcade ? .63 : .54,
               1,
               curve: Curves.easeOutCubic,
             ).transform(time);
             return LayoutBuilder(
               builder: (context, bounds) {
                 final full = Offset.zero & bounds.biggest;
                 return Stack(
                   fit: StackFit.expand,
                   children: [
                     if (arcade)
                       CustomPaint(
                         painter: time < 1
                             ? _ArcadeTunnel(source.center, time)
                             : null,
                       )
                     else
                       Positioned.fromRect(
                         rect: Rect.lerp(
                           source,
                           full,
                           Curves.easeInOutCubic.transform(time),
                         )!,
                         child: Opacity(
                           opacity: 1 - reveal,
                           child: calendarPage,
                         ),
                       ),
                     IgnorePointer(
                       ignoring: time < 1,
                       child: Opacity(opacity: reveal, child: child),
                     ),
                   ],
                 );
               },
             );
           },
         ),
       );

  @override
  AnimationController createAnimationController() => AnimationController(
    vsync: navigator!,
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    animationBehavior: AnimationBehavior.preserve,
  );
}

class _ArcadeTunnel extends CustomPainter {
  const _ArcadeTunnel(this.origin, this.time);

  final Offset origin;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final focus = Offset.lerp(
      origin,
      size.center(Offset.zero),
      Curves.easeOut.transform(time),
    )!;
    final reach = size.longestSide * 1.2;
    final radius =
        15 +
        reach *
            const Interval(0, .52, curve: Curves.easeInCubic).transform(time);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: focus, radius: radius)),
    );
    canvas.drawColor(const Color(0xff030b06), BlendMode.srcOver);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 0; i < 11; i++) {
      final wave = (i / 11 + time * 2.8) % 1;
      final distance = math.pow(wave, 2.6).toDouble() * reach;
      glow.color = const Color(0xff76e38b).withValues(alpha: (1 - wave) * .52);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: focus,
            width: 24 + distance * 1.5,
            height: 22 + distance,
          ),
          const Radius.circular(8),
        ),
        glow,
      );
    }
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final position = (i * .173 + time * 2.3) % 1;
      final length = position * position * reach;
      glow.color = const Color(
        0xffa6ff99,
      ).withValues(alpha: .25 + position * .48);
      canvas.drawLine(
        focus + direction * length,
        focus + direction * (length + 12 + position * 64),
        glow,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArcadeTunnel oldDelegate) =>
      oldDelegate.time != time || oldDelegate.origin != origin;
}
