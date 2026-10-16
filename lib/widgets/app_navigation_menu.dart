import 'home_brand_button.dart';
import '../screens/company_data_page.dart';
import 'company_data_access.dart';
import '../screens/assistant_workspace_page.dart';
import '../screens/transaction_learning_page.dart';
import '../screens/learning_dashboard_page.dart';
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
  dealComparison,
  memberStudio,
  profile,
  businessesForSale,
  sellerPosts,
  memberPricing,
  memberMarketing,
  learningDashboard,
  learningSeminars,
  learningMap,
  consulting,
  companyData,
  usagePrivacy,
}

List<AppNavigationDestination> destinationsForTunnel(AppTunnel tunnel) =>
    switch (tunnel) {
      AppTunnel.landing => [
        AppNavigationDestination.buyerDashboard,
        AppNavigationDestination.sellerDashboard,
        AppNavigationDestination.memberStudio,
        AppNavigationDestination.learningDashboard,
      ],
      AppTunnel.buyer => [
        AppNavigationDestination.buyerDashboard,
        AppNavigationDestination.resources,
        AppNavigationDestination.transactionRoom,
        AppNavigationDestination.businessesForSale,
        AppNavigationDestination.consulting,
      ],
      AppTunnel.seller => [
        AppNavigationDestination.sellerDashboard,
        AppNavigationDestination.transactionRoom,
        AppNavigationDestination.sellerPosts,
        AppNavigationDestination.consulting,
      ],
      AppTunnel.learning => [
        AppNavigationDestination.learningDashboard,
        AppNavigationDestination.learningSeminars,
        AppNavigationDestination.learningMap,
        AppNavigationDestination.transactionRoom,
        AppNavigationDestination.profile,
        AppNavigationDestination.consulting,
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
    this.showPrivateUpdates = true,
  });

  // Kept while older callers are migrated to the single acquisition app.
  final String? guidePage;
  final bool showPrivateUpdates;
  final PlatformSide side;
  final bool dark;
  final ValueChanged<PlatformSide>? onSideChanged;

  @override
  State<AppNavigationMenu> createState() => _AppNavigationMenuState();
}

class _AppNavigationMenuState extends State<AppNavigationMenu> {
  final _selectedPill = GlobalKey();
  String? _lastNavigationGuide;
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationCenterPage()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _label(AppNavigationDestination destination) => switch (destination) {
    AppNavigationDestination.companyData => 'Company data · owners only',
    AppNavigationDestination.usagePrivacy => 'Usage privacy',
    AppNavigationDestination.consulting => 'Personal consulting',
    AppNavigationDestination.resources => 'Resources',
    AppNavigationDestination.sellerDashboard => 'Seller dashboard',
    AppNavigationDestination.buyerDashboard => 'Buyer dashboard',
    AppNavigationDestination.transactionRoom => 'Transaction Room',
    AppNavigationDestination.dealComparison => 'Deal comparison quiz',
    AppNavigationDestination.memberStudio => 'Member dashboard',
    AppNavigationDestination.businessesForSale => 'Businesses for sale',
    AppNavigationDestination.sellerPosts => 'My posts & analytics',
    AppNavigationDestination.memberPricing => 'Pricing',
    AppNavigationDestination.memberMarketing => 'Marketing',
    AppNavigationDestination.learningDashboard => 'Learning dashboard',
    AppNavigationDestination.learningSeminars => 'Live seminars',
    AppNavigationDestination.learningMap => 'Buying & selling map',
    AppNavigationDestination.profile => 'My profile',
  };

