import 'package:flutter/material.dart';

import '../services/site_content_service.dart';
import '../models/learning_track_content.dart';
import 'navigation_organizer.dart';
import 'site_copy_text.dart';

/// The Learning Home topic picker uses the public page clicker's pill styling.
class LearningHomeQuestion extends StatelessWidget {
  const LearningHomeQuestion({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LearningTrack? selected;
  final ValueChanged<LearningTrack> onSelected;
  static const _topics = [
    ('buying', 'Buying a Business'),
    ('succession', 'Succession'),
    ('transfer', 'Transfer'),
  ];
  static const _palette = NavigationOrganizerPalette();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) {
      final still = editing || MediaQuery.disableAnimationsOf(context);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: still ? 1 : 0, end: 1),
            duration: still ? Duration.zero : const Duration(milliseconds: 700),
            builder: (context, value, child) => Opacity(
              key: const ValueKey('learning-home-question-reveal'),
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: Transform.scale(
                  scale: .94 + .06 * Curves.easeOutBack.transform(value),
                  child: child,
                ),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: SiteCopyText(
                'learning.home.question',
                'What do you want to learn?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172817),
                  height: 1.2,
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, bounds) {
              final compact = bounds.maxWidth < 600;
              return Row(
                children: [
                  for (var i = 0; i < _topics.length; i++) ...[
                    if (i > 0) SizedBox(width: compact ? 8 : 24),
                    Expanded(
                      child: Material(
                        color: const Color(0xFFFCFCFA),
                        elevation: 2,
                        shadowColor: const Color(0x160F2418),
                        borderRadius: BorderRadius.circular(40),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: TextButton(
                            key: ValueKey(
                              'learning-home-topic-${_topics[i].$1}',
                            ),
                            onPressed: () =>
                                onSelected(LearningTrack.values[i]),
                            isSemanticButton: true,
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  selected == LearningTrack.values[i]
                                  ? _palette.active
                                  : Colors.transparent,
                              foregroundColor:
                                  selected == LearningTrack.values[i]
                                  ? _palette.activeText
                                  : _palette.text,
                              overlayColor: _palette.hover,
                              minimumSize: const Size(0, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Semantics(
                              selected: selected == LearningTrack.values[i],
                              child: SiteCopyText(
                                'learning.home.topic.${_topics[i].$1}',
                                _topics[i].$2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      );
    },
  );
}
