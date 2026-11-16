import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/design_preview_content.dart';
import '../models/about_story_content.dart';
import '../models/footer_page_content.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/navigation_organizer.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_parallax_image.dart';
import 'dashboard_showcase_page.dart';

const _navy = Color(0xFF0C2331);
const _yellow = Color(0xFFF8DE7E);
const _teal = Color(0xFF008CA3);
const _mint = Color(0xFFAAE1D8);
const _lavender = Color(0xFFD6CEF0);
const _coral = Color(0xFFFA8E76);
const _muted = Color(0xFF476471);
const _accents = [
  _yellow,
  _lavender,
  _mint,
  Color(0xFFA4E0EC),
  _coral,
  _yellow,
];

/// About Pact, retaining the approved animation design and published slot IDs.
class DesignPreviewPage extends StatelessWidget {
  const DesignPreviewPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SiteContentService.editing,
    builder: (context, editing, _) => MediaQuery(
      // The owner requires always-on motion for this preview. Keep the
      // override local; inline editing still holds content steady for selection.
      data: MediaQuery.of(context).copyWith(disableAnimations: editing),
      child: const _DesignPreviewBody(),
    ),
  );
}

class _DesignPreviewBody extends StatefulWidget {
  const _DesignPreviewBody();
  @override
  State<_DesignPreviewBody> createState() => _DesignPreviewBodyState();
}

