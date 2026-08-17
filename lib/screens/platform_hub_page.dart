import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/topo_background.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/site_footer.dart';
import 'auth_page.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';
import 'home_screen.dart';
import 'local_network_page.dart';
import 'marketing_pages.dart';
import 'profile_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF1677FF);
const _lilac = Color(0xFF8FC5FF);

class PlatformHubPage extends StatelessWidget {
  const PlatformHubPage({super.key, required this.side});

  final PlatformSide side;

  bool get _business => side == PlatformSide.business;

  void _replaceSide(BuildContext context, PlatformSide next) {
    if (next == side) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => PlatformHubPage(side: next)),
    );
  }

  void _calculator(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _business
          ? const BusinessAcquisitionPage()
          : const UnderwritingScreen(),
    ),
  );

  void _network(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => LocalNetworkPage(side: side)));

  void _profile(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BackendService.user == null ? const AuthPage() : const ProfilePage(),
    ),
  );

  void _deals(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BackendService.user == null
          ? const AuthPage()
          : DealRoomsPage(initialSide: side),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero(context)),
        SliverToBoxAdapter(child: _actions(context)),
        SliverToBoxAdapter(child: _journey()),
        SliverToBoxAdapter(
          child: SiteFooter(
            onHome: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            onAbout: () =>
                openMarketingPage(context, MarketingDestination.about),
            onTeam: () => openMarketingPage(context, MarketingDestination.team),
            onMember: () =>
                openMarketingPage(context, MarketingDestination.membership),
          ),
        ),
      ],
    ),
  );

  Widget _hero(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    return TopoBackground(
      opacity: .055,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          narrow ? 22 : 54,
          24,
          narrow ? 22 : 54,
          80,
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HomeBrandButton(size: 44),
                      const Spacer(),
                      AppNavigationMenu(side: side),
                    ],
                  ),
                  const SizedBox(height: 86),
                  Text(
                    _business
                        ? 'DEALIQ · BUSINESS ACQUISITIONS'
                        : 'PROPERTYIQ · REAL ESTATE',
                    style: const TextStyle(
                      color: _lilac,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _business
                        ? 'Buy a business\nwith a clear process.'
                        : 'Make the property\ndecision with clarity.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: narrow ? 50 : 72,
                      height: .94,
                      fontWeight: FontWeight.w600,
                      letterSpacing: narrow ? -2.5 : -3.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      _business
                          ? 'Screen the economics, assemble specialist advisers and move through diligence, financing, closing and transition in one place.'
                          : 'Assess affordability and investment risk, find the right local professionals and keep every active purchase on track.',
                      style: const TextStyle(
                        color: Color(0xFFC5C5D0),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 76),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHOOSE WHAT YOU NEED',
              style: TextStyle(
                color: _purple,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _business
                  ? 'Your acquisition workspace.'
                  : 'Your property workspace.',
              style: const TextStyle(
                color: _ink,
                fontSize: 44,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 34),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 4 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _HubAction(
                      width: width,
                      icon: Icons.calculate_outlined,
                      title: _business
                          ? 'Viability calculator'
                          : 'Risk calculator',
                      detail: _business
                          ? 'Test earnings, debt and owner cash flow.'
                          : 'Model affordability, returns and downside risk.',
                      onTap: () => _calculator(context),
                    ),
                    _HubAction(
                      width: width,
                      icon: Icons.groups_outlined,
                      title: 'Specialist network',
                      detail: _business
                          ? 'Find acquisition-specific advisers.'
                          : 'Find local property professionals.',
                      onTap: () => _network(context),
                    ),
                    _HubAction(
                      width: width,
                      icon: Icons.people_alt_outlined,
                      title: 'My team',
                      detail: 'Review saved professionals and your profile.',
                      onTap: () => _profile(context),
                    ),
                    _HubAction(
                      width: width,
                      icon: Icons.track_changes_outlined,
                      title: 'Current deals',
                      detail: 'See the current step and what comes next.',
                      onTap: () => _deals(context),
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

  Widget _journey() {
    final steps = _business
        ? const [
            (
              '01',
              'Screen',
              'Test whether the business can support the buyer.',
            ),
            (
              '02',
              'Assemble',
              'Select the specialists the acquisition requires.',
            ),
            (
              '03',
              'Diligence',
              'Work through financial, legal and operating evidence.',
            ),
            (
              '04',
              'Close & transition',
              'Track conditions, closing and the first 100 days.',
            ),
          ]
        : const [
            (
              '01',
              'Assess',
              'Understand affordability, returns and material risk.',
            ),
            (
              '02',
              'Build the team',
              'Select local professionals for the purchase.',
            ),
            (
              '03',
              'Offer & diligence',
              'Track financing, conditions and property review.',
            ),
            ('04', 'Close', 'Coordinate documents, insurance and completion.'),
          ];
    return Container(
      color: const Color(0xFF11111C),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 76),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: steps
                .map(
                  (step) => Container(
                    width: 275,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .055),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1, style: const TextStyle(color: _lilac)),
                        const SizedBox(height: 18),
                        Text(
                          step.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.$3,
                          style: const TextStyle(
                            color: Color(0xFFB5B5C1),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _HubAction extends StatefulWidget {
  const _HubAction({
    required this.width,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  State<_HubAction> createState() => _HubActionState();
}

class _HubActionState extends State<_HubAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: widget.width,
        height: 240,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _hovered ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: _hovered ? _lilac : _purple, size: 30),
            const Spacer(),
            Text(
              widget.title,
              style: TextStyle(
                color: _hovered ? Colors.white : _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.detail,
              style: TextStyle(
                color: _hovered ? Colors.white60 : const Color(0xFF666674),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.arrow_outward,
              color: _hovered ? Colors.white : _ink,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