  Widget _page(
    BuildContext context,
    AppNavigationDestination destination,
  ) => switch (destination) {
    AppNavigationDestination.companyData => const CompanyDataPage(),
    AppNavigationDestination.usagePrivacy => const SizedBox.shrink(),
    AppNavigationDestination.learningDashboard => const LearningDashboardPage(),
    AppNavigationDestination.learningSeminars => const LearningDashboardPage(
      initialView: LearningView.seminars,
    ),
    AppNavigationDestination.learningMap => const LearningDashboardPage(
      initialView: LearningView.map,
    ),
    AppNavigationDestination.consulting => const PersonalizedConsultingPage(),
    AppNavigationDestination.resources => const BuyerResourcesPage(),
    AppNavigationDestination.sellerDashboard => const SellerDashboardPage(),
    AppNavigationDestination.buyerDashboard => const DealRoomsPage(
      initialSide: PlatformSide.business,
    ),
    AppNavigationDestination.transactionRoom => const TransactionLearningPage(),
    AppNavigationDestination.dealComparison => const LearningDashboardPage(
      initialView: LearningView.quiz,
    ),
    AppNavigationDestination.businessesForSale =>
      const BusinessSaleBulletinPage(),
    AppNavigationDestination.sellerPosts => const SellerPostsPage(),
    AppNavigationDestination.memberPricing => const MemberPricingPage(),
    AppNavigationDestination.memberMarketing => const MemberMarketingPage(),
    AppNavigationDestination.memberStudio => const MemberPricingPage(),
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
    if (destination == AppNavigationDestination.usagePrivacy) {
      showUsagePrivacy(context);
      return;
    }
    if (widget.guidePage == 'landing' ||
        AppTunnelController.current.value == AppTunnel.landing) {
      final tunnel = switch (destination) {
        AppNavigationDestination.buyerDashboard => AppTunnel.buyer,
        AppNavigationDestination.sellerDashboard => AppTunnel.seller,
        AppNavigationDestination.memberStudio => AppTunnel.member,
        AppNavigationDestination.learningDashboard => AppTunnel.learning,
        _ => AppTunnel.landing,
      };
      AppTunnelController.select(tunnel);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: destination == AppNavigationDestination.companyData
              ? 'owner-data'
              : destination.name,
        ),
        builder: (_) => _page(context, destination),
      ),
    );
  }

  String _guidePage() {
    final controller = NovaTrainingController.instance;
    final page = widget.guidePage ?? novaGuidePageFor(context);
    return page == 'buyer/dealScreen'
        ? '$page/${controller.calculatorMode}'
        : page;
  }

  void _showPika() {
    CalculatorHelpController.instance.close();
    NovaTrainingController.instance.startPage(_guidePage());
  }

  AppNavigationDestination? _activeDestination(String guide) {
    if (guide == 'landing') return null;
    if (guide == 'resources') return AppNavigationDestination.resources;
    if (guide == 'member-pricing')
      return AppNavigationDestination.memberPricing;
    if (guide == 'member-marketing')
      return AppNavigationDestination.memberMarketing;
    if (guide == 'consulting') return AppNavigationDestination.consulting;
    if (guide == 'profile') return AppNavigationDestination.profile;
    if (guide == 'learning/seminars')
      return AppNavigationDestination.learningSeminars;
    if (guide == 'learning/map') return AppNavigationDestination.learningMap;
    if (guide.startsWith('learning/'))
      return AppNavigationDestination.learningDashboard;
    if (guide.startsWith('buyer/'))
      return AppNavigationDestination.buyerDashboard;
    if (guide.startsWith('seller/'))
      return AppNavigationDestination.sellerDashboard;
    if (guide.startsWith('member/'))
      return AppNavigationDestination.memberStudio;
    return null;
  }

  Widget _navigationBar(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final maxWidth = screen < 600
        ? (screen - 250).clamp(100.0, 240.0)
        : screen < 1000
        ? screen * .43
        : (screen * .62).clamp(0.0, 760.0);
    final guide = _guidePage();
    final active = _activeDestination(guide);
    if (_lastNavigationGuide != guide) {
      _lastNavigationGuide = guide;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final selected = _selectedPill.currentContext;
        if (mounted && selected != null) {
          Scrollable.ensureVisible(selected, alignment: .5);
        }
      });
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        key: const Key('affinity-navigation-bar'),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCF8),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080D2418),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          key: const Key('affinity-navigation-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppNavigationPill(
                key: guide == 'landing' ? _selectedPill : null,
                label: 'Home',
                selected: guide == 'landing',
                onPressed: () => HomeBrandButton.open(context),
                child: const SiteCopyText('navigation.home', 'Home'),
              ),
              for (final destination in destinationsForTunnel(
                guide == 'landing'
                    ? AppTunnel.landing
                    : AppTunnelController.current.value,
              ))
                AppNavigationPill(
                  key: destination == active ? _selectedPill : null,
                  destination: destination,
                  label: _label(destination),
                  selected: destination == active,
                  onPressed: () => _open(context, destination),
                  child:
                      destination == AppNavigationDestination.buyerDashboard ||
                          destination ==
                              AppNavigationDestination.sellerDashboard ||
                          destination ==
                              AppNavigationDestination.transactionRoom
                      ? SiteCopyText(
                          'navigation.${destination.name}',
                          _label(destination),
                        )
                      : SiteText(
                          contentKey: 'copy.app_navigation_menu.m2',
                          literal: false,
                          _label(destination),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != false) {
      NovaTrainingController.instance.currentPage = _guidePage();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navigationBar(context),
        const SizedBox(width: 8),
        if (_guidePage() != 'landing')
          ListenableBuilder(
            listenable: NovaTrainingController.instance,
            builder: (context, _) =>
                (!NovaTrainingController.instance.hosted ||
                    !NovaTrainingController.instance.docked)
                ? IconButton(
                    key: const Key('pebble_page_help'),
                    tooltip: 'Pika · guide to this page',
                    onPressed: () {
                      NovaTrainingController.instance.restoreDock();
                      _showPika();
                    },
                    icon: const NovaCharacter(size: 32),
                  )
                : const SizedBox.shrink(),
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
        if (widget.showPrivateUpdates && BackendService.user != null)
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
      ],
    );
  }
}

/// A direct destination in the shared, horizontally scrollable top bar.
class AppNavigationPill extends StatelessWidget {
  const AppNavigationPill({
    super.key,
    this.destination,
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.child,
  });
  final AppNavigationDestination? destination;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('navigation-${destination?.name ?? 'home'}'),
          borderRadius: BorderRadius.circular(36),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF122815) : Colors.transparent,
              borderRadius: BorderRadius.circular(36),
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected
                    ? const Color(0xFFBFDC99)
                    : const Color(0xFF172817),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: IconTheme(
                data: const IconThemeData(size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
