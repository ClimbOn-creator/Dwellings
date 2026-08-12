import 'dart:math' as math;

class BusinessInputs {
  const BusinessInputs({
    required this.businessName,
    required this.industry,
    required this.location,
    required this.values,
  });

  final String businessName;
  final String industry;
  final String location;
  final Map<String, double> values;

  double n(String key, [double fallback = 0]) => values[key] ?? fallback;
  double pct(String key, [double fallback = 0]) => n(key, fallback) / 100;

  Map<String, dynamic> toJson() => {
    'business_name': businessName,
    'industry': industry,
    'location': location,
    ...values,
  };
}

class BusinessScenario {
  const BusinessScenario({
    required this.name,
    required this.revenue,
    required this.cashAfterOwner,
    required this.dscr,
    required this.paybackYears,
  });
  final String name;
  final double revenue;
  final double cashAfterOwner;
  final double dscr;
  final double paybackYears;

  Map<String, dynamic> toJson() => {
    'name': name,
    'revenue': revenue,
    'cash_after_owner': cashAfterOwner,
    'dscr': dscr,
    'payback_years': paybackYears,
  };
}

class BusinessResult {
  const BusinessResult({
    required this.viabilityScore,
    required this.riskScore,
    required this.dataCompleteness,
    required this.normalizedEbitda,
    required this.normalizedOwnerEarnings,
    required this.totalAcquisitionCost,
    required this.buyerEquity,
    required this.loanAmount,
    required this.annualDebtService,
    required this.cashAfterDebt,
    required this.cashAfterOwnerSalary,
    required this.dscr,
    required this.priceToEbitda,
    required this.priceToOwnerEarnings,
    required this.paybackYears,
    required this.breakEvenRevenue,
    required this.workingCapitalGap,
    required this.roic,
    required this.flags,
    required this.strengths,
    required this.missingEvidence,
    required this.scenarios,
  });

  final double viabilityScore;
  final double riskScore;
  final double dataCompleteness;
  final double normalizedEbitda;
  final double normalizedOwnerEarnings;
  final double totalAcquisitionCost;
  final double buyerEquity;
  final double loanAmount;
  final double annualDebtService;
  final double cashAfterDebt;
  final double cashAfterOwnerSalary;
  final double dscr;
  final double priceToEbitda;
  final double priceToOwnerEarnings;
  final double paybackYears;
  final double breakEvenRevenue;
  final double workingCapitalGap;
  final double roic;
  final List<String> flags;
  final List<String> strengths;
  final List<String> missingEvidence;
  final List<BusinessScenario> scenarios;

  String get verdict => switch (viabilityScore) {
    >= 75 => 'Promising—proceed to professional diligence',
    >= 55 => 'Possible, but material questions remain',
    >= 35 => 'High-risk without a lower price or stronger evidence',
    _ => 'The current structure does not appear financially viable',
  };

  Map<String, dynamic> toJson() => {
    'viability_score': viabilityScore,
    'risk_score': riskScore,
    'data_completeness': dataCompleteness,
    'normalized_ebitda': normalizedEbitda,
    'normalized_owner_earnings': normalizedOwnerEarnings,
    'total_acquisition_cost': totalAcquisitionCost,
    'buyer_equity': buyerEquity,
    'loan_amount': loanAmount,
    'annual_debt_service': annualDebtService,
    'cash_after_debt': cashAfterDebt,
    'cash_after_owner_salary': cashAfterOwnerSalary,
    'dscr': dscr,
    'price_to_ebitda': priceToEbitda,
    'price_to_owner_earnings': priceToOwnerEarnings,
    'payback_years': paybackYears,
    'break_even_revenue': breakEvenRevenue,
    'working_capital_gap': workingCapitalGap,
    'roic': roic,
    'flags': flags,
    'strengths': strengths,
    'missing_evidence': missingEvidence,
    'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
  };
}

