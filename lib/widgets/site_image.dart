import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import 'site_inline_editor.dart';

class SiteImage extends StatelessWidget {
  const SiteImage({
    super.key,
    required this.contentKey,
    required this.original,
  });
  final String contentKey;
  final Image original;
  @override
  Widget build(BuildContext context) {
    final id = contentKey;
    return ValueListenableBuilder<int>(
      valueListenable: SiteContentService.revision,
      builder: (context, _, _) {
        final url = SiteContentService.published(id);
        return SiteEditTarget(
          contentKey: id,
          fallback: '',
          image: true,
          child: url == null
              ? original
              : Image.network(
                  url,
                  width: original.width,
                  height: original.height,
                  fit: original.fit,
                  alignment: original.alignment,
                  repeat: original.repeat,
                  color: original.color,
                  colorBlendMode: original.colorBlendMode,
                  filterQuality: original.filterQuality,
                  semanticLabel: original.semanticLabel,
                  excludeFromSemantics: original.excludeFromSemantics,
                  matchTextDirection: original.matchTextDirection,
                  errorBuilder: (_, _, _) => original,
                ),
        );
      },
    );
  }
}

/// Uses a separate edit control so foreground copy remains individually selectable.
class SiteBackground extends StatelessWidget {
  const SiteBackground({
    super.key,
    required this.contentKey,
    required this.original,
  });
  final String contentKey;
  final Container original;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (context, _, _) {
      final decoration = original.decoration! as BoxDecoration;
      final image = decoration.image!;
      final url = SiteContentService.published(contentKey);
      final container = Container(
        alignment: original.alignment,
        padding: original.padding,
        color: original.color,
        foregroundDecoration: original.foregroundDecoration,
        constraints: original.constraints,
        margin: original.margin,
        transform: original.transform,
        transformAlignment: original.transformAlignment,
        clipBehavior: original.clipBehavior,
        decoration: decoration.copyWith(
          image: url == null
              ? image
              : DecorationImage(
                  image: NetworkImage(url),
                  fit: image.fit,
                  alignment: image.alignment,
                  colorFilter: image.colorFilter,
                  repeat: image.repeat,
                  opacity: image.opacity,
                  filterQuality: image.filterQuality,
                  matchTextDirection: image.matchTextDirection,
                ),
        ),
        child: original.child,
      );
      return Stack(
        children: [
          container,
          ValueListenableBuilder<bool>(
            valueListenable: SiteContentService.editing,
            builder: (context, editing, _) => editing
                ? Positioned(
                    top: 8,
                    left: 8,
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
      );
    },
  );
}
