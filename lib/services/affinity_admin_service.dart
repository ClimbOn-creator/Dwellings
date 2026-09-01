import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class AffinityBetaMetrics {
  const AffinityBetaMetrics({
    required this.submittedDeals,
    required this.publishedDeals,
    required this.totalPitches,
    required this.shortlistedPitches,
    required this.acceptedPitches,
    required this.activeProfessionals,
    required this.pendingEmails,
    required this.averageHoursToPublish,
  });

  final int submittedDeals;
  final int publishedDeals;
  final int totalPitches;
  final int shortlistedPitches;
  final int acceptedPitches;
  final int activeProfessionals;
  final int pendingEmails;
  final double averageHoursToPublish;

  factory AffinityBetaMetrics.fromJson(Map<String, dynamic> row) =>
      AffinityBetaMetrics(
        submittedDeals: (row['submitted_deals'] as num?)?.toInt() ?? 0,
        publishedDeals: (row['published_deals'] as num?)?.toInt() ?? 0,
        totalPitches: (row['total_pitches'] as num?)?.toInt() ?? 0,
        shortlistedPitches: (row['shortlisted_pitches'] as num?)?.toInt() ?? 0,
        acceptedPitches: (row['accepted_pitches'] as num?)?.toInt() ?? 0,
        activeProfessionals:
            (row['active_professionals'] as num?)?.toInt() ?? 0,
        pendingEmails: (row['pending_emails'] as num?)?.toInt() ?? 0,
        averageHoursToPublish:
            (row['average_hours_to_publish'] as num?)?.toDouble() ?? 0,
      );
}