class _DesignPreviewBodyState extends State<_DesignPreviewBody> {
  final _scroll = ScrollController();
  final _intro = GlobalKey();
  final _gallery = GlobalKey();
  final _projects = List.generate(
    designPreviewImages.length,
    (_) => GlobalKey(),
  );
  int _activeProject = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackProject);
  }

  void _trackProject() {
    var active = 0;
    for (var i = 0; i < _projects.length; i++) {
      final box = _projects[i].currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          box.localToGlobal(Offset.zero).dy <
              View.of(context).physicalSize.height /
                  View.of(context).devicePixelRatio *
                  .5) {
        active = i;
      }
    }
    if (active != _activeProject) setState(() => _activeProject = active);
  }

  void _jump(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: .12,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1100),
      curve: Curves.easeInOutCubic,
    );
  }

  void _dashboards() => Navigator.of(context).push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'dashboards'),
      pageBuilder: (_, _, _) => const DashboardShowcasePage(),
      transitionDuration: const Duration(milliseconds: 550),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    ),
  );

  void _backToTop() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _fallback(String id) {
    final about = FooterTopic.approach.content;
    if (id == 'footer.page.approach.headline') return about.headline;
    if (id == 'footer.page.approach.intro') return about.intro;
    final section = RegExp(
      r'^footer\.page\.approach\.section\.(\d+)\.(title|body|point\.(\d+))$',
    ).firstMatch(id);
    if (section != null) {
      final content = about.sections[int.parse(section[1]!)];
      if (section[2] == 'title') return content.title;
      if (section[2] == 'body') return content.body;
      return content.points[int.parse(section[3]!)];
    }
    return (aboutStoryCopy[id] ?? designPreviewCopy[id])!;
  }

  Widget _copy(
    String id, {
    double size = 18,
    Color color = _navy,
    FontWeight weight = FontWeight.w400,
    double height = 1.35,
  }) => SiteCopyText(
    id,
    _fallback(id),
    style: TextStyle(
      fontFamily: 'PactInter',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: size > 30 ? -size * .045 : -.3,
    ),
  );

  Widget _reveal(Widget child, {int delay = 0}) =>
      _Reveal(scroll: _scroll, delay: delay, child: child);

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(fontFamily: 'PactInter'),
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth >= 1000;
          final mobile = bounds.maxWidth < 600;
          final margin = mobile ? 24.0 : bounds.maxWidth * .09;
          final contentWidth = bounds.maxWidth - margin * 2;
          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(margin, mobile),
                    Container(
                      key: _intro,
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: margin,
                        vertical: mobile ? 88 : 140,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reveal(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 850),
                              child: _copy(
                                'footer.page.approach.headline',
                                size: mobile ? 36 : 54,
                                weight: FontWeight.w600,
                                height: 1.08,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _reveal(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: _copy(
                                'footer.page.approach.intro',
                                size: mobile ? 18 : 22,
                                color: const Color(0xFF476471),
                              ),
                            ),
                            delay: 100,
                          ),
                          const SizedBox(height: 56),
                          _ArrowButton(
                            label: 'preview.scroll',
                            down: true,
                            onTap: () => _jump(_gallery),
                            iconOnly: true,
                            dark: false,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      key: _gallery,
                      padding: EdgeInsets.fromLTRB(
                        margin,
                        mobile ? 88 : 140,
                        margin,
                        mobile ? 88 : 160,
                      ),
                      child: wide
                          ? _desktopGallery(contentWidth)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _galleryIndex(false),
                                const SizedBox(height: 80),
                                ...List.generate(
                                  designPreviewImages.length,
                                  (i) => _project(i, mobile),
                                ),
                              ],
                            ),
                    ),
                    Container(
                      color: const Color(0xFFE9E2F7),
                      padding: EdgeInsets.fromLTRB(margin, 100, margin, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reveal(
                            _copy(
                              'preview.close.eyebrow',
                              size: 13,
                              color: _teal,
                            ),
                          ),
                          const SizedBox(height: 38),
                          _reveal(
                            _copy(
                              'preview.close.title',
                              size: mobile ? 52 : 100,
                              height: 1.02,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _ArrowButton(
                            label: 'preview.close.action',
                            onTap: _dashboards,
                            dark: false,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(margin, 64, margin, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: HomeBrandButton(size: 44, dark: false),
                            ),
                          ),
                          const SizedBox(height: 36),
                          _copy('preview.footer.note', size: 14, color: _muted),
                          const SizedBox(height: 28),
                          _ArrowButton(label: 'preview.top', onTap: _backToTop),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 20,
                left: mobile ? 16 : 36,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: HomeBrandButton(
                      size: 38,
                      showWordmark: !mobile,
                      dark: false,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 20,
                right: mobile ? 12 : 30,
                child: const AppNavigationMenu(
                  guidePage: 'about-us',
                  organizerPalette: NavigationOrganizerPalette(
                    active: _navy,
                    activeText: _yellow,
                    text: _navy,
                    hover: Color(0xFFDDF2EE),
                  ),
                  showPrivateUpdates: false,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _hero(double margin, bool mobile) {
    final viewport = MediaQuery.sizeOf(context);
    final height = math.max(mobile ? 780.0 : 980.0, viewport.height * 1.2);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scroll,
                builder: (context, _) => CustomPaint(
                  painter: _ChevronPainter(
                    offset: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : (_scroll.hasClients ? _scroll.offset * .13 : 0),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                mobile ? 290 : 370,
                margin,
                70,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(
                    _copy(
                      'preview.eyebrow',
                      size: mobile ? 15 : 18,
                      color: _teal,
                      weight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: mobile ? 60 : 100),
                  _reveal(
                    _copy(
                      'preview.hero.first',
                      size: mobile
                          ? 49
                          : (viewport.width * .077).clamp(64, 126),
                      color: _navy,
                      weight: FontWeight.w600,
                      height: 1.06,
                    ),
                    delay: 120,
                  ),
                  _reveal(
                    _copy(
                      'preview.hero.second',
                      size: mobile
                          ? 49
                          : (viewport.width * .077).clamp(64, 126),
                      color: _teal,
                      weight: FontWeight.w600,
                      height: 1.06,
                    ),
                    delay: 260,
                  ),
                  SizedBox(height: mobile ? 90 : 120),
                  _reveal(
                    _ArrowButton(
                      label: 'preview.scroll',
                      down: true,
                      onTap: () => _jump(_intro),
                    ),
                    delay: 400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _galleryIndex(bool vertical) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _reveal(
        _copy(
          'preview.gallery.title',
          size: 32,
          color: _navy,
          weight: FontWeight.w500,
          height: 1.12,
        ),
      ),
      const SizedBox(height: 24),
      _copy('preview.gallery.note', size: 12, color: _muted),
      const SizedBox(height: 48),
      if (vertical)
        ...List.generate(
          designPreviewImages.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IndexLink(
              index: i,
              selected: _activeProject == i,
              onTap: () => _jump(_projects[i]),
            ),
          ),
        )
      else
        Wrap(
          spacing: 28,
          runSpacing: 12,
          children: List.generate(
            designPreviewImages.length,
            (i) => _IndexLink(
              index: i,
              selected: _activeProject == i,
              onTap: () => _jump(_projects[i]),
            ),
          ),
        ),
    ],
  );

  Widget _desktopGallery(double width) => LayoutBuilder(
    builder: (context, _) => Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(right: width * .34),
          child: Column(
            children: List.generate(
              designPreviewImages.length,
              (i) => _project(i, false),
            ),
          ),
        ),
        // Paint-time positioning follows the native scroll after layout.
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: width * .27,
          child: Flow(
            delegate: _StickyIndexFlow(
              _scroll,
              _gallery,
              MediaQuery.disableAnimationsOf(context),
            ),
            children: [_galleryIndex(true)],
          ),
        ),
      ],
    ),
  );

  Widget _approachDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < FooterTopic.approach.content.sections.length; i++)
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: _reveal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy(
                  'footer.page.approach.section.$i.title',
                  size: 24,
                  weight: FontWeight.w600,
                ),
                const SizedBox(height: 12),
                _copy('footer.page.approach.section.$i.body', color: _muted),
                const SizedBox(height: 16),
                for (
                  var j = 0;
                  j < FooterTopic.approach.content.sections[i].points.length;
                  j++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _copy(
                      'footer.page.approach.section.$i.point.$j',
                      size: 14,
                      color: _teal,
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _teamPortraits() => LayoutBuilder(
    builder: (context, box) {
      final narrow = box.maxWidth < 480;
      return Wrap(
        spacing: 18,
        runSpacing: 28,
        children: [
          for (var i = 0; i < 3; i++)
            SizedBox(
              width: narrow ? box.maxWidth : (box.maxWidth - 36) / 3,
              child: _reveal(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AspectRatio(
                        aspectRatio: .8,
                        child: SiteParallaxImage(
                          controller: _scroll,
                          contentKey: 'image.about.team.$i',
                          asset: 'assets/images/pact-team-$i.png',
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _copy(
                      'about.story.team.$i.name',
                      size: 23,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 6),
                    _copy('about.story.team.$i.role', size: 14, color: _muted),
                  ],
                ),
                delay: i * 100,
              ),
            ),
        ],
      );
    },
  );

  Widget _project(int i, bool mobile) => Padding(
    key: _projects[i],
    padding: EdgeInsets.only(bottom: mobile ? 90 : 140),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (i == 2)
          _teamPortraits()
        else
          _reveal(_HoverPhoto(scroll: _scroll, index: i)),
        const SizedBox(height: 30),
        _reveal(
          Container(height: 4, width: 72, color: _accents[i % _accents.length]),
        ),
        const SizedBox(height: 24),
        if (i == 3) ...[
          _reveal(
            _copy(
              'about.story.pledge.amount',
              size: 82,
              color: _teal,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _reveal(
          _copy(
            aboutSectionHeadingIds[i],
            size: mobile ? 38 : 52,
            color: _navy,
            height: 1.08,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        _reveal(
          _copy(aboutSectionBodyIds[i], size: 19, color: _muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (i == 3) ...[
          _reveal(_copy('about.story.pledge.note', size: 15, color: _teal)),
          const SizedBox(height: 14),
          _copy('about.story.photo.credit', size: 11, color: _muted),
        ] else if (i == 4)
          _approachDetails()
        else if (i == 6)
          _ArrowButton(label: 'preview.project.action', onTap: _dashboards),
      ],
    ),
  );
}

/// Viewport-triggered entrances, with final content immediately available to
/// editors. Public preview motion is always enabled by the owner.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.scroll, required this.child, this.delay = 0});
  final ScrollController scroll;
  final Widget child;
  final int delay;
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1250 + widget.delay),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _shown = false;
  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_check);
    SiteContentService.editing.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        SiteContentService.editing.value) {
      _shown = true;
      _motion.value = 1;
      return;
    }
    if (_shown) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    if (box.localToGlobal(Offset.zero).dy <
        View.of(context).physicalSize.height /
            View.of(context).devicePixelRatio *
            .92) {
      _shown = true;
      _motion.forward();
    }
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_check);
    SiteContentService.editing.removeListener(_check);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    child: widget.child,
    builder: (context, child) {
      final value = Curves.easeOutQuart.transform(
        ((_motion.value - widget.delay / (1250 + widget.delay)) /
                (1250 / (1250 + widget.delay)))
            .clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 46),
          child: child,
        ),
      );
    },
  );
}

class _HoverPhoto extends StatefulWidget {
  const _HoverPhoto({required this.scroll, required this.index});
  final ScrollController scroll;
  final int index;
  @override
  State<_HoverPhoto> createState() => _HoverPhotoState();
}

class _HoverPhotoState extends State<_HoverPhoto> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: AspectRatio(
      aspectRatio: 1.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _PreviewMotion(
          scale:
              _hover &&
                  !MediaQuery.disableAnimationsOf(context) &&
                  !SiteContentService.editing.value
              ? 1.035
              : 1,
          duration: const Duration(milliseconds: 750),
          child: SiteParallaxImage(
            controller: widget.scroll,
            contentKey: widget.index == 3
                ? 'image.about.river'
                : widget.index == 1
                ? 'image.about.workshop'
                : widget.index == 6
                ? 'image.about.watershed'
                : 'image.design-preview.project.${widget.index}',
            asset: widget.index == 3
                ? 'assets/images/pact-river.jpg'
                : widget.index == 1
                ? 'assets/images/pact-workshop.jpg'
                : designPreviewImages[widget.index],
            maxTravel: 34,
            scrollFactor: .09,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

class _IndexLink extends StatefulWidget {
  const _IndexLink({
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_IndexLink> createState() => _IndexLinkState();
}

class _IndexLinkState extends State<_IndexLink> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: TextButton(
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        foregroundColor: widget.selected || _hover ? _teal : _navy,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      child: _PreviewMotion(
        offset: _hover && !MediaQuery.disableAnimationsOf(context)
            ? const Offset(8, 0)
            : Offset.zero,
        duration: const Duration(milliseconds: 250),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '0${widget.index + 1}',
              style: const TextStyle(fontSize: 10, color: _teal),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: SiteCopyText(
                'preview.project.${widget.index}.title',
                designPreviewCopy['preview.project.${widget.index}.title']!,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.label,
    required this.onTap,
    this.down = false,
    this.iconOnly = false,
    this.dark = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool down, iconOnly, dark;
  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: TextButton(
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        foregroundColor: _teal,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
      ),
      child: Semantics(
        label: widget.iconOnly ? designPreviewCopy[widget.label] : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.iconOnly) ...[
              Flexible(
                child: SiteCopyText(
                  widget.label,
                  designPreviewCopy[widget.label]!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
            _PreviewMotion(
              offset: _hover && !MediaQuery.disableAnimationsOf(context)
                  ? (widget.down ? const Offset(0, 6) : const Offset(6, 0))
                  : Offset.zero,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                widget.down ? Icons.south : Icons.north_east,
                size: widget.iconOnly ? 30 : 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.offset});
  final double offset;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE4EEED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Quiet architectural herringbone; the generous upper field stays empty.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, size.height * .65, size.width, size.height * .35),
    );
    for (double x = -160; x < size.width + 160; x += 160) {
      for (
        double y = size.height * .55 - 180 + offset % 16;
        y < size.height + 160;
        y += 16
      ) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + 80, y + 80)
            ..lineTo(x + 160, y),
          paint,
        );
      }
    }
    canvas.restore();
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [0, .52, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) =>
      oldDelegate.offset != offset;
}

class _StickyIndexFlow extends FlowDelegate {
  _StickyIndexFlow(this.scroll, this.gallery, this.reduced)
    : super(repaint: Listenable.merge([scroll, SiteContentService.editing]));
  final ScrollController scroll;
  final GlobalKey gallery;
  final bool reduced;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  void paintChildren(FlowPaintingContext context) {
    var travel = 0.0;
    final box = gallery.currentContext?.findRenderObject();
    if (!reduced &&
        !SiteContentService.editing.value &&
        box is RenderBox &&
        box.hasSize) {
      // Convert viewport coordinates into the gallery's local space so the
      // shared AppDisplayScale does not shrink the sticky travel distance.
      final localAnchor = box.globalToLocal(const Offset(0, 110)).dy - 140;
      travel = localAnchor.clamp(
        0.0,
        math.max(
          0.0,
          context.size.height - (context.getChildSize(0)?.height ?? 0),
        ),
      );
    }
    context.paintChild(0, transform: Matrix4.translationValues(0, travel, 0));
  }

  @override
  bool shouldRepaint(_StickyIndexFlow oldDelegate) =>
      oldDelegate.reduced != reduced ||
      oldDelegate.gallery != gallery ||
      oldDelegate.scroll != scroll;
}

/// Preserve full durations even when the platform advertises reduced motion;
/// inline editing can still hold the preview steady for selecting saved copy.
class _PreviewMotion extends StatefulWidget {
  const _PreviewMotion({
    required this.child,
    this.offset = Offset.zero,
    this.scale = 1,
    this.duration = const Duration(milliseconds: 300),
  });
  final Widget child;
  final Offset offset;
  final double scale;
  final Duration duration;
  @override
  State<_PreviewMotion> createState() => _PreviewMotionState();
}

class _PreviewMotionState extends State<_PreviewMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    animationBehavior: AnimationBehavior.preserve,
  )..value = 1;
  Offset _fromOffset = Offset.zero;
  double _fromScale = 1;
  double get _progress => Curves.easeOutCubic.transform(_controller.value);
  Offset get _offset => Offset.lerp(_fromOffset, widget.offset, _progress)!;
  double get _scale => _fromScale + (widget.scale - _fromScale) * _progress;

  @override
  void didUpdateWidget(_PreviewMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offset != widget.offset || oldWidget.scale != widget.scale) {
      final value = _progress;
      _fromOffset = Offset.lerp(_fromOffset, oldWidget.offset, value)!;
      _fromScale += (oldWidget.scale - _fromScale) * value;
      _controller.duration = widget.duration;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: _offset,
      child: Transform.scale(scale: _scale, child: child),
    ),
  );
}
