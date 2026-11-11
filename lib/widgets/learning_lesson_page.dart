import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/learning_lesson_content.dart';
import 'acquisition_journey_panel.dart';
import 'learning_start_search.dart';
import 'learning_activity_ui.dart';
import 'learning_trail.dart';
import 'learning_two_saturdays.dart';
import 'learning_listing_swipe.dart';
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
  final _scroll = ScrollController();
  final _videoKey = GlobalKey();
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
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => SingleChildScrollView(
      controller: _scroll,
      key: ValueKey('learning-workspace-${widget.lesson.name}-'),
      padding: EdgeInsets.fromLTRB(
        bounds.maxWidth < 700 ? 18 : 36,
        32,
        bounds.maxWidth < 700 ? 18 : 36,
        48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 26),
              creativeCopy('${widget.lesson.name}.intro'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final link in [
                    (slot: 'try', target: _exampleKey),
                    (slot: 'watch', target: _videoKey),
                    (slot: 'read', target: _coreKey),
                  ])
                    TextButton(
                      onPressed: () => _readSection(link.target),
                      child: creativeCopy(
                        'shared.${link.slot}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              switch (widget.lesson) {
                LearningLesson.roadmap => _trailPage(),
                LearningLesson.discover => _saturdaysPage(),
                LearningLesson.search => _swipePage(),
              },
              const SizedBox(height: 34),
              _finish(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _copy(
        'eyebrow',
        style: const TextStyle(
          fontSize: 12,
          color: _forest,
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
                fontSize: 18,
                color: learningMuted,
                fontWeight: FontWeight.w500,
              ),
            )
          : _copy(
              'title',
              style: const TextStyle(fontSize: 18, color: learningMuted),
            ),
      const SizedBox(height: 6),
      creativeCopy(
        '${widget.lesson.name}.activity',
        style: const TextStyle(
          fontSize: 46,
          height: 1.1,
          letterSpacing: -1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      _copy(
        'subtitle',
        style: const TextStyle(fontSize: 20, height: 1.4, color: learningMuted),
      ),
    ],
  );

  Widget _trailPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KeyedSubtree(
        key: _exampleKey,
        child: LearningTrail(controller: _scroll, onOpen: widget.onOpen),
      ),
      const SizedBox(height: 40),
      _videoPanel(hero: true),
      const SizedBox(height: 28),
      _columns(_reading(_roadmapExample()), _lessonSupport(), wideAt: 940),
    ],
  );

  Widget _saturdaysPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KeyedSubtree(key: _exampleKey, child: const LearningTwoSaturdays()),
      const SizedBox(height: 42),
      _columns(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _videoPanel(),
            const SizedBox(height: 22),
            _lessonSupport(),
          ],
        ),
        _reading(_discoverExample()),
        wideAt: 940,
        leftFlex: 4,
        rightFlex: 7,
      ),
    ],
  );

  Widget _swipePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _columns(
        KeyedSubtree(key: _exampleKey, child: const LearningListingSwipe()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _videoPanel(),
            const SizedBox(height: 22),
            _lessonSupport(),
          ],
        ),
        wideAt: 940,
      ),
      const SizedBox(height: 42),
      _reading(_searchExample()),
    ],
  );

  Widget _columns(
    Widget left,
    Widget right, {
    required double wideAt,
    int leftFlex = 7,
    int rightFlex = 4,
  }) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= wideAt
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 36),
              Expanded(flex: rightFlex, child: right),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 28), right],
          ),
  );

  Widget _reading(Widget example) => Column(
    key: ValueKey('lesson-${widget.lesson.name}-text'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      creativeCopy(
        '${widget.lesson.name}.reading',
        style: const TextStyle(
          fontSize: 28,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 18),
      KeyedSubtree(key: _coreKey, child: _copy('core')),
      const SizedBox(height: 24),
      example,
      const SizedBox(height: 20),
      _moreNotes(),
      const SizedBox(height: 16),
      _source(),
    ],
  );

  Widget _moreNotes() => ExpansionTile(
    key: _mistakesKey,
    tilePadding: EdgeInsets.zero,
    title: creativeCopy(
      'shared.more',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    children: [
      _lessonCopy(
        'learning.lesson.shared.goals',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < 3; i++) _point('goal.$i'),
      _section(
        'mistakes',
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
          children: [for (var i = 0; i < 2; i++) _point('takeaway.$i')],
        ),
      ),
    ],
  );

  Widget _finish() => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.icon(
      key: ValueKey('lesson-${widget.lesson.name}-next'),
      style: FilledButton.styleFrom(
        backgroundColor: _forest,
        padding: const EdgeInsets.all(20),
      ),
      onPressed: () => widget.onOpen(switch (widget.lesson) {
        LearningLesson.roadmap => 'discover',
        LearningLesson.discover => 'search',
        LearningLesson.search => 'evaluate',
      }),
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: _copy(
        'next',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
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
      _copy(
        'exampleTitle',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      _copy('exampleIntro'),
      const SizedBox(height: 22),
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

  Widget _videoPanel({bool hero = false}) => KeyedSubtree(
    key: _videoKey,
    child: Column(
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
          aspectRatio: hero && MediaQuery.sizeOf(context).width >= 900
              ? 3
              : 16 / 9,
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
                    creativeCopy(
                      'shared.videoDuration',
                      style: const TextStyle(
                        color: Color(0xFFCDD9CB),
                        fontSize: 13,
                      ),
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
          style: const TextStyle(
            color: learningMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
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
              _readSection([_exampleKey, _coreKey, _mistakesKey][i]),
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
      _lessonCopy(
        'learning.lesson.shared.terms',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      creativeCopy(
        'shared.terms',
        style: const TextStyle(fontSize: 14, color: learningMuted),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < 3; i++)
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          title: _copy(
            'term.$i',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [_copy('definition.$i')],
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
