import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_service.dart';
import 'business_sale_bulletin_service.dart';
import 'deal_room_service.dart';
import 'pact_messaging_service.dart';

enum PactMobileRole { buyer, seller, member }

extension PactMobileRoleDetails on PactMobileRole {
  String get label => switch (this) {
    PactMobileRole.buyer => 'Buyer',
    PactMobileRole.seller => 'Seller',
    PactMobileRole.member => 'Member',
  };
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

/// Role capability comes from provider ownership on the server, never an
/// editable account-role field. Switching Buyer/Seller is a workspace choice.
class PactMobileWorkspaceService {
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
