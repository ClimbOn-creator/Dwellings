import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/services/member_deal_marketplace_service.dart';

void main() {
  test(
    'privacy-safe example deals load without backend member access',
    () async {
      final opportunities = await MemberDealMarketplaceService.browse();

      expect(opportunities, isNotEmpty);
      expect(opportunities.every((deal) => deal.isPreview), isTrue);
    },
  );

  test('member opportunity model exposes only sanitized deal fields', () {
    final opportunity = MemberDealOpportunity.fromJson({
      'id': 'deal-1',
      'headline': 'Anonymous services acquisition',
      'industry': 'Business services',
      'region': 'British Columbia',
      'summary': 'Affinity-approved summary',
      'stage': 'Evaluation complete',
      'purchase_price_band': r'$1M–$2M',
      'capital_required_band': r'$300K–$500K',
      'affinity_score': 81,
      'score_label': 'Strong fit',
      'support_needed': ['Lender', 'M&A lawyer'],
      'published_at': '2026-08-18T12:00:00Z',
      // These server-side fields must not become properties on the feed model.
      'owner_user_id': 'private-user-id',
      'buyer_contact_email': 'private@example.com',
      'deal_room_id': 'private-room-id',
    });

    expect(opportunity.headline, 'Anonymous services acquisition');
    expect(opportunity.affinityScore, 81);
    expect(opportunity.supportNeeded, ['Lender', 'M&A lawyer']);
    expect(
      opportunity.toString(),
      isNot(
        anyOf(contains('private@example.com'), contains('private-user-id')),
      ),
    );
  });
}
