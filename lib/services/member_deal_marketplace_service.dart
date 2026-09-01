import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';
import 'affinity_admin_service.dart';
import 'member_beta_service.dart';

class MemberDealTeamMember {
  const MemberDealTeamMember({
    required this.providerId,
    required this.name,
    required this.company,
    required this.providerType,
    required this.jobTitle,
    this.photoIndex,
    this.photoUrl = '',
  });

  final String providerId;
  final String name;
  final String company;
  final String providerType;
  final String jobTitle;
  final int? photoIndex;
  final String photoUrl;

  factory MemberDealTeamMember.fromJson(Map<String, dynamic> row) =>
      MemberDealTeamMember(
        providerId: row['provider_id'] as String? ?? '',
        name: row['name'] as String? ?? 'Affinity professional',
        company: row['company'] as String? ?? '',
        providerType: row['provider_type'] as String? ?? 'professional',
        jobTitle: row['job_title'] as String? ?? 'Professional',
        photoIndex: (row['photo_index'] as num?)?.toInt(),
        photoUrl: row['photo_url'] as String? ?? '',
      );
}

class MemberDealOpportunity {
  const MemberDealOpportunity({
    required this.id,
    required this.headline,
    required this.industry,
    required this.region,
    required this.summary,
    required this.stage,
    required this.dealType,
    required this.purchasePriceBand,
    required this.capitalRequiredBand,
    required this.affinityScore,
    required this.scoreLabel,
    required this.supportNeeded,
    required this.publishedAt,
    this.matchScore,
    this.matchReason = '',
    this.matchComponents = const {},
    this.publicDetails = const {},
    this.canContact = true,
    this.isRecommended = true,
    this.teamMembers = const [],
    this.isPreview = false,
  });

  final String id;
  final String headline;
  final String industry;
  final String region;
  final String summary;
  final String stage;
  final String dealType;
  final String purchasePriceBand;
  final String capitalRequiredBand;
  final int affinityScore;
  final String scoreLabel;
  final List<String> supportNeeded;
  final DateTime publishedAt;
  final int? matchScore;
  final String matchReason;
  final Map<String, int> matchComponents;

  /// Reviewer-approved acquisition criteria. Raw buyer inputs never enter the
  /// member feed; only this deliberately anonymized brief is returned.
  final Map<String, String> publicDetails;
  final bool canContact;
  final bool isRecommended;
  final List<MemberDealTeamMember> teamMembers;
  final bool isPreview;

  int get dealScore => affinityScore.clamp(1, 99);

  factory MemberDealOpportunity.fromJson(
    Map<String, dynamic> row,
  ) => MemberDealOpportunity(
    id: row['id'] as String,
    headline: row['headline'] as String? ?? 'Anonymous opportunity',
    industry: row['industry'] as String? ?? 'Business services',
    region: row['region'] as String? ?? 'Canada',
    summary: row['summary'] as String? ?? '',
    stage: row['stage'] as String? ?? 'Evaluated',
    dealType: row['deal_type'] as String? ?? 'business',
    purchasePriceBand: row['purchase_price_band'] as String? ?? 'Private',
    capitalRequiredBand:
        row['capital_required_band'] as String? ?? 'To be discussed',
    affinityScore: (row['affinity_score'] as num?)?.toInt() ?? 0,
    scoreLabel: row['score_label'] as String? ?? 'Affinity reviewed',
    supportNeeded: List<String>.from(
      row['support_needed'] as List<dynamic>? ?? const [],
    ),
    publishedAt:
        DateTime.tryParse(row['published_at'] as String? ?? '') ??
        DateTime.now(),
    matchScore: (row['match_score'] as num?)?.toInt(),
    matchReason: row['match_reason'] as String? ?? '',
    matchComponents: row['match_components'] is Map
        ? Map<String, dynamic>.from(
            row['match_components'] as Map,
          ).map((key, value) => MapEntry(key, (value as num).toInt()))
        : const {},
    publicDetails: row['public_details'] is Map
        ? Map<String, dynamic>.from(
            row['public_details'] as Map,
          ).map((key, value) => MapEntry(key, value?.toString() ?? ''))
        : const {},
    canContact: row['can_contact'] as bool? ?? true,
    isRecommended: row['is_recommended'] as bool? ?? true,
    teamMembers: (row['team_members'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (member) =>
              MemberDealTeamMember.fromJson(Map<String, dynamic>.from(member)),
        )
        .toList(),
  );
}

class MemberDealPitch {
  const MemberDealPitch({
    required this.id,
    required this.opportunityId,
    required this.opportunityHeadline,
    required this.providerName,
    required this.companyName,
    required this.providerType,
    required this.pitch,
    required this.offerSummary,
    required this.contactEmail,
    required this.status,
    required this.createdAt,
    this.buyerContactEmail = '',
  });

