import 'package:flutter/material.dart';

/// A quiet, non-interactive topographic texture for dark surfaces.
class TopoBackground extends StatelessWidget {
  const TopoBackground({
    super.key,
    required this.child,
    this.color = const Color(0xFF050510),
    this.opacity = .16,
  });

  final Widget child;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => ColoredBox(color: color, child: child);
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
    this.opacity = .12,
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

/// Compatibility painter retained for older decorative stacks. It deliberately
/// paints nothing: the former contour-line visual has been retired.
class TopoLinesPainter extends CustomPainter {
  const TopoLinesPainter({this.opacity = 0});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant TopoLinesPainter oldDelegate) => false;
}
