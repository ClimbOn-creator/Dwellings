import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class MemberDealOpportunity {
  const MemberDealOpportunity({
    required this.id,
    required this.headline,
    required this.industry,
    required this.region,
    required this.summary,
    required this.stage,
    required this.purchasePriceBand,
    required this.capitalRequiredBand,
    required this.affinityScore,
    required this.scoreLabel,
    required this.supportNeeded,
    required this.publishedAt,
    this.isPreview = false,
  });

  final String id;
  final String headline;
  final String industry;
  final String region;
  final String summary;
  final String stage;
  final String purchasePriceBand;
  final String capitalRequiredBand;
  final int affinityScore;
  final String scoreLabel;
  final List<String> supportNeeded;
  final DateTime publishedAt;
  final bool isPreview;

  factory MemberDealOpportunity.fromJson(Map<String, dynamic> row) =>
      MemberDealOpportunity(
        id: row['id'] as String,
        headline: row['headline'] as String? ?? 'Anonymous opportunity',
        industry: row['industry'] as String? ?? 'Business services',
        region: row['region'] as String? ?? 'Canada',
        summary: row['summary'] as String? ?? '',
        stage: row['stage'] as String? ?? 'Evaluated',
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
    final rows = await _client.rpc('browse_member_deals');
    return (rows as List<dynamic>)
        .map(
          (row) => MemberDealOpportunity.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> submitForReview(String dealRoomId) async {
    _requireUser();
    await _client.rpc(
      'submit_deal_to_member_studio',
      params: {'target_deal_room_id': dealRoomId},
    );
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
      purchasePriceBand: r'$2M–$3M',
      capitalRequiredBand: r'$650K–$900K',
      affinityScore: 82,
      scoreLabel: 'Strong strategic fit',
      supportNeeded: const ['Commercial lender', 'M&A lawyer', 'QOE'],
      publishedAt: DateTime(2026, 8, 17),
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
      purchasePriceBand: r'$750K–$1.25M',
      capitalRequiredBand: r'$225K–$350K',
      affinityScore: 76,
      scoreLabel: 'Viable with conditions',
      supportNeeded: const ['Accountant', 'Commercial lender', 'HR adviser'],
      publishedAt: DateTime(2026, 8, 16),
      isPreview: true,
    ),
  ];
}
