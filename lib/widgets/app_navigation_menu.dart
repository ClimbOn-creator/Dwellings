import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../screens/auth_page.dart';
import '../screens/business_acquisition_page.dart';
import '../screens/deal_rooms_page.dart';
import '../screens/home_screen.dart';
import '../screens/local_network_page.dart';
import '../screens/marketing_pages.dart';
import '../screens/platform_hub_page.dart';
import '../screens/profile_page.dart';
import 'platform_switcher.dart';

enum AppNavigationDestination { network, membership, deals, profile, model }

class AppNavigationMenu extends StatelessWidget {
  const AppNavigationMenu({
    super.key,
    this.side = PlatformSide.property,
    this.dark = true,
    this.onSideChanged,
  });

  final PlatformSide side;
  final bool dark;
  final ValueChanged<PlatformSide>? onSideChanged;

  void _changeSide(BuildContext context, PlatformSide next) {
    if (next == side) return;
    if (onSideChanged != null) {
      onSideChanged!(next);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => PlatformHubPage(side: next)),
    );
  }

  String _label(AppNavigationDestination destination) => switch (destination) {
    AppNavigationDestination.network => 'Local network',
    AppNavigationDestination.membership => 'Become a member',
    AppNavigationDestination.deals => 'Current deals',
    AppNavigationDestination.profile => 'Profile',
    AppNavigationDestination.model =>
      side == PlatformSide.business ? 'Open business model' : 'Open risk model',
  };

  void _open(BuildContext context, AppNavigationDestination destination) {
    final Widget? page = switch (destination) {
      AppNavigationDestination.network => LocalNetworkPage(side: side),
      AppNavigationDestination.deals => DealRoomsPage(initialSide: side),
      AppNavigationDestination.profile =>
        BackendService.user == null
            ? AuthPage(
                onAuthenticated: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                ),
              )
            : const ProfilePage(),
      AppNavigationDestination.model =>
        side == PlatformSide.business
            ? const BusinessAcquisitionPage()
            : const UnderwritingScreen(),
      AppNavigationDestination.membership => null,
    };
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
      return;
    }
    openMarketingPage(context, MarketingDestination.membership);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformSwitcher(
          selected: side,
          onChanged: (next) => _changeSide(context, next),
          compact: true,
          micro: narrow,
        ),
        SizedBox(width: narrow ? 3 : 7),
        PopupMenuButton<AppNavigationDestination>(
          tooltip: 'Open navigation',
          color: dark ? const Color(0xFF171728) : Colors.white,
          offset: const Offset(0, 42),
          onSelected: (destination) => _open(context, destination),
          itemBuilder: (_) => [
            for (final destination in AppNavigationDestination.values)
              PopupMenuItem(
                value: destination,
                height: 44,
                child: Text(
                  _label(destination),
                  style: TextStyle(
                    color: dark ? Colors.white : const Color(0xFF050510),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          child: SizedBox.square(
            dimension: narrow ? 38 : 44,
            child: Icon(
              Icons.menu_rounded,
              color: dark ? Colors.white : const Color(0xFF050510),
              size: narrow ? 25 : 28,
            ),
          ),
        ),
      ],
    );
  }
}
