import 'package:flutter/material.dart';

/// Keep browsing native while scroll changes the surrounding color field.
class MarketplaceAtmosphere extends StatelessWidget {
  const MarketplaceAtmosphere({
    super.key,
    required this.controller,
    required this.child,
  });
  final ScrollController controller;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, content) {
      final p = MediaQuery.disableAnimationsOf(context)
          ? 0.0
          : ((controller.hasClients ? controller.offset : 0) / 1600).clamp(
              0.0,
              1.0,
            );
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + p, -1),
            end: Alignment(1 - p, 1),
            colors: [
              Color.lerp(const Color(0xFFD4E7DE), const Color(0xFFD8E4F2), p)!,
              const Color(0xFFF4F1EA),
              Color.lerp(const Color(0xFFE4E8F2), const Color(0xFFD2E8E1), p)!,
            ],
          ),
        ),
        child: content,
      );
    },
  );
}

class MarketplaceHover extends StatefulWidget {
  const MarketplaceHover({super.key, required this.child});
  final Widget child;
  @override
  State<MarketplaceHover> createState() => _MarketplaceHoverState();
}

class _MarketplaceHoverState extends State<MarketplaceHover> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: hover && !still ? -7 : 0),
        duration: still ? Duration.zero : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: widget.child,
        builder: (context, y, child) =>
            Transform.translate(offset: Offset(0, y), child: child),
      ),
    );
  }
}
