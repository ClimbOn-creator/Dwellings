import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/site_footer.dart';
import '../widgets/topo_background.dart';
import '../models/platform_side.dart';
import 'home_screen.dart';
import 'marketing_pages.dart';
import 'platform_hub_page.dart';

const _ink = Color(0xFF050510);
const _navy = Color(0xFF09091B);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF252525);
const _lilac = Color(0xFF9B9B98);
const _blue = Color(0xFF526DFF);
const _muted = Color(0xFFA5A5B5);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();

  void _openModel() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, _) => const UnderwritingScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openBusiness() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, _) =>
            const PlatformHubPage(side: PlatformSide.business),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  void _openPropertyHub() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PlatformHubPage(side: PlatformSide.property),
    ),
  );

  void _scrollToCapabilities() {
    _scrollController.animateTo(
      MediaQuery.sizeOf(context).height * .92,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    body: TopoBackground(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              onOpen: _openModel,
              onProperty: _openPropertyHub,
              onBusiness: _openBusiness,
              onExplore: _scrollToCapabilities,
            ),
          ),
          const SliverToBoxAdapter(child: _ProofStrip()),
          SliverToBoxAdapter(
            child: _AssetGrid(onOpen: _openModel, onBusiness: _openBusiness),
          ),
          SliverToBoxAdapter(child: _IntelligenceSection(onOpen: _openModel)),
          SliverToBoxAdapter(child: _ProcessSection(onOpen: _openModel)),
          SliverToBoxAdapter(child: _ClosingSection(onOpen: _openModel)),
          SliverToBoxAdapter(
            child: SiteFooter(
              onHome: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
              onAbout: () =>
                  openMarketingPage(context, MarketingDestination.about),
              onTeam: () =>
                  openMarketingPage(context, MarketingDestination.team),
              onMember: () =>
                  openMarketingPage(context, MarketingDestination.membership),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.onOpen,
    required this.onProperty,
    required this.onBusiness,
    required this.onExplore,
  });
  final VoidCallback onOpen;
  final VoidCallback onProperty;
  final VoidCallback onBusiness;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;
    return SizedBox(
      height: desktop ? 820 : 1280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _Atmosphere()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 54 : 22,
              24,
              desktop ? 54 : 22,
              48,
            ),
            child: Column(
              children: [
                MarketingNavigation(
                  onModel: onProperty,
                  onBusiness: onBusiness,
                ),
                SizedBox(height: desktop ? 70 : 54),
                if (desktop)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 11, child: _HeroCopy(onOpen: onOpen)),
                        const SizedBox(width: 48),
                        const Expanded(flex: 9, child: _DealPreview()),
                      ],
                    ),
                  )
                else ...[
                  _HeroCopy(onOpen: onOpen),
                  const SizedBox(height: 44),
                  const SizedBox(height: 390, child: _DealPreview()),
                ],
                const SizedBox(height: 28),
                _HeroFooter(onExplore: onExplore),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        Positioned(
          right: -140,
          top: -190,
          child: Container(
            width: 620,
            height: 620,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_purple.withValues(alpha: .36), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          left: -240,
          bottom: -270,
          child: Container(
            width: 680,
            height: 680,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_blue.withValues(alpha: .18), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: TopoLinesPainter(opacity: .055)),
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .025)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.light = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
        decoration: BoxDecoration(
          color: _hovered ? _purple : (widget.light ? Colors.white : _ink),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.light ? Colors.transparent : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: widget.light && !_hovered ? _ink : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white
                    : (widget.light ? _purple : Colors.white10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_outward,
                size: 15,
                color: _hovered
                    ? _purple
                    : (widget.light ? Colors.white : Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width < 520 ? 54.0 : (width < 1100 ? 68.0 : 84.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _lilac.withValues(alpha: .35)),
          ),
          child: const Text(
            'PROPERTY DECISION INTELLIGENCE',
            style: TextStyle(
              color: _lilac,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'See the deal\nbefore you\nlive with it.',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: .91,
            fontWeight: FontWeight.w600,
            letterSpacing: -4.1,
          ),
        ),
        const SizedBox(height: 28),
        const SizedBox(
          width: 560,
          child: Text(
            'One intelligent workspace for homebuyers and property investors. Model the income, debt, risk, location and exit—then make the call with confidence.',
            style: TextStyle(color: _muted, fontSize: 16, height: 1.55),
          ),
        ),
        const SizedBox(height: 30),
        _PillButton(label: 'CALCULATE PROPERTY RISK', onTap: onOpen),
      ],
    );
  }
}

