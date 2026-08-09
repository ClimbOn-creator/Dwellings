import 'package:flutter/material.dart';

import 'home_screen.dart';

const _black = Color(0xFF070707);
const _white = Color(0xFFF7F7F7);
const _purple = Color(0xFF6D28D9);
const _violet = Color(0xFFA78BFA);
const _grey = Color(0xFFB8B8B8);
const _mono = ColorFilter.matrix(<double>[
  .33,
  .33,
  .33,
  0,
  0,
  .33,
  .33,
  .33,
  0,
  0,
  .33,
  .33,
  .33,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openModel(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UnderwritingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _black,
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _black.withValues(alpha: .96),
          surfaceTintColor: Colors.transparent,
          titleSpacing: 24,
          title: const _LandingBrand(),
          actions: [
            TextButton(
              onPressed: () => _openModel(context),
              child: const Text(
                'OPEN THE MODEL  ↗',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
        ),
        SliverToBoxAdapter(
          child: _InteractiveHero(onOpen: () => _openModel(context)),
        ),
        const SliverToBoxAdapter(child: _KineticTicker()),
        SliverToBoxAdapter(
          child: _DecisionDeck(onOpen: () => _openModel(context)),
        ),
        SliverToBoxAdapter(
          child: _SystemSection(onOpen: () => _openModel(context)),
        ),
        SliverToBoxAdapter(
          child: _FinalCall(onOpen: () => _openModel(context)),
        ),
      ],
    ),
  );
}

class _Story {
  const _Story(
    this.index,
    this.label,
    this.title,
    this.body,
    this.asset,
    this.tint,
  );
  final String index;
  final String label;
  final String title;
  final String body;
  final String asset;
  final Color tint;
}

const _stories = [
  _Story(
    '01',
    'LIVE',
    'A HOME\nWITHOUT BLIND SPOTS.',
    'Affordability, location, physical risk and long-term value in one decision.',
    'assets/images/residential-courtyard.jpg',
    Color(0xFF4C1D95),
  ),
  _Story(
    '02',
    'INVEST',
    'THE INCOME.\nTHE DEBT.\nTHE EXIT.',
    'See the complete path from gross income to cash flow, IRR and equity multiple.',
    'assets/images/commercial-atrium.jpg',
    Color(0xFF6D28D9),
  ),
  _Story(
    '03',
    'DEVELOP',
    'WHAT EXISTS.\nWHAT COULD.',
    'Interrogate zoning, buildable area, redevelopment feasibility and market scarcity.',
    'assets/images/hero-city.jpg',
    Color(0xFF312E81),
  ),
  _Story(
    '04',
    'STRESS',
    'BEFORE YOU BUY,\nBREAK THE MODEL.',
    'Push vacancy, expenses, debt coverage and exit values through downside scenarios.',
    'assets/images/commercial-atrium.jpg',
    Color(0xFF7C3AED),
  ),
];

class _InteractiveHero extends StatefulWidget {
  const _InteractiveHero({required this.onOpen});
  final VoidCallback onOpen;
  @override
  State<_InteractiveHero> createState() => _InteractiveHeroState();
}

class _InteractiveHeroState extends State<_InteractiveHero> {
  int _active = 0;
  Offset _pointer = const Offset(400, 350);
  bool _pointerVisible = false;

  @override
  Widget build(BuildContext context) {
    final story = _stories[_active];
    final desktop = MediaQuery.sizeOf(context).width >= 820;
    final height = desktop ? 720.0 : 760.0;
    return MouseRegion(
      cursor: desktop ? SystemMouseCursors.none : MouseCursor.defer,
      onEnter: (_) => setState(() => _pointerVisible = true),
      onExit: (_) => setState(() => _pointerVisible = false),
      onHover: (event) => setState(() => _pointer = event.localPosition),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 620),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: ColorFiltered(
                key: ValueKey(story.asset),
                colorFilter: _mono,
                child: Image.asset(story.asset, fit: BoxFit.cover),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _black.withValues(alpha: .96),
                    story.tint.withValues(alpha: .76),
                    _black.withValues(alpha: .28),
                  ],
                  stops: const [0, .57, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                desktop ? 38 : 22,
                42,
                desktop ? 38 : 22,
                32,
              ),
              child: desktop
                  ? Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: _HeroCopy(story: story, onOpen: widget.onOpen),
                        ),
                        Expanded(
                          flex: 4,
                          child: _HeroMenu(
                            active: _active,
                            onSelect: (value) =>
                                setState(() => _active = value),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _HeroCopy(story: story, onOpen: widget.onOpen),
                        ),
                        _HeroMenu(
                          active: _active,
                          onSelect: (value) => setState(() => _active = value),
                          compact: true,
                        ),
                      ],
                    ),
            ),
            if (desktop)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                curve: Curves.linear,
                left: _pointer.dx - 33,
                top: _pointer.dy - 33,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _pointerVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: _violet.withValues(alpha: .92),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'VIEW',
                        style: TextStyle(
                          color: _black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.story, required this.onOpen});
  final _Story story;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      child: Column(
        key: ValueKey(story.index),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${story.index} / ${story.label}',
            style: const TextStyle(
              color: _violet,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            story.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.sizeOf(context).width < 700 ? 46 : 70,
              height: .88,
              letterSpacing: -3.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              story.body,
              style: const TextStyle(
                color: Color(0xFFD0D0D0),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _black,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              shape: const RoundedRectangleBorder(),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_outward, size: 18),
            label: const Text(
              'OPEN THE UNDERWRITING MODEL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeroMenu extends StatelessWidget {
  const _HeroMenu({
    required this.active,
    required this.onSelect,
    this.compact = false,
  });
  final int active;
  final ValueChanged<int> onSelect;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final items = List.generate(_stories.length, (index) {
      final selected = index == active;
      return MouseRegion(
        onEnter: (_) => onSelect(index),
        child: GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? _violet : Colors.white24,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _stories[index].index,
                  style: TextStyle(
                    color: selected ? _violet : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  _stories[index].label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: selected ? 20 : 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.arrow_forward, color: _violet, size: 17),
              ],
            ),
          ),
        ),
      );
    });
    return compact
        ? Row(children: items.map((item) => Expanded(child: item)).toList())
        : Column(mainAxisSize: MainAxisSize.min, children: items);
  }
}

