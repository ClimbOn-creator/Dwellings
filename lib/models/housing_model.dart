import 'dart:math' as math;

enum DecisionMode { home, invest }

enum PropertyType {
  singleFamily,
  condo,
  multifamily,
  retail,
  office,
  industrial,
  mixedUse,
  land,
  hospitality,
  selfStorage,
}

extension PropertyTypeLabel on PropertyType {
  String get label => switch (this) {
    PropertyType.singleFamily => 'Single-family',
    PropertyType.condo => 'Condo / townhome',
    PropertyType.multifamily => 'Multifamily',
    PropertyType.retail => 'Retail',
    PropertyType.office => 'Office',
    PropertyType.industrial => 'Industrial',
    PropertyType.mixedUse => 'Mixed-use',
    PropertyType.land => 'Development land',
    PropertyType.hospitality => 'Hospitality',
    PropertyType.selfStorage => 'Self-storage',
  };

  bool get isResidential =>
      this == PropertyType.singleFamily ||
      this == PropertyType.condo ||
      this == PropertyType.multifamily;
}

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
    'delinquency': delinquency,
    'transit': transit,
    'walkability': walkability,
    'hazards': {'flood': flood, 'wildfire': wildfire, 'geo': geo},
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
  const PropertyInputs({
    required this.address,
    required this.propertyType,
    required this.profile,
    required this.values,
  });

  final String address;
  final PropertyType propertyType;
  final MarketProfile profile;
  final Map<String, double> values;

  double n(String key, [double fallback = 0]) => values[key] ?? fallback;
  double pct(String key, [double fallback = 0]) => n(key, fallback) / 100;

  Map<String, dynamic> toJson() => {
    'address': address,
    'propertyType': propertyType.name,
    ...values,
  };
}

class FactorResult {
  const FactorResult(this.name, this.score, this.impact, this.isRisk);
  final String name;
  final double score;
  final double impact;
  final bool isRisk;
}

class ScenarioResult {
  const ScenarioResult({
    required this.name,
    required this.noi,
    required this.dscr,
    required this.irr,
    required this.exitValue,
  });
  final String name;
  final double noi;
  final double dscr;
  final double irr;
  final double exitValue;
}

class AnalysisResult {
  const AnalysisResult({
    required this.opportunity,
    required this.risk,
    required this.net,
    required this.probability,
    required this.totalCost,
    required this.effectiveGrossIncome,
    required this.noi,
    required this.capRate,
    required this.loanAmount,
    required this.annualDebtService,
    required this.monthlyMortgage,
    required this.monthlyCarry,
    required this.dscr,
    required this.debtYield,
    required this.cashOnCash,
    required this.breakEvenOccupancy,
    required this.grm,
    required this.projectedValue,
    required this.saleProceeds,
    required this.irr,
    required this.equityMultiple,
    required this.npv,
    required this.pricePerSquareFoot,
    required this.ltv,
    required this.dti,
    required this.dataCompleteness,
    required this.drivers,
    required this.flags,
    required this.scenarios,
  });

  final double opportunity;
  final double risk;
  final double net;
  final double probability;
  final double totalCost;
  final double effectiveGrossIncome;
  final double noi;
  final double capRate;
  final double loanAmount;
  final double annualDebtService;
  final double monthlyMortgage;
  final double monthlyCarry;
  final double dscr;
  final double debtYield;
  final double cashOnCash;
  final double breakEvenOccupancy;
  final double grm;
  final double projectedValue;
  final double saleProceeds;
  final double irr;
  final double equityMultiple;
  final double npv;
  final double pricePerSquareFoot;
  final double ltv;
  final double dti;
  final double dataCompleteness;
  final List<FactorResult> drivers;
  final List<String> flags;
  final List<ScenarioResult> scenarios;

