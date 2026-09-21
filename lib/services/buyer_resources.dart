import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class BuyerResource {
  const BuyerResource(
    this.id,
    this.name,
    this.kind,
    this.region,
    this.summary,
    this.eligibility,
    this.url,
  );
  final String id, name, kind, region, summary, eligibility, url;
  bool matches(String query) => query
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .every(
        ('$name $kind $region $summary $eligibility').toLowerCase().contains,
      );
}

const buyerResources = <BuyerResource>[
  BuyerResource(
    'benefits-finder',
    'Business Benefits Finder',
    'Funding directory',
    'Canada',
    'Find government grants, loans, tax credits and advisory support matched to your business.',
    'Answer the official questionnaire for your location, sector and ownership. Each program has its own eligibility and intake.',
    'https://innovation.ised-isde.canada.ca/s/?language=en_CA',
  ),
  BuyerResource(
    'community-futures',
    'Community Futures BC',
    'Community support',
    'British Columbia',
    'Local business advice, succession support and repayable financing for starting, growing or buying a business.',
    'Contact the office serving the business location. Services, loan terms and lending decisions vary by office.',
    'https://www.communityfutures.ca/',
  ),
  BuyerResource(
    'bdc-acquisition',
    'BDC business purchase financing',
    'Loans',
    'Canada',
    'Financing designed for buying or transferring an established business.',
    'An acquisition with revenue and an established client base. BDC assesses the business, buyer and proposed transaction.',
    'https://www.bdc.ca/en/financing/buy-transfer-a-business-loan',
  ),
  BuyerResource(
    'csbfp',
    'Canada Small Business Financing Program',
    'Loans',
    'Canada',
    'Government-backed lending through participating financial institutions for eligible business costs.',
    'Lender approval required. Share purchases are not eligible; check eligible asset and operating costs before structuring a purchase.',
    'https://ised-isde.canada.ca/site/canada-small-business-financing-program/en/frequently-asked-questions-small-businesses',
  ),
  BuyerResource(
    'bc-training',
    'B.C. Employer Training Grant',
    'Grants & contributions',
    'British Columbia',
    'Cost-sharing support for employee training after you take over or grow a business.',
    'For eligible B.C. employers and training. Check approval timing and current intake before committing to expenses. Does not fund a business purchase.',
    'https://www.workbc.ca/employers-industry/funding-programs/bc-employer-training-grant/frequently-asked-questions',
  ),
  BuyerResource(
    'irap',
    'NRC Industrial Research Assistance Program',
    'Grants & contributions',
    'Canada',
    'Innovation advice and potential project funding for technology-focused small and medium businesses.',
    'For eligible innovative Canadian businesses and assessed projects. Project support is not acquisition financing.',
    'https://nrc.canada.ca/en/support-technology-innovation/financial-support-technology-innovation',
  ),
  BuyerResource(
    'canexport',
    'CanExport SMEs',
    'Grants & contributions',
    'Canada',
    'Competitive support for eligible businesses developing new international markets.',
    'For qualifying export-development projects. Check the current applicant guide, intake and eligible costs; not purchase-price funding.',
    'https://www.tradecommissioner.gc.ca/en/our-solutions/funding-financing-international-business/canexport-smes.html',
  ),
  BuyerResource(
    'webc',
    'WeBC',
    'Community support',
    'British Columbia',
    'Business loans and advisory support for women entrepreneurs, including business purchase planning.',
    'Check ownership, location and lending requirements with WeBC. Financing is repayable and subject to approval.',
    'https://we-bc.ca/programs-services/loans/business-loans-for-women/',
  ),
  BuyerResource(
    'futurpreneur',
    'Futurpreneur',
    'Community support',
    'Canada',
    'Financing, mentorship and planning resources for young entrepreneurs exploring business ownership.',
    'Programs serve entrepreneurs aged 18–39. Confirm whether your proposed purchase and ownership structure qualify.',
    'https://futurpreneur.ca/en/faq/',
  ),
  BuyerResource(
    'nacca',
    'NACCA / Indigenous Financial Institutions',
    'Community support',
    'Canada',
    'Find an Indigenous Financial Institution for business financing and planning support.',
    'For eligible First Nations, Métis and Inuit entrepreneurs. Ask your local institution about purchase financing and program requirements.',
    'https://nacca.ca/',
  ),
  BuyerResource(
    'canada-support',
    'Government business support directory',
    'Funding directory',
    'Canada',
    'Explore federal and regional organizations offering business support and financing.',
    'Use the official directory to discover additional local, sector-specific and ownership-specific programs.',
    'https://www.canada.ca/en/services/business/start/support-financing.html',
  ),
];

// Small account preferences use separate metadata keys, so saving one resource
// does not replace other resource selections or existing profile metadata.
class BuyerResourceTeam {
  static String key(String id) => 'affinity_resource_team_$id';
  static Future<Set<String>> load() async {
    if (BackendService.user == null) return {};
    final user = (await Supabase.instance.client.auth.getUser()).user;
    return {
      for (final r in buyerResources)
        if (user?.userMetadata?[key(r.id)] == true) r.id,
    };
  }

  static Future<void> setSaved(String id, bool saved) async {
    if (BackendService.user == null) {
      throw StateError('Sign in to save resources.');
    }
    if (!buyerResources.any((r) => r.id == id)) throw ArgumentError.value(id);
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {key(id): saved}),
    );
  }
}
