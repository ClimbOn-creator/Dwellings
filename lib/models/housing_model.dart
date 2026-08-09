import 'dart:math' as math;

enum DecisionMode { home, invest }

class MarketProfile {
  const MarketProfile({
    required this.city,
    required this.region,
    required this.appreciation,
    required this.priceIncome,
    required this.population,
    required this.employment,
    required this.inventory,
    required this.saleList,
    required this.infrastructure,
    required this.rezoning,
    required this.mortgage,
    required this.delinquency,
    required this.mbs,
    required this.renewal,
    required this.debtService,
    required this.unemployment,
    required this.investor,
    required this.insurance,
    required this.regulatory,
    required this.transit,
    required this.walkability,
    required this.amenities,
    required this.school,
    required this.flood,
    required this.wildfire,
    required this.geo,
    required this.nuisance,
  });

  final String city;
  final String region;
  final double appreciation;
  final double priceIncome;
  final double population;
  final double employment;
  final double inventory;
  final double saleList;
  final double infrastructure;
  final double rezoning;
  final double mortgage;
  final double delinquency;
  final double mbs;
  final double renewal;
  final double debtService;
  final double unemployment;
  final double investor;
  final double insurance;
  final double regulatory;
  final double transit;
  final double walkability;
  final double amenities;
  final double school;
  final double flood;
  final double wildfire;
  final double geo;
  final double nuisance;

  Map<String, dynamic> toJson() => {
    'city': city,
    'region': region,
    'appreciation': appreciation,
    'priceIncome': priceIncome,
    'population': population,
    'employment': employment,
    'inventory': inventory,
    'saleList': saleList,
    'infrastructure': infrastructure,
    'rezoning': rezoning,
    'mortgage': mortgage,
    'transit': transit,
    'walkability': walkability,
  };
}

const marketProfiles = <MarketProfile>[
  MarketProfile(
    city: 'Vancouver',
    region: 'BC',
    appreciation: .039,
    priceIncome: 12.1,
    population: .014,
    employment: .012,
    inventory: 3.1,
    saleList: 1,
    infrastructure: 78,
    rezoning: 74,
    mortgage: .045,
    delinquency: .003,
    mbs: .011,
    renewal: .14,
    debtService: .15,
    unemployment: .059,
    investor: .24,
    insurance: 18,
    regulatory: 38,
    transit: 88,
    walkability: 84,
    amenities: 91,
    school: 82,
    flood: 27,
    wildfire: 8,
    geo: 10,
    nuisance: 31,
  ),
  MarketProfile(
    city: 'Victoria',
    region: 'BC',
    appreciation: .037,
    priceIncome: 10.7,
    population: .013,
    employment: .011,
    inventory: 3.4,
    saleList: .996,
    infrastructure: 68,
    rezoning: 70,
    mortgage: .045,
    delinquency: .003,
    mbs: .011,
    renewal: .14,
    debtService: .15,
    unemployment: .048,
    investor: .23,
    insurance: 17,
    regulatory: 36,
    transit: 73,
    walkability: 80,
    amenities: 88,
    school: 83,
    flood: 23,
    wildfire: 7,
    geo: 9,
    nuisance: 24,
  ),
  MarketProfile(
    city: 'Kelowna',
    region: 'BC',
    appreciation: .034,
    priceIncome: 9.2,
    population: .022,
    employment: .018,
    inventory: 4.4,
    saleList: .985,
    infrastructure: 66,
    rezoning: 63,
    mortgage: .045,
    delinquency: .004,
    mbs: .011,
    renewal: .14,
    debtService: .15,
    unemployment: .057,
    investor: .26,
    insurance: 37,
    regulatory: 34,
    transit: 52,
    walkability: 57,
    amenities: 76,
    school: 78,
    flood: 19,
    wildfire: 48,
    geo: 8,
    nuisance: 20,
  ),
  MarketProfile(
    city: 'Calgary',
    region: 'AB',
    appreciation: .042,
    priceIncome: 5.5,
    population: .029,
    employment: .021,
    inventory: 2.3,
    saleList: 1.01,
    infrastructure: 72,
    rezoning: 67,
    mortgage: .045,
    delinquency: .005,
    mbs: .011,
    renewal: .13,
    debtService: .14,
    unemployment: .071,
    investor: .20,
    insurance: 24,
    regulatory: 24,
    transit: 70,
    walkability: 61,
    amenities: 81,
    school: 80,
    flood: 16,
    wildfire: 4,
    geo: 3,
    nuisance: 26,
  ),
  MarketProfile(
    city: 'Toronto',
    region: 'ON',
    appreciation: .032,
    priceIncome: 10.5,
    population: .018,
    employment: .013,
    inventory: 4.8,
    saleList: .987,
    infrastructure: 82,
    rezoning: 69,
    mortgage: .045,
    delinquency: .004,
    mbs: .011,
    renewal: .15,
    debtService: .155,
    unemployment: .072,
    investor: .28,
    insurance: 16,
    regulatory: 42,
    transit: 86,
    walkability: 83,
    amenities: 92,
    school: 84,
    flood: 14,
    wildfire: 1,
    geo: 2,
    nuisance: 36,
  ),
];

