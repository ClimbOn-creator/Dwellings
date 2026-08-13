import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../widgets/brand_logo.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/site_footer.dart';
import '../widgets/app_navigation_menu.dart';
import 'become_member_page.dart';
import 'home_screen.dart';
import 'local_network_page.dart';
import 'platform_hub_page.dart';

const _ink = brandInk;
const _navy = Color(0xFF09091B);
const _paper = Color(0xFFF5F5F7);
const _purple = brandPurple;
const _lilac = brandLilac;
const _muted = Color(0xFFA5A5B5);

enum MarketingDestination { network, about, team, membership }

void openMarketingPage(
  BuildContext context,
  MarketingDestination destination, {
  bool replace = false,
}) {
  final Widget page = switch (destination) {
    MarketingDestination.network => const LocalNetworkPage(),
    MarketingDestination.about => const AboutPage(),
    MarketingDestination.team => const TeamPage(),
    MarketingDestination.membership => BecomeMemberPage(
      onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onAbout: () =>
          openMarketingPage(context, MarketingDestination.about, replace: true),
      onTeam: () =>
          openMarketingPage(context, MarketingDestination.team, replace: true),
    ),
  };
  final route = PageRouteBuilder<void>(
    pageBuilder: (_, animation, _) => page,
    transitionDuration: const Duration(milliseconds: 520),
    transitionsBuilder: (_, animation, _, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

void openUnderwriting(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, animation, _) => const UnderwritingScreen(),
      transitionDuration: const Duration(milliseconds: 560),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
        child: child,
      ),
    ),
  );
}

class MarketingNavigation extends StatelessWidget {
  const MarketingNavigation({
    super.key,
    this.active,
    this.onModel,
    this.onBusiness,
    this.side,
  });

  final MarketingDestination? active;
  final VoidCallback? onModel;
  final VoidCallback? onBusiness;
  final PlatformSide? side;

  void _home(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  void _go(BuildContext context, MarketingDestination destination) {
    if (active == destination) return;
    openMarketingPage(context, destination, replace: active != null);
  }

  void _openSide(BuildContext context, PlatformSide value) {
    final callback = value == PlatformSide.property ? onModel : onBusiness;
    if (callback != null) return callback();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlatformHubPage(side: value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: .11)),
      ),
      child: Row(
        children: [
          const HomeBrandButton(size: 44),
          const Spacer(),
          AppNavigationMenu(side: side ?? PlatformSide.property),
        ],
      ),
    );
  }
}

String _destinationLabel(MarketingDestination value) => switch (value) {
  MarketingDestination.network => 'LOCAL NETWORK',
  MarketingDestination.about => 'ABOUT',
  MarketingDestination.team => 'TEAM',
  MarketingDestination.membership => 'BECOME A MEMBER',
};

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _lilac : const Color(0xFFD6D6E0),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
      ),
    ),
  );
}

class _ModelButton extends StatefulWidget {
  const _ModelButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_ModelButton> createState() => _ModelButtonState();
}

