import '../services/site_content_service.dart';
import 'site_inline_editor.dart';
import 'site_image.dart';
import 'package:flutter/material.dart';

/// Keeps one decoded photograph behind a separately scrolling content layer.
/// The repaint boundary is important on web: the browser no longer has to
/// re-rasterize a full-page image whenever the user scrolls a form.
class FixedEditorialBackground extends StatelessWidget {
  const FixedEditorialBackground({
    super.key,
    required this.imagePath,
    required this.contentKey,
    required this.child,
    this.wash = const Color(0xFFF4F1EB),
    this.washOpacity = .68,
    this.alignment = Alignment.center,
  });

  final String imagePath;
  final String contentKey;
  final Widget child;
  final Color wash;
  final double washOpacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        child: SiteImage(
          contentKey: contentKey,
          original: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: alignment,
            filterQuality: FilterQuality.low,
            cacheWidth: 1800,
          ),
        ),
      ),
      ColoredBox(color: wash.withValues(alpha: washOpacity)),
      child,
      ValueListenableBuilder<bool>(
        valueListenable: SiteContentService.editing,
        builder: (context, editing, _) => editing
            ? Positioned(
                top: 8,
                left: 8,
                child: FilledButton.icon(
                  onPressed: () =>
                      selectSiteContent(context, contentKey, '', image: true),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Edit background'),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
