import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/x2_landing_content.dart';
import '../models/footer_page_content.dart';
import '../services/app_tunnel.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/navigation_organizer.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_parallax_image.dart';
import '../widgets/x2_motion.dart';
import 'dashboard_showcase_page.dart';
import 'design_preview_page.dart';
import 'footer_information_page.dart';
import 'learning_dashboard_page.dart';
import 'acquisition_support_page.dart';
import 'buyer_resources_page.dart';

const _black = Color(0xFF050505);
const _purple = Color(0xFF6241F5);
const _pale = Color(0xFFF5F4F7);
const _ink = Color(0xFF121212);
const _muted = Color(0xFF77767C);
const _lavender = Color(0xFFE2D1F7);

Widget _text(
  String id, {
  double size = 18,
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.4,
  TextAlign? align,
}) => SiteCopyText(
  id,
  x2LandingCopy[id]!,
  textAlign: align,
  style: TextStyle(
    fontFamily: 'RevioInterTight',
    fontSize: size,
    height: height,
    letterSpacing: size >= 30 ? -size * .025 : -.15,
    color: color,
    fontWeight: weight,
  ),
);

/// Separate candidate homepage. Existing published slots and Home remain intact.
class X2LandingPage extends StatelessWidget {
  const X2LandingPage({super.key});
  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: const _X2Body(),
  );
}

class _X2Body extends StatefulWidget {
  const _X2Body();
  @override
  State<_X2Body> createState() => _X2BodyState();
}