class AffinityAuditEvent {
  const AffinityAuditEvent({
    required this.id,
    required this.eventType,
    required this.entityType,
    required this.actorEmail,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String eventType;
  final String entityType;
  final String actorEmail;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory AffinityAuditEvent.fromJson(Map<String, dynamic> row) =>
      AffinityAuditEvent(
        id: row['id'] as String,
        eventType: row['event_type'] as String? ?? 'activity',
        entityType: row['entity_type'] as String? ?? '',
        actorEmail: row['actor_email'] as String? ?? 'system',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        metadata: row['metadata'] is Map
            ? Map<String, dynamic>.from(row['metadata'] as Map)
            : const {},
      );
}

class AffinityReviewItem {
  const AffinityReviewItem({
    required this.id,
    required this.status,
    required this.submittedAt,
    required this.updatedAt,
    required this.buyerEmail,
    required this.dealTitle,
    required this.region,
    required this.currentStage,
    required this.purchasePrice,
    required this.businessName,
    required this.industry,
    required this.assessmentInputs,
    required this.assessmentResults,
    required this.headline,
    required this.summary,
    required this.publicDetails,
    required this.purchasePriceBand,
    required this.capitalRequiredBand,
    required this.affinityScore,
    required this.scoreLabel,
    required this.supportNeeded,
    required this.reviewNotes,
    required this.pitchCount,
  });

  final String id;
  final String status;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String buyerEmail;
  final String dealTitle;
  final String region;
  final String currentStage;
  final double purchasePrice;
  final String businessName;
  final String industry;
  final Map<String, dynamic> assessmentInputs;
  final Map<String, dynamic> assessmentResults;
  final String headline;
  final String summary;
  final Map<String, String> publicDetails;
  final String purchasePriceBand;
  final String capitalRequiredBand;
  final int? affinityScore;
  final String scoreLabel;
  final List<String> supportNeeded;
  final String reviewNotes;
  final int pitchCount;

  factory AffinityReviewItem.fromJson(Map<String, dynamic> row) =>
      AffinityReviewItem(
        id: row['id'] as String,
        status: row['status'] as String? ?? 'submitted',
        submittedAt:
            DateTime.tryParse(row['submitted_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(row['updated_at'] as String? ?? '') ??
            DateTime.now(),
        buyerEmail: row['buyer_email'] as String? ?? '',
        dealTitle: row['deal_title'] as String? ?? 'Private deal',
        region: row['region'] as String? ?? '',
        currentStage: row['current_stage'] as String? ?? 'discovery',
        purchasePrice: (row['purchase_price'] as num?)?.toDouble() ?? 0,
        businessName: row['business_name'] as String? ?? '',
        industry: row['industry'] as String? ?? '',
        assessmentInputs: row['assessment_inputs'] is Map
            ? Map<String, dynamic>.from(row['assessment_inputs'] as Map)
            : const {},
        assessmentResults: row['assessment_results'] is Map
            ? Map<String, dynamic>.from(row['assessment_results'] as Map)
            : const {},
        headline: row['headline'] as String? ?? '',
        summary: row['summary'] as String? ?? '',
        publicDetails: row['public_details'] is Map
            ? Map<String, dynamic>.from(
                row['public_details'] as Map,
              ).map((key, value) => MapEntry(key, value?.toString() ?? ''))
            : const {},
        purchasePriceBand: row['purchase_price_band'] as String? ?? 'Private',
        capitalRequiredBand:
            row['capital_required_band'] as String? ?? 'To be discussed',
        affinityScore: (row['affinity_score'] as num?)?.toInt(),
        scoreLabel: row['score_label'] as String? ?? 'Under review',
        supportNeeded: List<String>.from(
          row['support_needed'] as List<dynamic>? ?? const [],
        ),
        reviewNotes: row['review_notes'] as String? ?? '',
        pitchCount: (row['pitch_count'] as num?)?.toInt() ?? 0,
      );
}

class AffinityMemberAccount {
  const AffinityMemberAccount({
    required this.id,
    required this.displayName,
    required this.companyName,
    required this.email,
    required this.providerType,
    required this.verified,
    required this.membershipTier,
    required this.membershipStatus,
    required this.onboardingStatus,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String companyName;
  final String email;
  final String providerType;
  final bool verified;
  final String membershipTier;
  final String membershipStatus;
  final String onboardingStatus;
  final DateTime createdAt;

  factory AffinityMemberAccount.fromJson(Map<String, dynamic> row) =>
      AffinityMemberAccount(
        id: row['id'] as String,
        displayName: row['display_name'] as String? ?? 'Professional applicant',
        companyName: row['company_name'] as String? ?? '',
        email: row['email'] as String? ?? '',
        providerType: row['provider_type'] as String? ?? 'professional',
        verified: row['verified'] as bool? ?? false,
        membershipTier: row['membership_tier'] as String? ?? 'free',
        membershipStatus: row['membership_status'] as String? ?? 'active',
        onboardingStatus: row['onboarding_status'] as String? ?? 'draft',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class AffinityAdminService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<bool> isAdmin() async {
    if (!BackendService.configured || BackendService.user == null) return false;
    try {
      return await _client.rpc('is_affinity_admin') as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AffinityReviewItem>> loadReviewQueue() async {
    _requireUser();
    final rows = await _client.rpc('load_affinity_review_queue_v2');
    return (rows as List<dynamic>)
        .map(
          (row) => AffinityReviewItem.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> saveReview({
    required String opportunityId,
    required String status,
    required String headline,
    required String industry,
    required String region,
    required String summary,
    required Map<String, String> publicDetails,
    required String stage,
    required String purchasePriceBand,
    required String capitalRequiredBand,
    required int? affinityScore,
    required String scoreLabel,
    required List<String> supportNeeded,
    required String reviewNotes,
  }) async {
    _requireUser();
    await _client.rpc(
      'review_member_deal_opportunity_brief',
      params: {
        'target_opportunity_id': opportunityId,
        'review_status': status,
        'public_headline': headline.trim(),
        'public_industry': industry.trim(),
        'public_region': region.trim(),
        'public_summary': summary.trim(),
        'public_brief': publicDetails,
        'public_stage': stage.trim(),
        'public_purchase_price_band': purchasePriceBand.trim(),
        'public_capital_required_band': capitalRequiredBand.trim(),
        'public_affinity_score': affinityScore,
        'public_score_label': scoreLabel.trim(),
        'public_support_needed': supportNeeded,
        'private_review_notes': reviewNotes.trim(),
      },
    );
  }

  static Future<List<AffinityMemberAccount>> loadMemberAccounts() async {
    _requireUser();
    final rows = await _client.rpc('load_affinity_member_accounts');
    return (rows as List<dynamic>)
        .map(
          (row) => AffinityMemberAccount.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> setMemberAccess({
    required String providerId,
    required bool verified,
    required String tier,
    required String membershipStatus,
    required String onboardingStatus,
  }) async {
    _requireUser();
    await _client.rpc(
      'set_affinity_member_access',
      params: {
        'target_provider_id': providerId,
        'access_verified': verified,
        'access_tier': tier,
        'access_membership_status': membershipStatus,
        'access_onboarding_status': onboardingStatus,
      },
    );
  }

  static Future<AffinityBetaMetrics> loadBetaMetrics() async {
    _requireUser();
    final row = await _client.rpc('load_affinity_beta_metrics');
    return AffinityBetaMetrics.fromJson(Map<String, dynamic>.from(row as Map));
  }

  static Future<List<AffinityAuditEvent>> loadAuditEvents() async {
    _requireUser();
    final rows = await _client.rpc(
      'load_affinity_audit_events',
      params: {'event_limit': 80},
    );
    return (rows as List<dynamic>)
        .map(
          (row) => AffinityAuditEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static void _requireUser() {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in with an Affinity administrator account.');
    }
  }
}