BusinessResult analyzeBusiness(BusinessInputs input) {
  final revenue = input.n('revenue');
  final grossProfit = input.n('grossProfit');
  final reportedEbitda = input.n('ebitda');
  final reportedNetIncome = input.n('netIncome');
  final ownerComp = input.n('ownerComp');
  final claimedAddBacks = input.n('addBacks');
  final verifiedAddBacks = math.min(
    claimedAddBacks,
    input.n('verifiedAddBacks', claimedAddBacks),
  );
  final replacementSalary = input.n('replacementSalary');
  final maintenanceCapex = input.n('maintenanceCapex');
  final askingPrice = input.n('askingPrice');
  final inventoryIncluded = input.n('inventoryIncluded');
  final workingCapitalIncluded = input.n('workingCapitalIncluded');
  final requiredWorkingCapital = input.n('requiredWorkingCapital');
  final transactionCosts = input.n('transactionCosts');
  final debtPercent = input.pct('debtPercent');
  final interestRate = input.pct('interestRate');
  final amortizationYears = math
      .max(1, input.n('amortizationYears', 7))
      .toDouble();

  final baseEbitda = reportedEbitda != 0 ? reportedEbitda : reportedNetIncome;
  // Reported EBITDA normally includes the seller's compensation as an
  // operating expense. Add it back, then separately charge a market salary for
  // the buyer or replacement manager below.
  final normalizedEbitda = baseEbitda + ownerComp + verifiedAddBacks;
  final normalizedOwnerEarnings =
      normalizedEbitda - replacementSalary - maintenanceCapex;
  final workingCapitalGap = math
      .max(0, requiredWorkingCapital - workingCapitalIncluded)
      .toDouble();
  final totalCost =
      askingPrice + transactionCosts + workingCapitalGap + inventoryIncluded;
  final loanAmount = totalCost * debtPercent.clamp(0, 1);
  final buyerEquity = totalCost - loanAmount;
  final annualDebtService = _annualDebtService(
    loanAmount,
    interestRate,
    amortizationYears,
  );
  final cashAfterDebt = normalizedEbitda - maintenanceCapex - annualDebtService;
  final cashAfterOwner = cashAfterDebt - replacementSalary;
  final dscr = _divide(
    normalizedOwnerEarnings,
    annualDebtService,
    annualDebtService == 0 ? 99 : 0,
  );
  final priceToEbitda = _divide(askingPrice, normalizedEbitda);
  final priceToOwner = _divide(askingPrice, normalizedOwnerEarnings);
  final paybackYears = _divide(buyerEquity, math.max(0, cashAfterOwner), 99);
  final grossMargin = _divide(grossProfit, revenue);
  final fixedCosts = math.max(0, grossProfit - baseEbitda - ownerComp);
  final contributionMargin = grossMargin.clamp(.01, 1);
  final breakEvenRevenue =
      (fixedCosts + replacementSalary + maintenanceCapex + annualDebtService) /
      contributionMargin;
  final roic = _divide(cashAfterOwner, buyerEquity) * 100;

  final flags = <String>[];
  final strengths = <String>[];
  final missing = <String>[];

  if (cashAfterOwner < 0) {
    flags.add(
      'After debt payments, maintenance investment and a reasonable owner salary, the business produces negative annual cash flow.',
    );
  } else if (cashAfterOwner < replacementSalary * .25) {
    flags.add(
      'Very little cash remains after paying the replacement owner and servicing acquisition debt.',
    );
  }
  if (dscr < 1) {
    flags.add('Operating cash flow does not cover modeled acquisition debt.');
  } else if (dscr < 1.25) {
    flags.add('Debt coverage is thin and may not satisfy a prudent lender.');
  } else {
    strengths.add(
      'Modeled cash flow provides reasonable debt-service coverage.',
    );
  }
  if (priceToEbitda > 6) {
    flags.add('The asking price exceeds 6× normalized EBITDA.');
  } else if (priceToEbitda > 0 && priceToEbitda <= 4) {
    strengths.add('The modeled EBITDA multiple is below 4×.');
  }
  final addBackRatio = _divide(claimedAddBacks, math.max(1, normalizedEbitda));
  if (addBackRatio > .3) {
    flags.add('Seller add-backs represent more than 30% of normalized EBITDA.');
  }
  if (verifiedAddBacks < claimedAddBacks) {
    flags.add('Not all claimed seller add-backs have been verified.');
  }
  final customerConcentration = input.pct('topCustomerPercent');
  if (customerConcentration > .3) {
    flags.add('The largest customer represents over 30% of revenue.');
  } else if (customerConcentration > 0 && customerConcentration < .15) {
    strengths.add('Customer concentration appears reasonably diversified.');
  }
  if (input.pct('ownerDependence') > .7) {
    flags.add('The business appears highly dependent on the current owner.');
  }
  if (input.pct('revenueGrowth') < -.05) {
    flags.add('Revenue is declining by more than 5% annually.');
  } else if (input.pct('revenueGrowth') > .05) {
    strengths.add('Revenue growth is above 5%.');
  }
  if (input.n('leaseYearsRemaining') > 0 &&
      input.n('leaseYearsRemaining') < 2) {
    flags.add('The operating lease has less than two years remaining.');
  }
  if (workingCapitalGap > 0) {
    flags.add(
      'The transaction requires an additional working-capital injection of ${workingCapitalGap.toStringAsFixed(0)}.',
    );
  }
  if (grossMargin <= 0) missing.add('Gross profit or gross margin');
  if (reportedEbitda == 0 && reportedNetIncome == 0) {
    missing.add('EBITDA or net income');
  }
  if (input.n('threeYearRevenueProvided') == 0) {
    missing.add('Three years of revenue and earnings history');
  }
  if (input.n('taxReturnsReviewed') == 0) missing.add('Corporate tax returns');
  if (input.n('bankStatementsReviewed') == 0) {
    missing.add('Bank statements matching reported revenue');
  }
  if (input.n('customerListReviewed') == 0) {
    missing.add('Customer concentration schedule');
  }

  final requiredFields = [
    revenue,
    grossProfit,
    askingPrice,
    normalizedEbitda,
    replacementSalary,
    requiredWorkingCapital,
    input.n('topCustomerPercent'),
    input.n('ownerDependence'),
  ];
  final completion =
      requiredFields.where((value) => value != 0).length /
      requiredFields.length *
      100;

  double risk = 20;
  risk += dscr < 1 ? 25 : (dscr < 1.25 ? 14 : 0);
  risk += cashAfterOwner < 0
      ? 25
      : (cashAfterOwner < replacementSalary * .25 ? 12 : 0);
  risk += priceToEbitda > 6 ? 15 : (priceToEbitda > 4.5 ? 8 : 0);
  risk += customerConcentration > .3
      ? 12
      : (customerConcentration > .2 ? 6 : 0);
  risk += input.pct('ownerDependence') * 12;
  risk += addBackRatio > .3 ? 8 : 0;
  risk += input.pct('revenueGrowth') < 0 ? 8 : 0;
  risk += (100 - completion) * .18;
  risk = risk.clamp(0, 100);
  final viability = (100 - risk + math.min(20, math.max(-20, roic) * .35))
      .clamp(0, 100);

  BusinessScenario scenario(String name, double revenueFactor) {
    final scenarioRevenue = revenue * revenueFactor;
    final scenarioGrossProfit = scenarioRevenue * grossMargin;
    final scenarioEbitda =
        normalizedEbitda + (scenarioGrossProfit - grossProfit);
    final scenarioCash =
        scenarioEbitda -
        maintenanceCapex -
        annualDebtService -
        replacementSalary;
    final scenarioDscr = _divide(
      scenarioEbitda - maintenanceCapex - replacementSalary,
      annualDebtService,
      99,
    );
    return BusinessScenario(
      name: name,
      revenue: scenarioRevenue,
      cashAfterOwner: scenarioCash,
      dscr: scenarioDscr,
      paybackYears: _divide(buyerEquity, math.max(0, scenarioCash), 99),
    );
  }

  return BusinessResult(
    viabilityScore: viability.toDouble(),
    riskScore: risk.toDouble(),
    dataCompleteness: completion,
    normalizedEbitda: normalizedEbitda,
    normalizedOwnerEarnings: normalizedOwnerEarnings,
    totalAcquisitionCost: totalCost,
    buyerEquity: buyerEquity,
    loanAmount: loanAmount,
    annualDebtService: annualDebtService,
    cashAfterDebt: cashAfterDebt,
    cashAfterOwnerSalary: cashAfterOwner,
    dscr: dscr,
    priceToEbitda: priceToEbitda,
    priceToOwnerEarnings: priceToOwner,
    paybackYears: paybackYears,
    breakEvenRevenue: breakEvenRevenue,
    workingCapitalGap: workingCapitalGap,
    roic: roic,
    flags: flags,
    strengths: strengths,
    missingEvidence: missing,
    scenarios: [
      scenario('Downside', .85),
      scenario('Expected', 1),
      scenario('Upside', 1.1),
    ],
  );
}

double _divide(double numerator, double denominator, [double fallback = 0]) =>
    denominator.abs() < .000001 ? fallback : numerator / denominator;

double _annualDebtService(double principal, double rate, double years) {
  if (principal <= 0) return 0;
  if (rate <= 0) return principal / years;
  final monthly = rate / 12;
  final payments = years * 12;
  return principal * monthly / (1 - math.pow(1 + monthly, -payments)) * 12;
}