  final String id;
  final String opportunityId;
  final String opportunityHeadline;
  final String providerName;
  final String companyName;
  final String providerType;
  final String pitch;
  final String offerSummary;
  final String contactEmail;
  final String status;
  final DateTime createdAt;
  final String buyerContactEmail;

  factory MemberDealPitch.fromJson(Map<String, dynamic> row) => MemberDealPitch(
    id: row['id'] as String,
    opportunityId: row['opportunity_id'] as String? ?? '',
    opportunityHeadline:
        row['opportunity_headline'] as String? ?? 'Anonymous opportunity',
    providerName: row['provider_name'] as String? ?? 'Affinity member',
    companyName: row['company_name'] as String? ?? '',
    providerType: row['provider_type'] as String? ?? 'Professional',
    pitch: row['pitch'] as String? ?? '',
    offerSummary: row['offer_summary'] as String? ?? '',
    contactEmail: row['contact_email'] as String? ?? '',
    status: row['status'] as String? ?? 'submitted',
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    buyerContactEmail: row['buyer_contact_email'] as String? ?? '',
  );
}

class MemberDealMarketplaceService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<MemberDealOpportunity>> browse() async {
    if (!BackendService.configured || BackendService.user == null) {
      return _previewDeals;
    }

    try {
      final admin = await AffinityAdminService.isAdmin();
      final rows = await _client.rpc(
        admin ? 'browse_admin_member_deals' : 'browse_matched_member_deals',
      );
      return _opportunityRows(rows);
    } catch (_) {
      try {
        final rows = await _client.rpc('browse_member_deals');
        return _opportunityRows(rows);
      } catch (_) {
        // Preview briefs contain no buyer identity or private deal data. Keep
        // the Studio useful while a professional awaits verification or a
        // newer Member Studio migration is still being deployed.
        return _previewDeals;
      }
    }
  }

