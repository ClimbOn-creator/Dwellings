import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.isExample = false,
    this.exampleAsset = '',
  });

  final bool isExample;
  final String exampleAsset;
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

  static const exampleIds = [
    'example-advisory',
    'example-workspace',
    'example-fabrication',
    'example-management',
  ];
  static Future<List<BusinessSaleBulletin>> examples() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getStringList('affinity.example-businesses.saved') ?? [];
    final specs = [
      (
        'example-advisory',
        'Harbour Advisory Studio',
        'Professional services',
        'Victoria, BC',
        r'$325,000',
        r'$680,000',
        r'$128,000',
        'affinity-consulting.jpg',
        'A boutique bookkeeping and advisory practice serving independent businesses. Recurring monthly retainers and a small delivery team create a practical foundation for a hands-on owner.',
        'Established client relationships; monthly service packages; documented onboarding process.',
        'Leased studio; lease assignment subject to landlord approval.',
        'Central Victoria with a hybrid service model.',
        'Illustrative owner transition; three months of handover support.',
      ),
      (
        'example-workspace',
        'Foundry Workspaces',
        'Coworking & business services',
        'Calgary, AB',
        r'$785,000',
        r'$1,120,000',
        r'$205,000',
        'commercial-atrium.jpg',
        'A flexible workspace business with private offices, shared desks and meeting-room bookings. Explore a membership model with recurring revenue and room to improve occupancy.',
        'Multiple membership tiers; meeting-room revenue; established local business community.',
        'Leased commercial premises; real estate is not included.',
        'An accessible mixed-use neighbourhood in Calgary.',
        'Illustrative portfolio simplification; staff-led day-to-day operations.',
      ),
      (
        'example-fabrication',
        'Northline Precision Works',
        'Manufacturing',
        'Hamilton, ON',
        r'$1,650,000',
        r'$2,850,000',
        r'$415,000',
        'affinity-deal-screen.jpg',
        'A small precision fabrication shop supporting regional industrial customers. The example includes an experienced production team, repeat commercial orders and a meaningful equipment base.',
        'Repeat B2B customers; skilled production team; equipment included subject to diligence.',
        'Leased industrial facility; equipment included in the illustrative asking price.',
        'Hamilton industrial corridor with regional distribution access.',
        'Illustrative retirement sale; six-month transition available.',
      ),
      (
        'example-management',
        'Evergreen Property Partners',
        'Property management',
        'Kelowna, BC',
        r'$2,450,000',
        r'$3,600,000',
        r'$580,000',
        'affinity-member-studio.jpg',
        'An established property-management operation coordinating leasing, maintenance and owner reporting. Explore the economics of recurring management fees and an experienced service team.',
        'Recurring management contracts; established vendor network; experienced operations manager.',
        'Leased office; managed client properties are not part of the sale.',
        'Serving Kelowna and surrounding Okanagan communities.',
        'Illustrative founder succession; structured handover proposed.',
      ),
    ];
    return [
      for (final x in specs)
        BusinessSaleBulletin(
          id: x.$1,
          title: x.$2,
          industry: x.$3,
          region: x.$4,
          askingPriceBand: x.$5,
          summary: x.$9,
          sourceLabel: 'Affinity fictional example — no seller',
          sourceUrl: '',
          postedAt: DateTime.utc(2026, 9, 11),
          canConvert: false,
          isExample: true,
          exampleAsset: 'assets/images/${x.$8}',
          isSaved: saved.contains(x.$1),
          details: {
            'revenue': x.$6,
            'cash_flow': x.$7,
            'highlights': x.$10,
            'real_estate': x.$11,
            'location_details': x.$12,
            'reason_for_selling': x.$13,
            'listing_type': 'Fictional example · amounts in CAD',
          },
        ),
    ];
  }

  static Future<List<BusinessSaleBulletin>> load({
    bool includeExamples = false,
  }) async {
    final real = <BusinessSaleBulletin>[];
    if (BackendService.configured) {
      final rows = await _client.rpc('browse_business_sale_bulletins_v2');
      real.addAll(
        (rows as List<dynamic>).map(
          (row) => BusinessSaleBulletin.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        ),
      );
    }
    return [...real, if (includeExamples) ...await examples()];
  }

  static Future<BusinessSaleBulletin?> loadOne(String id) async {
    if (exampleIds.contains(id))
      return (await examples()).firstWhere((b) => b.id == id);
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
    if (exampleIds.contains(id)) {
      final prefs = await SharedPreferences.getInstance();
      final ids =
          (prefs.getStringList('affinity.example-businesses.saved') ?? [])
              .toSet();
      if (saved) {
        ids.add(id);
      } else {
        ids.remove(id);
      }
      await prefs.setStringList(
        'affinity.example-businesses.saved',
        ids.toList(),
      );
      return;
    }
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