  Map<String, dynamic> toJson() => {
    'opportunity': opportunity,
    'risk': risk,
    'net': net,
    'probability': probability,
    'totalCost': totalCost,
    'effectiveGrossIncome': effectiveGrossIncome,
    'noi': noi,
    'capRate': capRate,
    'loanAmount': loanAmount,
    'annualDebtService': annualDebtService,
    'monthlyMortgage': monthlyMortgage,
    'monthlyCarry': monthlyCarry,
    'dscr': dscr,
    'debtYield': debtYield,
    'cashOnCash': cashOnCash,
    'breakEvenOccupancy': breakEvenOccupancy,
    'projectedValue': projectedValue,
    'irr': irr,
    'equityMultiple': equityMultiple,
    'npv': npv,
    'ltv': ltv,
    'dti': dti,
    'dataCompleteness': dataCompleteness,
    'flags': flags,
  };
}

double _safeDivide(
  double numerator,
  double denominator, [
  double fallback = 0,
]) => denominator.abs() < .0000001 ? fallback : numerator / denominator;
double _clamp(double value) => value.clamp(0, 100).toDouble();
double _normalize(
  double raw,
  double low,
  double high, {
  bool lowerIsBetter = false,
}) {
  if ((high - low).abs() < .0000001) return 50;
  final value = lowerIsBetter
      ? ((low - raw) / (low - high)) * 100
      : ((raw - low) / (high - low)) * 100;
  return _clamp(value);
}

double _payment(double principal, double annualRate, double years) {
  if (principal <= 0 || years <= 0) return 0;
  if (annualRate.abs() < .0000001) return principal / (years * 12);
  final rate = annualRate / 12;
  final periods = years * 12;
  final growth = math.pow(1 + rate, periods).toDouble();
  return principal * rate * growth / (growth - 1);
}

double _balance(
  double principal,
  double annualRate,
  double years,
  double elapsedYears,
) {
  if (principal <= 0) return 0;
  final months = (elapsedYears.clamp(0, years) * 12).round();
  if (months == 0) return principal;
  if (annualRate.abs() < .0000001) {
    return math.max(0, principal * (1 - elapsedYears / years));
  }
  final rate = annualRate / 12;
  final payment = _payment(principal, annualRate, years);
  final growth = math.pow(1 + rate, months).toDouble();
  return math.max(0, principal * growth - payment * (growth - 1) / rate);
}

double _npv(List<double> cashFlows, double discountRate) {
  var value = 0.0;
  for (var year = 0; year < cashFlows.length; year++) {
    value += cashFlows[year] / math.pow(1 + discountRate, year);
  }
  return value;
}

double _irr(List<double> cashFlows) {
  if (!cashFlows.any((v) => v < 0) || !cashFlows.any((v) => v > 0)) return 0;
  var low = -.95;
  var high = 5.0;
  var lowValue = _npv(cashFlows, low);
  var highValue = _npv(cashFlows, high);
  if (lowValue.sign == highValue.sign) return 0;
  for (var i = 0; i < 140; i++) {
    final mid = (low + high) / 2;
    final value = _npv(cashFlows, mid);
    if (value.abs() < .01) return mid;
    if (value.sign == lowValue.sign) {
      low = mid;
      lowValue = value;
    } else {
      high = mid;
      highValue = value;
    }
  }
  return (low + high) / 2;
}

