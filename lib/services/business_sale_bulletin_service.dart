import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class BusinessSaleBulletin {
  const BusinessSaleBulletin({
    required this.id,
    required this.title,
    required this.industry,
    required this.region,
    required this.askingPriceBand,
    required this.summary,
    required this.sourceLabel,
    required this.sourceUrl,
    required this.postedAt,
    required this.canConvert,
    this.convertedOpportunityId,
  });

  final String id;
  final String title;
  final String industry;
  final String region;
  final String askingPriceBand;
  final String summary;
  final String sourceLabel;
  final String sourceUrl;
  final DateTime postedAt;
  final bool canConvert;
  final String? convertedOpportunityId;

  bool get converted => convertedOpportunityId != null;

  factory BusinessSaleBulletin.fromJson(
    Map<String, dynamic> row,
  ) => BusinessSaleBulletin(
    id: row['id'] as String,
    title: row['title'] as String? ?? 'Business for sale',
    industry: row['industry'] as String? ?? 'Business',
    region: row['region'] as String? ?? 'Location not listed',
    askingPriceBand: row['asking_price_band'] as String? ?? 'Contact seller',
    summary: row['summary'] as String? ?? '',
    sourceLabel: row['source_label'] as String? ?? '',
    sourceUrl: row['source_url'] as String? ?? '',
    postedAt:
        DateTime.tryParse(row['posted_at'] as String? ?? '') ?? DateTime.now(),
    canConvert: row['can_convert'] as bool? ?? false,
    convertedOpportunityId: row['converted_opportunity_id'] as String?,
  );
}

class BusinessSaleBulletinService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<BusinessSaleBulletin>> load() async {
    if (!BackendService.configured) return const [];
    final rows = await _client.rpc('browse_business_sale_bulletins');
    return (rows as List<dynamic>)
        .map(
          (row) => BusinessSaleBulletin.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> create({
    required String title,
    required String industry,
    required String region,
    required String askingPriceBand,
    required String summary,
    required String sourceLabel,
    required String sourceUrl,
  }) async {
    _requireUser();
    await _client.rpc(
      'create_business_sale_bulletin',
      params: {
        'business_title': title.trim(),
        'business_industry': industry.trim(),
        'business_region': region.trim(),
        'business_asking_price_band': askingPriceBand.trim(),
        'business_summary': summary.trim(),
        'business_source_label': sourceLabel.trim(),
        'business_source_url': sourceUrl.trim(),
      },
    );
  }

  static Future<String> makeAnonymousDeal({
    required String bulletinId,
    required String headline,
    required String summary,
  }) async {
    _requireUser();
    final result = await _client.rpc(
      'create_anonymous_deal_from_bulletin',
      params: {
        'target_bulletin_id': bulletinId,
        'anonymous_headline': headline.trim(),
        'anonymous_summary': summary.trim(),
      },
    );
    return result as String;
  }

  static void _requireUser() {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in to open the business sale bulletin board.');
    }
  }
}
