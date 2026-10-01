import 'package:flutter/material.dart';
import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/membership_service.dart';
import '../widgets/site_text.dart';
import 'auth_page.dart';
import 'acquisition_support_page.dart';
import 'become_member_page.dart';
import 'bulletin_listing_pages.dart';
import 'deal_comparison_page.dart';
import 'deal_rooms_page.dart';
import 'member_deal_marketplace_page.dart';
import 'seller_dashboard_page.dart';

enum JourneyRole { buyer, seller, member }

void openJourneyPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

Widget journeyDashboard(JourneyRole role) => switch (role) {
  JourneyRole.buyer => const DealRoomsPage(initialSide: PlatformSide.business),
  JourneyRole.seller => const SellerDashboardPage(),
  JourneyRole.member => const MemberDealMarketplacePage(),
};

class JourneyEntrances extends StatelessWidget {
  const JourneyEntrances({super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      FilledButton(
        onPressed: () =>
            openJourneyPage(context, journeyDashboard(JourneyRole.buyer)),
        child: const Text('See buyer dashboard'),
      ),
      OutlinedButton(
        onPressed: () => openJourneyPage(
          context,
          const JourneyChoicePage(role: JourneyRole.buyer),
        ),
        child: const Text('I want to learn'),
      ),
      OutlinedButton(
        onPressed: () => openJourneyPage(
          context,
          const JourneyChoicePage(role: JourneyRole.seller),
        ),
        child: const Text('Succession or transfer'),
      ),
      OutlinedButton(
        onPressed: () => openJourneyPage(
          context,
          const JourneyChoicePage(role: JourneyRole.member),
        ),
        child: const Text('I am a member'),
      ),
    ],
  );
}

