import 'package:flutter/material.dart';
import '../screens/deal_rooms_page.dart';
import '../screens/seller_dashboard_page.dart';
import '../screens/member_deal_marketplace_page.dart';
import '../services/workspace_role_service.dart';
import 'workspace_role_gate.dart';

/// Direct links and in-app navigation always resolve to the account's side.
Widget? lockedWorkspaceDestination(
  BuildContext context,
  WorkspaceRole requested,
) {
  final role = WorkspaceRoleScope.of(context);
  if (role == null || role == requested) return null;
  return workspaceHome(role);
}

Widget workspaceHome(WorkspaceRole role) => switch (role) {
  WorkspaceRole.buyer => const DealRoomsPage(),
  WorkspaceRole.seller => const SellerDashboardPage(),
  WorkspaceRole.member => const MemberDashboardPage(),
};
