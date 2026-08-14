import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quiet, non-interactive topographic texture for dark surfaces.
class TopoBackground extends StatelessWidget {
  const TopoBackground({
    super.key,
    required this.child,
    this.color = const Color(0xFF050510),
    this.opacity = .07,
  });

  final Widget child;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: TopoLinesPainter(opacity: opacity)),
          ),
        ),
        child,
      ],
    ),
  );
}

/// A clipped topographic surface for dark cards and panels.
class TopoCard extends StatelessWidget {
  const TopoCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.color = const Color(0xFF050510),
    this.opacity = .055,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final BorderRadius borderRadius;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    margin: margin,
    decoration: BoxDecoration(borderRadius: borderRadius),
    clipBehavior: Clip.antiAlias,
    child: TopoBackground(
      color: color,
      opacity: opacity,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class TopoLinesPainter extends CustomPainter {
  const TopoLinesPainter({this.opacity = .07});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFFB8B8C4).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centres = <Offset>[
      Offset(size.width * .12, size.height * .24),
      Offset(size.width * .84, size.height * .2),
      Offset(size.width * .78, size.height * .76),
      Offset(size.width * .2, size.height * .88),
    ];
    final scale = math.min(size.width, size.height);
    for (var group = 0; group < centres.length; group++) {
      for (var ring = 0; ring < 7; ring++) {
        final path = Path();
        for (var point = 0; point <= 72; point++) {
          final angle = point / 72 * math.pi * 2;
          final base = scale * (.065 + ring * .038);
          final shape =
              1 + .1 * math.sin(angle * 3 + group) + .06 * math.cos(angle * 5);
          final x = centres[group].dx + math.cos(angle) * base * 1.7 * shape;
          final y = centres[group].dy + math.sin(angle) * base * shape;
          point == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TopoLinesPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
