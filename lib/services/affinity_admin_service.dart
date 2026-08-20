import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

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
    final rows = await _client.rpc('load_affinity_review_queue');
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
      'review_member_deal_opportunity',
      params: {
        'target_opportunity_id': opportunityId,
        'review_status': status,
        'public_headline': headline.trim(),
        'public_industry': industry.trim(),
        'public_region': region.trim(),
        'public_summary': summary.trim(),
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

  static void _requireUser() {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in with an Affinity administrator account.');
    }
  }
}
