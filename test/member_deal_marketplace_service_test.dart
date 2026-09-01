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
      'public_details': {
        'buyer_objective': 'Acquire a recurring-revenue operator',
        'revenue_profile': r'$2M–$4M annual revenue',
      },
      'stage': 'Evaluation complete',
      'deal_type': 'business',
      'purchase_price_band': r'$1M–$2M',
      'capital_required_band': r'$300K–$500K',
      'affinity_score': 81,
      'score_label': 'Strong fit',
      'support_needed': ['Lender', 'M&A lawyer'],
      'match_score': 91,
      'match_reason': 'your profession is requested · strong location match',
      'match_components': {
        'profession': 25,
        'location': 20,
        'background': 16,
        'deal_type': 10,
        'deal_quality': 16,
        'member_profile': 5,
      },
      'can_contact': false,
      'is_recommended': false,
      'traffic_count': 42,
      'is_owner': true,
      'can_repost': true,
      'last_reposted_at': '2026-07-01T12:00:00Z',
      'team_members': [
        {
          'provider_id': 'provider-1',
          'name': 'Nadia Campbell',
          'company': 'Campbell M&A Law',
          'provider_type': 'ma_lawyer',
          'job_title': 'M&A Lawyer',
          'photo_index': 2,
        },
      ],
      'published_at': '2026-08-18T12:00:00Z',
      // These server-side fields must not become properties on the feed model.
      'owner_user_id': 'private-user-id',
      'buyer_contact_email': 'private@example.com',
      'deal_room_id': 'private-room-id',
      'assessment_inputs': {'business_name': 'Secret Company Ltd.'},
    });

    expect(opportunity.headline, 'Anonymous services acquisition');
    expect(opportunity.affinityScore, 81);
    expect(opportunity.supportNeeded, ['Lender', 'M&A lawyer']);
    expect(opportunity.dealType, 'business');
    expect(opportunity.canContact, isFalse);
    expect(opportunity.isRecommended, isFalse);
    expect(opportunity.trafficCount, 42);
    expect(opportunity.isOwner, isTrue);
    expect(opportunity.canRepost, isTrue);
    expect(opportunity.matchComponents['deal_quality'], 16);
    expect(
      opportunity.publicDetails['buyer_objective'],
      'Acquire a recurring-revenue operator',
    );
    expect(opportunity.teamMembers.single.name, 'Nadia Campbell');
    expect(
      opportunity.toString(),
      isNot(
        anyOf(
          contains('private@example.com'),
          contains('private-user-id'),
          contains('Secret Company Ltd.'),
        ),
      ),
    );
  });

  test('recommendations exclude filled roles and rank best fit first', () {
    MemberDealOpportunity opportunity(
      String id,
      int score, {
      bool canContact = true,
      bool recommended = true,
    }) => MemberDealOpportunity.fromJson({
      'id': id,
      'match_score': score,
      'can_contact': canContact,
      'is_recommended': recommended,
    });

    final ranked = MemberDealMarketplaceService.rankRecommendations([
      opportunity('medium', 63),
      opportunity('filled-role', 99, canContact: false),
      opportunity('best', 92),
      opportunity('below-preference', 88, recommended: false),
    ]);

    expect(ranked.map((deal) => deal.id), ['best', 'medium']);
  });
}
