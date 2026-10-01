import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/membership_service.dart';
import 'auth_page.dart';
import 'acquisition_support_page.dart';
import 'become_member_page.dart';
import 'marketing_pages.dart';
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

Future<void> startBuyerLearning(BuildContext context) =>
    openAccountPage(context, const AcquisitionBlueprintPage());
Future<void> startSellerLearning(BuildContext context) => openAccountPage(
  context,
  const SellerDashboardPage(
    initialView: SellerDashboardView.settings,
    learning: true,
  ),
);
Future<void> startMemberSetup(BuildContext context) => openAccountPage(
  context,
  BecomeMemberPage(
    initialType: MemberType.businessBroker,
    onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
    onAbout: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
    onTeam: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TeamPage())),
  ),
);
