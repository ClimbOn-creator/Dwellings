import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/membership_service.dart';
import 'auth_page.dart';
import 'acquisition_support_page.dart';
import 'become_member_page.dart';
import '../services/app_tunnel.dart';
import 'tunnel_pages.dart';
import '../widgets/home_brand_button.dart';
import 'seller_dashboard_page.dart';

Future<void> openAccountPage(BuildContext context, Widget page) async {
  if (BackendService.user == null) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (!context.mounted || BackendService.user == null) return;
  }
  if (context.mounted)
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
}

Future<void> startBuyerLearning(BuildContext context) {
  AppTunnelController.select(AppTunnel.buyer);
  return openAccountPage(context, const AcquisitionBlueprintPage());
}

Future<void> startSellerLearning(BuildContext context) {
  AppTunnelController.select(AppTunnel.seller);
  return openAccountPage(
    context,
    const SellerDashboardPage(
      initialView: SellerDashboardView.plan,
      learning: true,
    ),
  );
}

Future<void> startMemberSetup(BuildContext context, {String tier = 'free'}) {
  AppTunnelController.select(AppTunnel.member);
  return openAccountPage(
    context,
    BecomeMemberPage(
      initialType: MemberType.businessBroker,
      initialTier: tier,
      onHome: () => HomeBrandButton.open(context),
      onAbout: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MemberPricingPage()),
      ),
      onTeam: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MemberMarketingPage()),
      ),
    ),
  );
}
