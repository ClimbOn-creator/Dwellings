import 'dart:math' as math;
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/transaction_learning.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_image.dart';

const _night = Color(0xFF070717);
const _ink = Color(0xFF11111F);
const _blue = Color(0xFF526DFF);
const _paper = Color(0xFFF5F5F7);
const _muted = Color(0xFF5C6074);
const _sectionColors = [Color(0xFFF5F5F7), Color(0xFFFFFFFF)];

class TransactionLearningPage extends StatefulWidget {
  const TransactionLearningPage({super.key});

  @override
  State<TransactionLearningPage> createState() =>
      _TransactionLearningPageState();
}

class _TransactionLearningPageState extends State<TransactionLearningPage> {
  final _scroll = ScrollController();
  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _messages = [
    'Understand the purpose',
    'Explore a worked example',
    'Download your editable file',
  ];

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted)
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _download(
    BuildContext context,
    TransactionLesson lesson,
    bool example,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await rootBundle.load(lesson.assetPath(filled: example));
      await FilePicker.platform.saveFile(
        dialogTitle:
            'Save ${example ? "completed example" : "editable template"}',
        fileName: lesson.fileName(filled: example),
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not download the ${lesson.fileTypeLabel} file. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _lessonSections(_scroll).toList();
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HomeBrandButton(size: 48, dark: false),
            if (MediaQuery.sizeOf(context).width >= 620) ...[
              const SizedBox(width: 18),
              const Text(
                'DOCUMENT GUIDES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
        actions: const [AppNavigationMenu(dark: false)],
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _hero(context, _scroll)),
          const SliverToBoxAdapter(child: _Orientation()),
          SliverList.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) => sections[index],
          ),
          SliverToBoxAdapter(child: _closing()),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, ScrollController scroll) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SizedBox(
      height: compact ? 640 : 440,
      child: _TransactionParallaxImage(
        controller: scroll,
        contentKey: 'image.transaction.hero',
        asset: 'assets/images/affinity-deal-screen.jpg',
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xB9070717)),
          child: Stack(
            children: [
              Positioned(
                right: compact ? -170 : -80,
                top: -190,
                child: Container(
                  width: compact ? 370 : 540,
                  height: compact ? 370 : 540,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue.withValues(alpha: .16),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 24 : 54,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(
                          child: const SiteCopyText(
                            'transaction.library.kicker',
                            'LEARN · PREPARE · APPLY',
                            style: TextStyle(
                              color: _night,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SiteCopyText(
                          'transaction.library.title',
                          'The deal,\nmade clear.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 46 : 58,
                            height: .98,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 730),
                          child: const SiteCopyText(
                            'transaction.library.intro',
                            'Understand each document, see how it works, and take the next step with confidence.',
                            style: TextStyle(
                              color: Color(0xFFEAEAF3),
                              fontSize: 17,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 30,
                          child: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 550),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, .35),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Text(
                              _messages[_messageIndex],
                              key: ValueKey(_messageIndex),
                              style: const TextStyle(
                                color: Color(0xFFBFC9FF),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _HeroFact(
                              icon: Icons.description_outlined,
                              label: '11 DOCUMENT GUIDES',
                            ),
                            _HeroFact(
                              icon: Icons.edit_document,
                              label: 'WORD + EXCEL DOWNLOADS',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pill({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
    ),
    child: child,
  );

  Iterable<Widget> _lessonSections(ScrollController scroll) sync* {
    var lessonIndex = 0;
    final stages = transactionLessons.map((lesson) => lesson.stage).toSet();
    for (final stage in stages) {
      yield _stageBanner(stage);
      for (final lesson in transactionLessons.where(
        (item) => item.stage == stage,
      )) {
        final index = lessonIndex++;
        yield _lessonSection(lesson, index, scroll);
      }
    }
  }

  Widget _stageBanner(String stage) => Container(
    color: _night,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Row(
          children: [
            Container(width: 38, height: 4, color: _blue),
            const SizedBox(width: 15),
            Expanded(
              child: SiteCopyText(
                'transaction.stage.${stage.split(" · ").first}',
                stage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _lessonSection(
    TransactionLesson lesson,
    int index,
    ScrollController scroll,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 860;
      final preview = _preview(lesson, scroll, compact);
      final guide = _lessonGuide(context, lesson, index);
      final children = index.isEven ? [preview, guide] : [guide, preview];
      return ColoredBox(
        color: _sectionColors[index % _sectionColors.length],
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 50,
                vertical: compact ? 54 : 90,
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [guide, const SizedBox(height: 34), preview],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: children.first),
                        const SizedBox(width: 58),
                        Expanded(child: children.last),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );

  Widget _preview(
    TransactionLesson lesson,
    ScrollController scroll,
    bool compact,
  ) => Container(
    height: compact
        ? (lesson.fileExtension == 'docx' ? 520 : 390)
        : (lesson.fileExtension == 'docx' ? 610 : 500),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26070717),
          blurRadius: 35,
          offset: Offset(0, 18),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: _TransactionParallaxImage(
      controller: scroll,
      contentKey: 'image.transaction.${lesson.id}.preview',
      asset: lesson.previewAsset,
      fit: BoxFit.contain,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 66,
            child: ColoredBox(color: Color(0xC9070717)),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.white),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'FICTIONAL WORKED EXAMPLE · ${lesson.fileTypeLabel.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _lessonGuide(
    BuildContext context,
    TransactionLesson lesson,
    int index,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _night,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${lesson.fileTypeLabel.toUpperCase()} · .${lesson.fileExtension}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: TextStyle(
              color: _ink.withValues(alpha: .45),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      SiteCopyText(
        'transaction.${lesson.id}.title',
        lesson.title,
        style: const TextStyle(
          color: _ink,
          fontSize: 38,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
        ),
      ),
      const SizedBox(height: 24),
      _guideBlock(
        'WHAT IT IS',
        'transaction.${lesson.id}.purpose',
        lesson.purpose,
      ),
      _guideBlock(
        'WHEN TO USE IT',
        'transaction.${lesson.id}.when',
        lesson.whenToUse,
      ),
      _guideBlock(
        'WHAT THE BUYER COMPLETES',
        'transaction.${lesson.id}.complete',
        lesson.whatToComplete,
      ),
      _guideBlock(
        'WHO SHOULD REVIEW IT',
        'transaction.${lesson.id}.review',
        lesson.reviewedBy,
      ),
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4, bottom: 22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _night,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BUYER WATCH-OUT',
              style: TextStyle(
                color: const Color(0xFFAEBBFF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SiteCopyText(
              'transaction.${lesson.id}.watchout',
              lesson.buyerWatchOut,
              style: const TextStyle(color: Color(0xFFEAEAEE), height: 1.45),
            ),
          ],
        ),
      ),
      Text(
        'The blank file uses the same structure as the example, so you can replace the fictional data with your deal facts.',
        style: TextStyle(color: _ink.withValues(alpha: .65), height: 1.4),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _ink),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onPressed: () => _download(context, lesson, true),
            icon: const Icon(Icons.image_outlined),
            label: const SiteCopyText(
              'transaction.action.example',
              'DOWNLOAD WORKED EXAMPLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onPressed: () => _download(context, lesson, false),
            icon: const Icon(Icons.download_rounded),
            label: const SiteCopyText(
              'transaction.action.template',
              'DOWNLOAD EDITABLE TEMPLATE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ],
  );

  static Widget _guideBlock(String label, String keyName, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            SiteCopyText(
              keyName,
              text,
              style: const TextStyle(
                color: _muted,
                height: 1.52,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      );

  Widget _closing() => Container(
    color: _night,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 84),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Column(
          children: [
            const SiteCopyText(
              'transaction.closing.title',
              'Prepared is not the same as advised.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
              ),
            ),
            const SizedBox(height: 18),
            const SiteCopyText(
              'transaction.library.scope',
              'These editable tools help you organize facts, requests, calculations and adviser questions. They are not contracts, legal or tax advice, lender approval, a valuation, or verified transaction evidence. Confirm deal-specific decisions with qualified legal, accounting, tax and financing professionals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD7D7E2),
                fontSize: 17,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'PUBLIC LEARNING RESOURCE · NO SIGN-IN REQUIRED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'REFERENCE GUIDANCE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.bdc.ca/en/articles-tools/start-buy-business/buy-business/buying-business-conducting-due-diligence',
                    ),
                  ),
                  child: const Text('BDC · Due diligence'),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.sba.gov/counseling/plan-your-business/#buy-an-existing-business-or-franchise',
                    ),
                  ),
                  child: const Text('SBA · Buying an existing business'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white38),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}

/// A composited transform keeps the preview in the normal paint tree.
/// The shared Flow-based effect can drop an entire long web frame when an
/// off-screen section repaints, so this page uses a bounded image translation.
class _TransactionParallaxImage extends StatelessWidget {
  const _TransactionParallaxImage({
    required this.controller,
    required this.contentKey,
    required this.asset,
    required this.child,
    this.fit = BoxFit.cover,
  });

  final ScrollController controller;
  final String contentKey;
  final String asset;
  final Widget child;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      children: [
        Positioned.fill(
          top: -26,
          bottom: -26,
          child: AnimatedBuilder(
            animation: controller,
            child: SiteImage(
              contentKey: contentKey,
              original: Image.asset(asset, fit: fit),
            ),
            builder: (context, image) {
              final offset = controller.hasClients ? controller.offset : 0.0;
              final travel = MediaQuery.disableAnimationsOf(context)
                  ? 0.0
                  : math.sin(offset / 560) * 20;
              return Transform.translate(
                offset: Offset(0, travel),
                child: image,
              );
            },
          ),
        ),
        child,
      ],
    ),
  );
}

class _Orientation extends StatelessWidget {
  const _Orientation();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 780;
    const cards = [
      (
        '01',
        'Understand the role',
        'Read what the item proves, the point in the deal when it becomes useful, and the decisions it should support.',
      ),
      (
        '02',
        'Inspect a worked example',
        'Scroll the completed fictional preview to understand the expected structure before opening the editable file.',
      ),
      (
        '03',
        'Build your version',
        'Replace placeholders with sourced facts, preserve evidence links, mark assumptions, and route open questions to the right adviser.',
      ),
    ];
    return ColoredBox(
      color: _paper,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 50,
          vertical: compact ? 62 : 90,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SiteCopyText(
                  'transaction.orientation.kicker',
                  'A BUYER’S WORKING LIBRARY',
                  style: TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                const SiteCopyText(
                  'transaction.orientation.title',
                  'Use the right document at the right moment.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 46,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 810),
                  child: const SiteCopyText(
                    'transaction.orientation.intro',
                    'A good transaction room does more than store files. It tells a first-time buyer what each item is for, where its information comes from, who should challenge it, and what not to assume from it.',
                    style: TextStyle(color: _muted, fontSize: 18, height: 1.5),
                  ),
                ),
                const SizedBox(height: 42),
                if (compact)
                  for (final card in cards) ...[
                    _orientationCard(card.$1, card.$2, card.$3),
                    const SizedBox(height: 14),
                  ]
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(
                          child: _orientationCard(
                            cards[i].$1,
                            cards[i].$2,
                            cards[i].$3,
                          ),
                        ),
                        if (i < cards.length - 1) const SizedBox(width: 14),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _orientationCard(String number, String title, String body) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x11070717)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(color: _muted, height: 1.5)),
          ],
        ),
      );
}
