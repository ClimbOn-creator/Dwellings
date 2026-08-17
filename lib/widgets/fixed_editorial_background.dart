import 'package:flutter/material.dart';

/// Keeps one decoded photograph behind a separately scrolling content layer.
/// The repaint boundary is important on web: the browser no longer has to
/// re-rasterize a full-page image whenever the user scrolls a form.
class FixedEditorialBackground extends StatelessWidget {
  const FixedEditorialBackground({
    super.key,
    required this.imagePath,
    required this.child,
    this.wash = const Color(0xFFF4F1EB),
    this.washOpacity = .68,
    this.alignment = Alignment.center,
  });

  final String imagePath;
  final Widget child;
  final Color wash;
  final double washOpacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.low,
          cacheWidth: 1800,
        ),
      ),
      ColoredBox(color: wash.withValues(alpha: washOpacity)),
      child,
    ],
  );
}