class _ModelButtonState extends State<_ModelButton> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(18, 11, 9, 11),
        decoration: BoxDecoration(
          color: hovered ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.sizeOf(context).width > 560)
              Text(
                'OPEN RISK MODEL',
                style: TextStyle(
                  color: hovered ? Colors.white : _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            if (MediaQuery.sizeOf(context).width > 560)
              const SizedBox(width: 11),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hovered ? Colors.white : _purple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_outward,
                size: 15,
                color: hovered ? _purple : Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CapabilitiesPage extends StatelessWidget {
  const CapabilitiesPage({super.key});

  @override
  Widget build(BuildContext context) => _MarketingPage(
    active: MarketingDestination.about,
    eyebrow: 'CAPABILITIES',
    title: 'Everything that can change the deal.',
    body:
        'A complete property decision system spanning purchase, operations, debt, risk, location and exit.',
    heroAsset: 'assets/images/commercial-atrium.jpg',
    child: Column(
      children: [
        const _CapabilityMatrix(),
        _DarkFeature(
          eyebrow: 'THE OUTPUT LAYER',
          title: 'From raw assumptions to decision-grade signals.',
          body:
              'Every input flows into an auditable set of returns, coverage, affordability and risk metrics—without hiding the math.',
          stats: const [
            ('NOI', 'Operating performance'),
            ('DSCR', 'Debt resilience'),
            ('IRR', 'Time-weighted return'),
            ('DTI', 'Personal affordability'),
          ],
          onOpen: () => openUnderwriting(context),
        ),
        _PageCta(
          title: 'Bring the entire property into focus.',
          button: 'START AN ANALYSIS',
          onTap: () => openUnderwriting(context),
        ),
      ],
    ),
  );
}

class _CapabilityMatrix extends StatelessWidget {
  const _CapabilityMatrix();

  @override
  Widget build(BuildContext context) {
    const capabilities = [
      _Capability(
        '01',
        'Acquisition',
        'Purchase price, closing costs, renovation, reserves, land allocation and total basis.',
        Icons.key_outlined,
      ),
      _Capability(
        '02',
        'Operations',
        'Rent roll, other income, vacancy, operating expenses, management, taxes and capital reserves.',
        Icons.apartment_outlined,
      ),
      _Capability(
        '03',
        'Financing',
        'Loan amount, LTV, amortization, rate, term, debt service and refinancing assumptions.',
        Icons.account_balance_outlined,
      ),
      _Capability(
        '04',
        'Returns',
        'Cash flow, cap rate, cash-on-cash, IRR, equity multiple, NPV and sale proceeds.',
        Icons.insights_outlined,
      ),
      _Capability(
        '05',
        'Risk',
        'Break-even occupancy, DSCR, debt yield, downside cases, expense pressure and exit sensitivity.',
        Icons.shield_outlined,
      ),
      _Capability(
        '06',
        'Homeownership',
        'Monthly ownership cost, income coverage, DTI, affordability and live-in value.',
        Icons.home_outlined,
      ),
      _Capability(
        '07',
        'Commercial',
        'Lease structure, recoveries, tenant rollover, TI, leasing commissions and stabilized NOI.',
        Icons.domain_outlined,
      ),
      _Capability(
        '08',
        'Development',
        'Land basis, buildable area, hard and soft costs, contingency, timing and residual value.',
        Icons.architecture_outlined,
      ),
    ];
    return Container(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 104),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : (constraints.maxWidth >= 580 ? 2 : 1);
              final width =
                  (constraints.maxWidth - (columns - 1) * 18) / columns;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: capabilities
                    .map((item) => SizedBox(width: width, child: item))
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Capability extends StatefulWidget {
  const _Capability(this.number, this.title, this.body, this.icon);
  final String number;
  final String title;
  final String body;
  final IconData icon;
  @override
  State<_Capability> createState() => _CapabilityState();
}

class _CapabilityState extends State<_Capability> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      transform: Matrix4.translationValues(0, hovered ? -7 : 0, 0),
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hovered ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hovered ? _ink : const Color(0xFFE3E3E9)),
        boxShadow: [
          if (hovered)
            BoxShadow(
              color: _purple.withValues(alpha: .18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.number,
                style: const TextStyle(
                  color: _purple,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(widget.icon, color: hovered ? _lilac : _purple, size: 25),
            ],
          ),
          const Spacer(),
          Text(
            widget.title,
            style: TextStyle(
              color: hovered ? Colors.white : _ink,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            widget.body,
            style: TextStyle(
              color: hovered ? _muted : const Color(0xFF666674),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Workflow extends StatelessWidget {
  const _Workflow();
  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '01',
        'Set the objective',
        'Choose whether this is a home, an investment, a commercial asset or a development opportunity.',
        'STRATEGY',
      ),
      (
        '02',
        'Build the property',
        'Enter acquisition, physical, operating, financing and location assumptions at the level you know today.',
        'INPUTS',
      ),
      (
        '03',
        'Stress the assumptions',
        'Move rent, vacancy, expenses, financing and exit values through downside, base and upside cases.',
        'SCENARIOS',
      ),
      (
        '04',
        'Read the decision',
        'Compare return, coverage, affordability and risk signals together—and see what is driving the result.',
        'OUTPUTS',
      ),
    ];
    return Container(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 104),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              return _WorkflowRow(
                number: step.$1,
                title: step.$2,
                body: step.$3,
                label: step.$4,
                reverse: index.isOdd,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({
    required this.number,
    required this.title,
    required this.body,
    required this.label,
    required this.reverse,
  });
  final String number;
  final String title;
  final String body;
  final String label;
  final bool reverse;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final copy = Padding(
        padding: EdgeInsets.all(narrow ? 26 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number / $label',
              style: const TextStyle(
                color: _purple,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.7,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF666674),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
      final visual = _StepVisual(number: number, index: int.parse(number) - 1);
      final children = reverse ? [visual, copy] : [copy, visual];
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E2E8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: narrow
            ? Column(
                children: [
                  copy,
                  SizedBox(height: 310, child: visual),
                ],
              )
            : SizedBox(
                height: 390,
                child: Row(
                  children: children
                      .map((child) => Expanded(child: child))
                      .toList(),
                ),
              ),
      );
    },
  );
}

class _StepVisual extends StatelessWidget {
  const _StepVisual({required this.number, required this.index});
  final String number;
  final int index;
  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.track_changes,
      Icons.tune,
      Icons.multiline_chart,
      Icons.check_circle_outline,
    ];
    return Container(
      color: index.isEven ? _ink : const Color(0xFF2B1D65),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          Center(
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _purple.withValues(alpha: .18),
                border: Border.all(color: _lilac.withValues(alpha: .45)),
              ),
              child: Icon(icons[index], color: Colors.white, size: 48),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 18,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 70,
                fontWeight: FontWeight.w700,
                letterSpacing: -5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioSection extends StatefulWidget {
  const _ScenarioSection();
  @override
  State<_ScenarioSection> createState() => _ScenarioSectionState();
}

class _ScenarioSectionState extends State<_ScenarioSection> {
  int active = 1;
  @override
  Widget build(BuildContext context) {
    const scenarios = [
      (
        'DOWNSIDE',
        'What breaks first?',
        'Lower income, higher vacancy, cost pressure and a softer exit expose the floor.',
      ),
      (
        'BASE CASE',
        'What is most likely?',
        'Your best current assumptions become the benchmark for comparison and diligence.',
      ),
      (
        'UPSIDE',
        'What creates value?',
        'Operational improvement and market growth show where the opportunity can compound.',
      ),
    ];
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const Text(
                'ONE PROPERTY / THREE FUTURES',
                style: TextStyle(
                  color: _lilac,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pressure-test before you commit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -2.4,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                children: List.generate(
                  scenarios.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => active = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          color: active == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          scenarios[index].$1,
                          style: TextStyle(
                            color: active == index ? _ink : Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(active),
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF27195B), Color(0xFF14142B)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        scenarios[active].$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        scenarios[active].$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => _MarketingPage(
    active: MarketingDestination.about,
    eyebrow: 'ABOUT DWELLINGSIQ',
    title: 'Property decisions should not require blind faith.',
    body:
        'We are building a clearer way to understand the financial and personal consequences of buying real estate.',
    heroAsset: 'assets/images/residential-courtyard.jpg',
    child: Column(
      children: [
        const _Manifesto(),
        const _Principles(),
        _PageCta(
          title: 'Better questions create better properties.',
          button: 'OPEN RISK MODEL',
          onTap: () => openUnderwriting(context),
        ),
      ],
    ),
  );
}

class _Manifesto extends StatelessWidget {
  const _Manifesto();
  @override
  Widget build(BuildContext context) => Container(
    color: _paper,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final statement = const Text(
              'A property is never just a price. It is debt, time, risk, place, income, optionality—and for many people, home.',
              style: TextStyle(
                color: _ink,
                fontSize: 42,
                height: 1.12,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
              ),
            );
            final copy = const Text(
              'DwellingsIQ exists to bring those dimensions into one honest picture. We believe sophisticated analysis can still be understandable, that assumptions should remain visible, and that software should help people think—not simply hand them a score.',
              style: TextStyle(
                color: Color(0xFF666674),
                fontSize: 16,
                height: 1.7,
              ),
            );
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [statement, const SizedBox(height: 32), copy],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: statement),
                      const SizedBox(width: 90),
                      Expanded(flex: 4, child: copy),
                    ],
                  );
          },
        ),
      ),
    ),
  );
}

class _Principles extends StatelessWidget {
  const _Principles();
  @override
  Widget build(BuildContext context) {
    const principles = [
      (
        'TRANSPARENCY',
        'Show the assumptions',
        'No black-box verdicts. The user should always understand what created the answer.',
      ),
      (
        'RIGOUR',
        'Respect the details',
        'Residential and commercial property demand different questions, metrics and risk lenses.',
      ),
      (
        'CONTEXT',
        'Numbers meet place',
        'A model becomes useful when the financial result sits beside location and lived reality.',
      ),
      (
        'AGENCY',
        'The decision stays yours',
        'AI should widen understanding and expose trade-offs—not make a life-changing choice for you.',
      ),
    ];
    return Container(
      color: _ink,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WHAT WE BELIEVE',
                style: TextStyle(
                  color: _lilac,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Four principles. No fine print.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -2.5,
                ),
              ),
              const SizedBox(height: 50),
              ...List.generate(principles.length, (index) {
                final item = principles[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < 700
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: const TextStyle(
                                  color: _purple,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.$3,
                                style: const TextStyle(
                                  color: _muted,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  item.$1,
                                  style: const TextStyle(
                                    color: _purple,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.$2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  item.$3,
                                  style: const TextStyle(
                                    color: _muted,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) => _MarketingPage(
    active: MarketingDestination.team,
    eyebrow: 'TEAM',
    title: 'Built at the intersection of property and technology.',
    body:
        'DwellingsIQ is an early-stage product bringing real estate thinking, financial modelling and responsible AI into one focused team.',
    heroAsset: 'assets/images/commercial-atrium.jpg',
    child: Column(
      children: [
        const _TeamGrid(),
        const _TeamNote(),
        _PageCta(
          title: 'Interested in helping shape DwellingsIQ?',
          button: 'SEE THE PRODUCT',
          onTap: () => openUnderwriting(context),
        ),
      ],
    ),
  );
}

class _TeamGrid extends StatelessWidget {
  const _TeamGrid();
  @override
  Widget build(BuildContext context) {
    const roles = [
      (
        'FOUNDER',
        'Product & vision',
        'Defines the property decision experience and turns real-world buying questions into a focused product.',
        Icons.person_outline,
      ),
      (
        'REAL ESTATE',
        'Underwriting intelligence',
        'Shapes the residential, commercial and development frameworks behind every result.',
        Icons.location_city_outlined,
      ),
      (
        'ENGINEERING',
        'Platform & AI',
        'Builds the data, modelling and intelligence layer that makes complex analysis understandable.',
        Icons.auto_awesome_outlined,
      ),
    ];
    return Container(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 104),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 800;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: roles
                    .map(
                      (role) => SizedBox(
                        width: narrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 40) / 3,
                        child: _RoleCard(role: role),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role});
  final (String, String, String, IconData) role;
  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: const BoxConstraints(minHeight: 470),
      transform: Matrix4.translationValues(0, hovered ? -8 : 0, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: hovered ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: hovered ? _ink : const Color(0xFFE2E2E8)),
        boxShadow: [
          if (hovered)
            BoxShadow(
              color: _purple.withValues(alpha: .16),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hovered ? const Color(0xFF5038B4) : const Color(0xFFEAE8F7),
                  hovered ? const Color(0xFF1A1730) : const Color(0xFFD7D2F4),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                widget.role.$4,
                size: 70,
                color: hovered ? Colors.white : _purple,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            widget.role.$1,
            style: const TextStyle(
              color: _purple,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.role.$2,
            style: TextStyle(
              color: hovered ? Colors.white : _ink,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.role.$3,
            style: TextStyle(
              color: hovered ? _muted : const Color(0xFF666674),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TeamNote extends StatelessWidget {
  const _TeamNote();
  @override
  Widget build(BuildContext context) => Container(
    color: _navy,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: const Column(
          children: [
            DwellingIqLogo(size: 58, showWordmark: false),
            SizedBox(height: 28),
            Text(
              'Small by design. Ambitious by necessity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                height: 1.08,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.6,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'DwellingsIQ is being shaped as a focused, multidisciplinary company. Every discipline works from the same principle: make complex property decisions clearer, more rigorous and more human.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 15, height: 1.65),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MarketingPage extends StatelessWidget {
  const _MarketingPage({
    required this.active,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.heroAsset,
    required this.child,
  });
  final MarketingDestination active;
  final String eyebrow;
  final String title;
  final String body;
  final String heroAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PageHero(
            active: active,
            eyebrow: eyebrow,
            title: title,
            body: body,
            asset: heroAsset,
          ),
        ),
        SliverToBoxAdapter(child: child),
        SliverToBoxAdapter(
          child: SiteFooter(
            onHome: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onAbout: () => openMarketingPage(
              context,
              MarketingDestination.about,
              replace: true,
            ),
            onTeam: () => openMarketingPage(
              context,
              MarketingDestination.team,
              replace: true,
            ),
            onMember: () => openMarketingPage(
              context,
              MarketingDestination.membership,
              replace: true,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PageHero extends StatelessWidget {
  const _PageHero({
    required this.active,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
  });
  final MarketingDestination active;
  final String eyebrow;
  final String title;
  final String body;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    return Container(
      height: desktop ? 690 : 820,
      decoration: const BoxDecoration(color: _ink),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: desktop
                ? MediaQuery.sizeOf(context).width * .47
                : MediaQuery.sizeOf(context).width,
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: desktop
                    ? const [_ink, Color(0xF5050510), Color(0x42050510)]
                    : const [_ink, Color(0xE8050510), Color(0x99050510)],
                stops: desktop ? const [0, .55, 1] : const [0, .72, 1],
              ),
            ),
          ),
          Positioned(
            right: -100,
            top: -160,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_purple.withValues(alpha: .32), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 54 : 22,
              24,
              desktop ? 54 : 22,
              54,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarketingNavigation(active: active),
                const Spacer(),
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: desktop ? 70 : 50,
                      height: .94,
                      fontWeight: FontWeight.w600,
                      letterSpacing: desktop ? -3.5 : -2.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 590),
                  child: Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFC4C4CF),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkFeature extends StatelessWidget {
  const _DarkFeature({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.stats,
    required this.onOpen,
  });
  final String eyebrow;
  final String title;
  final String body;
  final List<(String, String)> stats;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    color: _navy,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 800;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: _lilac,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2.2,
                  ),
                ),
                const SizedBox(height: 22),
                Text(body, style: const TextStyle(color: _muted, height: 1.6)),
                const SizedBox(height: 28),
                _ModelButton(onTap: onOpen),
              ],
            );
            final grid = Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats
                  .map(
                    (stat) => Container(
                      width: narrow ? constraints.maxWidth : 210,
                      height: 170,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            stat.$2,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [copy, const SizedBox(height: 54), grid],
                  )
                : Row(
                    children: [
                      Expanded(flex: 4, child: copy),
                      const SizedBox(width: 70),
                      Expanded(flex: 5, child: grid),
                    ],
                  );
          },
        ),
      ),
    ),
  );
}

class _PageCta extends StatelessWidget {
  const _PageCta({
    required this.title,
    required this.button,
    required this.onTap,
  });
  final String title;
  final String button;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    color: _ink,
    padding: const EdgeInsets.all(24),
    child: Container(
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B31BB), Color(0xFF1D1449), Color(0xFF0B0B18)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DwellingIqLogo(size: 54, showWordmark: false),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width < 650 ? 42 : 62,
                  height: .98,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -2.8,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _ModelButton(onTap: onTap),
          ],
        ),
      ),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .08);
    for (double x = 18; x < size.width; x += 28) {
      for (double y = 18; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
