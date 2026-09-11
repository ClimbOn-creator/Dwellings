import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

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
    this.details = const {},
    this.canEdit = false,
    this.isSaved = false,
    this.updatedAt,
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
  final Map<String, dynamic> details;
  final bool canEdit;
  final bool isSaved;
  final DateTime? updatedAt;
  String detail(String key) => '${details[key] ?? ''}';
  List<String> get photos => (details['photos'] is List)
      ? (details['photos'] as List)
            .whereType<String>()
            .where(validWebUrl)
            .toList()
      : const [];
  static bool validWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
  }

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
    canEdit: row['can_edit'] == true,
    isSaved: row['is_saved'] == true,
    updatedAt: DateTime.tryParse('${row['updated_at'] ?? ''}'),
    details: row['details'] is Map
        ? Map<String, dynamic>.from(row['details'] as Map)
        : const {},
  );
}

class BusinessSaleBulletinService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<BusinessSaleBulletin>> load() async {
    if (!BackendService.configured) return const [];
    final rows = await _client.rpc('browse_business_sale_bulletins_v2');
    return (rows as List<dynamic>)
        .map(
          (row) => BusinessSaleBulletin.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<BusinessSaleBulletin?> loadOne(String id) async {
    if (!BackendService.configured) return null;
    final rows =
        await _client.rpc(
              'browse_business_sale_bulletins_v2',
              params: {'target_id': id},
            )
            as List;
    return rows.isEmpty
        ? null
        : BusinessSaleBulletin.fromJson(
            Map<String, dynamic>.from(rows.first as Map),
          );
  }

  static Future<void> setSaved(String id, bool saved) async {
    _requireUser();
    await _client.rpc(
      'set_business_sale_bulletin_saved',
      params: {'target_id': id, 'should_save': saved},
    );
  }

  static Future<String> saveListing(
    Map<String, dynamic> listing, {
    String? id,
  }) async {
    _requireUser();
    return await _client.rpc(
          'save_business_sale_bulletin',
          params: {'target_id': id, 'listing': listing},
        )
        as String;
  }

  static Future<String> uploadPhoto(Uint8List bytes, String extension) async {
    _requireUser();
    final ext = extension.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext) ||
        bytes.length > 8388608) {
      throw StateError('Choose a JPG, PNG or WebP image under 8 MB.');
    }
    final path =
        '${BackendService.user!.id}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final bucket = _client.storage.from('business-listing-photos');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
      ),
    );
    return bucket.getPublicUrl(path);
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
