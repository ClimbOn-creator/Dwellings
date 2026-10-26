import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_service.dart';
import 'business_sale_bulletin_service.dart';
import 'deal_room_service.dart';
import 'pact_messaging_service.dart';

import 'workspace_role_service.dart';
export 'workspace_role_service.dart' show WorkspaceRole;

typedef PactMobileRole = WorkspaceRole;

extension PactMobileRoleDetails on PactMobileRole {
  List<String> get tabs => switch (this) {
    PactMobileRole.buyer => const [
      'Home',
      'Businesses',
      'Messages',
      'Help',
      'Profile',
    ],
    PactMobileRole.seller => const [
      'Home',
      'My Listing',
      'Messages',
      'Find Buyers',
      'Profile',
    ],
    PactMobileRole.member => const [
      'Home',
      'Clients',
      'Messages',
      'Leads',
      'Profile',
    ],
  };
}

/// Workspace identity is permanent; professional capabilities remain separate.
class PactMobileWorkspaceService {
  Future<WorkspaceRole?> loadRole() => WorkspaceRoleService().load();
  Future<WorkspaceRole> chooseRole(WorkspaceRole role) =>
      WorkspaceRoleService().choose(role);
  Future<bool> isMember(PactMessagingService messaging) async =>
      (await messaging.call('capabilities'))['is_member'] == true;
  Future<List<SellerPostStats>> listings() =>
      BusinessSaleBulletinService.loadOwnedPosts();
  Future<List<BusinessSaleBulletin>> businesses() =>
      BusinessSaleBulletinService.load();
  Future<List<DealRoom>> deals() => DealRoomService.loadRooms();
  Future<List<IntroductionRequest>> leads() =>
      AccountService.loadIncomingIntroductions();
  Future<void> updateLead(
    IntroductionRequest lead,
    String status,
    String notes,
  ) => AccountService.respondToIntroduction(
    introductionId: lead.id,
    status: status,
    followUpAt: lead.nextFollowUpAt,
    privateNotes: notes,
    closedReason: lead.closedReason,
  );
  Future<Map<String, List<Map<String, dynamic>>>> insights(int days) async {
    final rows =
        await Supabase.instance.client.rpc(
              'pact_seller_listing_insights',
              params: {'days': days},
            )
            as List;
    return {
      for (final row in rows)
        row['listing_id'] as String: (row['daily_saves'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList(),
    };
  }
}
