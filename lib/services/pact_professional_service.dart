import 'package:supabase_flutter/supabase_flutter.dart';
import 'marketplace_service.dart';
import 'backend_service.dart';

const pactServices = <String, String>{
  'acquisition_financing': 'Acquisition financing',
  'financial_due_diligence': 'Financial due diligence',
  'legal_due_diligence': 'Legal due diligence',
  'valuation': 'Business valuation',
  'tax_planning': 'Tax planning',
  'succession_planning': 'Succession planning',
  'business_sale': 'Business sale',
  'acquisition_strategy': 'Acquisition strategy',
  'integration': 'Post-acquisition integration',
  'commercial_property': 'Commercial property',
  'insurance': 'Insurance',
  'risk_security': 'Risk and cybersecurity',
};
const pactIndustries = <String, String>{
  'hospitality': 'Hospitality',
  'manufacturing': 'Manufacturing',
  'professional_services': 'Professional services',
  'retail': 'Retail',
  'technology': 'Technology',
  'healthcare': 'Healthcare',
  'construction': 'Construction',
  'real_estate': 'Real estate',
  'transportation': 'Transportation',
  'agriculture': 'Agriculture',
  'other': 'Other',
};
const pactTransactions = <String, String>{
  'business_acquisition': 'Business acquisition',
  'business_sale': 'Business sale',
  'asset_purchase': 'Asset purchase',
  'share_purchase': 'Share purchase',
  'commercial_property': 'Commercial property',
  'mortgage': 'Mortgage',
  'succession': 'Succession',
};
const pactAvailability = <String, String>{
  'unknown': 'Not confirmed',
  'accepting': 'Accepting clients',
  'limited': 'Limited availability',
  'unavailable': 'Not accepting clients',
};
const pactCredentialKinds = <String, String>{
  'professional_licence': 'Professional licence',
  'designation': 'Professional designation',
  'certification': 'Professional certification',
  'education': 'Education',
};
const pactCurrencies = ['CAD', 'USD', 'EUR', 'GBP', 'AUD'];
const pactJurisdictions = <String, String>{
  'CA-BC': 'British Columbia, Canada',
  'CA-AB': 'Alberta, Canada',
  'CA-SK': 'Saskatchewan, Canada',
  'CA-MB': 'Manitoba, Canada',
  'CA-ON': 'Ontario, Canada',
  'CA-QC': 'Quebec, Canada',
  'CA-NB': 'New Brunswick, Canada',
  'CA-NS': 'Nova Scotia, Canada',
  'CA-PE': 'Prince Edward Island, Canada',
  'CA-NL': 'Newfoundland and Labrador, Canada',
  'CA-YT': 'Yukon, Canada',
  'CA-NT': 'Northwest Territories, Canada',
  'CA-NU': 'Nunavut, Canada',
};

class ProfessionalBackground {
  const ProfessionalBackground([this.data = const {}]);
  final Map<String, dynamic> data;
  List<String> values(String key) =>
      (data[key] as List? ?? const []).whereType<String>().toList();
  List<Map<String, dynamic>> entries(String key) =>
      (data[key] as List? ?? const [])
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
  String text(String key) => '${data[key] ?? ''}';
}

class ProfessionalMatch {
  ProfessionalMatch(Map<String, dynamic> row)
    : provider = MarketplaceService.providersFromRows([row['provider']]).single,
      score = (row['score'] as num).toInt(),
      eligible = row['eligible'] == true,
      reasons = List<String>.from(row['reasons'] as List),
      missing = List<String>.from(row['missing'] as List),
      components = Map<String, dynamic>.from(row['components'] as Map);
  final MarketplaceProvider provider;
  final int score;
  final bool eligible;
  final List<String> reasons, missing;
  final Map<String, dynamic> components;
  String get label => !eligible
      ? 'More information needed'
      : score >= 85 &&
            components['service'] == 35 &&
            components['industry'] == 30 &&
            (components['deal'] as num) >= 15
      ? 'Strong fit'
      : score >= 50
      ? 'Relevant experience'
      : 'Limited alignment';
}

class PactProfessionalService {
  static Future<bool> canReviewCredentials() async {
    if (BackendService.user == null) return false;
    try {
      return await Supabase.instance.client.rpc('is_affinity_admin') == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> verifyCredential(
    MarketplaceProvider provider,
    int index,
    bool approved,
  ) async {
    if (provider.updatedAt == null) {
      throw StateError('Refresh this profile first');
    }
    await Supabase.instance.client.rpc(
      'pact_verify_professional_credential',
      params: {
        'target_id': provider.id,
        'claim_index': index,
        'expected_stamp': provider.updatedAt,
        'approve': approved,
      },
    );
  }

  static Future<List<ProfessionalMatch>> match(
    Map<String, dynamic> criteria,
  ) async {
    final rows =
        await Supabase.instance.client.rpc(
              'pact_professional_matches',
              params: {'criteria': criteria},
            )
            as List;
    return rows
        .map((v) => ProfessionalMatch(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> credentials(
    String providerId,
  ) async {
    final rows =
        await Supabase.instance.client.rpc(
              'pact_professional_credentials',
              params: {'target_id': providerId},
            )
            as List;
    return rows.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }
}
