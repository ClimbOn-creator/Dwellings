import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/learning_lesson_content.dart';
import 'acquisition_journey_panel.dart';
import 'learning_start_search.dart';
import 'site_copy_text.dart';
import 'transaction_room_panel.dart';

enum LearningLesson { roadmap, discover, search }

const _sage = Color(0xFFE8EEE8);
const _forest = Color(0xFF334B40);
const _cream = Color(0xFFF6F1E7);
const _bodyStyle = TextStyle(color: learningInk, fontSize: 16, height: 1.65);

class LearningLessonPage extends StatefulWidget {
  const LearningLessonPage({
    super.key,
    required this.lesson,
    required this.onOpen,
    required this.onSearchResult,
    this.initialStageId,
  });

  final LearningLesson lesson;
  final ValueChanged<String> onOpen;
  final ValueChanged<LearningSearchDestination> onSearchResult;
  final String? initialStageId;

  @override
  State<LearningLessonPage> createState() => _LearningLessonPageState();
}

class _LearningLessonPageState extends State<LearningLessonPage> {
  final _coreKey = GlobalKey();
  final _exampleKey = GlobalKey();
  final _mistakesKey = GlobalKey();
  final _stagesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.lesson == LearningLesson.roadmap &&
        widget.initialStageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _readSection(_stagesKey);
      });
    }
  }

  String get _prefix => 'learning.lesson.${widget.lesson.name}';

  Widget _copy(String suffix, {TextStyle? style}) =>
      _lessonCopy('$_prefix.$suffix', style: style);

  Future<void> _readSection(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      alignment: .04,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth >= 980;
      final text = _lessonText();
      final video = _videoPanel();
      final support = _lessonSupport();
      return SingleChildScrollView(
        key: ValueKey('learning-workspace-${widget.lesson.name}-'),
        padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 32, wide ? 40 : 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: text),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            video,
                            const SizedBox(height: 26),
                            support,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      video,
                      const SizedBox(height: 36),
                      text,
                      const SizedBox(height: 36),
                      support,
                    ],
                  ),
          ),
        ),
      );
    },
  );

  Widget _lessonText() => Column(
    key: ValueKey('lesson-${widget.lesson.name}-text'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _copy(
        'eyebrow',
        style: const TextStyle(
          color: _forest,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 12),
      widget.lesson == LearningLesson.roadmap
          ? const SiteCopyText(
              'learning.journey.title',
              'Roadmap',
              style: TextStyle(
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
              ),
            )
          : _copy(
              'title',
              style: const TextStyle(
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
              ),
            ),
      const SizedBox(height: 12),
      _copy(
        'subtitle',
        style: const TextStyle(
          fontSize: 23,
          height: 1.35,
          color: learningMuted,
        ),
      ),
      const SizedBox(height: 14),
      _copy(
        'readTime',
        style: const TextStyle(fontSize: 13, color: learningMuted),
      ),
      const SizedBox(height: 32),
      _surface(
        color: _sage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _lessonCopy(
              'learning.lesson.shared.goals',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < 3; i++) _point('goal.$i'),
          ],
        ),
      ),
      _section('core', key: _coreKey, child: _copy('core')),
      _section(
        'example',
        key: _exampleKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _copy(
              'exampleTitle',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _copy('exampleIntro'),
            const SizedBox(height: 22),
            switch (widget.lesson) {
              LearningLesson.roadmap => _roadmapExample(),
              LearningLesson.discover => _discoverExample(),
              LearningLesson.search => _searchExample(),
            },
          ],
        ),
      ),
      _section(
        'mistakes',
        key: _mistakesKey,
        child: Column(
          children: [for (var i = 0; i < 3; i++) _point('mistake.$i')],
        ),
      ),
      _section(
        'check',
        child: Column(
          children: [
            for (var i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Reflection(
                  questionKey: '$_prefix.question.$i',
                  answerKey: '$_prefix.answer.$i',
                ),
              ),
          ],
        ),
      ),
      _section(
        'takeaways',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 2; i++) _point('takeaway.$i'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: ValueKey('lesson-${widget.lesson.name}-next'),
                style: FilledButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                ),
                onPressed: () => widget.onOpen(switch (widget.lesson) {
                  LearningLesson.roadmap => 'discover',
                  LearningLesson.discover => 'search',
                  LearningLesson.search => 'evaluate',
                }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: _copy(
                        'next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      _source(),
    ],
  );

  Widget _section(String id, {Key? key, required Widget child}) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lessonCopy(
          'learning.lesson.shared.$id',
          style: const TextStyle(
            color: learningInk,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _point(String id) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10, right: 12),
          child: Icon(Icons.circle, size: 5, color: _forest),
        ),
        Expanded(child: _copy(id)),
      ],
    ),
  );

  Widget _roadmapExample() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in const [
        (id: 'discover', destination: 'discover'),
        (id: 'search', destination: 'search'),
        (id: 'evaluate', destination: 'evaluate'),
        (id: 'financial', destination: 'financial'),
        (id: 'documents', destination: 'room'),
        (id: 'dealStructure', destination: 'dealStructure'),
        (id: 'transition', destination: 'transition'),
        (id: 'faq', destination: 'faq'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: learningLine),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => widget.onOpen(item.destination),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _lessonCopy(
                            'learning.lesson.syllabus.${item.id}.title',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _lessonCopy(
                            'learning.lesson.syllabus.${item.id}.body',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: learningMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _lessonCopy(
                      'learning.lesson.syllabus.${item.id}.time',
                      style: const TextStyle(
                        fontSize: 12,
                        color: learningMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 17, color: _forest),
                  ],
                ),
              ),
            ),
          ),
        ),
      _lessonCopy(
        'learning.lesson.shared.studyTime',
        style: const TextStyle(fontSize: 13, height: 1.5, color: learningMuted),
      ),
      const SizedBox(height: 24),
      _surface(color: _cream, child: _detail('timingTitle', 'timing')),
      const SizedBox(height: 24),
      _copy(
        'stages',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _stagesKey,
        child: AcquisitionJourneyPanel(
          initialStageId: widget.initialStageId,
          showTitle: false,
        ),
      ),
    ],
  );

  Widget _discoverExample() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _pair([
        _surface(child: _detail('buy.title', 'buy.body')),
        _surface(color: _cream, child: _detail('start.title', 'start.body')),
      ]),
      const SizedBox(height: 26),
      _copy(
        'rolesTitle',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      for (final role in ['operator', 'investor', 'firstTimer'])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _surface(child: _detail('$role.title', '$role.body')),
        ),
    ],
  );

  Widget _searchExample() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _pair([
        for (final lens in ['skills', 'money', 'lifestyle', 'industry'])
          _surface(color: _sage, child: _detail('$lens.title', '$lens.body')),
      ]),
      const SizedBox(height: 24),
      _surface(
        color: _cream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _lessonCopy(
              'learning.lesson.shared.fictional',
              style: const TextStyle(fontSize: 12, color: learningMuted),
            ),
            const SizedBox(height: 10),
            _detail('listingTitle', 'listingBody'),
          ],
        ),
      ),
      const SizedBox(height: 18),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _detail('annotation.$i.title', 'annotation.$i.body'),
        ),
      const SizedBox(height: 8),
      _copy(
        'sourcesTitle',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 18),
      for (final source in ['brokers', 'marketplaces', 'outreach'])
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _detail('$source.title', '$source.body'),
        ),
    ],
  );

  Widget _detail(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _copy(
        title,
        style: const TextStyle(
          fontSize: 17,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: learningInk,
        ),
      ),
      const SizedBox(height: 8),
      _copy(body),
    ],
  );

  Widget _videoPanel() => Column(
    key: ValueKey('lesson-${widget.lesson.name}-video'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _lessonCopy(
        'learning.lesson.shared.video',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: learningMuted,
        ),
      ),
      const SizedBox(height: 12),
      AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _forest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ondemand_video_outlined,
                    color: Color(0xFFCDD9CB),
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  _lessonCopy(
                    'learning.lesson.shared.recording',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '60–90 sec',
                    style: TextStyle(color: Color(0xFFCDD9CB), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _lessonCopy(
        'learning.lesson.shared.videoNote',
        style: const TextStyle(color: learningMuted, fontSize: 13, height: 1.5),
      ),
    ],
  );

  Widget _lessonSupport() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _lessonCopy(
        'learning.lesson.shared.chapters',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < 3; i++)
        TextButton(
          key: ValueKey('lesson-chapter-$i'),
          style: TextButton.styleFrom(
            foregroundColor: _forest,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
          onPressed: () =>
              _readSection([_coreKey, _exampleKey, _mistakesKey][i]),
          child: Row(
            children: [
              const Icon(Icons.subject, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: _copy(
                  'chapter.$i',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.south, size: 15),
            ],
          ),
        ),
      const SizedBox(height: 20),
      _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _lessonCopy(
              'learning.lesson.shared.terms',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _detail('term.$i', 'definition.$i'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
        title: _lessonCopy(
          'learning.lesson.shared.transcript',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        children: [_copy('story')],
      ),
      if (widget.lesson == LearningLesson.search)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ExpansionTile(
            key: const ValueKey('learning-lesson-search-library'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            title: _copy(
              'findLesson',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [LearningStartSearch(onOpen: widget.onSearchResult)],
          ),
        ),
    ],
  );

  Widget _source() {
    final (label, path) = switch (widget.lesson) {
      LearningLesson.roadmap => (
        'BDC · Steps to buying a business',
        'what-are-steps-buying-business',
      ),
      LearningLesson.discover => (
        'BDC · Buying an existing business',
        'pros-cons-buying-business',
      ),
      LearningLesson.search => (
        'BDC · Finding a business to buy',
        'tips-finding-business-buy',
      ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: learningMuted),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          var opened = false;
          try {
            opened = await launchUrl(
              Uri.parse(
                'https://www.bdc.ca/en/articles-tools/start-buy-business/buy-business/$path',
              ),
            );
          } catch (_) {
            opened = false;
          }
          if (!opened && messenger.mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not open this resource. Please try again.',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.open_in_new, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

Widget _lessonCopy(String id, {TextStyle? style}) =>
    SiteCopyText(id, learningLessonCopy[id]!, style: style ?? _bodyStyle);

Widget _surface({required Widget child, Color color = Colors.white}) =>
    Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: learningLine),
      ),
      child: child,
    );

Widget _pair(List<Widget> children) => LayoutBuilder(
  builder: (context, bounds) {
    final columns = bounds.maxWidth >= 560 ? 2 : 1;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final child in children)
          SizedBox(
            width: (bounds.maxWidth - 14 * (columns - 1)) / columns,
            child: child,
          ),
      ],
    );
  },
);

class _Reflection extends StatelessWidget {
  const _Reflection({required this.questionKey, required this.answerKey});

  final String questionKey, answerKey;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: learningLine),
    ),
    child: ExpansionTile(
      key: PageStorageKey(questionKey),
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: _lessonCopy(
        questionKey,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: _lessonCopy(
          'learning.lesson.shared.reveal',
          style: const TextStyle(fontSize: 13, color: learningMuted),
        ),
      ),
      children: [_lessonCopy(answerKey)],
    ),
  );
}