  static List<MemberDealOpportunity> _opportunityRows(dynamic rows) =>
      (rows as List<dynamic>)
          .map(
            (row) => MemberDealOpportunity.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

  static List<MemberDealOpportunity> rankRecommendations(
    Iterable<MemberDealOpportunity> opportunities,
  ) {
    final ranked = opportunities
        .where(
          (deal) =>
              deal.canContact &&
              deal.isRecommended &&
              deal.matchScore != null &&
              deal.matchScore! > 0,
        )
        .toList();
    ranked.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return ranked;
  }

  static Future<void> submitForReview(String dealRoomId) async {
    _requireUser();
    await _client.rpc(
      'submit_deal_to_member_studio',
      params: {'target_deal_room_id': dealRoomId},
    );
    await MemberBetaService.flushEmailOutbox();
  }

  static Future<void> sendPitch({
    required String opportunityId,
    required String pitch,
    required String offerSummary,
    required String contactEmail,
  }) async {
    _requireUser();
    await _client.rpc(
      'submit_member_deal_pitch',
      params: {
        'target_opportunity_id': opportunityId,
        'pitch_text': pitch.trim(),
        'offer_text': offerSummary.trim(),
        'reply_email': contactEmail.trim(),
      },
    );
    await MemberBetaService.flushEmailOutbox();
  }

  static Future<List<MemberDealPitch>> loadMyPitches() async {
    if (!BackendService.configured || BackendService.user == null) return [];
    final rows = await _client.rpc('load_my_member_deal_pitches');
    return _pitchRows(rows);
  }

  static Future<List<MemberDealPitch>> loadBuyerResponses() async {
    if (!BackendService.configured || BackendService.user == null) return [];
    final rows = await _client.rpc('load_my_member_deal_responses');
    return _pitchRows(rows);
  }

  static Future<void> respondToPitch(String pitchId, String status) async {
    _requireUser();
    await _client.rpc(
      'respond_to_member_deal_pitch',
      params: {'target_pitch_id': pitchId, 'response_status': status},
    );
    await MemberBetaService.flushEmailOutbox();
  }

  static List<MemberDealPitch> _pitchRows(dynamic rows) =>
      (rows as List<dynamic>)
          .map(
            (row) =>
                MemberDealPitch.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

  static void _requireUser() {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in to use the Member Studio.');
    }
  }

  static final _previewDeals = <MemberDealOpportunity>[
    MemberDealOpportunity(
      id: 'preview-industrial-services',
      headline: 'Established industrial services acquisition',
      industry: 'Industrial services',
      region: 'Lower Mainland, BC',
      summary:
          'Recurring commercial customers, an experienced operating team, and a buyer seeking financing and transaction support before entering exclusivity.',
      stage: 'Initial diligence',
      dealType: 'Business acquisition',
      purchasePriceBand: r'$2M–$3M',
      capitalRequiredBand: r'$650K–$900K',
      affinityScore: 82,
      scoreLabel: 'Strong strategic fit',
      supportNeeded: const ['Commercial lender', 'M&A lawyer', 'QOE'],
      publishedAt: DateTime(2026, 8, 17),
      matchScore: 93,
      matchReason:
          'your profession is requested · strong location match · background strongly aligns',
      matchComponents: const {
        'profession': 25,
        'location': 20,
        'background': 16,
        'deal_type': 10,
        'deal_quality': 17,
        'member_profile': 5,
      },
      publicDetails: const {
        'buyer_objective':
            'Acquire a durable industrial-services operator and preserve the existing management team while professionalizing reporting and finance.',
        'target_business':
            'Established B2B service company with recurring commercial accounts, defensible local relationships, and limited customer concentration.',
        'operating_profile':
            'Experienced operating team expected to remain after closing; owner transition support is preferred.',
        'revenue_profile': r'$3M–$5M annual revenue',
        'earnings_profile': r'$500K–$800K normalized EBITDA',
        'financing_plan':
            'Combination of buyer equity, acquisition debt, and a potential vendor note.',
        'timeline': 'Targeting exclusivity within 60–90 days.',
        'diligence_priorities':
            'Earnings quality, customer concentration, working capital, management continuity, and environmental exposure.',
        'transaction_preferences':
            'Share or asset purchase remains open; meaningful transition support is preferred.',
      },
      teamMembers: const [
        MemberDealTeamMember(
          providerId: 'preview-team-qoe',
          name: 'Grace Okafor',
          company: 'ClearLedger Advisory',
          providerType: 'quality_of_earnings',
          jobTitle: 'Quality of Earnings Director',
          photoIndex: 4,
        ),
      ],
      isPreview: true,
    ),
    MemberDealOpportunity(
      id: 'preview-home-services',
      headline: 'Recurring-revenue home services company',
      industry: 'Home services',
      region: 'Vancouver Island, BC',
      summary:
          'Owner-operated company with a durable customer base. The buyer wants help validating earnings quality, transition risk, and an appropriate financing structure.',
      stage: 'Evaluation complete',
      dealType: 'Business acquisition',
      purchasePriceBand: r'$750K–$1.25M',
      capitalRequiredBand: r'$225K–$350K',
      affinityScore: 76,
      scoreLabel: 'Viable with conditions',
      supportNeeded: const ['Accountant', 'Commercial lender', 'HR adviser'],
      publishedAt: DateTime(2026, 8, 16),
      matchScore: 53,
      matchReason:
          'adjacent professional fit · same province · some background overlap',
      matchComponents: const {
        'profession': 0,
        'location': 12,
        'background': 12,
        'deal_type': 10,
        'deal_quality': 15,
        'member_profile': 4,
      },
      publicDetails: const {
        'buyer_objective':
            'Acquire a recurring-revenue home-services platform with a stable customer base and clear opportunities for operational improvement.',
        'target_business':
            'Owner-operated residential services company with repeat customers and an established local brand.',
        'operating_profile':
            'Buyer expects to retain key technicians and needs a practical owner-transition plan.',
        'revenue_profile': r'$1M–$2M annual revenue',
        'earnings_profile': r'$200K–$350K normalized EBITDA',
        'financing_plan': 'Buyer equity plus senior acquisition financing.',
        'timeline': 'Flexible close after diligence and financing approval.',
        'diligence_priorities':
            'Earnings normalization, technician retention, seasonality, customer churn, and fleet condition.',
        'transaction_preferences':
            'Asset purchase preferred, subject to tax and legal review.',
      },
      isPreview: true,
    ),
  ];
}
