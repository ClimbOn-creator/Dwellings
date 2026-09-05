import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/site_content_service.dart';
import '../screens/acquisition_support_page.dart';
import '../screens/assistant_workspace_page.dart';
import '../screens/auth_page.dart';
import '../screens/local_network_page.dart';
import '../screens/member_deal_marketplace_page.dart';
import '../screens/profile_page.dart';
import '../screens/content_studio_page.dart';
import '../screens/deal_comparison_page.dart';
import '../screens/notification_center_page.dart';
import '../services/member_beta_service.dart';
import 'profile_photo.dart';

enum AppNavigationDestination {
  overview,
  dealComparison,
  bulletinBoard,
  memberStudio,
  network,
  consulting,
  profile,
}

class AppNavigationMenu extends StatefulWidget {
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

  @override
  State<AppNavigationMenu> createState() => _AppNavigationMenuState();
}

class _AppNavigationMenuState extends State<AppNavigationMenu> {
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationCenterPage()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _label(AppNavigationDestination destination) => switch (destination) {
    AppNavigationDestination.overview => 'Acquisition workspace',
    AppNavigationDestination.dealComparison => 'Compare business deals',
    AppNavigationDestination.bulletinBoard => 'Businesses for sale',
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
    AppNavigationDestination.dealComparison => const DealComparisonPage(),
    AppNavigationDestination.bulletinBoard => const BusinessSaleBulletinPage(),
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FutureBuilder<bool>(
        future: SiteContentService.canEdit(),
        builder: (context, snapshot) => snapshot.data == true
            ? IconButton(
                tooltip: 'Edit site content',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContentStudioPage(),
                  ),
                ),
                icon: Icon(
                  Icons.edit_note_rounded,
                  color: widget.dark ? Colors.white : const Color(0xFF161616),
                ),
              )
            : const SizedBox.shrink(),
      ),
      if (BackendService.user != null)
        FutureBuilder<int>(
          future: MemberBetaService.unreadCount(),
          builder: (context, snapshot) => Badge(
            isLabelVisible: (snapshot.data ?? 0) > 0,
            label: Text('${snapshot.data ?? 0}'),
            child: IconButton(
              tooltip: 'Private updates',
              onPressed: _openNotifications,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: widget.dark ? Colors.white : const Color(0xFF161616),
              ),
            ),
          ),
        ),
      if (BackendService.user == null)
        IconButton(
          tooltip: 'Sign in',
          onPressed: () => _open(context, AppNavigationDestination.profile),
          icon: Icon(
            Icons.person_outline_rounded,
            color: widget.dark ? Colors.white : const Color(0xFF161616),
          ),
        )
      else
        FutureBuilder<AccountProfile?>(
          future: AccountService.loadProfile(),
          builder: (context, snapshot) => Tooltip(
            message: 'My profile',
            child: Semantics(
              button: true,
              label: 'Open my profile',
              child: InkWell(
                onTap: () => _open(context, AppNavigationDestination.profile),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.dark
                          ? Colors.white.withValues(alpha: .55)
                          : const Color(0xFFD2D0C9),
                    ),
                  ),
                  child: ProfilePhoto(
                    size: 32,
                    photoUrl: snapshot.data?.photoUrl ?? '',
                  ),
                ),
              ),
            ),
          ),
        ),
      PopupMenuButton<AppNavigationDestination>(
        tooltip: 'Open navigation',
        color: widget.dark ? const Color(0xFF171728) : Colors.white,
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
                  color: widget.dark ? Colors.white : const Color(0xFF161616),
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
            color: widget.dark ? Colors.white : const Color(0xFF161616),
            size: 28,
          ),
        ),
      ),
    ],
  );
}
