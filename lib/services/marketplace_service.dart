import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

enum ProviderCategory { realtor, mortgageBroker, lawyer, accountant, lender }

extension ProviderCategoryLabel on ProviderCategory {
  String get databaseValue => switch (this) {
    ProviderCategory.realtor => 'realtor',
    ProviderCategory.mortgageBroker => 'mortgage_broker',
    ProviderCategory.lawyer => 'lawyer',
    ProviderCategory.accountant => 'accountant',
    ProviderCategory.lender => 'lender',
  };

  String get label => switch (this) {
    ProviderCategory.realtor => 'Realtors',
    ProviderCategory.mortgageBroker => 'Mortgage brokers',
    ProviderCategory.lawyer => 'Property lawyers',
    ProviderCategory.accountant => 'Accountants',
    ProviderCategory.lender => 'Banks & lenders',
  };
}

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
    MarketplaceCity('Victoria', 'BC', 'CA'),
    MarketplaceCity('Kelowna', 'BC', 'CA'),
    MarketplaceCity('Surrey', 'BC', 'CA'),
    MarketplaceCity('Calgary', 'AB', 'CA'),
    MarketplaceCity('Edmonton', 'AB', 'CA'),
    MarketplaceCity('Toronto', 'ON', 'CA'),
    MarketplaceCity('Ottawa', 'ON', 'CA'),
    MarketplaceCity('Hamilton', 'ON', 'CA'),
    MarketplaceCity('Montreal', 'QC', 'CA'),
    MarketplaceCity('Quebec City', 'QC', 'CA'),
    MarketplaceCity('Winnipeg', 'MB', 'CA'),
    MarketplaceCity('Saskatoon', 'SK', 'CA'),
    MarketplaceCity('Regina', 'SK', 'CA'),
    MarketplaceCity('Halifax', 'NS', 'CA'),
    MarketplaceCity('Moncton', 'NB', 'CA'),
    MarketplaceCity('St. John’s', 'NL', 'CA'),
    MarketplaceCity('Charlottetown', 'PE', 'CA'),
    MarketplaceCity('Whitehorse', 'YT', 'CA'),
    MarketplaceCity('Yellowknife', 'NT', 'CA'),
    MarketplaceCity('Iqaluit', 'NU', 'CA'),
  ];

  static MarketplaceCity customCity(String city, String provinceCode) =>
      MarketplaceCity(city.trim(), provinceCode, 'CA');

  static MarketplaceCity inferCity(String value) {
    final normalized = value.toLowerCase();
    return cities.firstWhere(
      (city) => normalized.contains(city.city.toLowerCase()),
      orElse: () {
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
      },
    );
  }

  static Future<MarketplaceDirectory> load(MarketplaceCity city) async {
    if (!BackendService.configured) return _demo(city);
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
          .limit(40);
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
            .limit(20);
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
      return _demo(city);
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
        _ => null,
      };

  static MarketplaceDirectory _demo(MarketplaceCity city) {
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
            rateLabel: category == ProviderCategory.lender
                ? 'Live quote'
                : null,
          ),
        );
      }
    }

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
    return MarketplaceDirectory(city: city, providers: providers, isDemo: true);
  }
}
