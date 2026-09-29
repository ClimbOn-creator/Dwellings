import 'package:flutter/material.dart';
import '../services/site_content_service.dart';

/// A permanent visibility slot; hiding never removes published copy or media.
class SiteSection extends StatefulWidget {
  const SiteSection({
    super.key,
    required this.id,
    required this.label,
    required this.child,
  });
  final String id, label;
  final Widget child;
  @override
  State<SiteSection> createState() => _SiteSectionState();
}

class _SiteSectionState extends State<SiteSection> {
  bool _saving = false;
  Future<void> _toggle(bool hidden) async {
    final key = 'section.${widget.id}.hidden';
    final expected = SiteContentService.published(key);
    setState(() => _saving = true);
    try {
      if (!await SiteContentService.canEdit() ||
          !SiteContentService.editing.value) {
        return;
      }
      await SiteContentService.saveExpected(
        key,
        hidden ? 'false' : 'true',
        expected: expected,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SiteContentService.saveError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: SiteContentService.revision,
    builder: (context, _, _) => ValueListenableBuilder<bool>(
      valueListenable: SiteContentService.editing,
      builder: (context, editing, _) {
        final hidden =
            SiteContentService.text('section.${widget.id}.hidden', 'false') ==
            'true';
        if (hidden && !editing) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (editing)
              Container(
                color: const Color(0xFFEAF0EC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.label}${hidden ? ' · hidden from visitors' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF053827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: Key('section_toggle_${widget.id}'),
                      onPressed: _saving ? null : () => _toggle(hidden),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      label: Text(
                        _saving
                            ? 'Saving…'
                            : hidden
                            ? 'Restore section'
                            : 'Hide section',
                      ),
                    ),
                  ],
                ),
              ),
            if (!hidden) widget.child,
          ],
        );
      },
    ),
  );
}
