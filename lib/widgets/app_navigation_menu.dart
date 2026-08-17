import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../screens/acquisition_support_page.dart';
import '../screens/assistant_workspace_page.dart';
import '../screens/auth_page.dart';
import '../screens/business_acquisition_page.dart';
import '../screens/deal_rooms_page.dart';
import '../screens/local_network_page.dart';
import '../screens/profile_page.dart';

enum AppNavigationDestination {
  overview,
  blueprint,
  readiness,
  dealScreen,
  pipeline,
  memberStudio,
  network,
  consulting,
  profile,
}

class AppNavigationMenu extends StatelessWidget {
  const AppNavigationMenu({
    super.key,
    this.side = PlatformSide.business,
    this.dark = true,
    this.onSideChanged,
  });

  // Kept while older callers are migrated to the single acquisition app.
  final PlatformSide side;
  final bool dark;
  final ValueChanged<PlatformSide>? onSideChanged;

  String _label(AppNavigationDestination destination) => switch (destination) {
    AppNavigationDestination.overview => 'Acquisition path overview',
    AppNavigationDestination.blueprint => 'Step 1 · Blueprint',
    AppNavigationDestination.readiness => 'Step 2 · Readiness',
    AppNavigationDestination.dealScreen => 'Step 3 · Deal screen',
    AppNavigationDestination.pipeline => 'Step 4 · Pipeline',
    AppNavigationDestination.memberStudio => 'Professional Member Studio',
    AppNavigationDestination.network => 'Members & experts',
    AppNavigationDestination.consulting => 'Personal consulting',
    AppNavigationDestination.profile => 'My profile',
  };

  Widget _page(
    BuildContext context,
    AppNavigationDestination destination,
  ) => switch (destination) {
    AppNavigationDestination.overview => const AcquisitionSupportPage(),
    AppNavigationDestination.blueprint => const AcquisitionBlueprintPage(),
    AppNavigationDestination.readiness => const BuyerReadinessPage(),
    AppNavigationDestination.dealScreen => const BusinessAcquisitionPage(),
    AppNavigationDestination.pipeline => const DealRoomsPage(
      initialSide: PlatformSide.business,
    ),
    AppNavigationDestination.memberStudio => const MemberStudioPage(),
    AppNavigationDestination.network => const LocalNetworkPage(
      side: PlatformSide.business,
    ),
    AppNavigationDestination.consulting => const PersonalizedConsultingPage(),
    AppNavigationDestination.profile =>
      BackendService.user == null
          ? AuthPage(
              onAuthenticated: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              ),
            )
          : const ProfilePage(),
  };

  void _open(BuildContext context, AppNavigationDestination destination) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _page(context, destination)),
    );
  }

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<AppNavigationDestination>(
        tooltip: 'Open navigation',
        color: dark ? const Color(0xFF171728) : Colors.white,
        offset: const Offset(0, 44),
        onSelected: (destination) => _open(context, destination),
        itemBuilder: (_) => [
          for (final destination in AppNavigationDestination.values) ...[
            if (destination == AppNavigationDestination.memberStudio)
              const PopupMenuDivider(),
            PopupMenuItem(
              value: destination,
              height: 43,
              child: Text(
                _label(destination),
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF161616),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            Icons.menu_rounded,
            color: dark ? Colors.white : const Color(0xFF161616),
            size: 28,
          ),
        ),
      );
}
