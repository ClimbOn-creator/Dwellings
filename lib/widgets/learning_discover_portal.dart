import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'buyer_workspace_style.dart';

class DiscoverPortalRoute extends PageRouteBuilder<void> {
  DiscoverPortalRoute({
    required WidgetBuilder destination,
    required Rect source,
    required bool arcade,
    Widget? calendarPage,
  }) : super(
         transitionDuration: Duration(milliseconds: arcade ? 1900 : 860),
         reverseTransitionDuration: const Duration(milliseconds: 640),
         pageBuilder: (context, _, _) => destination(context),
         transitionsBuilder: (context, animation, _, child) => AnimatedBuilder(
           animation: animation,
           child: child,
           builder: (context, child) {
             final time = animation.value;
             final reveal = Interval(
               arcade ? .79 : .54,
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
    if (time > .3) _bootSequence(canvas, size);
    canvas.restore();
  }

  void _bootSequence(Canvas canvas, Size size) {
    final sidebar = BuyerWorkspaceStyle.sidebar;
    final rows = [
      sidebar.home,
      sidebar.pipeline,
      sidebar.dealScreen,
      sidebar.resources,
      sidebar.messages,
      sidebar.team,
      sidebar.transactionPlan,
      sidebar.refresh,
    ];
    final panel = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.min(340, size.width - 32),
      height: 238,
    );
    final alpha = const Interval(
      .3,
      .48,
      curve: Curves.easeOutCubic,
    ).transform(time);
    canvas.drawRect(
      panel,
      Paint()..color = const Color(0xff06140b).withValues(alpha: alpha * .88),
    );
    canvas.drawRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff5b9e66).withValues(alpha: alpha * .8),
    );
    void line(String text, double y, double opacity, double fontSize) {
      final label = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xffa2eb8e).withValues(alpha: opacity),
            fontFamily: 'monospace',
            fontSize: fontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: panel.width - 28);
      label.paint(canvas, Offset(panel.left + 14, panel.top + y));
      label.dispose();
    }

    line('PACT / BUYER WORKSPACE', 12, alpha, 16);
    for (var i = 0; i < rows.length; i++) {
      final start = .36 + i * .045;
      final loaded = Interval(
        start,
        start + .095,
        curve: Curves.easeOut,
      ).transform(time);
      if (loaded == 0) continue;
      line(
        '${loaded > .84 ? '[OK]' : '[..]'}  ${rows[i].toUpperCase()}',
        42 + i * 22,
        loaded,
        13,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcadeTunnel oldDelegate) =>
      oldDelegate.time != time || oldDelegate.origin != origin;
}
