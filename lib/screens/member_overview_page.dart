import 'package:flutter/material.dart';
import '../models/platform_side.dart';
import '../services/app_tunnel.dart';
import '../widgets/affinity_cinematic.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/pika_introduction.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/site_image.dart';
import 'deal_rooms_page.dart';
import 'member_deal_marketplace_page.dart';
import 'learning_dashboard_page.dart';
import 'seller_dashboard_page.dart';
import 'tunnel_pages.dart';

/// Public Member overview, separate from pricing and the signed-in work area.
class MemberOverviewPage extends StatelessWidget {
  const MemberOverviewPage({super.key});
  void _open(BuildContext context, AppTunnel tunnel, Widget page) {
    AppTunnelController.select(tunnel);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      automaticallyImplyLeading: MediaQuery.sizeOf(context).width >= 900,
      toolbarHeight: 72,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const DashboardHeader(
        label: 'Member dash',
        contentKey: 'copy.member_deal_marketplace_page.11',
      ),
      actions: const [
        AppNavigationMenu(
          guidePage: 'member/overview',
          dark: false,
          showPrivateUpdates: false,
        ),
        SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: SiteImage(
                  contentKey: 'image.acquisition_support_page.mbackground1',
                  original: Image.asset(
                    'assets/images/affinity-city-hero.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: const Color(0x99101613)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 700 ? 24 : 64,
                  vertical: 72,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SiteCopyText(
                      'member.overview.eyebrow',
                      'YOUR NEXT CHAPTER',
                      style: TextStyle(
                        color: Color(0xFFCCD8BF),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SiteCopyText(
                      'member.overview.title',
                      'Choose where you want to go.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.sizeOf(context).width < 700
                            ? 38
                            : 58,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AffinityEntryChoices(
                      onBuyer: () => _open(
                        context,
                        AppTunnel.buyer,
                        const DealRoomsPage(initialSide: PlatformSide.business),
                      ),
                      onMember: () => _open(
                        context,
                        AppTunnel.member,
                        const MemberDashboardPage(),
                      ),
                      onSeller: () => _open(
                        context,
                        AppTunnel.seller,
                        const SellerDashboardPage(),
                      ),
                      onLearn: () => _open(
                        context,
                        AppTunnel.learning,
                        const LearningDashboardPage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const PikaIntroduction(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  FilledButton.icon(
                    key: const Key('member-overview-workspace'),
                    onPressed: () => _open(
                      context,
                      AppTunnel.member,
                      const MemberDashboardPage(),
                    ),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const SiteCopyText(
                      'member.overview.workspace',
                      'Open my professional workspace',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _open(
                      context,
                      AppTunnel.member,
                      const MemberPricingPage(),
                    ),
                    child: const SiteCopyText(
                      'member.overview.pricing',
                      'View membership pricing',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