class _DealPreview extends StatefulWidget {
  const _DealPreview();

  @override
  State<_DealPreview> createState() => _DealPreviewState();
}

class _DealPreviewState extends State<_DealPreview> {
  Offset _position = Offset.zero;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _position = Offset.zero;
      }),
      onHover: (event) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        setState(() => _position = event.localPosition - center);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .001)
          ..rotateX(_hovered ? -_position.dy / 6500 : 0)
          ..rotateY(_hovered ? _position.dx / 6500 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: _hovered ? .31 : .18),
              blurRadius: _hovered ? 80 : 54,
              spreadRadius: -16,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/hero-city.jpg', fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEB080815)],
                    stops: [.28, 1],
                  ),
                ),
              ),
              Positioned(
                top: 22,
                left: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: .66),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'LIVE ANALYSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 20,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF58E6A9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x9958E6A9), blurRadius: 12),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: _DealCard(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DealCard extends StatelessWidget {
  const _DealCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xE6161628),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .14)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'West 12th Avenue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'BASE CASE',
              style: TextStyle(
                color: _lilac,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Row(
          children: [
            Expanded(
              child: _Metric(label: 'CAP RATE', value: '5.82%'),
            ),
            Expanded(
              child: _Metric(label: 'CASH FLOW', value: r'$1,864'),
            ),
            Expanded(
              child: _Metric(label: 'DSCR', value: '1.34×'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: const LinearProgressIndicator(
            value: .78,
            minHeight: 7,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(_purple),
          ),
        ),
        const SizedBox(height: 9),
        const Row(
          children: [
            Text(
              'INVESTMENT SCORE',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            Text(
              '78 / 100',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _HeroFooter extends StatelessWidget {
  const _HeroFooter({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GestureDetector(
        onTap: onExplore,
        child: const Row(
          children: [
            Icon(Icons.south, color: Colors.white70, size: 16),
            SizedBox(width: 9),
            Text(
              'EXPLORE THE PLATFORM',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
      if (MediaQuery.sizeOf(context).width > 700)
        const Text(
          'RESIDENTIAL  /  COMMERCIAL  /  DEVELOPMENT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.1,
          ),
        ),
    ],
  );
}

class _ProofStrip extends StatelessWidget {
  const _ProofStrip();

  @override
  Widget build(BuildContext context) => Container(
    color: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final stats = const [
              _Proof('40+', 'DEAL INPUTS'),
              _Proof('12', 'CORE OUTPUTS'),
              _Proof('3', 'STRESS CASES'),
              _Proof('1', 'CLEAR DECISION'),
            ];
            return compact
                ? Wrap(
                    runSpacing: 24,
                    children: stats
                        .map(
                          (s) => SizedBox(
                            width: constraints.maxWidth / 2,
                            child: s,
                          ),
                        )
                        .toList(),
                  )
                : Row(children: stats.map((s) => Expanded(child: s)).toList());
          },
        ),
      ),
    ),
  );
}

class _Proof extends StatelessWidget {
  const _Proof(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _ink,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.8,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF656573),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}

class _AssetGrid extends StatelessWidget {
  const _AssetGrid({required this.onOpen, required this.onBusiness});
  final VoidCallback onOpen;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) => Container(
    color: _paper,
    padding: const EdgeInsets.fromLTRB(24, 76, 24, 108),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'BUILT FOR THE WHOLE MARKET',
              title: 'Every deal tells a different story.',
              body:
                  'Switch the lens, not the platform. PropertyIQ and AcquisitionIQ organize the decision, evidence and professional team around the deal.',
              dark: false,
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 850;
                final gap = 20.0;
                final cardWidth = desktop
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _AssetCard(
                      width: cardWidth,
                      height: 500,
                      title: 'A home to live in',
                      tag: 'RESIDENTIAL',
                      detail: 'Affordability · neighbourhood · ownership cost',
                      asset: 'assets/images/residential-courtyard.jpg',
                      accent: _purple,
                      onOpen: onOpen,
                    ),
                    _AssetCard(
                      width: cardWidth,
                      height: desktop ? 390 : 500,
                      title: 'Buy an operating business',
                      tag: 'ACQUISITIONIQ · PLACEHOLDER',
                      detail:
                          'Earnings · debt · owner salary · diligence · transition',
                      asset: 'assets/images/hero-city.jpg',
                      accent: const Color(0xFF8B5CF6),
                      onOpen: onBusiness,
                    ),
                    _AssetCard(
                      width: cardWidth,
                      height: desktop ? 390 : 500,
                      title: 'Income property',
                      tag: 'INVESTMENT',
                      detail: 'NOI · debt · returns · exit',
                      asset: 'assets/images/commercial-atrium.jpg',
                      accent: _blue,
                      onOpen: onOpen,
                    ),
                    _AssetCard(
                      width: cardWidth,
                      height: desktop ? 390 : 500,
                      title: 'Commercial real estate',
                      tag: 'COMMERCIAL',
                      detail: 'Leases · vacancy · capex · coverage',
                      asset: 'assets/images/commercial-atrium.jpg',
                      accent: const Color(0xFF5F3DC4),
                      onOpen: onOpen,
                    ),
                    _AssetCard(
                      width: cardWidth,
                      height: 500,
                      title: 'Development potential',
                      tag: 'DEVELOPMENT',
                      detail: 'Land · buildable area · sensitivity · exit',
                      asset: 'assets/images/hero-city.jpg',
                      accent: const Color(0xFF4430A8),
                      onOpen: onOpen,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.dark,
  });
  final String eyebrow;
  final String title;
  final String body;
  final bool dark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final titleWidget = Text(
        title,
        style: TextStyle(
          color: dark ? Colors.white : _ink,
          fontSize: narrow ? 42 : 58,
          height: .98,
          fontWeight: FontWeight.w600,
          letterSpacing: -2.6,
        ),
      );
      final bodyWidget = Text(
        body,
        style: TextStyle(
          color: dark ? _muted : const Color(0xFF666674),
          fontSize: 15,
          height: 1.55,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: _purple,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (narrow) ...[
            titleWidget,
            const SizedBox(height: 18),
            bodyWidget,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 7, child: titleWidget),
                const SizedBox(width: 70),
                Expanded(flex: 3, child: bodyWidget),
              ],
            ),
        ],
      );
    },
  );
}

class _AssetCard extends StatefulWidget {
  const _AssetCard({
    required this.width,
    required this.height,
    required this.title,
    required this.tag,
    required this.detail,
    required this.asset,
    required this.accent,
    required this.onOpen,
  });
  final double width;
  final double height;
  final String title;
  final String tag;
  final String detail;
  final String asset;
  final Color accent;
  final VoidCallback onOpen;

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _hovered ? -9 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: _hovered ? .18 : .08),
              blurRadius: _hovered ? 35 : 20,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 650),
                scale: _hovered ? 1.055 : 1,
                child: Image.asset(widget.asset, fit: BoxFit.cover),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.accent.withValues(alpha: _hovered ? .18 : .07),
                      _ink.withValues(alpha: .88),
                    ],
                    stops: const [.25, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            widget.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: 44,
                          height: 44,
                          transform: Matrix4.rotationZ(
                            _hovered ? math.pi / 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: _hovered ? Colors.white : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: _hovered ? _ink : Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      widget.detail,
                      style: const TextStyle(
                        color: Color(0xFFD1D1DB),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _IntelligenceSection extends StatelessWidget {
  const _IntelligenceSection({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    color: _navy,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 860;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ONE MODEL. COMPLETE CONTEXT.',
                  style: TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'The numbers are only the beginning.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: narrow ? 46 : 62,
                    height: .98,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'See operating performance, financing pressure and future value together. Then stress the assumptions before the market does.',
                  style: TextStyle(color: _muted, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 30),
                _PillButton(label: 'SEE THE FULL MODEL', onTap: onOpen),
              ],
            );
            const visual = _SignalPanel();
            if (narrow) {
              return Column(
                children: [
                  copy,
                  const SizedBox(height: 54),
                  const SizedBox(height: 520, child: visual),
                ],
              );
            }
            return SizedBox(
              height: 590,
              child: Row(
                children: [
                  Expanded(flex: 4, child: copy),
                  const SizedBox(width: 70),
                  const Expanded(flex: 5, child: visual),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _SignalPanel extends StatefulWidget {
  const _SignalPanel();

  @override
  State<_SignalPanel> createState() => _SignalPanelState();
}

class _SignalPanelState extends State<_SignalPanel> {
  int _active = 1;
  static const labels = ['DOWNSIDE', 'BASE CASE', 'UPSIDE'];
  static const values = [61, 78, 89];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF20164A), Color(0xFF111126)],
      ),
      borderRadius: BorderRadius.circular(34),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCENARIO INTELLIGENCE',
          style: TextStyle(
            color: _lilac,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: List.generate(
            labels.length,
            (index) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _active = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: index == _active
                        ? Colors.white
                        : Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: index == _active ? _ink : Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Column(
              key: ValueKey(_active),
              children: [
                Text(
                  '${values[_active]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 112,
                    height: .9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -8,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'DECISION SCORE',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Row(
          children: [
            Expanded(
              child: _Signal(label: 'IRR', value: '14.2%'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Signal(label: 'EQUITY MULTIPLE', value: '1.91×'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Signal(label: 'BREAK-EVEN', value: '71%'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Signal extends StatelessWidget {
  const _Signal({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProcessSection extends StatelessWidget {
  const _ProcessSection({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    color: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 108),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          children: [
            const _SectionHeader(
              eyebrow: 'FROM LISTING TO DECISION',
              title: 'Clarity in three moves.',
              body:
                  'A focused workflow that turns a complicated property into a decision you can explain.',
              dark: false,
            ),
            const SizedBox(height: 52),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 800;
                const steps = [
                  _Step(
                    '01',
                    'Describe the property',
                    'Choose the asset type and enter the complete purchase, operating, financing and location picture.',
                  ),
                  _Step(
                    '02',
                    'Pressure-test the deal',
                    'Compare downside, base and upside cases across cash flow, coverage, returns and ownership cost.',
                  ),
                  _Step(
                    '03',
                    'Make the call',
                    'Read the signals together and understand what must be true for the property to work.',
                  ),
                ];
                return narrow
                    ? const Column(children: steps)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: steps[0]),
                          SizedBox(width: 20),
                          Expanded(child: steps[1]),
                          SizedBox(width: 20),
                          Expanded(child: steps[2]),
                        ],
                      );
              },
            ),
            const SizedBox(height: 42),
            _PillButton(
              label: 'START YOUR ANALYSIS',
              onTap: onOpen,
              light: false,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.title, this.body);
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE4E4EA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _purple,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 42),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFF666674),
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _ClosingSection extends StatelessWidget {
  const _ClosingSection({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => TopoBackground(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 560),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2BC3), Color(0xFF1C124D), Color(0xFF080812)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'YOUR NEXT PROPERTY DESERVES A BETTER QUESTION.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _lilac,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'What if you could know\nbefore you commit?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.sizeOf(context).width < 650
                            ? 46
                            : 72,
                        height: .95,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -3.5,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _PillButton(label: 'OPEN AFFINITY', onTap: onOpen),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 28,
              bottom: 25,
              child: Text(
                'AFFINITY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const Positioned(
              right: 28,
              bottom: 25,
              child: Text(
                'PROPERTY DECISION INTELLIGENCE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