MarketProfile profileForAddress(String address) {
  final lower = address.toLowerCase();
  return marketProfiles.firstWhere(
    (profile) => lower.contains(profile.city.toLowerCase()),
    orElse: () => marketProfiles.first,
  );
}

class PropertyInputs {
  PropertyInputs({
    required this.address,
    required this.price,
    required this.finishedArea,
    required this.lotArea,
    required this.buildable,
    required this.bedrooms,
    required this.bathrooms,
    required this.yearBuilt,
    required this.repairs,
    required this.rent,
    required this.operatingCosts,
    required this.redevelopment,
    required this.scarcity,
    required this.daysOnMarket,
    required this.downPayment,
    required this.amortization,
    required this.holdingPeriod,
    required this.profile,
  });

  final String address;
  final double price;
  final double finishedArea;
  final double lotArea;
  final double buildable;
  final double bedrooms;
  final double bathrooms;
  final double yearBuilt;
  final double repairs;
  final double rent;
  final double operatingCosts;
  final double redevelopment;
  final double scarcity;
  final double daysOnMarket;
  final double downPayment;
  final double amortization;
  final double holdingPeriod;
  final MarketProfile profile;

  Map<String, dynamic> toJson() => {
    'address': address,
    'price': price,
    'finishedArea': finishedArea,
    'lotArea': lotArea,
    'buildable': buildable,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'yearBuilt': yearBuilt,
    'repairs': repairs,
    'rent': rent,
    'operatingCosts': operatingCosts,
    'redevelopment': redevelopment,
    'scarcity': scarcity,
    'daysOnMarket': daysOnMarket,
    'downPayment': downPayment,
    'amortization': amortization,
    'holdingPeriod': holdingPeriod,
  };
}

class FactorResult {
  const FactorResult(this.name, this.score, this.impact, this.isRisk);
  final String name;
  final double score;
  final double impact;
  final bool isRisk;
}

class AnalysisResult {
  const AnalysisResult({
    required this.opportunity,
    required this.risk,
    required this.net,
    required this.probability,
    required this.annualAppreciation,
    required this.projectedValue,
    required this.monthlyMortgage,
    required this.monthlyCarry,
    required this.capRate,
    required this.drivers,
  });
  final double opportunity;
  final double risk;
  final double net;
  final double probability;
  final double annualAppreciation;
  final double projectedValue;
  final double monthlyMortgage;
  final double monthlyCarry;
  final double capRate;
  final List<FactorResult> drivers;

  Map<String, dynamic> toJson() => {
    'opportunity': opportunity,
    'risk': risk,
    'net': net,
    'probability': probability,
    'annualAppreciation': annualAppreciation,
    'projectedValue': projectedValue,
    'monthlyMortgage': monthlyMortgage,
    'monthlyCarry': monthlyCarry,
    'capRate': capRate,
  };
}

double _clamp(double value) => value.clamp(0, 100).toDouble();
double _normalize(
  double raw,
  double low,
  double high, {
  bool lowerIsBetter = false,
}) {
  final value = lowerIsBetter
      ? ((low - raw) / (low - high)) * 100
      : ((raw - low) / (high - low)) * 100;
  return _clamp(value);
}