class _X2BodyState extends State<_X2Body> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _features = GlobalKey();
  final _roles = GlobalKey();
  final _carousel = PageController(viewportFraction: .86);
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
    animationBehavior: AnimationBehavior.preserve,
  )..repeat();
  int _tab = 0;
  int _role = 0;
  int _carouselBeat = 0;
  bool _readingCarousel = false;

  @override
  void initState() {
    super.initState();
    _ambient.addListener(_advanceRole);
    SiteContentService.editing.addListener(_editing);
    _editing();
  }

  void _advanceRole() {
    final beat = (_ambient.lastElapsedDuration?.inSeconds ?? 0) ~/ 7;
    if (beat == _carouselBeat) return;
    _carouselBeat = beat;
    if (_readingCarousel ||
        SiteContentService.editing.value ||
        !_carousel.hasClients)
      return;
    final box = _roles.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewport =
        View.of(context).physicalSize.height /
        View.of(context).devicePixelRatio;
    if (top < viewport - 140 && top + box.size.height > 140) {
      _carousel.animateToPage(
        (_role + 1) % 4,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _editing() {
    if (SiteContentService.editing.value) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    SiteContentService.editing.removeListener(_editing);
    _ambient.dispose();
    _scroll.dispose();
    _carousel.dispose();
    super.dispose();
  }

  Widget _reveal(Widget child, {int delay = 0}) =>
      X2Reveal(scroll: _scroll, delay: delay, child: child);
  void _jump(GlobalKey key) {
    final target = key.currentContext;
    if (target != null)
      Scrollable.ensureVisible(
        target,
        alignment: .12,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
      );
  }

  void _open(Widget page) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 650),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
        child: child,
      ),
    ),
  );
  void _dashboards() {
    AppTunnelController.select(AppTunnel.landing);
    _open(const DashboardShowcasePage(openDashboardMenu: true));
  }

  void _learn() {
    AppTunnelController.select(AppTunnel.learning);
    _open(const LearningDashboardPage());
  }

  Widget _badge(String id, {bool dark = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.verified_outlined,
        size: 17,
        color: dark ? _lavender : _purple,
      ),
      const SizedBox(width: 10),
      Flexible(
        child: _text(
          id,
          size: 16,
          color: dark ? const Color(0xFFBDB9C4) : _purple,
        ),
      ),
    ],
  );
  Widget _button(
    String id,
    VoidCallback onTap, {
    bool secondary = false,
    bool dark = false,
  }) => X2Hover(
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: secondary ? Colors.transparent : _purple,
        foregroundColor: secondary
            ? (dark ? const Color(0xFFBDB9C4) : _ink)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _text(
              id,
              size: 17,
              color: secondary
                  ? (dark ? const Color(0xFFBDB9C4) : _ink)
                  : Colors.white,
            ),
          ),
          if (!secondary) ...[
            const SizedBox(width: 14),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ],
      ),
    ),
  );
  Widget _section(
    Widget child, {
    Color color = Colors.white,
    double vertical = 140,
  }) => ColoredBox(
    color: color,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 700 ? 24 : 50,
        vertical: MediaQuery.sizeOf(context).width < 700
            ? vertical * .65
            : vertical,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: child,
        ),
      ),
    ),
  );
  Widget _split(
    Widget left,
    Widget right, {
    double gap = 80,
    int leftFlex = 1,
    int rightFlex = 1,
  }) => MediaQuery.sizeOf(context).width < 1000
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: gap * .7),
            right,
          ],
        )
      : Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
  Widget _float(
    Widget child, {
    double phase = 0,
    double travel = 14,
    double turn = 0,
  }) => AnimatedBuilder(
    animation: _ambient,
    child: child,
    builder: (_, child) {
      final p = _ambient.value * math.pi * 6 + phase;
      return Transform.translate(
        offset: Offset(math.sin(p * .5) * travel * .3, math.sin(p) * travel),
        child: Transform.rotate(angle: math.sin(p) * turn, child: child),
      );
    },
  );
  Widget _panel(Widget child, {Color color = _pale, double padding = 36}) =>
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(
        context,
      ).textTheme.apply(fontFamily: 'RevioInterTight'),
    ),
    child: Scaffold(
      backgroundColor: _black,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(),
                _featureOverview(),
                _coreFeatures(),
                _mobile(),
                _workflowTabs(),
                _orbit(),
                _security(),
                _roleCarousel(),
                _resources(),
                _closing(),
                _footer(),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 18,
            left: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: HomeBrandButton(size: 38, dark: false),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 18,
            right: 20,
            child: const AppNavigationMenu(
              guidePage: 'x2',
              showPrivateUpdates: false,
              organizerPalette: NavigationOrganizerPalette(
                active: _purple,
                activeText: Colors.white,
                text: _ink,
                hover: Color(0xFFECE6FF),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _hero() {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return _section(
      Column(
        children: [
          _reveal(
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              runSpacing: 14,
              children: [
                _badge('x2.hero.badge', dark: true),
                _badge('x2.hero.audience', dark: true),
              ],
            ),
          ),
          const SizedBox(height: 52),
          _reveal(
            _text(
              'x2.hero.title',
              size: mobile ? 52 : 84,
              color: Colors.white,
              weight: FontWeight.w600,
              height: 1.08,
              align: TextAlign.center,
            ),
            delay: 140,
          ),
          const SizedBox(height: 44),
          _reveal(
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                _button('x2.hero.primary', _dashboards),
                _button(
                  'x2.hero.secondary',
                  () => _jump(_features),
                  secondary: true,
                  dark: true,
                ),
              ],
            ),
            delay: 260,
          ),
          const SizedBox(height: 86),
          _reveal(
            SizedBox(
              height: mobile ? 340 : 450,
              child: LayoutBuilder(
                builder: (_, box) {
                  final width = box.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 10,
                        child: SizedBox(
                          width: mobile ? 250 : 430,
                          height: mobile ? 250 : 430,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _TokenPainter(_ambient),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: mobile ? 0 : width * .1,
                        top: 24,
                        child: SizedBox(
                          width: mobile ? width * .7 : 490,
                          child: _float(
                            _workspaceCard(dark: true),
                            phase: .3,
                            travel: 18,
                            turn: .012,
                          ),
                        ),
                      ),
                      Positioned(
                        right: mobile ? 0 : width * .09,
                        top: mobile ? 210 : 50,
                        child: SizedBox(
                          width: mobile ? width * .7 : 365,
                          child: _float(_statusCard(), phase: 2.2, travel: 22),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            delay: 360,
          ),
          const SizedBox(height: 28),
          _text('x2.hero.caption', size: 12, color: const Color(0xFF8E8995)),
        ],
      ),
      color: _black,
      vertical: mobile ? 160 : 250,
    );
  }

  Widget _featureOverview() => _section(
    Container(
      key: _features,
      child: Column(
        children: [
          _reveal(
            _text(
              'x2.features.title',
              size: 46,
              weight: FontWeight.w600,
              align: TextAlign.center,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 84),
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > 850;
              final features = List.generate(
                4,
                (i) => _reveal(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconTile(
                        [
                          Icons.explore_outlined,
                          Icons.auto_stories_outlined,
                          Icons.insights_outlined,
                          Icons.hub_outlined,
                        ][i],
                      ),
                      const SizedBox(height: 24),
                      _text(
                        'x2.feature.$i.title',
                        size: 23,
                        weight: FontWeight.w600,
                      ),
                      const SizedBox(height: 12),
                      _text('x2.feature.$i.body', size: 18, color: _muted),
                    ],
                  ),
                  delay: (i % 2) * 130,
                ),
              );
              if (!wide)
                return Wrap(
                  spacing: 36,
                  runSpacing: 52,
                  children: [
                    for (var i = 0; i < 4; i++)
                      SizedBox(
                        width: box.maxWidth < 500
                            ? box.maxWidth
                            : (box.maxWidth - 36) / 2,
                        child: features[i],
                      ),
                  ],
                );
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        features[0],
                        const SizedBox(height: 58),
                        features[1],
                      ],
                    ),
                  ),
                  const SizedBox(width: 70),
                  SizedBox(
                    width: 300,
                    height: 360,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              color: _pale,
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _TokenPainter(_ambient),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 70),
                  Expanded(
                    child: Column(
                      children: [
                        features[2],
                        const SizedBox(height: 58),
                        features[3],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _coreFeatures() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(_badge('x2.core.badge')),
        const SizedBox(height: 32),
        _reveal(
          _text(
            'x2.core.title',
            size: 64,
            weight: FontWeight.w600,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 24),
        _reveal(_text('x2.core.body', size: 21, color: _muted)),
        const SizedBox(height: 70),
        _reveal(
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SiteParallaxImage(
              controller: _scroll,
              contentKey: 'image.x2.core.background',
              asset: 'assets/images/affinity-reflection-facade.jpg',
              maxTravel: 55,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xF0050505),
                      Color(0x99050505),
                      Color(0x44050505),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(52),
                child: _split(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        'x2.banner.title',
                        size: 46,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        height: 1.15,
                      ),
                      const SizedBox(height: 24),
                      _text(
                        'x2.banner.body',
                        size: 20,
                        color: const Color(0xFFD0CBD8),
                      ),
                      const SizedBox(height: 68),
                      _button('x2.banner.action', _dashboards),
                    ],
                  ),
                  _float(_scheduleCard(), phase: 1.1, travel: 13),
                  gap: 70,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _split(
          _reveal(
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 330,
                    child: Center(
                      child: _float(
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: 340, child: _toolsCard()),
                        ),
                        phase: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _text('x2.tools.0.title', size: 30, weight: FontWeight.w500),
                  const SizedBox(height: 14),
                  _text('x2.tools.0.body', color: _muted),
                ],
              ),
            ),
          ),
          _reveal(
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 330,
                    child: Center(
                      child: _float(
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: 340, child: _statusCard()),
                        ),
                        phase: 2.5,
                        travel: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _text('x2.tools.1.title', size: 30, weight: FontWeight.w500),
                  const SizedBox(height: 14),
                  _text('x2.tools.1.body', color: _muted),
                ],
              ),
            ),
            delay: 140,
          ),
          gap: 22,
          leftFlex: 7,
          rightFlex: 5,
        ),
      ],
    ),
    vertical: 110,
  );

  Widget _mobile() => _section(
    _split(
      _reveal(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _badge('x2.mobile.badge', dark: true),
            const SizedBox(height: 36),
            _text(
              'x2.mobile.title',
              size: 70,
              color: Colors.white,
              height: 1.1,
              weight: FontWeight.w600,
            ),
            const SizedBox(height: 26),
            _text('x2.mobile.body', size: 21, color: const Color(0xFFA7A2AD)),
            const SizedBox(height: 60),
            for (var i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i == 0 ? Icons.space_dashboard_outlined : Icons.tune,
                      size: 26,
                      color: _lavender,
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _text(
                            'x2.mobile.$i.title',
                            size: 23,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          _text(
                            'x2.mobile.$i.body',
                            color: const Color(0xFFA7A2AD),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _button('x2.hero.primary', _dashboards),
          ],
        ),
      ),
      _reveal(
        Center(child: _float(_phone(), phase: 1.5, travel: 18)),
        delay: 180,
      ),
      gap: 110,
    ),
    color: _black,
    vertical: 160,
  );

  Widget _workflowTabs() => _section(
    Column(
      children: [
        _reveal(
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _pale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: TextButton(
                          key: ValueKey('x2-workflow-tab-$i'),
                          onPressed: () => setState(() => _tab = i),
                          style: TextButton.styleFrom(
                            backgroundColor: _tab == i
                                ? Colors.white
                                : Colors.transparent,
                            foregroundColor: _tab == i ? _ink : _muted,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (box.maxWidth > 600) ...[
                                _iconTile(
                                  [
                                    Icons.search,
                                    Icons.storefront,
                                    Icons.work_outline,
                                  ][i],
                                  size: 38,
                                ),
                                const SizedBox(width: 14),
                              ],
                              Flexible(
                                child: _text(
                                  'x2.tab.$i',
                                  size: box.maxWidth < 500 ? 16 : 20,
                                  weight: _tab == i
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
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
        ),
        const SizedBox(height: 76),
        _split(
          _TabTransition(
            index: _tab,
            child: Column(
              key: ValueKey(_tab),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge('x2.tab.$_tab.badge'),
                const SizedBox(height: 32),
                _text(
                  'x2.tab.$_tab.title',
                  size: 48,
                  weight: FontWeight.w600,
                  height: 1.15,
                ),
                const SizedBox(height: 24),
                _text('x2.tab.$_tab.body', size: 21, color: _muted),
                const SizedBox(height: 40),
                _button('x2.hero.primary', _dashboards),
              ],
            ),
          ),
          _reveal(
            _panel(
              SizedBox(
                height: 450,
                child: Center(child: _float(_stackedCards(), phase: .9)),
              ),
              padding: 24,
            ),
          ),
          gap: 90,
          leftFlex: 5,
          rightFlex: 7,
        ),
      ],
    ),
  );

  Widget _orbit() => _section(
    Column(
      children: [
        _reveal(
          _text(
            'x2.orbit.title',
            size: 70,
            align: TextAlign.center,
            height: 1.12,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 28),
        _reveal(
          _text(
            'x2.orbit.body',
            color: _muted,
            align: TextAlign.center,
            size: 21,
          ),
        ),
        const SizedBox(height: 54),
        _reveal(
          SizedBox(
            height: 430,
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: SizedBox(
                  width: math.min(960, box.maxWidth),
                  height: 430,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: _OrbitPainter(_ambient)),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x336241F5),
                              blurRadius: 50,
                              spreadRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.north_east,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    color: _pale,
    vertical: 150,
  );

  Widget _security() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(_badge('x2.security.badge', dark: true)),
        const SizedBox(height: 36),
        _split(
          _reveal(
            _text(
              'x2.security.title',
              size: 68,
              weight: FontWeight.w600,
              height: 1.12,
              color: Colors.white,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _reveal(_button('x2.hero.primary', _dashboards)),
          ),
          gap: 50,
          leftFlex: 3,
        ),
        const SizedBox(height: 78),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 36,
            runSpacing: 42,
            children: [
              for (var i = 0; i < 3; i++)
                SizedBox(
                  width: box.maxWidth < 800
                      ? box.maxWidth
                      : (box.maxWidth - 72) / 3,
                  child: _reveal(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Colors.white.withValues(alpha: .2)),
                        const SizedBox(height: 24),
                        Icon(
                          [
                            Icons.explore_outlined,
                            Icons.question_answer_outlined,
                            Icons.favorite_border,
                          ][i],
                          color: _lavender,
                          size: 34,
                        ),
                        const SizedBox(height: 34),
                        _text(
                          'x2.security.$i.title',
                          size: 29,
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                        const SizedBox(height: 18),
                        _text(
                          'x2.security.$i.body',
                          color: const Color(0xFFA7A2AD),
                          size: 20,
                        ),
                      ],
                    ),
                    delay: i * 130,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 70),
        Divider(color: Colors.white.withValues(alpha: .2)),
        const SizedBox(height: 30),
        _text('x2.security.note', size: 20, color: const Color(0xFFA7A2AD)),
      ],
    ),
    color: _black,
    vertical: 145,
  );

  Widget _roleCarousel() => _section(
    MouseRegion(
      onEnter: (_) => _readingCarousel = true,
      onExit: (_) => _readingCarousel = false,
      child: Container(
        key: _roles,
        child: Column(
          children: [
            _reveal(_badge('x2.carousel.badge')),
            const SizedBox(height: 32),
            _reveal(
              _text(
                'x2.carousel.title',
                size: 56,
                weight: FontWeight.w600,
                align: TextAlign.center,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 70),
            _reveal(
              SizedBox(
                height: MediaQuery.sizeOf(context).width < 700 ? 560 : 500,
                child: PageView.builder(
                  controller: _carousel,
                  itemCount: 4,
                  onPageChanged: (value) => setState(() => _role = value),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: X2Hover(
                      child: _panel(
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _iconTile(
                                [
                                  Icons.search,
                                  Icons.storefront,
                                  Icons.work_outline,
                                  Icons.school_outlined,
                                ][i],
                                size: 60,
                              ),
                              const SizedBox(height: 40),
                              _text(
                                'x2.role.$i.title',
                                size: 36,
                                weight: FontWeight.w500,
                              ),
                              const SizedBox(height: 18),
                              _text('x2.role.$i.body', size: 20, color: _muted),
                              const SizedBox(height: 24),
                              _button(
                                'x2.role.action',
                                i == 3 ? _learn : _dashboards,
                                secondary: true,
                              ),
                            ],
                          ),
                        ),
                        color: i.isEven ? _pale : const Color(0xFFF1EAFA),
                        padding: MediaQuery.sizeOf(context).width < 700
                            ? 26
                            : 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous perspective',
                  onPressed: () => _carousel.animateToPage(
                    (_role - 1).clamp(0, 3),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubic,
                  ),
                  icon: const Icon(Icons.west),
                ),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: _role == i ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _role == i ? _purple : const Color(0xFFDBD8E4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Next perspective',
                  onPressed: () => _carousel.animateToPage(
                    (_role + 1).clamp(0, 3),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOutCubic,
                  ),
                  icon: const Icon(Icons.east),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _resources() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(_badge('x2.resources.badge')),
        const SizedBox(height: 32),
        _reveal(
          _text(
            'x2.resources.title',
            size: 70,
            height: 1.12,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 65),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 28,
            runSpacing: 42,
            children: [
              for (var i = 0; i < 3; i++)
                SizedBox(
                  width: box.maxWidth < 800
                      ? box.maxWidth
                      : (box.maxWidth - 56) / 3,
                  child: _reveal(
                    X2Hover(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 1.4,
                              child: SiteParallaxImage(
                                controller: _scroll,
                                contentKey: 'image.x2.resource.$i',
                                asset: [
                                  'assets/images/commercial-atrium.jpg',
                                  'assets/images/pact-river.jpg',
                                  'assets/images/residential-courtyard.jpg',
                                ][i],
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _text(
                            'x2.resource.$i.category',
                            size: 12,
                            color: _purple,
                            weight: FontWeight.w600,
                          ),
                          const SizedBox(height: 14),
                          _text(
                            'x2.resource.$i.title',
                            size: 31,
                            weight: FontWeight.w500,
                            height: 1.15,
                          ),
                          const SizedBox(height: 24),
                          _button(
                            'x2.resource.action',
                            () => i == 0
                                ? _open(const AcquisitionBlueprintPage())
                                : i == 1
                                ? _learn()
                                : _open(const BuyerResourcesPage()),
                            secondary: true,
                          ),
                        ],
                      ),
                    ),
                    delay: i * 140,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    vertical: 130,
  );

  Widget _closing() => _section(
    Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ClosingGridPainter()),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                _reveal(
                  _text(
                    'x2.close.title',
                    size: MediaQuery.sizeOf(context).width < 700 ? 56 : 84,
                    color: Colors.white,
                    align: TextAlign.center,
                    weight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 32),
                _reveal(
                  _text(
                    'x2.close.body',
                    size: 21,
                    color: const Color(0xFFC2BDCF),
                    align: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 42),
                _reveal(_button('x2.hero.primary', _dashboards)),
              ],
            ),
          ),
        ),
      ],
    ),
    color: const Color(0xFF0C0717),
    vertical: 150,
  );

  Widget _footer() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeBrandButton(size: 48, dark: false),
        const SizedBox(height: 24),
        _text('x2.footer.body', color: _muted),
        const SizedBox(height: 40),
        Wrap(
          spacing: 30,
          runSpacing: 18,
          children: [
            for (final item in [
              ('x2.footer.home', () => HomeBrandButton.open(context)),
              ('x2.footer.about', () => _open(const DesignPreviewPage())),
              ('x2.footer.dashboards', _dashboards),
              (
                'x2.footer.privacy',
                () => _open(footerDestination(FooterTopic.privacy)),
              ),
              (
                'x2.footer.terms',
                () => _open(footerDestination(FooterTopic.terms)),
              ),
              (
                'x2.footer.contact',
                () => _open(footerDestination(FooterTopic.contact)),
              ),
            ])
              TextButton(
                onPressed: item.$2,
                child: _text(item.$1, size: 16, color: _muted),
              ),
          ],
        ),
      ],
    ),
    vertical: 80,
  );

  Widget _iconTile(IconData icon, {double size = 52}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * .3),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1DFF8), Color(0xFFBFA7EC)],
      ),
    ),
    child: Icon(icon, size: size * .46, color: const Color(0xFF56329A)),
  );
  Widget _whiteCard(Widget child, {double padding = 26, bool dark = false}) =>
      Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1A1A1D) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: dark ? const Color(0xFF39373F) : const Color(0xFFF1F0F4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: child,
      );
  Widget _workspaceCard({bool dark = false}) => _whiteCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              color: dark ? Colors.white : _purple,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _text(
                'x2.demo.label',
                size: 10,
                color: dark ? const Color(0xFF9D98A9) : _muted,
                align: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 54),
        _text(
          'x2.demo.title',
          size: 32,
          color: dark ? Colors.white : _ink,
          weight: FontWeight.w500,
        ),
        const SizedBox(height: 8),
        _text(
          'x2.demo.subtitle',
          size: 18,
          color: dark ? const Color(0xFFB7B0C3) : _muted,
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? _purple
                        : dark
                        ? const Color(0xFF46404F)
                        : const Color(0xFFE9E5EF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _text(
          'x2.demo.progress',
          size: 12,
          color: dark ? const Color(0xFFB7B0C3) : _muted,
        ),
      ],
    ),
    dark: dark,
    padding: 34,
  );
  Widget _statusCard() => _whiteCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _iconTile(Icons.north_east, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text('x2.demo.review', size: 21, weight: FontWeight.w500),
                  _text('x2.demo.pending', size: 14, color: _muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF53BFA0), size: 20),
            const SizedBox(width: 10),
            Expanded(child: _text('x2.demo.ready', size: 16)),
          ],
        ),
      ],
    ),
  );
  Widget _toolsCard() => _whiteCard(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: i == 1 ? const Color(0xFFF7F2FC) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: i == 1 ? const Color(0xFFCBB4ED) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  [
                    Icons.tune,
                    Icons.search,
                    Icons.forum_outlined,
                    Icons.checklist,
                  ][i],
                  size: 23,
                  color: i == 1 ? _purple : _ink,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _text(
                    [
                      'x2.demo.criteria',
                      'x2.demo.opportunities',
                      'x2.demo.conversations',
                      'x2.demo.plan',
                    ][i],
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
    padding: 16,
  );
  Widget _scheduleCard() => _whiteCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _text('x2.demo.next', size: 25, weight: FontWeight.w600),
        const SizedBox(height: 25),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  height: 44,
                  decoration: BoxDecoration(
                    color: i == 3 ? _purple : _pale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'RevioInterTight',
                        color: i == 3 ? Colors.white : _muted,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _text('x2.demo.note', size: 18, color: _muted),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.check_circle, color: _purple),
            const SizedBox(width: 14),
            Expanded(child: _text('x2.demo.ready', size: 18)),
          ],
        ),
      ],
    ),
    padding: 30,
  );
  Widget _stackedCards() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(28, -30),
            child: Transform.scale(scale: .88, child: _toolsCard()),
          ),
          Transform.translate(
            offset: const Offset(12, -8),
            child: Transform.scale(scale: .95, child: _toolsCard()),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Row(
              children: [
                _iconTile(
                  [Icons.search, Icons.storefront, Icons.work_outline][_tab],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _text(
                    'x2.tab.$_tab.badge',
                    size: 24,
                    color: Colors.white,
                    weight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.north_east, color: _lavender),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _phone() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 410),
    child: AspectRatio(
      aspectRatio: .52,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 410,
          height: 788,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF090909),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: const Color(0xFF655E68), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332D2053),
                  blurRadius: 70,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: ColoredBox(
                color: _black,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Spacer(),
                          Icon(
                            Icons.signal_cellular_alt,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.battery_full,
                            color: Colors.white,
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 54),
                      _text(
                        'x2.demo.phone',
                        size: 29,
                        color: Colors.white,
                        weight: FontWeight.w500,
                      ),
                      const SizedBox(height: 10),
                      _text(
                        'x2.demo.phone.subtitle',
                        size: 15,
                        color: const Color(0xFFA9A1B6),
                      ),
                      const SizedBox(height: 32),
                      _whiteCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.north_east,
                              color: _lavender,
                              size: 34,
                            ),
                            const SizedBox(height: 22),
                            _text(
                              'x2.demo.plan',
                              size: 23,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            _text(
                              'x2.demo.note',
                              size: 14,
                              color: const Color(0xFFADA4B8),
                            ),
                            const SizedBox(height: 24),
                            const LinearProgressIndicator(
                              value: .6,
                              color: _purple,
                              backgroundColor: Color(0xFF3B3547),
                              minHeight: 5,
                            ),
                          ],
                        ),
                        dark: true,
                        padding: 22,
                      ),
                      const SizedBox(height: 28),
                      for (var i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Row(
                            children: [
                              Icon(
                                i == 0 ? Icons.search : Icons.forum_outlined,
                                color: _lavender,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _text(
                                  i == 0
                                      ? 'x2.demo.opportunities'
                                      : 'x2.demo.conversations',
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Container(
                        height: 5,
                        width: 95,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 90),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TabTransition extends StatefulWidget {
  const _TabTransition({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<_TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<_TabTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    animationBehavior: AnimationBehavior.preserve,
  )..value = 1;
  @override
  void didUpdateWidget(_TabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
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
    builder: (_, child) {
      final p = Curves.easeOutCubic.transform(_controller.value);
      return Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset((1 - p) * 20, 0),
          child: child,
        ),
      );
    },
  );
}

class _TokenPainter extends CustomPainter {
  _TokenPainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2 + math.sin(motion.value * math.pi * 6) * 12,
    );
    final radius = math.min(size.width, size.height) * .36;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.3 + math.sin(motion.value * math.pi * 2) * .09);
    final side = Rect.fromCenter(
      center: Offset(22, 8),
      width: radius * 1.7,
      height: radius * 2,
    );
    canvas.drawOval(
      side,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD6F8F4),
            Color(0xFF484353),
            Color(0xFF9B6FED),
            Color(0xFFFFBBA6),
            Color(0xFF222027),
          ],
        ).createShader(side),
    );
    for (var i = 0; i < 14; i++) {
      canvas.drawArc(
        side.deflate(i * .8),
        -.8,
        2.8,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final face = Rect.fromCenter(
      center: const Offset(-10, -4),
      width: radius * 1.7,
      height: radius * 2,
    );
    canvas.drawOval(
      face,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.5, -.5),
          radius: 1.3,
          colors: [
            Color(0xFFBCE5E5),
            Color(0xFF88ABB6),
            Color(0xFF42505F),
            Color(0xFF17212C),
          ],
        ).createShader(face),
    );
    canvas.drawOval(
      face.deflate(8),
      Paint()
        ..color = const Color(0xFF9DCCCF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      face.deflate(18),
      Paint()
        ..color = const Color(0xFF33495A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final text = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          fontFamily: 'RevioInterTight',
          fontSize: radius * 1.05,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFA9D9DD),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(-10 - text.width / 2, -4 - text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TokenPainter oldDelegate) => oldDelegate.motion != motion;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rx = math.min(size.width * .42, 380.0), ry = 150.0;
    final line = Paint()
      ..color = const Color(0xFFDED9E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      line,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 1.4, height: ry * 1.4),
      line,
    );
    const icons = [
      Icons.auto_stories_outlined,
      Icons.search,
      Icons.forum_outlined,
      Icons.insights_outlined,
      Icons.event_outlined,
      Icons.folder_outlined,
    ];
    for (var i = 0; i < icons.length; i++) {
      final angle = motion.value * math.pi * 2 + i * math.pi / 3;
      final p = Offset(
        c.dx + math.cos(angle) * rx,
        c.dy + math.sin(angle) * ry,
      );
      final rect = Rect.fromCenter(center: p, width: 68, height: 68);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        Paint()..color = Colors.white,
      );
      final icon = icons[i];
      final t = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 29,
            color: i.isEven ? _purple : const Color(0xFF686271),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, p - Offset(t.width / 2, t.height / 2));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.motion != motion;
}

class _ClosingGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x255F3FD5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ClosingGridPainter oldDelegate) => false;
}
