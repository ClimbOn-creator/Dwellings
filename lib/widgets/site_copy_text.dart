import 'package:flutter/material.dart';

import '../services/site_content_service.dart';

class SiteCopyText extends StatelessWidget {
  const SiteCopyText(
    this.contentKey,
    this.fallback, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String contentKey;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (_, _, _) => Text(
      SiteContentService.text(contentKey, fallback),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    ),
  );
}
