import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

enum ProviderCategory { realtor, mortgageBroker, lawyer, lender }

extension ProviderCategoryLabel on ProviderCategory {
  String get databaseValue => switch (this) {
    ProviderCategory.realtor => 'realtor',
    ProviderCategory.mortgageBroker => 'mortgage_broker',
    ProviderCategory.lawyer => 'lawyer',
    ProviderCategory.lender => 'lender',
  };

  String get label => switch (this) {
    ProviderCategory.realtor => 'Realtors',
    ProviderCategory.mortgageBroker => 'Mortgage brokers',
    ProviderCategory.lawyer => 'Property lawyers',
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
  final String? rateLabel;
  final DateTime? rateVerifiedAt;
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
  static const cities = [
    MarketplaceCity('Vancouver', 'BC', 'CA'),
    MarketplaceCity('Victoria', 'BC', 'CA'),
    MarketplaceCity('Calgary', 'AB', 'CA'),
    MarketplaceCity('Toronto', 'ON', 'CA'),
    MarketplaceCity('Seattle', 'WA', 'US'),
  ];

  static MarketplaceCity inferCity(String value) {
    final normalized = value.toLowerCase();
    return cities.firstWhere(
      (city) => normalized.contains(city.city.toLowerCase()),
      orElse: () => cities.first,
    );
  }

  static Future<MarketplaceDirectory> load(MarketplaceCity city) async {
    if (!BackendService.configured) return _demo(city);
    try {
      final rows = await Supabase.instance.client
          .from('provider_profiles')
          .select(
            'id, provider_type, display_name, company_name, description, '
            'verified, years_experience, review_score, review_count, '
            'provider_regions!inner(service_regions!inner(city, region, country_code)), '
            'sponsored_placements(disclosure_label, active, starts_at, ends_at), '
            'lender_rates(interest_rate, mortgage_type, verified_at, effective_at, expires_at)',
          )
          .eq('provider_regions.service_regions.city', city.city)
          .eq('provider_regions.service_regions.region', city.region)
          .eq('verified', true)
          .limit(40);
      final providers = <MarketplaceProvider>[];
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final category = _categoryFromDatabase(row['provider_type'] as String?);
        if (category == null) continue;
        final sponsorships = (row['sponsored_placements'] as List?) ?? const [];
        final rates = (row['lender_rates'] as List?) ?? const [];
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
            rateLabel: rate == null
                ? null
                : '${(rate['interest_rate'] as num).toStringAsFixed(2)}%',
            rateVerifiedAt: rate?['verified_at'] == null
                ? null
                : DateTime.tryParse(rate!['verified_at'] as String),
          ),
        );
      }
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
      ProviderCategory.lender,
      lenders,
      'Qualification-dependent pricing',
    );
    return MarketplaceDirectory(city: city, providers: providers, isDemo: true);
  }
}
