import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import 'site_image.dart';
import 'site_inline_editor.dart';

/// Scroll-driven photography; its permanent slot ID survives redesigns.
/// Foreground controls stay still, and motion pauses during editing.
class SiteParallaxImage extends StatelessWidget {
  const SiteParallaxImage({
    super.key,
    required this.controller,
    required this.contentKey,
    required this.asset,
    required this.child,
  });
  final ScrollController controller;
  final String contentKey, asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: SiteContentService.editing,
              builder: (context, editing, _) => Flow(
                delegate: _PhotoFlow(
                  controller,
                  context,
                  MediaQuery.sizeOf(context).height,
                  reduced || editing,
                ),
                children: [
                  RepaintBoundary(
                    child: SiteImage(
                      contentKey: contentKey,
                      original: Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child,
          ValueListenableBuilder<bool>(
            valueListenable: SiteContentService.editing,
            builder: (context, editing, _) => editing
                ? Positioned(
                    top: 12,
                    right: 12,
                    child: FilledButton.icon(
                      onPressed: () => selectSiteContent(
                        context,
                        contentKey,
                        '',
                        image: true,
                      ),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Edit background'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Compute movement at paint time, after scroll layout, to avoid a one-frame lag.
class _PhotoFlow extends FlowDelegate {
  _PhotoFlow(this.controller, this.section, this.viewportHeight, this.still)
    : super(repaint: controller);
  final ScrollController controller;
  final BuildContext section;
  final double viewportHeight;
  final bool still;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(
        Size(constraints.maxWidth, constraints.maxHeight + 128),
      );

  @override
  void paintChildren(FlowPaintingContext context) {
    // A Flow delegate can briefly outlive its section during scrolling.
    // Paint at the neutral position until its RenderBox is attached again.
    var travel = 0.0;
    if (!still && section.mounted) {
      final renderObject = section.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final top = renderObject.localToGlobal(Offset.zero).dy;
        travel = ((viewportHeight / 2 - top - context.size.height / 2) * .16)
            .clamp(-54.0, 54.0);
      }
    }
    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, -64 + travel, 0),
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoFlow oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.section != section ||
      oldDelegate.viewportHeight != viewportHeight ||
      oldDelegate.still != still;
}