AnalysisResult analyzeProperty(PropertyInputs d, DecisionMode mode) {
  final p = d.profile;
  final price = math.max(0.0, d.n('price')).toDouble();
  final closing = math.max(0.0, d.n('closingCosts')).toDouble();
  final improvements = math.max(0.0, d.n('improvements')).toDouble();
  final totalCost = price + closing + improvements;
  final baseRent = math.max(0.0, d.n('annualRent')).toDouble();
  final otherIncome = math.max(0.0, d.n('otherIncome')).toDouble();
  final grossPotentialIncome = baseRent + otherIncome;
  final vacancy = d.pct('vacancy').clamp(0.0, .95).toDouble();
  final effectiveGrossIncome = grossPotentialIncome * (1 - vacancy);
  final fixedExpenses =
      d.n('propertyTax') +
      d.n('insurance') +
      d.n('utilities') +
      d.n('maintenance') +
      d.n('reserves') +
      d.n('otherExpenses');
  final management = effectiveGrossIncome * d.pct('management');
  final operatingExpenses = math
      .max(0.0, fixedExpenses + management)
      .toDouble();
  final noi = effectiveGrossIncome - operatingExpenses;
  final ltv = (1 - d.pct('downPayment')).clamp(0, 1).toDouble();
  final loanAmount = price * ltv;
  final interestRate = d.pct('interestRate', p.mortgage * 100);
  final amortization = math.max(1.0, d.n('amortization', 25)).toDouble();
  final monthlyMortgage = _payment(loanAmount, interestRate, amortization);
  final annualDebtService = monthlyMortgage * 12;
  final initialEquity = math
      .max(1.0, price - loanAmount + closing + improvements)
      .toDouble();
  final capRate = _safeDivide(noi, price);
  final dscr = _safeDivide(noi, annualDebtService);
  final debtYield = _safeDivide(noi, loanAmount);
  final cashOnCash = _safeDivide(noi - annualDebtService, initialEquity);
  final breakEvenOccupancy = _safeDivide(
    operatingExpenses + annualDebtService,
    grossPotentialIncome,
  );
  final grm = _safeDivide(price, grossPotentialIncome);
  final area = math.max(0.0, d.n('area')).toDouble();
  final pricePerSquareFoot = _safeDivide(price, area);
  final holdingPeriod = math.max(1, d.n('holdingPeriod', 5).round());
  final rentGrowth = d.pct('rentGrowth');
  final expenseGrowth = d.pct('expenseGrowth');
  final exitCap = math.max(.005, d.pct('exitCap', 5.5));
  final sellingCosts = d.pct('sellingCosts', 4);
  final appreciation = d.pct('appreciation', p.appreciation * 100);

  final cashFlows = <double>[-initialEquity];
  var finalNoi = noi;
  for (var year = 1; year <= holdingPeriod; year++) {
    final grownIncome =
        grossPotentialIncome * math.pow(1 + rentGrowth, year) * (1 - vacancy);
    final grownExpenses = operatingExpenses * math.pow(1 + expenseGrowth, year);
    finalNoi = grownIncome - grownExpenses;
    cashFlows.add(finalNoi - annualDebtService);
  }
  final nextYearIncome =
      grossPotentialIncome *
      math.pow(1 + rentGrowth, holdingPeriod + 1) *
      (1 - vacancy);
  final nextYearExpenses =
      operatingExpenses * math.pow(1 + expenseGrowth, holdingPeriod + 1);
  final exitNoi = nextYearIncome - nextYearExpenses;
  final incomeExitValue = math.max(0.0, exitNoi / exitCap).toDouble();
  final appreciationExitValue =
      price * math.pow(1 + appreciation, holdingPeriod);
  final projectedValue =
      d.propertyType == PropertyType.singleFamily ||
          d.propertyType == PropertyType.condo
      ? appreciationExitValue.toDouble()
      : incomeExitValue;
  final remainingLoan = _balance(
    loanAmount,
    interestRate,
    amortization,
    holdingPeriod.toDouble(),
  );
  final saleProceeds = math
      .max(0.0, projectedValue * (1 - sellingCosts) - remainingLoan)
      .toDouble();
  cashFlows[cashFlows.length - 1] += saleProceeds;
  final irr = _irr(cashFlows);
  final equityMultiple = _safeDivide(
    cashFlows.skip(1).fold<double>(0, (a, b) => a + b),
    initialEquity,
  );
  final npv = _npv(cashFlows, d.pct('discountRate', 8));
  final monthlyCarry = mode == DecisionMode.home
      ? monthlyMortgage + operatingExpenses / 12
      : (noi - annualDebtService) / 12;
  final monthlyIncome = d.n('householdIncome') / 12;
  final dti = _safeDivide(
    monthlyMortgage + operatingExpenses / 12 + d.n('monthlyDebt'),
    monthlyIncome,
  );

  final positives = <(String, double, double)>[
    ('Income yield', .15, _normalize(capRate, .02, .09)),
    ('Debt coverage', .13, _normalize(dscr, .85, 1.8)),
    ('Debt yield', .08, _normalize(debtYield, .04, .13)),
    ('Occupancy', .08, _normalize(1 - vacancy, .70, 1)),
    (
      'Population & jobs',
      .09,
      _normalize((p.population + p.employment) / 2, 0, .04),
    ),
    (
      'Supply pressure',
      .07,
      _normalize(p.inventory, 8, 1, lowerIsBetter: true),
    ),
    (
      'Transit & walkability',
      .08,
      _normalize((p.transit + p.walkability) / 2, 20, 95),
    ),
    ('Infrastructure catalyst', .08, _normalize(p.infrastructure, 10, 95)),
    (
      'Redevelopment optionality',
      .09,
      _normalize(d.n('redevelopment'), 20, 90),
    ),
    ('Comparable scarcity', .08, _normalize(d.n('scarcity'), 20, 95)),
    ('Cash-on-cash return', .09, _normalize(cashOnCash, -.05, .14)),
    ('Lease durability / WALT', .08, _normalize(d.n('walt'), 0, 12)),
  ];
  if (mode == DecisionMode.home) {
    positives[1] = (
      'Household affordability',
      .13,
      _normalize(dti, .55, .20, lowerIsBetter: true),
    );
    positives[2] = (
      'Liveability access',
      .08,
      _normalize((p.amenities + p.school) / 2, 30, 95),
    );
  }
  final physicalHazard =
      (p.flood + p.wildfire + p.geo + p.nuisance + d.n('environmentRisk')) / 5;
  final creditStress =
      100 * ((p.delinquency / .03) + (p.mbs / .03) + (p.renewal / .40)) / 3;
  final risks = <(String, double, double)>[
    ('Physical & climate hazard', .14, _normalize(physicalHazard, 0, 100)),
    (
      'Condition & capital needs',
      .12,
      _normalize(
        d.n('conditionRisk') +
            _safeDivide(improvements, math.max(1, price)) * 400,
        0,
        100,
      ),
    ),
    ('Leverage', .12, _normalize(ltv, .45, .90)),
    ('Break-even occupancy', .10, _normalize(breakEvenOccupancy, .55, 1.05)),
    ('Lease rollover', .09, _normalize(d.n('leaseRollover'), 0, 100)),
    (
      'Tenant concentration',
      .08,
      _normalize(d.n('tenantConcentration'), 10, 100),
    ),
    ('Resale liquidity', .08, _normalize(d.n('daysOnMarket'), 15, 120)),
    ('Local affordability', .08, _normalize(p.priceIncome, 4, 14)),
    ('Credit & renewal stress', .08, _normalize(creditStress, 0, 100)),
    (
      'Labour & cycle exposure',
      .06,
      _normalize(p.unemployment + p.investor * .12, .03, .17),
    ),
    (
      'Insurance & regulation',
      .05,
      _normalize((p.insurance + p.regulatory) / 2, 0, 100),
    ),
  ];
  final opportunity = positives.fold<double>(0, (sum, f) => sum + f.$2 * f.$3);
  final risk = risks.fold<double>(0, (sum, f) => sum + f.$2 * f.$3);
  final net = _clamp(opportunity - .50 * risk);
  final probability = 1 / (1 + math.exp(-.09 * (net - 50)));
  final drivers = <FactorResult>[
    ...positives.map((f) => FactorResult(f.$1, f.$3, f.$2 * f.$3, false)),
    ...risks.map((f) => FactorResult(f.$1, f.$3, -.50 * f.$2 * f.$3, true)),
  ]..sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));

  final flags = <String>[];
  if (mode == DecisionMode.invest && dscr < 1.25)
    flags.add('DSCR is below the common 1.25× lender cushion.');
  if (mode == DecisionMode.invest && debtYield < .08)
    flags.add('Debt yield is below 8%; financing resilience is thin.');
  if (ltv > .75)
    flags.add('Leverage exceeds 75% LTV and amplifies downside risk.');
  if (breakEvenOccupancy > .85)
    flags.add('Break-even occupancy exceeds 85%; vacancy headroom is limited.');
  if (d.n('leaseRollover') > 35)
    flags.add('More than 35% of income rolls during the hold period.');
  if (d.n('tenantConcentration') > 40)
    flags.add('A single tenant contributes more than 40% of income.');
  if (mode == DecisionMode.home && dti > .39)
    flags.add('Housing and debt costs exceed 39% of gross household income.');
  if (flags.isEmpty)
    flags.add('No major threshold breach in the entered assumptions.');

  final scenarios = <ScenarioResult>[
    _scenario(
      'Downside',
      d,
      annualDebtService,
      loanAmount,
      initialEquity,
      vacancy + .08,
      rentGrowth - .02,
      expenseGrowth + .02,
      exitCap + .01,
    ),
    ScenarioResult(
      name: 'Base',
      noi: noi,
      dscr: dscr,
      irr: irr,
      exitValue: projectedValue,
    ),
    _scenario(
      'Upside',
      d,
      annualDebtService,
      loanAmount,
      initialEquity,
      math.max(0.0, vacancy - .03).toDouble(),
      rentGrowth + .015,
      math.max(0.0, expenseGrowth - .005).toDouble(),
      math.max(.005, exitCap - .005).toDouble(),
    ),
  ];
  final required = [
    'price',
    'area',
    'annualRent',
    'vacancy',
    'propertyTax',
    'insurance',
    'maintenance',
    'downPayment',
    'interestRate',
    'amortization',
    'holdingPeriod',
    'exitCap',
  ];
  final dataCompleteness =
      required
          .where((key) => d.values.containsKey(key) && d.n(key) > 0)
          .length /
      required.length;

  return AnalysisResult(
    opportunity: opportunity,
    risk: risk,
    net: net,
    probability: probability,
    totalCost: totalCost,
    effectiveGrossIncome: effectiveGrossIncome,
    noi: noi,
    capRate: capRate,
    loanAmount: loanAmount,
    annualDebtService: annualDebtService,
    monthlyMortgage: monthlyMortgage,
    monthlyCarry: monthlyCarry,
    dscr: dscr,
    debtYield: debtYield,
    cashOnCash: cashOnCash,
    breakEvenOccupancy: breakEvenOccupancy,
    grm: grm,
    projectedValue: projectedValue,
    saleProceeds: saleProceeds,
    irr: irr,
    equityMultiple: equityMultiple,
    npv: npv,
    pricePerSquareFoot: pricePerSquareFoot,
    ltv: ltv,
    dti: dti,
    dataCompleteness: dataCompleteness,
    drivers: drivers,
    flags: flags,
    scenarios: scenarios,
  );
}

