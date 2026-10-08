import '../screens/transaction_rooms_page.dart';
import '../services/app_tunnel.dart';
import '../screens/tunnel_pages.dart';
import '../screens/member_deal_marketplace_page.dart';
import 'nova_page_resolver.dart';
import 'nova_character.dart';
import 'calculator_help_sidebar.dart';
import '../services/nova_training_controller.dart';
import '../screens/buyer_resources_page.dart';
import '../screens/seller_dashboard_page.dart';
import '../screens/deal_rooms_page.dart';
import 'site_text.dart';
import 'site_copy_text.dart';
import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/site_content_service.dart';
import '../screens/auth_page.dart';
import '../screens/profile_page.dart';
import '../screens/content_studio_page.dart';
import '../screens/notification_center_page.dart';
import '../services/member_beta_service.dart';
import 'profile_photo.dart';

enum AppNavigationDestination {
  resources,
  sellerDashboard,
  buyerDashboard,
  transactionRoom,
  memberStudio,
  profile,
  businessesForSale,
  sellerPosts,
  memberPricing,
  memberMarketing,
}

List<AppNavigationDestination> destinationsForTunnel(AppTunnel tunnel) =>
    switch (tunnel) {
      AppTunnel.landing => [
        AppNavigationDestination.buyerDashboard,
        AppNavigationDestination.sellerDashboard,
        AppNavigationDestination.memberStudio,
      ],
      AppTunnel.buyer => [
        AppNavigationDestination.buyerDashboard,
        AppNavigationDestination.resources,
        AppNavigationDestination.profile,
        AppNavigationDestination.transactionRoom,
        AppNavigationDestination.businessesForSale,
      ],
      AppTunnel.seller => [
        AppNavigationDestination.sellerDashboard,
        AppNavigationDestination.transactionRoom,
        AppNavigationDestination.sellerPosts,
        AppNavigationDestination.profile,
      ],
      AppTunnel.member => [
        AppNavigationDestination.memberPricing,
        AppNavigationDestination.memberStudio,
        AppNavigationDestination.profile,
        AppNavigationDestination.memberMarketing,
      ],
    };

class AppNavigationMenu extends StatefulWidget {
  const AppNavigationMenu({
    super.key,
    this.side = PlatformSide.business,
    this.dark = true,
    this.onSideChanged,
    this.guidePage,
  });

  // Kept while older callers are migrated to the single acquisition app.
  final String? guidePage;
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
    AppNavigationDestination.resources => 'Resources',
    AppNavigationDestination.sellerDashboard => 'Seller dashboard',
    AppNavigationDestination.buyerDashboard => 'Buyer dashboard',
    AppNavigationDestination.transactionRoom => 'Transaction Room',
    AppNavigationDestination.memberStudio => 'Member dashboard',
    AppNavigationDestination.businessesForSale => 'Businesses for sale',
    AppNavigationDestination.sellerPosts => 'My posts & analytics',
    AppNavigationDestination.memberPricing => 'Pricing',
    AppNavigationDestination.memberMarketing => 'Marketing',
    AppNavigationDestination.profile => 'My profile',
  };

  Widget _page(BuildContext context, AppNavigationDestination destination) =>
      switch (destination) {
        AppNavigationDestination.resources => const BuyerResourcesPage(),
        AppNavigationDestination.sellerDashboard => const SellerDashboardPage(),
        AppNavigationDestination.buyerDashboard => const DealRoomsPage(
          initialSide: PlatformSide.business,
        ),
        AppNavigationDestination.transactionRoom => TransactionRoomsPage(
          seller: AppTunnelController.current.value == AppTunnel.seller,
        ),
        AppNavigationDestination.businessesForSale =>
          const BusinessSaleBulletinPage(),
        AppNavigationDestination.sellerPosts => const SellerPostsPage(),
        AppNavigationDestination.memberPricing => const MemberPricingPage(),
        AppNavigationDestination.memberMarketing => const MemberMarketingPage(),
        AppNavigationDestination.memberStudio =>
          const MemberDealMarketplacePage(),
        AppNavigationDestination.profile =>
          BackendService.user == null
              ? AuthPage(
                  onAuthenticated: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => _profilePage()),
                  ),
                )
              : _profilePage(),
      };

  Widget _profilePage() => AppTunnelController.current.value == AppTunnel.member
      ? const MemberDealMarketplacePage(
          initialView: MemberDashboardView.profile,
        )
      : const ProfilePage();

  void _open(BuildContext context, AppNavigationDestination destination) {
    if (widget.guidePage == 'landing' ||
        AppTunnelController.current.value == AppTunnel.landing) {
      final tunnel = switch (destination) {
        AppNavigationDestination.buyerDashboard => AppTunnel.buyer,
        AppNavigationDestination.sellerDashboard => AppTunnel.seller,
        AppNavigationDestination.memberStudio => AppTunnel.member,
        _ => AppTunnel.landing,
      };
      AppTunnelController.select(tunnel);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _page(context, destination)),
    );
  }

  String _guidePage() {
    final controller = NovaTrainingController.instance;
    final page = widget.guidePage ?? novaGuidePageFor(context);
    return page == 'buyer/dealScreen'
        ? '$page/${controller.calculatorMode}'
        : page;
  }

  void _showPebble() {
    CalculatorHelpController.instance.close();
    NovaTrainingController.instance.startPage(_guidePage());
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != false) {
      NovaTrainingController.instance.currentPage = _guidePage();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_guidePage() != 'landing')
          IconButton(
            key: const Key('pebble_page_help'),
            tooltip: 'Pebble · guide to this page',
            onPressed: _showPebble,
            icon: const NovaCharacter(size: 32),
          ),
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
              label: SiteText(
                contentKey: 'copy.app_navigation_menu.m1',
                literal: false,
                '${snapshot.data ?? 0}',
              ),
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
            for (final destination in destinationsForTunnel(
              widget.guidePage == 'landing'
                  ? AppTunnel.landing
                  : AppTunnelController.current.value,
            )) ...[
              PopupMenuItem(
                value: destination,
                height: 43,
                child:
                    destination == AppNavigationDestination.buyerDashboard ||
                        destination ==
                            AppNavigationDestination.sellerDashboard ||
                        destination == AppNavigationDestination.transactionRoom
                    ? SiteCopyText(
                        'navigation.${destination.name}',
                        _label(destination),
                        style: TextStyle(
                          color: widget.dark
                              ? Colors.white
                              : const Color(0xFF161616),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : SiteText(
                        contentKey: 'copy.app_navigation_menu.m2',
                        literal: false,
                        _label(destination),
                        style: TextStyle(
                          color: widget.dark
                              ? Colors.white
                              : const Color(0xFF161616),
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
}