class _KineticTicker extends StatefulWidget {
  const _KineticTicker();
  @override
  State<_KineticTicker> createState() => _KineticTickerState();
}

class _KineticTickerState extends State<_KineticTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: ClipRect(
      child: ColoredBox(
        color: _purple,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(-1100 * _controller.value, 0),
            child: child,
          ),
          child: const Row(
            children: [_TickerText(), _TickerText(), _TickerText()],
          ),
        ),
      ),
    ),
  );
}

class _TickerText extends StatelessWidget {
  const _TickerText();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 1100,
    child: Center(
      child: Text(
        'LOCATION  ×  INCOME  ×  DEBT  ×  RISK  ×  EXIT  ×',
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -.5,
        ),
      ),
    ),
  );
}

class _DecisionDeck extends StatefulWidget {
  const _DecisionDeck({required this.onOpen});
  final VoidCallback onOpen;
  @override
  State<_DecisionDeck> createState() => _DecisionDeckState();
}

class _DecisionDeckState extends State<_DecisionDeck> {
  int _active = 1;
  @override
  Widget build(BuildContext context) => Container(
    color: _white,
    padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 22),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHOOSE THE QUESTION',
              style: TextStyle(
                color: _purple,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'One engine. Different decisions.',
              style: TextStyle(
                color: _black,
                fontSize: 46,
                height: .95,
                letterSpacing: -2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 34),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 800;
                final panels = List.generate(
                  _stories.length,
                  (index) => _DeckPanel(
                    story: _stories[index],
                    active: index == _active,
                    onEnter: () => setState(() => _active = index),
                    onOpen: widget.onOpen,
                  ),
                );
                if (narrow)
                  return Column(
                    children: panels
                        .map((panel) => SizedBox(height: 280, child: panel))
                        .toList(),
                  );
                return SizedBox(
                  height: 580,
                  child: Row(
                    children: List.generate(
                      panels.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        width:
                            constraints.maxWidth *
                            (index == _active ? .43 : .19),
                        child: panels[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeckPanel extends StatelessWidget {
  const _DeckPanel({
    required this.story,
    required this.active,
    required this.onEnter,
    required this.onOpen,
  });
  final _Story story;
  final bool active;
  final VoidCallback onEnter;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => onEnter(),
    child: GestureDetector(
      onTap: onEnter,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: _mono,
            child: Image.asset(story.asset, fit: BoxFit.cover),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: active
                ? story.tint.withValues(alpha: .58)
                : _black.withValues(alpha: .78),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.index,
                  style: const TextStyle(
                    color: _violet,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  story.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: active ? 34 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.body,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: onOpen,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'ENTER MODEL  ↗',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SystemSection extends StatelessWidget {
  const _SystemSection({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
    color: _black,
    padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'THE DECISION SYSTEM',
                  style: TextStyle(
                    color: _violet,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '40+ INPUTS.\n12 CORE OUTPUTS.\n3 STRESS CASES.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: .9,
                    letterSpacing: -2.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Residential and commercial assumptions flow into transparent operating, debt, return and risk calculations.',
                  style: TextStyle(color: _grey, height: 1.55),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: _violet),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                  ),
                  child: const Text(
                    'SEE THE MATH  →',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            );
            final visual = Container(
              height: 520,
              decoration: const BoxDecoration(color: _purple),
              child: const Stack(
                children: [
                  Positioned(
                    left: 28,
                    top: 30,
                    child: Text(
                      'INPUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 28,
                    top: 30,
                    child: Text(
                      'OUTPUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(left: 32, top: 115, child: _FlowNode('PRICE')),
                  Positioned(left: 32, top: 205, child: _FlowNode('INCOME')),
                  Positioned(left: 32, top: 295, child: _FlowNode('DEBT')),
                  Positioned(left: 32, top: 385, child: _FlowNode('RISK')),
                  Positioned(
                    right: 32,
                    top: 115,
                    child: _FlowNode('NOI', inverse: true),
                  ),
                  Positioned(
                    right: 32,
                    top: 205,
                    child: _FlowNode('DSCR', inverse: true),
                  ),
                  Positioned(
                    right: 32,
                    top: 295,
                    child: _FlowNode('IRR', inverse: true),
                  ),
                  Positioned(
                    right: 32,
                    top: 385,
                    child: _FlowNode('SCORE', inverse: true),
                  ),
                  Center(
                    child: Icon(Icons.hub_outlined, color: _violet, size: 88),
                  ),
                ],
              ),
            );
            return narrow
                ? Column(children: [copy, const SizedBox(height: 44), visual])
                : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 70),
                      Expanded(child: visual),
                    ],
                  );
          },
        ),
      ),
    ),
  );
}

class _FlowNode extends StatelessWidget {
  const _FlowNode(this.label, {this.inverse = false});
  final String label;
  final bool inverse;
  @override
  Widget build(BuildContext context) => Container(
    width: 105,
    padding: const EdgeInsets.symmetric(vertical: 12),
    color: inverse ? Colors.white : _black,
    alignment: Alignment.center,
    child: Text(
      label,
      style: TextStyle(
        color: inverse ? _black : Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  );
}

class _FinalCall extends StatelessWidget {
  const _FinalCall({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 110, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'READY TO KNOW?',
              style: TextStyle(
                color: _black,
                fontSize: 80,
                height: .86,
                letterSpacing: -4.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'OPEN THE MODEL.',
              style: TextStyle(
                color: _purple,
                fontSize: 80,
                height: .86,
                letterSpacing: -4.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 42),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: _black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 21,
                ),
              ),
              child: const Text(
                'START UNDERWRITING  ↗',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandingBrand extends StatelessWidget {
  const _LandingBrand();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 30,
        height: 30,
        child: ColoredBox(
          color: _purple,
          child: Icon(Icons.domain, color: Colors.white, size: 18),
        ),
      ),
      SizedBox(width: 10),
      Text(
        'DWELLINGS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      Text(
        'IQ',
        style: TextStyle(
          color: _violet,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