ScenarioResult _scenario(
  String name,
  PropertyInputs d,
  double debtService,
  double loanAmount,
  double initialEquity,
  double vacancy,
  double rentGrowth,
  double expenseGrowth,
  double exitCap,
) {
  final gross = d.n('annualRent') + d.n('otherIncome');
  final baseEgi = gross * (1 - vacancy.clamp(0, .95));
  final expenses =
      d.n('propertyTax') +
      d.n('insurance') +
      d.n('utilities') +
      d.n('maintenance') +
      d.n('reserves') +
      d.n('otherExpenses') +
      baseEgi * d.pct('management');
  final hold = math.max(1, d.n('holdingPeriod', 5).round());
  final cashFlows = <double>[-initialEquity];
  var noi = baseEgi - expenses;
  for (var year = 1; year <= hold; year++) {
    noi =
        gross * math.pow(1 + rentGrowth, year) * (1 - vacancy) -
        expenses * math.pow(1 + expenseGrowth, year);
    cashFlows.add(noi - debtService);
  }
  final exitNoi =
      gross * math.pow(1 + rentGrowth, hold + 1) * (1 - vacancy) -
      expenses * math.pow(1 + expenseGrowth, hold + 1);
  final exitValue = math.max(0.0, exitNoi / math.max(.005, exitCap)).toDouble();
  final balance = _balance(
    loanAmount,
    d.pct('interestRate'),
    math.max(1, d.n('amortization', 25)),
    hold.toDouble(),
  );
  cashFlows[cashFlows.length - 1] += math
      .max(0.0, exitValue * (1 - d.pct('sellingCosts', 4)) - balance)
      .toDouble();
  return ScenarioResult(
    name: name,
    noi: noi,
    dscr: _safeDivide(noi, debtService),
    irr: _irr(cashFlows),
    exitValue: exitValue,
  );
}
