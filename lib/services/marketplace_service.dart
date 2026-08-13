import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/platform_side.dart';
import 'backend_service.dart';

enum ProviderCategory {
  realtor,
  mortgageBroker,
  lawyer,
  accountant,
  lender,
  businessBroker,
  maLawyer,
  qualityOfEarnings,
  commercialLender,
  taxAdvisor,
  insuranceAdvisor,
  humanResources,
  cybersecurity,
  industryAdvisor,
  wealthManager,
}

extension ProviderCategoryLabel on ProviderCategory {
  String get databaseValue => switch (this) {
    ProviderCategory.realtor => 'realtor',
    ProviderCategory.mortgageBroker => 'mortgage_broker',
    ProviderCategory.lawyer => 'lawyer',
    ProviderCategory.accountant => 'accountant',
    ProviderCategory.lender => 'lender',
    ProviderCategory.businessBroker => 'business_broker',
    ProviderCategory.maLawyer => 'ma_lawyer',
    ProviderCategory.qualityOfEarnings => 'quality_of_earnings',
    ProviderCategory.commercialLender => 'commercial_lender',
    ProviderCategory.taxAdvisor => 'tax_advisor',
    ProviderCategory.insuranceAdvisor => 'insurance_advisor',
    ProviderCategory.humanResources => 'human_resources',
    ProviderCategory.cybersecurity => 'cybersecurity',
    ProviderCategory.industryAdvisor => 'industry_advisor',
    ProviderCategory.wealthManager => 'wealth_manager',
  };

  String get label => switch (this) {
    ProviderCategory.realtor => 'Realtors',
    ProviderCategory.mortgageBroker => 'Mortgage brokers',
    ProviderCategory.lawyer => 'Property lawyers',
    ProviderCategory.accountant => 'Accountants',
    ProviderCategory.lender => 'Banks & lenders',
    ProviderCategory.businessBroker => 'Business brokers',
    ProviderCategory.maLawyer => 'M&A lawyers',
    ProviderCategory.qualityOfEarnings => 'QOE professionals',
    ProviderCategory.commercialLender => 'Commercial lenders',
    ProviderCategory.taxAdvisor => 'Tax advisers',
    ProviderCategory.insuranceAdvisor => 'Insurance advisers',
    ProviderCategory.humanResources => 'HR specialists',
    ProviderCategory.cybersecurity => 'Cybersecurity',
    ProviderCategory.industryAdvisor => 'Industry advisers',
    ProviderCategory.wealthManager => 'Wealth managers',
  };

  PlatformSide get side => switch (this) {
    ProviderCategory.realtor ||
    ProviderCategory.mortgageBroker ||
    ProviderCategory.lawyer ||
    ProviderCategory.accountant ||
    ProviderCategory.lender => PlatformSide.property,
    _ => PlatformSide.business,
  };
}

List<ProviderCategory> providerCategoriesFor(PlatformSide side) =>
    ProviderCategory.values.where((category) => category.side == side).toList();

class MarketplaceCity {
  const MarketplaceCity(this.city, this.region, this.countryCode);
  final String city;
  final String region;
  final String countryCode;

  String get label => '$city, $region';
}

class MarketplaceProvince {
  const MarketplaceProvince(this.code, this.name);
  final String code;
  final String name;
}

class MarketplaceProvider {
  const MarketplaceProvider({
    required this.id,
    required this.category,
    required this.name,
    required this.company,
    required this.specialty,
    required this.verified,
    required this.sponsored,
    required this.reviewScore,
    required this.reviewCount,
    required this.experience,
    required this.jobTitle,
    required this.isExample,
    this.photoIndex,
    this.photoUrl = '',
    this.email = '',
    this.phone = '',
    this.websiteUrl = '',
    this.licenseNumber = '',
    this.licenseRegion = '',
    this.acceptingLeads = true,
    this.locations = const [],
    this.membershipTier = 'free',
    this.rateLabel,
    this.rateVerifiedAt,
  });

