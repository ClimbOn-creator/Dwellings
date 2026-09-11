import 'package:flutter/material.dart';
import '../services/site_content_service.dart';
import '../services/site_copy_catalog.dart';
import 'site_inline_editor.dart';

/// Source keys identify copy locations; catalog membership keeps account data,
/// calculated figures and messages out of the public content store.
class SiteText extends StatelessWidget {
  const SiteText(
    this.data, {
    required this.contentKey,
    this.literal = false,
    this.templateValues,
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final String contentKey;
  final bool literal;
  final Map<String, String>? templateValues;

  String _expand(String value) => value.replaceAllMapped(
    RegExp(r"\{\{(value[0-9]+)\}\}"),
    (match) => templateValues?[match[1]] ?? match[0]!,
  );
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  Widget _render(String value) => Text(
    value,
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    semanticsIdentifier: semanticsIdentifier,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );

  @override
  Widget build(BuildContext context) {
    final legacy = SiteContentService.legacyKey(data);
    final original = legacy == null
        ? data
        : SiteContentService.originalCopy(legacy) ?? data;
    if (!literal &&
        templateValues == null &&
        legacy == null &&
        !siteCopyIdsByDefault.containsKey(original))
      return _render(original);
    final id =
        legacy ??
        (literal || templateValues != null
            ? contentKey
            : '$contentKey.${siteCopyIdsByDefault[original]}');
    return ValueListenableBuilder<int>(
      valueListenable: SiteContentService.revision,
      builder: (context, _, _) => SiteEditTarget(
        contentKey: id,
        fallback: original,
        child: _render(_expand(SiteContentService.text(id, original))),
      ),
    );
  }
}

/// Preserve absent form labels/hints while editing source-owned labels normally.
Widget? siteInputCopy(
  String? value, {
  required String contentKey,
  Map<String, String>? templateValues,
}) => value == null
    ? null
    : SiteText(value, contentKey: contentKey, templateValues: templateValues);
