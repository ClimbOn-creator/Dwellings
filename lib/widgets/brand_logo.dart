import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import 'site_inline_editor.dart';

const brandInk = Color(0xFF050510);
const brandPurple = Color(0xFF252525);
const brandLilac = Color(0xFF9B9B98);

/// Historical widget names and editor IDs remain stable across the rebrand.
class AffinityLogo extends StatelessWidget {
  const AffinityLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.dark = true,
  });
  final double size;
  final bool showWordmark;

  /// A light mark for a dark surface; a dark mark for a light surface.
  final bool dark;
  @override
  Widget build(BuildContext context) => _PactLogo(
    contentKey: 'image.brand_logo.m1',
    width: showWordmark ? size * 2.5 : size * 1.7,
    height: size,
    light: dark,
  );
}

class AffinityFooterLogo extends StatelessWidget {
  const AffinityFooterLogo({super.key, this.width = 300});
  final double width;
  @override
  Widget build(BuildContext context) => _PactLogo(
    contentKey: 'image.brand_logo.m2',
    width: width,
    height: width * .30,
    light: false,
  );
}

class _PactLogo extends StatelessWidget {
  const _PactLogo({
    required this.contentKey,
    required this.width,
    required this.height,
    required this.light,
  });
  final String contentKey;
  final double width, height;
  final bool light;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (context, _, _) {
      final url = SiteContentService.published(contentKey);
      final artwork = _PactArtwork(width: width, height: height, light: light);
      return SiteEditTarget(
        contentKey: contentKey,
        fallback: '',
        image: true,
        child: url == null
            ? artwork
            : Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.contain,
                semanticLabel: 'Pact',
                errorBuilder: (_, _, _) => artwork,
              ),
      );
    },
  );
}

/// Frame the supplied PNGs in layout, leaving their original bytes untouched.
class _PactArtwork extends StatelessWidget {
  const _PactArtwork({
    required this.width,
    required this.height,
    required this.light,
  });
  final double width, height;
  final bool light;
  @override
  Widget build(BuildContext context) {
    final frame = light
        ? const Rect.fromLTRB(198, 528, 1053, 787)
        : const Rect.fromLTRB(254, 540, 1001, 758);
    final scale = math.min(width / frame.width, height / frame.height);
    return Semantics(
      image: true,
      label: 'Pact',
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: (width - frame.width * scale) / 2 - frame.left * scale,
                top: (height - frame.height * scale) / 2 - frame.top * scale,
                width: 1254 * scale,
                height: 1254 * scale,
                child: Image.asset(
                  light
                      ? 'assets/brand/pact-logo-light.png'
                      : 'assets/brand/pact-logo-dark.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
