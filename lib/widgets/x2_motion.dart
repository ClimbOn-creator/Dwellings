import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/site_content_service.dart';

/// Revio-style blur/fade/lift entrances. The explicit preview motion keeps
/// its real duration under platform motion flags; editing holds it still.
class X2Reveal extends StatefulWidget {
  const X2Reveal({
    super.key,
    required this.scroll,
    required this.child,
    this.delay = 0,
  });
  final ScrollController scroll;
  final Widget child;
  final int delay;
  @override
  State<X2Reveal> createState() => _X2RevealState();
}

class _X2RevealState extends State<X2Reveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1050 + widget.delay),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _shown = false;
  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_check);
    SiteContentService.editing.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    if (SiteContentService.editing.value) {
      _shown = true;
      _controller.value = 1;
      return;
    }
    if (_shown) return;
    final box = context.findRenderObject();
    if (box is RenderBox &&
        box.hasSize &&
        box.localToGlobal(Offset.zero).dy <
            View.of(context).physicalSize.height /
                View.of(context).devicePixelRatio *
                .94) {
      _shown = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_check);
    SiteContentService.editing.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final start = widget.delay / (1050 + widget.delay);
      final p = Curves.easeOutCubic.transform(
        ((_controller.value - start) / (1 - start)).clamp(0.0, 1.0),
      );
      final content = Transform.translate(
        offset: Offset(0, (1 - p) * 42),
        child: child,
      );
      return Opacity(
        opacity: p,
        child: p > .995 || p == 0
            ? content
            : ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: (1 - p) * 7,
                  sigmaY: (1 - p) * 7,
                ),
                child: content,
              ),
      );
    },
  );
}

class X2Hover extends StatefulWidget {
  const X2Hover({super.key, required this.child, this.lift = 5});
  final Widget child;
  final double lift;
  @override
  State<X2Hover> createState() => _X2HoverState();
}

class _X2HoverState extends State<X2Hover> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    animationBehavior: AnimationBehavior.preserve,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      if (!SiteContentService.editing.value) _controller.forward();
    },
    onExit: (_) => _controller.reverse(),
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          -widget.lift * Curves.easeOutCubic.transform(_controller.value),
        ),
        child: child,
      ),
    ),
  );
}