  final String id;
  final ProviderCategory category;
  final String name;
  final String company;
  final String specialty;
  final bool verified;
  final bool sponsored;
  final double reviewScore;
  final int reviewCount;
  final int experience;
  final String jobTitle;
  final bool isExample;
  final int? photoIndex;
  final String photoUrl;
  final String email;
  final String phone;
  final String websiteUrl;
  final String licenseNumber;
  final String licenseRegion;
  final bool acceptingLeads;
  final List<String> locations;
  final String membershipTier;
  final String? rateLabel;
  final DateTime? rateVerifiedAt;
}

class ProviderReview {
  const ProviderReview({
    required this.id,
    required this.userId,
    required this.reviewerName,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String reviewerName;
  final int rating;
  final String text;
  final DateTime createdAt;

  factory ProviderReview.fromJson(Map<String, dynamic> row) => ProviderReview(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    reviewerName: row['reviewer_name'] as String? ?? 'DwellingsIQ member',
    rating: row['rating'] as int,
    text: row['review_text'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

class MarketplaceDirectory {
  const MarketplaceDirectory({
    required this.city,
    required this.providers,
    required this.isDemo,
  });
  final MarketplaceCity city;
  final List<MarketplaceProvider> providers;
  final bool isDemo;

  List<MarketplaceProvider> forCategory(ProviderCategory category) => providers
      .where((provider) => provider.category == category)
      .take(5)
      .toList();
}

class MarketplaceService {
  static const provinces = [
    MarketplaceProvince('AB', 'Alberta'),
    MarketplaceProvince('BC', 'British Columbia'),
    MarketplaceProvince('MB', 'Manitoba'),
    MarketplaceProvince('NB', 'New Brunswick'),
    MarketplaceProvince('NL', 'Newfoundland and Labrador'),
    MarketplaceProvince('NS', 'Nova Scotia'),
    MarketplaceProvince('NT', 'Northwest Territories'),
    MarketplaceProvince('NU', 'Nunavut'),
    MarketplaceProvince('ON', 'Ontario'),
    MarketplaceProvince('PE', 'Prince Edward Island'),
    MarketplaceProvince('QC', 'Quebec'),
    MarketplaceProvince('SK', 'Saskatchewan'),
    MarketplaceProvince('YT', 'Yukon'),
  ];

  static const cities = [
    MarketplaceCity('Vancouver', 'BC', 'CA'),
    MarketplaceCity('Abbotsford', 'BC', 'CA'),
    MarketplaceCity('Burnaby', 'BC', 'CA'),
    MarketplaceCity('Campbell River', 'BC', 'CA'),
    MarketplaceCity('Chilliwack', 'BC', 'CA'),
    MarketplaceCity('Coquitlam', 'BC', 'CA'),
    MarketplaceCity('Courtenay', 'BC', 'CA'),
    MarketplaceCity('Cranbrook', 'BC', 'CA'),
    MarketplaceCity('Dawson Creek', 'BC', 'CA'),
    MarketplaceCity('Fort St. John', 'BC', 'CA'),
    MarketplaceCity('Kamloops', 'BC', 'CA'),
    MarketplaceCity('Victoria', 'BC', 'CA'),
    MarketplaceCity('Kelowna', 'BC', 'CA'),
    MarketplaceCity('Langley', 'BC', 'CA'),
    MarketplaceCity('Nanaimo', 'BC', 'CA'),
    MarketplaceCity('Nelson', 'BC', 'CA'),
    MarketplaceCity('New Westminster', 'BC', 'CA'),
    MarketplaceCity('North Vancouver', 'BC', 'CA'),
    MarketplaceCity('Penticton', 'BC', 'CA'),
    MarketplaceCity('Port Coquitlam', 'BC', 'CA'),
    MarketplaceCity('Prince George', 'BC', 'CA'),
    MarketplaceCity('Prince Rupert', 'BC', 'CA'),
    MarketplaceCity('Richmond', 'BC', 'CA'),
    MarketplaceCity('Squamish', 'BC', 'CA'),
    MarketplaceCity('Surrey', 'BC', 'CA'),
    MarketplaceCity('Terrace', 'BC', 'CA'),
    MarketplaceCity('Vernon', 'BC', 'CA'),
    MarketplaceCity('Whistler', 'BC', 'CA'),
    MarketplaceCity('Calgary', 'AB', 'CA'),
    MarketplaceCity('Airdrie', 'AB', 'CA'),
    MarketplaceCity('Banff', 'AB', 'CA'),
    MarketplaceCity('Canmore', 'AB', 'CA'),
    MarketplaceCity('Edmonton', 'AB', 'CA'),
    MarketplaceCity('Fort McMurray', 'AB', 'CA'),
    MarketplaceCity('Grande Prairie', 'AB', 'CA'),
    MarketplaceCity('Lethbridge', 'AB', 'CA'),
    MarketplaceCity('Medicine Hat', 'AB', 'CA'),
    MarketplaceCity('Red Deer', 'AB', 'CA'),
    MarketplaceCity('Toronto', 'ON', 'CA'),
    MarketplaceCity('Barrie', 'ON', 'CA'),
    MarketplaceCity('Belleville', 'ON', 'CA'),
    MarketplaceCity('Brampton', 'ON', 'CA'),
    MarketplaceCity('Brantford', 'ON', 'CA'),
    MarketplaceCity('Burlington', 'ON', 'CA'),
    MarketplaceCity('Guelph', 'ON', 'CA'),
    MarketplaceCity('Ottawa', 'ON', 'CA'),
    MarketplaceCity('Hamilton', 'ON', 'CA'),
    MarketplaceCity('Kingston', 'ON', 'CA'),
    MarketplaceCity('Kitchener', 'ON', 'CA'),
    MarketplaceCity('London', 'ON', 'CA'),
    MarketplaceCity('Markham', 'ON', 'CA'),
    MarketplaceCity('Mississauga', 'ON', 'CA'),
    MarketplaceCity('Niagara Falls', 'ON', 'CA'),
    MarketplaceCity('North Bay', 'ON', 'CA'),
    MarketplaceCity('Oakville', 'ON', 'CA'),
    MarketplaceCity('Oshawa', 'ON', 'CA'),
    MarketplaceCity('Peterborough', 'ON', 'CA'),
    MarketplaceCity('Richmond Hill', 'ON', 'CA'),
    MarketplaceCity('St. Catharines', 'ON', 'CA'),
    MarketplaceCity('Sudbury', 'ON', 'CA'),
    MarketplaceCity('Thunder Bay', 'ON', 'CA'),
    MarketplaceCity('Vaughan', 'ON', 'CA'),
    MarketplaceCity('Waterloo', 'ON', 'CA'),
    MarketplaceCity('Windsor', 'ON', 'CA'),
    MarketplaceCity('Montreal', 'QC', 'CA'),
    MarketplaceCity('Gatineau', 'QC', 'CA'),
    MarketplaceCity('Laval', 'QC', 'CA'),
    MarketplaceCity('Longueuil', 'QC', 'CA'),
    MarketplaceCity('Quebec City', 'QC', 'CA'),
    MarketplaceCity('Saguenay', 'QC', 'CA'),
    MarketplaceCity('Sherbrooke', 'QC', 'CA'),
    MarketplaceCity('Trois-Rivières', 'QC', 'CA'),
    MarketplaceCity('Winnipeg', 'MB', 'CA'),
    MarketplaceCity('Brandon', 'MB', 'CA'),
    MarketplaceCity('Saskatoon', 'SK', 'CA'),
    MarketplaceCity('Regina', 'SK', 'CA'),
    MarketplaceCity('Prince Albert', 'SK', 'CA'),
    MarketplaceCity('Halifax', 'NS', 'CA'),
    MarketplaceCity('Cape Breton', 'NS', 'CA'),
    MarketplaceCity('Truro', 'NS', 'CA'),
    MarketplaceCity('Fredericton', 'NB', 'CA'),
    MarketplaceCity('Moncton', 'NB', 'CA'),
    MarketplaceCity('Saint John', 'NB', 'CA'),
    MarketplaceCity('Corner Brook', 'NL', 'CA'),
    MarketplaceCity('St. John’s', 'NL', 'CA'),
    MarketplaceCity('Summerside', 'PE', 'CA'),
    MarketplaceCity('Charlottetown', 'PE', 'CA'),
    MarketplaceCity('Whitehorse', 'YT', 'CA'),
    MarketplaceCity('Yellowknife', 'NT', 'CA'),
    MarketplaceCity('Iqaluit', 'NU', 'CA'),
  ];

  static String _normal(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static List<MarketplaceCity> citySuggestions(
    String query, {
    String? provinceCode,
    int limit = 8,
  }) {
    final needle = _normal(query.split(',').first);
    final pool = provinceCode == null
        ? cities
        : cities.where((city) => city.region == provinceCode).toList();
    if (needle.isEmpty) return pool.take(limit).toList();
    final ranked = <(MarketplaceCity, int)>[];
    for (final city in pool) {
      final name = _normal(city.city);
      final score = name.startsWith(needle)
          ? 0
          : name.contains(needle)
          ? 1
          : 2 + _editDistance(needle, name);
      if (score <= 5 || name.contains(needle)) ranked.add((city, score));
    }
    ranked.sort((a, b) {
      final score = a.$2.compareTo(b.$2);
      return score != 0 ? score : a.$1.city.compareTo(b.$1.city);
    });
    return ranked.take(limit).map((item) => item.$1).toList();
  }

  /// Searches Canada's official CGNDB place-name service, with the local
  /// typo-tolerant catalogue retained as a fast and offline fallback.
  static Future<List<MarketplaceCity>> searchCanadianCities(
    String query, {
    int limit = 8,
  }) async {
    final local = citySuggestions(query, limit: limit);
    if (query.trim().length < 2) return local;
    try {
      final uri =
          Uri.https('geogratis.gc.ca', '/services/geoname/en/geonames.json', {
            'category': 'O',
            'q': query.trim(),
            'expand': 'items.province',
            'select': 'items.province.description',
          });
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return local;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = (payload['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final province = item['province'] as Map<String, dynamic>?;
            final provinceName = province?['description'] as String? ?? '';
            final region = provinces
                .where((entry) => entry.name == provinceName)
                .map((entry) => entry.code)
                .firstOrNull;
            final name = item['name'] as String? ?? '';
            return name.isEmpty || region == null
                ? null
                : MarketplaceCity(name, region, 'CA');
          })
          .whereType<MarketplaceCity>();
      final merged = <String, MarketplaceCity>{
        for (final city in [...local, ...remote])
          '${_normal(city.city)}-${city.region}': city,
      };
      return merged.values.take(limit).toList();
    } catch (_) {
      return local;
    }
  }

  static Future<MarketplaceCity?> cityNearCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri =
          Uri.https('geogratis.gc.ca', '/services/geoname/en/geonames.json', {
            'lat': latitude.toStringAsFixed(6),
            'lon': longitude.toStringAsFixed(6),
            'radius': '50',
            'theme': '985',
            'category': 'O',
            'sort-field': 'distance',
            'expand': 'items.province',
            'select': 'items.province.description',
          });
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      for (final item in payload['items'] as List<dynamic>? ?? const []) {
        if (item is! Map<String, dynamic>) continue;
        final province = item['province'] as Map<String, dynamic>?;
        final provinceName = province?['description'] as String? ?? '';
        final region = provinces
            .where((entry) => entry.name == provinceName)
            .map((entry) => entry.code)
            .firstOrNull;
        final name = item['name'] as String? ?? '';
        if (name.isNotEmpty && region != null) {
          return MarketplaceCity(name, region, 'CA');
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static MarketplaceCity? resolveCanadianCity(
    String value, {
    String? provinceCode,
  }) {
    final suggestions = citySuggestions(
      value,
      provinceCode: provinceCode,
      limit: 1,
    );
    if (suggestions.isEmpty) return null;
    final typed = _normal(value.split(',').first);
    final match = suggestions.first;
    final distance = _editDistance(typed, _normal(match.city));
    return distance <= (typed.length < 6 ? 1 : 3) ||
            _normal(match.city).startsWith(typed)
        ? match
        : null;
  }

  static int _editDistance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
        ].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous.last;
  }

  static MarketplaceCity customCity(String city, String provinceCode) =>
      MarketplaceCity(city.trim(), provinceCode, 'CA');

  static MarketplaceCity inferCity(String value) {
    final normalized = value.toLowerCase();
    final named = cities.where(
      (city) => normalized.contains(city.city.toLowerCase()),
    );
    if (named.isNotEmpty) return named.first;
    final corrected = resolveCanadianCity(value.split(',').first);
    if (corrected != null) return corrected;
    return (() {
      final province = provinces.firstWhere(
        (item) =>
            normalized.contains(item.code.toLowerCase()) ||
            normalized.contains(item.name.toLowerCase()),
        orElse: () => provinces[1],
      );
      final parts = value.split(',');
      final city = parts.first.trim();
      return MarketplaceCity(
        city.isEmpty ? 'Vancouver' : city,
        province.code,
        'CA',
      );
    })();
  }

  static Future<MarketplaceDirectory> load(
    MarketplaceCity city, {
    PlatformSide side = PlatformSide.property,
  }) async {
    final providerTypes = providerCategoriesFor(
      side,
    ).map((category) => category.databaseValue).toList();
    if (!BackendService.configured) return _demo(city, side);
    try {
      var rows = await Supabase.instance.client
          .from('provider_profiles')
          .select(
            'id, provider_type, display_name, company_name, description, phone, email, website_url, '
            'license_number, license_region, accepting_leads, membership_tier, verified, years_experience, review_score, review_count, job_title, '
            'is_example, photo_index, logo_object_key, '
            'provider_regions!inner(service_regions!inner(city, region, country_code)), '
            'sponsored_placements(disclosure_label, active, starts_at, ends_at), '
            'lender_rates(interest_rate, mortgage_type, verified_at, effective_at, expires_at)',
          )
          .eq('provider_regions.service_regions.city', city.city)
          .eq('provider_regions.service_regions.region', city.region)
          .inFilter('provider_type', providerTypes)
          .limit(80);
      if (rows.isEmpty) {
        rows = await Supabase.instance.client
            .from('provider_profiles')
            .select(
              'id, provider_type, display_name, company_name, description, phone, email, website_url, '
              'license_number, license_region, accepting_leads, membership_tier, verified, years_experience, review_score, review_count, job_title, '
              'is_example, photo_index, logo_object_key, '
              'sponsored_placements(disclosure_label, active, starts_at, ends_at), '
              'lender_rates(interest_rate, mortgage_type, verified_at, effective_at, expires_at)',
            )
            .eq('is_example', true)
            .inFilter('provider_type', providerTypes)
            .limit(80);
      }
      final providers = providersFromRows(rows);
      providers.sort((a, b) {
        if (a.sponsored != b.sponsored) return a.sponsored ? -1 : 1;
        return b.reviewScore.compareTo(a.reviewScore);
      });
      return MarketplaceDirectory(
        city: city,
        providers: providers,
        isDemo: false,
      );
    } catch (_) {
      return _demo(city, side);
    }
  }

  static List<MarketplaceProvider> providersFromRows(List<dynamic> rows) {
    final providers = <MarketplaceProvider>[];
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      final category = _categoryFromDatabase(row['provider_type'] as String?);
      if (category == null) continue;
      final sponsorships = (row['sponsored_placements'] as List?) ?? const [];
      final rates = (row['lender_rates'] as List?) ?? const [];
      final regionRows = (row['provider_regions'] as List?) ?? const [];
      final locations = regionRows
          .map((rawRegion) => Map<String, dynamic>.from(rawRegion as Map))
          .map((region) => region['service_regions'])
          .whereType<Map>()
          .map((rawLocation) => Map<String, dynamic>.from(rawLocation))
          .map(
            (location) =>
                '${location['city'] as String? ?? ''}, ${location['region'] as String? ?? ''}',
          )
          .where((location) => !location.startsWith(','))
          .toSet()
          .toList();
      final rate = rates.isEmpty
          ? null
          : Map<String, dynamic>.from(rates.first as Map);
      providers.add(
        MarketplaceProvider(
          id: row['id'] as String,
          category: category,
          name: row['display_name'] as String? ?? 'Provider',
          company: row['company_name'] as String? ?? '',
          specialty: row['description'] as String? ?? '',
          verified: row['verified'] as bool? ?? false,
          sponsored: sponsorships.isNotEmpty,
          reviewScore: (row['review_score'] as num?)?.toDouble() ?? 0,
          reviewCount: row['review_count'] as int? ?? 0,
          experience: row['years_experience'] as int? ?? 0,
          jobTitle: row['job_title'] as String? ?? category.label,
          isExample: row['is_example'] as bool? ?? false,
          photoIndex: row['photo_index'] as int?,
          photoUrl: row['logo_object_key'] as String? ?? '',
          email: row['email'] as String? ?? '',
          phone: row['phone'] as String? ?? '',
          websiteUrl: row['website_url'] as String? ?? '',
          licenseNumber: row['license_number'] as String? ?? '',
          licenseRegion: row['license_region'] as String? ?? '',
          acceptingLeads: row['accepting_leads'] as bool? ?? true,
          locations: locations,
          membershipTier: row['membership_tier'] as String? ?? 'free',
          rateLabel: rate == null
              ? null
              : '${(rate['interest_rate'] as num).toStringAsFixed(2)}%',
          rateVerifiedAt: rate?['verified_at'] == null
              ? null
              : DateTime.tryParse(rate!['verified_at'] as String),
        ),
      );
    }
    return providers;
  }

  static Future<void> addToTeam(MarketplaceProvider provider) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to build your team.');
    if (provider.id.startsWith('demo-')) return;
    await Supabase.instance.client.from('user_team_members').upsert({
      'user_id': user.id,
      'provider_id': provider.id,
    });
  }

  static Future<void> removeFromTeam(String providerId) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to manage your team.');
    await Supabase.instance.client
        .from('user_team_members')
        .delete()
        .eq('user_id', user.id)
        .eq('provider_id', providerId);
  }

  static Future<bool> isOnTeam(String providerId) async {
    final user = BackendService.user;
    if (user == null) return false;
    final row = await Supabase.instance.client
        .from('user_team_members')
        .select('provider_id')
        .eq('user_id', user.id)
        .eq('provider_id', providerId)
        .maybeSingle();
    return row != null;
  }

  static Future<List<ProviderReview>> loadReviews(String providerId) async {
    final rows = await Supabase.instance.client
        .from('provider_reviews')
        .select('id, user_id, reviewer_name, rating, review_text, created_at')
        .eq('provider_id', providerId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map((row) => ProviderReview.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<void> saveReview({
    required MarketplaceProvider provider,
    required int rating,
    required String text,
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to leave a review.');
    if (provider.isExample) {
      throw StateError('Example profiles cannot receive real reviews.');
    }
    await Supabase.instance.client.from('provider_reviews').upsert({
      'provider_id': provider.id,
      'user_id': user.id,
      'rating': rating,
      'review_text': text.trim(),
    }, onConflict: 'provider_id,user_id');
  }

  static Future<void> requestConnection({
    required MarketplaceProvider provider,
    required MarketplaceCity city,
    required String name,
    required String email,
    String? phone,
    String? propertySummary,
  }) async {
    if (!BackendService.configured || provider.id.startsWith('demo-')) return;
    final region = await Supabase.instance.client
        .from('service_regions')
        .select('id')
        .eq('city', city.city)
        .eq('region', city.region)
        .limit(1)
        .maybeSingle();
    await Supabase.instance.client.from('lead_requests').insert({
      'user_id': BackendService.user?.id,
      'provider_id': provider.id,
      'region_id': region?['id'],
      'requester_name': name,
      'requester_email': email,
      'requester_phone': phone,
      'property_summary': propertySummary,
      'consent_to_contact': true,
    });
  }

  static ProviderCategory? _categoryFromDatabase(String? value) =>
      switch (value) {
        'realtor' => ProviderCategory.realtor,
        'mortgage_broker' => ProviderCategory.mortgageBroker,
        'lawyer' => ProviderCategory.lawyer,
        'accountant' => ProviderCategory.accountant,
        'lender' => ProviderCategory.lender,
        'business_broker' => ProviderCategory.businessBroker,
        'ma_lawyer' => ProviderCategory.maLawyer,
        'quality_of_earnings' => ProviderCategory.qualityOfEarnings,
        'commercial_lender' => ProviderCategory.commercialLender,
        'tax_advisor' => ProviderCategory.taxAdvisor,
        'insurance_advisor' => ProviderCategory.insuranceAdvisor,
        'human_resources' => ProviderCategory.humanResources,
        'cybersecurity' => ProviderCategory.cybersecurity,
        'industry_advisor' => ProviderCategory.industryAdvisor,
        'wealth_manager' => ProviderCategory.wealthManager,
        _ => null,
      };

  static MarketplaceDirectory _demo(MarketplaceCity city, PlatformSide side) {
    final cityName = city.city;
    const names = [
      ('Avery Chen', 'Northline Property Group'),
      ('Maya Singh', 'Keyside Real Estate'),
      ('Noah Williams', 'Civic Homes Advisory'),
      ('Sofia Martin', 'Groundwork Realty'),
      ('Eli Thompson', 'Urbanframe Partners'),
    ];
    const brokerNames = [
      ('Taylor Morgan', 'ClearPath Mortgage'),
      ('Jordan Lee', 'Foundation Lending'),
      ('Alex Rivera', 'OpenDoor Mortgage'),
      ('Sam Patel', 'Homeward Finance'),
      ('Riley Kim', 'TrueNorth Mortgages'),
    ];
    const lawyerNames = [
      ('Jamie Park', 'Threshold Law'),
      ('Morgan Bell', 'Civic Property Legal'),
      ('Drew Wilson', 'Title & Key Law'),
      ('Casey Nguyen', 'Harbour Conveyancing'),
      ('Robin Shah', 'Cornerstone Legal'),
    ];
    const lenders = [
      ('Home Lending Desk', 'Civic Bank'),
      ('Mortgage Team', 'Northshore Credit Union'),
      ('Property Finance', 'Foundation Bank'),
      ('Residential Lending', 'Keyline Financial'),
      ('Commercial Lending', 'Metro Capital'),
    ];
    const accountants = [
      ('Elena Rossi', 'Rossi Property Tax Advisory'),
      ('Omar Haddad', 'Haddad CPA Practice'),
    ];
    const businessGroups = <ProviderCategory, List<(String, String)>>{
      ProviderCategory.businessBroker: [
        ('Amelia Foster', 'Northstar Business Sales'),
        ('Liam Desai', 'Pacific Transaction Partners'),
      ],
      ProviderCategory.maLawyer: [
        ('Nadia Campbell', 'Campbell M&A Law'),
        ('Julian Park', 'Harbour Corporate Legal'),
      ],
      ProviderCategory.qualityOfEarnings: [
        ('Grace Okafor', 'ClearLedger Advisory'),
        ('Thomas Leung', 'Northline Transaction Services'),
      ],
      ProviderCategory.commercialLender: [
        ('Mia Reynolds', 'Western Commercial Bank'),
        ('Arjun Mehta', 'Growth Capital Credit'),
      ],
      ProviderCategory.taxAdvisor: [
        ('Sophie Tremblay', 'Continuity Tax Partners'),
        ('Marcus Chen', 'Keystone Tax Advisory'),
      ],
      ProviderCategory.insuranceAdvisor: [
        ('Olivia Brooks', 'Shieldline Risk'),
        ('Ethan Clarke', 'Continuum Insurance'),
      ],
      ProviderCategory.humanResources: [
        ('Aisha Morgan', 'PeopleBridge HR'),
        ('Lucas Nguyen', 'Transition Workforce Advisory'),
      ],
      ProviderCategory.cybersecurity: [
        ('Isabelle Roy', 'SignalFort Security'),
        ('Mateo Wilson', 'Northwall Cyber'),
      ],
      ProviderCategory.industryAdvisor: [
        ('Chloe Bennett', 'SectorWorks Advisory'),
        ('Benjamin Singh', 'Operator Insight Group'),
      ],
      ProviderCategory.wealthManager: [
        ('Emma Laurent', 'Longview Private Wealth'),
        ('Nathan Patel', 'Continuity Wealth Partners'),
      ],
    };
    final providers = <MarketplaceProvider>[];
    void addGroup(
      ProviderCategory category,
      List<(String, String)> group,
      String specialty,
    ) {
      for (var index = 0; index < group.length; index++) {
        providers.add(
          MarketplaceProvider(
            id: 'demo-${category.name}-$index',
            category: category,
            name: group[index].$1,
            company: group[index].$2,
            specialty: '$cityName · $specialty',
            verified: index < 4,
            sponsored: index == 0,
            reviewScore: 4.9 - index * .1,
            reviewCount: 86 - index * 9,
            experience: 12 - index,
            jobTitle: category.label,
            isExample: true,
            photoIndex: index,
            rateLabel:
                category == ProviderCategory.lender ||
                    category == ProviderCategory.commercialLender
                ? 'Live quote'
                : null,
          ),
        );
      }
    }

    if (side == PlatformSide.property) {
      addGroup(ProviderCategory.realtor, names, 'Buyer representation');
      addGroup(
        ProviderCategory.mortgageBroker,
        brokerNames,
        'Residential & investment financing',
      );
      addGroup(
        ProviderCategory.lawyer,
        lawyerNames,
        'Property purchase & conveyancing',
      );
      addGroup(
        ProviderCategory.accountant,
        accountants,
        'Property tax & accounting',
      );
      addGroup(
        ProviderCategory.lender,
        lenders,
        'Qualification-dependent pricing',
      );
    } else {
      const specialties = {
        ProviderCategory.businessBroker: 'Search, valuation and negotiation',
        ProviderCategory.maLawyer: 'LOI, diligence and purchase agreements',
        ProviderCategory.qualityOfEarnings:
            'Earnings normalization and financial diligence',
        ProviderCategory.commercialLender:
            'Acquisition and working-capital financing',
        ProviderCategory.taxAdvisor: 'Deal structure and tax diligence',
        ProviderCategory.insuranceAdvisor:
            'Transaction, liability and continuity coverage',
        ProviderCategory.humanResources:
            'Employment obligations and transition planning',
        ProviderCategory.cybersecurity:
            'Technology, privacy and cyber-risk diligence',
        ProviderCategory.industryAdvisor:
            'Sector benchmarks and operating diligence',
        ProviderCategory.wealthManager:
            'Buyer liquidity and post-close wealth planning',
      };
      for (final entry in businessGroups.entries) {
        addGroup(entry.key, entry.value, specialties[entry.key]!);
      }
    }
    return MarketplaceDirectory(city: city, providers: providers, isDemo: true);
  }
}
