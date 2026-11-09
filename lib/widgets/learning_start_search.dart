import 'package:flutter/material.dart';

import '../models/acquisition_journey.dart';
import '../services/site_content_service.dart';
import '../services/transaction_learning.dart';

enum LearningSearchSection { roadmap, documents, seminars }

typedef LearningSearchDestination = ({
  LearningSearchSection section,
  String? id,
});

class LearningStartSearch extends StatefulWidget {
  const LearningStartSearch({super.key, required this.onOpen});

  final ValueChanged<LearningSearchDestination> onOpen;

  @override
  State<LearningStartSearch> createState() => _LearningStartSearchState();
}

class _LearningStartSearchState extends State<LearningStartSearch> {
  final _field = TextEditingController();
  List<_Result>? _results;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _search(String value) {
    final words = value
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toSet();
    if (words.isEmpty) {
      setState(() => _results = null);
      return;
    }
    final catalog = [
      for (final stage in acquisitionJourneyStages)
        _Result(
          title: SiteContentService.text(
            'learning.journey.${stage.id}.title',
            stage.title,
          ),
          description: SiteContentService.text(
            'learning.journey.${stage.id}.subtitle',
            stage.subtitle,
          ),
          section: LearningSearchSection.roadmap,
          id: stage.id,
          keywords: stage.phase.explanation,
        ),
      for (final lesson in transactionLessons)
        _Result(
          title: SiteContentService.text(
            'transaction.${lesson.id}.title',
            lesson.title,
          ),
          description: lesson.purpose,
          section: LearningSearchSection.documents,
          id: lesson.id,
          keywords: '${lesson.stage} ${lesson.fields}',
        ),
      const _Result(
        title: 'Seminars',
        description: 'Find upcoming events on the Canada map.',
        section: LearningSearchSection.seminars,
        keywords: 'webinar workshop local nearby live training',
      ),
    ];
    final matches =
        catalog.where((result) {
          final text =
              '${result.title} ${result.description} ${result.keywords}'
                  .toLowerCase();
          return words.every(text.contains);
        }).toList()..sort((a, b) {
          int titleMatches(_Result result) =>
              words.where(result.title.toLowerCase().contains).length;
          final rank = titleMatches(b).compareTo(titleMatches(a));
          return rank == 0 ? a.title.compareTo(b.title) : rank;
        });
    setState(() => _results = matches);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('learning-first-steps-search'),
                    controller: _field,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    onChanged: (_) {
                      if (_results != null) setState(() => _results = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Pact Learning',
                      hintStyle: const TextStyle(color: Color(0xFF646464)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF606060),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: IconButton.filled(
                          tooltip: 'Search',
                          onPressed: () {
                            _search(_field.text);
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF303030)),
                      ),
                    ),
                  ),
                  if (_results case final results?) ...[
                    const SizedBox(height: 20),
                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'No matches in Pact Learning. Try a different search.',
                        ),
                      ),
                    for (final result in results)
                      ListTile(
                        title: Text(result.title),
                        subtitle: Text(
                          '${result.section.label} · ${result.description}',
                        ),
                        trailing: const Icon(Icons.arrow_outward, size: 18),
                        onTap: () => widget.onOpen((
                          section: result.section,
                          id: result.id,
                        )),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

extension on LearningSearchSection {
  String get label => switch (this) {
    LearningSearchSection.roadmap => 'Roadmap',
    LearningSearchSection.documents => 'Documents',
    LearningSearchSection.seminars => 'Seminars',
  };
}

class _Result {
  const _Result({
    required this.title,
    required this.description,
    required this.section,
    required this.keywords,
    this.id,
  });

  final String title, description, keywords;
  final LearningSearchSection section;
  final String? id;
}