AnalysisResult analyzeProperty(PropertyInputs d, DecisionMode mode) {
  final p = d.profile;
  final positives = <(String, double, double?)>[
    (
      'Land value / buildable area',
      .12,
      d.buildable > 0
          ? _normalize(d.price / d.buildable, 150, 500, lowerIsBetter: true)
          : null,
    ),
    ('Redevelopment feasibility', .10, _normalize(d.redevelopment, 20, 90)),
    ('Transit access', .07, _normalize(p.transit, 20, 95)),
    ('Walkability', .05, _normalize(p.walkability, 20, 95)),
    (
      'Amenity & school access',
      .05,
      _normalize((p.amenities + p.school) / 2, 30, 95),
    ),
    ('Comparable scarcity', .10, _normalize(d.scarcity, 20, 95)),
    (
      'Rental net yield',
      .08,
      _normalize(((d.rent * 12) - d.operatingCosts) / d.price, .01, .06),
    ),
    (
      'Population & jobs growth',
      .10,
      _normalize((p.population + p.employment) / 2, 0, .04),
    ),
    (
      'Market supply pressure',
      .08,
      _normalize(p.inventory, 8, 1, lowerIsBetter: true),
    ),
    ('Market momentum', .07, _normalize(p.saleList, .94, 1.05)),
    ('Infrastructure catalyst', .09, _normalize(p.infrastructure, 10, 95)),
    ('Rezoning catalyst', .09, _normalize(p.rezoning, 10, 95)),
  ];
  final creditStress =
      100 * ((p.delinquency / .03) + (p.mbs / .03) + (p.renewal / .40)) / 3;
  final risks = <(String, double, double)>[
    (
      'Physical hazard',
      .20,
      _normalize((p.flood + p.wildfire + p.geo + p.nuisance) / 4, 0, 100),
    ),
    ('Property condition', .12, _normalize(d.repairs / d.price, 0, .10)),
    ('Resale liquidity', .10, _normalize(d.daysOnMarket, 15, 90)),
    ('Local affordability', .12, _normalize(p.priceIncome, 4, 14)),
    ('Mortgage pressure', .12, _normalize(p.mortgage, .02, .09)),
    ('Credit stress', .12, _normalize(creditStress, 0, 100)),
    ('Household leverage', .10, _normalize(p.debtService, .08, .22)),
    ('Labour market', .08, _normalize(p.unemployment, .03, .12)),
    ('Investor-cycle exposure', .07, _normalize(p.investor, .05, .45)),
    (
      'Insurance & regulation',
      .07,
      _normalize((p.insurance + p.regulatory) / 2, 0, 100),
    ),
  ];
  final availableWeight = positives
      .where((f) => f.$3 != null)
      .fold<double>(0, (sum, f) => sum + f.$2);
  final opportunity =
      positives
          .where((f) => f.$3 != null)
          .fold<double>(0, (sum, f) => sum + f.$2 * f.$3!) /
      availableWeight;
  final risk = risks.fold<double>(0, (sum, f) => sum + f.$2 * f.$3);
  final net = _clamp(opportunity - .55 * risk);
  final probability = 1 / (1 + math.exp(-.09 * (net - 50)));
  final annual =
      p.appreciation + ((opportunity - 50) / 50) * .04 - (risk / 100) * .03;
  final projected = d.price * math.pow(1 + annual, d.holdingPeriod);
  final principal = d.price * (1 - d.downPayment / 100);
  final monthlyRate = p.mortgage / 12;
  final payments = d.amortization * 12;
  final mortgage =
      principal *
      monthlyRate *
      math.pow(1 + monthlyRate, payments) /
      (math.pow(1 + monthlyRate, payments) - 1);
  final carry = mode == DecisionMode.invest
      ? d.rent - mortgage - d.operatingCosts / 12
      : mortgage + d.operatingCosts / 12;
  final capRate = ((d.rent * 12) - d.operatingCosts) / d.price;
  final drivers = <FactorResult>[
    ...positives
        .where((f) => f.$3 != null)
        .map((f) => FactorResult(f.$1, f.$3!, f.$3! * f.$2, false)),
    ...risks.map((f) => FactorResult(f.$1, f.$3, -f.$3 * f.$2 * .55, true)),
  ]..sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));
  return AnalysisResult(
    opportunity: opportunity,
    risk: risk,
    net: net,
    probability: probability,
    annualAppreciation: annual,
    projectedValue: projected.toDouble(),
    monthlyMortgage: mortgage.toDouble(),
    monthlyCarry: carry,
    capRate: capRate,
    drivers: drivers,
  );
}
