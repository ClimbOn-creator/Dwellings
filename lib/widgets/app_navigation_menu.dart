import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../screens/business_acquisition_page.dart';
import '../screens/deal_rooms_page.dart';
import '../screens/home_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/local_network_page.dart';
import '../screens/marketing_pages.dart';
import '../screens/platform_hub_page.dart';
import '../screens/profile_page.dart';

enum AppNavigationDestination {
  home,
  property,
  business,
  propertyModel,
  businessModel,
  network,
  deals,
  profile,
  process,
  about,
  team,
  membership,
}

class AppNavigationMenu extends StatelessWidget {
  const AppNavigationMenu({
    super.key,
    this.side = PlatformSide.property,
    this.compact = false,
    this.dark = true,
  });

  final PlatformSide side;
  final bool compact;
  final bool dark;

  String _label(AppNavigationDestination destination) => switch (destination) {
    AppNavigationDestination.home => 'Home',
    AppNavigationDestination.property => 'Property overview',
    AppNavigationDestination.business => 'Business overview',
    AppNavigationDestination.propertyModel => 'Property risk model',
    AppNavigationDestination.businessModel => 'Business viability model',
    AppNavigationDestination.network => 'Professional network',
    AppNavigationDestination.deals => 'Current deals',
    AppNavigationDestination.profile => 'Profile & my team',
    AppNavigationDestination.process => 'How it works',
    AppNavigationDestination.about => 'About',
    AppNavigationDestination.team => 'Team',
    AppNavigationDestination.membership => 'Become a member',
  };

  void _open(BuildContext context, AppNavigationDestination destination) {
    final navigator = Navigator.of(context);
    final Widget? page = switch (destination) {
      AppNavigationDestination.home => const LandingScreen(),
      AppNavigationDestination.property => const PlatformHubPage(
        side: PlatformSide.property,
      ),
      AppNavigationDestination.business => const PlatformHubPage(
        side: PlatformSide.business,
      ),
      AppNavigationDestination.propertyModel => const UnderwritingScreen(),
      AppNavigationDestination.businessModel => const BusinessAcquisitionPage(),
      AppNavigationDestination.network => LocalNetworkPage(side: side),
      AppNavigationDestination.deals => DealRoomsPage(initialSide: side),
      AppNavigationDestination.profile => const ProfilePage(),
      AppNavigationDestination.process ||
      AppNavigationDestination.about ||
      AppNavigationDestination.team ||
      AppNavigationDestination.membership => null,
    };
    if (page != null) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
      return;
    }
    final marketingDestination = switch (destination) {
      AppNavigationDestination.process => MarketingDestination.process,
      AppNavigationDestination.about => MarketingDestination.about,
      AppNavigationDestination.team => MarketingDestination.team,
      AppNavigationDestination.membership => MarketingDestination.membership,
      _ => throw StateError('Not a marketing destination'),
    };
    openMarketingPage(context, marketingDestination);
  }

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<AppNavigationDestination>(
        tooltip: 'Open all pages',
        color: dark ? const Color(0xFF171728) : Colors.white,
        offset: const Offset(0, 38),
        onSelected: (destination) => _open(context, destination),
        itemBuilder: (_) => [
          for (final destination in AppNavigationDestination.values)
            PopupMenuItem(
              value: destination,
              height: 42,
              child: Text(
                _label(destination),
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF050510),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: .08)
                : const Color(0xFFF0F0F4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .16)
                  : const Color(0xFFD8D8E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: dark ? Colors.white : const Color(0xFF050510),
                size: 16,
              ),
              if (!compact) ...[
                const SizedBox(width: 5),
                Text(
                  'EXPLORE',
                  style: TextStyle(
                    color: dark ? Colors.white : const Color(0xFF050510),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .75,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