class JourneyChoicePage extends StatelessWidget {
  const JourneyChoicePage({super.key, required this.role});
  final JourneyRole role;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose your path')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(28),
          children: [
            SiteText(
              contentKey: 'journey.${role.name}.title',
              literal: true,
              switch (role) {
                JourneyRole.buyer => 'Find your way to business ownership.',
                JourneyRole.seller =>
                  'Plan the next chapter for your business.',
                JourneyRole.member => 'Bring your expertise to a deal team.',
              },
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SiteText(
              contentKey: 'journey.${role.name}.intro',
              literal: true,
              switch (role) {
                JourneyRole.buyer =>
                  'Understand the numbers, compare opportunities, and connect with the people who can help you buy.',
                JourneyRole.seller =>
                  'Explore a sale, family succession, or management transfer. Prepare your numbers and connect with advisers before bringing your deal to market.',
                JourneyRole.member =>
                  'Review membership options, set up your professional profile, and respond to opportunities. Buyers and sellers can discover you and invite you to their teams.',
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () =>
                  openJourneyPage(context, JourneyWalkthrough(role: role)),
              child: Text(
                role == JourneyRole.member
                    ? 'Sign in / create account and get started'
                    : 'Yes, I want to learn',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => openJourneyPage(context, journeyDashboard(role)),
              child: Text(
                role == JourneyRole.member
                    ? 'Already set up? Open member dashboard'
                    : 'No walkthrough — open my dashboard',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Each step opens the working screen. The guide remains available underneath
/// routes opened by that screen and never reports a transaction as completed.
class JourneyWalkthrough extends StatefulWidget {
  const JourneyWalkthrough({super.key, required this.role});
  final JourneyRole role;
  @override
  State<JourneyWalkthrough> createState() => _JourneyWalkthroughState();
}

class _JourneyWalkthroughState extends State<JourneyWalkthrough> {
  int step = 0;
  List<(String, String, Widget)> get steps => switch (widget.role) {
    JourneyRole.buyer => [
      (
        'Your buying goals',
        'Complete your questionnaire and save it to your profile. Then continue below.',
        const AcquisitionBlueprintPage(),
      ),
      (
        'Walk through the deal screen',
        'Compare business earnings, asset values, and commercial property. Enter your own figures to see how the result changes.',
        const DealRoomsPage(
          initialSide: PlatformSide.business,
          initialView: BuyerDashboardView.dealScreen,
        ),
      ),
      (
        'Meet the people who can help',
        'Explore resources and connect with professionals. Save relevant providers to your team.',
        const DealRoomsPage(
          initialSide: PlatformSide.business,
          initialView: BuyerDashboardView.resources,
        ),
      ),
      (
        'Your buyer dashboard',
        'Track your pipeline. Add a private deal or find a business for sale. Each deal opens its own workspace.',
        const DealRoomsPage(initialSide: PlatformSide.business),
      ),
    ],
    JourneyRole.seller => [
      (
        'Your transfer goals',
        'Choose your transfer path and timing. Your seller workspace keeps this planning draft on this device.',
        const SellerDashboardPage(initialView: SellerDashboardView.settings),
      ),
      (
        'Pricing your business',
        'Explore earnings, assets, property, and estimated proceeds. Review your assumptions with an adviser.',
        const SellerDashboardPage(initialView: SellerDashboardView.value),
      ),
      (
        'Find your advisers',
        'Connect with the people you need for valuation, tax, legal work, and the transition.',
        const SellerDashboardPage(initialView: SellerDashboardView.resources),
      ),
      (
        'Your seller dashboard',
        'Prepare your deal pack, publish a listing when ready, and organize your transfer plan.',
        const SellerDashboardPage(),
      ),
    ],
    JourneyRole.member => [
      (
        'Choose your membership',
        'Review the available membership options and submit your selection. Continuing this guide does not activate or purchase a plan.',
        BecomeMemberPage(
          initialType: MemberType.businessBroker,
          onHome: () => Navigator.of(context).pop(),
          onAbout: () => Navigator.of(context).pop(),
          onTeam: () => Navigator.of(context).pop(),
        ),
      ),
      (
        'Your member dashboard',
        'Browse opportunities, manage responses, and connect with deal teams. You can skip this walkthrough below.',
        const MemberDealMarketplacePage(),
      ),
      (
        'Create your professional profile',
        'Complete your expertise, service area, and contact details so buyers and sellers can find you. Save your changes on this screen.',
        const MemberDealMarketplacePage(
          initialView: MemberDashboardView.profile,
        ),
      ),
    ],
  };
  @override
  Widget build(BuildContext context) {
    if (BackendService.user == null)
      return AuthPage(
        onAuthenticated: () {
          if (mounted) setState(() {});
        },
      );
    final items = steps;
    final current = items[step];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.role.name[0].toUpperCase()}${widget.role.name.substring(1)} guide · ${step + 1}/${items.length}',
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F3EF),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(current.$2),
              ],
            ),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey('${widget.role.name}.$step'),
              child: current.$3,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (step > 0)
                TextButton(
                  onPressed: () => setState(() => step--),
                  child: const Text('Previous step'),
                ),
              TextButton(
                onPressed: () =>
                    openJourneyPage(context, journeyDashboard(widget.role)),
                child: const Text('Skip walkthrough'),
              ),
              FilledButton(
                onPressed: () {
                  if (step < items.length - 1) {
                    setState(() => step++);
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => JourneyNextPage(role: widget.role),
                      ),
                    );
                  }
                },
                child: Text(
                  step == items.length - 1
                      ? 'Choose my next step'
                      : 'Continue guide',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JourneyNextPage extends StatelessWidget {
  const JourneyNextPage({super.key, required this.role});
  final JourneyRole role;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your next step')),
    body: ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Text(
          'Put your plan into action',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        JourneyActions(role: role),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => openJourneyPage(context, journeyDashboard(role)),
          child: const Text('Open my dashboard'),
        ),
      ],
    ),
  );
}

class JourneyActions extends StatelessWidget {
  const JourneyActions({super.key, required this.role});
  final JourneyRole role;
  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, Widget page) =>
        OutlinedButton.icon(
          onPressed: () => openJourneyPage(context, page),
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (role == JourneyRole.buyer) ...[
          action(
            'Search businesses',
            Icons.search,
            const BusinessSaleBulletinPage(),
          ),
          action(
            'Enter a private deal',
            Icons.add,
            const DealRoomsPage(
              initialSide: PlatformSide.business,
              startIntake: true,
            ),
          ),
          action(
            'Deal comparison quiz',
            Icons.compare_arrows,
            const DealComparisonPage(),
          ),
        ],
        if (role == JourneyRole.seller) ...[
          action(
            'Pricing calculators',
            Icons.calculate_outlined,
            const SellerDashboardPage(initialView: SellerDashboardView.value),
          ),
          action(
            'Create a business listing',
            Icons.add_business_outlined,
            const BulletinListingEditor(),
          ),
          action(
            'Open deal workspaces',
            Icons.folder_open,
            const DealRoomsPage(initialSide: PlatformSide.business),
          ),
        ],
        action(
          'Messaging',
          Icons.chat_bubble_outline,
          const MemberDealMarketplacePage(
            initialView: MemberDashboardView.dealResponses,
          ),
        ),
        action(
          'Take the walkthrough',
          Icons.route_outlined,
          JourneyWalkthrough(role: role),
        ),
      ],
    );
  }
}
