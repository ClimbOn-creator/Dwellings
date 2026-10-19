export '../models/marketing_motion_content.dart';
import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import 'site_parallax_image.dart';
import 'ambient_video.dart';

/// A clearly visible entrance, replayed when a section re-enters the viewport.
class MarketingReveal extends StatefulWidget {
  const MarketingReveal({
    super.key,
    required this.controller,
    required this.child,
  });
  final ScrollController controller;
  final Widget child;
  @override
  State<MarketingReveal> createState() => _MarketingRevealState();
}

class _MarketingRevealState extends State<MarketingReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
    duration: const Duration(milliseconds: 950),
  );
  bool _visible = false, _scheduled = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant MarketingReveal old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_schedule);
      widget.controller.addListener(_schedule);
    }
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final still =
          MediaQuery.disableAnimationsOf(context) ||
          SiteContentService.editing.value;
      if (still) {
        _animation.value = 1;
        return;
      }
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final visible =
          top < MediaQuery.sizeOf(context).height * .98 &&
          top + box.size.height > 70;
      if (visible && !_visible) _animation.forward(from: 0);
      if (!visible && _visible) _animation.value = 0;
      _visible = visible;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedule);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) => AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = editing || MediaQuery.disableAnimationsOf(context)
            ? 1.0
            : Curves.easeOutCubic.transform(_animation.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 64 * (1 - value)),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Decorative video runs automatically behind the page content, without controls.
class MarketingFilm extends StatelessWidget {
  const MarketingFilm({
    super.key,
    required this.controller,
    required this.contentKey,
    required this.imageAsset,
    required this.videoAsset,
    required this.height,
    this.child,
  });
  final ScrollController controller;
  final String contentKey, imageAsset, videoAsset;
  final double height;
  final Widget? child;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: SiteParallaxImage(
      controller: controller,
      contentKey: contentKey,
      asset: imageAsset,
      maxTravel: 160,
      scrollFactor: .5,
      movingBackground: AmbientVideo(
        url: 'assets/$videoAsset',
        poster: 'assets/$imageAsset',
        paused: false,
      ),
      child: SizedBox.expand(child: child),
    ),
  );
}

/// Public marketing pages always animate, as explicitly requested by the owner.
/// This local scope does not alter motion settings on the working dashboards.
class MarketingMotionScope extends StatelessWidget {
  const MarketingMotionScope({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  );
}
