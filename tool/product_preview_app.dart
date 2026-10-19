// Local-only, account-free product capture harness. No Supabase initialization.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/screens/learning_dashboard_page.dart';
import 'package:dwelling_iq/services/app_tunnel.dart';

void main() {
  final role = Uri.base.queryParameters['role'] ?? 'buyer';
  final feature = Uri.base.queryParameters['feature'] == 'true';
  AppTunnelController.select(
    AppTunnel.values.firstWhere((t) => t.name == role),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
      ),
      home: switch (role) {
        'buyer' => DealRoomsPage(
          initialView: feature
              ? BuyerDashboardView.pipeline
              : BuyerDashboardView.home,
        ),
        'seller' => SellerDashboardPage(
          initialView: feature
              ? SellerDashboardView.plan
              : SellerDashboardView.overview,
        ),
        'member' => MemberDealMarketplacePage(
          initialView: feature
              ? MemberDashboardView.professionals
              : MemberDashboardView.home,
        ),
        _ => LearningDashboardPage(
          initialView: feature ? LearningView.seminars : LearningView.feed,
        ),
      },
    ),
  );
}
