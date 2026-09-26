import 'dart:math' as math;

/// Annual, fully amortizing payment. Rates are entered as percentages.
double annualDebtService(double principal, double interestPercent, int years) {
  if (principal <= 0 || years <= 0) return 0;
  final monthlyRate = interestPercent / 1200;
  final payments = years * 12;
  if (monthlyRate == 0) return principal / years;
  final factor = math.pow(1 + monthlyRate, payments).toDouble();
  return principal * monthlyRate * factor / (factor - 1) * 12;
}

double safeRatio(double numerator, double denominator) =>
    denominator > 0 ? numerator / denominator : 0;

class BusinessPriceScreen {
  const BusinessPriceScreen({
    required this.askingPrice,
    required this.revenue,
    required this.reportedEbitda,
    required this.verifiedAddbacks,
    required this.ownerCompensation,
    required this.replacementSalary,
    required this.maintenanceCapex,
    required this.lowMultiple,
    required this.highMultiple,
    required this.downPaymentPercent,
    required this.interestPercent,
    required this.amortizationYears,
  });

  final double askingPrice;
  final double revenue;
  final double reportedEbitda;
  final double verifiedAddbacks;
  final double ownerCompensation;
  final double replacementSalary;
  final double maintenanceCapex;
  final double lowMultiple;
  final double highMultiple;
  final double downPaymentPercent;
  final double interestPercent;
  final int amortizationYears;

  double get maintainableEbitda =>
      reportedEbitda + verifiedAddbacks + ownerCompensation - replacementSalary;
  double get lowValue => math.max(0, maintainableEbitda * lowMultiple);
  double get highValue => math.max(0, maintainableEbitda * highMultiple);
  double get midpoint => (lowValue + highValue) / 2;
  double get askingMultiple => safeRatio(askingPrice, maintainableEbitda);
  double get priceGap => askingPrice - midpoint;
  double get loan => askingPrice * (1 - downPaymentPercent / 100);
  double get annualDebt =>
      annualDebtService(loan, interestPercent, amortizationYears);
  double get cashAvailableForDebt => maintainableEbitda - maintenanceCapex;
  double get dscr =>
      annualDebt == 0 ? 99 : safeRatio(cashAvailableForDebt, annualDebt);
  double get cashAfterDebt => cashAvailableForDebt - annualDebt;
  double get cashOnCash => safeRatio(cashAfterDebt, askingPrice - loan);
  double get ebitdaMargin => safeRatio(maintainableEbitda, revenue);

  bool get isValid =>
      askingPrice > 0 &&
      revenue > 0 &&
      maintainableEbitda > 0 &&
      [
        reportedEbitda,
        verifiedAddbacks,
        ownerCompensation,
        replacementSalary,
        maintenanceCapex,
      ].every((value) => value >= 0) &&
      lowMultiple > 0 &&
      highMultiple >= lowMultiple &&
      downPaymentPercent >= 0 &&
      downPaymentPercent <= 100 &&
      interestPercent >= 0 &&
      amortizationYears > 0;
}

class AssetDealScreen {
  const AssetDealScreen({
    required this.askingPrice,
    required this.equipment,
    required this.inventory,
    required this.receivables,
    required this.intangibles,
    required this.cash,
    required this.liabilities,
    required this.deferredMaintenance,
    required this.transactionCosts,
    required this.recoveryPercent,
  });

  final double askingPrice;
  final double equipment;
  final double inventory;
  final double receivables;
  final double intangibles;
  final double cash;
  final double liabilities;
  final double deferredMaintenance;
  final double transactionCosts;
  final double recoveryPercent;

  double get grossAssets =>
      equipment + inventory + receivables + intangibles + cash;
  double get adjustedNetAssets =>
      grossAssets - liabilities - deferredMaintenance;
  double get liquidationFloor =>
      cash +
      (equipment + inventory + receivables + intangibles) *
          recoveryPercent /
          100 -
      liabilities -
      deferredMaintenance -
      transactionCosts;
  double get totalBuyerCost =>
      askingPrice + transactionCosts + deferredMaintenance;
  double get priceGap => askingPrice - adjustedNetAssets;
  double get assetCoverage => safeRatio(adjustedNetAssets, askingPrice);

  bool get isValid =>
      askingPrice > 0 &&
      grossAssets > 0 &&
      [
        equipment,
        inventory,
        receivables,
        intangibles,
        cash,
        liabilities,
        deferredMaintenance,
        transactionCosts,
      ].every((value) => value >= 0) &&
      recoveryPercent >= 0 &&
      recoveryPercent <= 100;
}

class CommercialRealEstateScreen {
  const CommercialRealEstateScreen({
    required this.askingPrice,
    required this.potentialRent,
    required this.otherIncome,
    required this.vacancyPercent,
    required this.operatingExpenses,
    required this.replacementReserve,
    required this.marketCapPercent,
    required this.downPaymentPercent,
    required this.interestPercent,
    required this.amortizationYears,
    required this.holdingYears,
    required this.annualNoiGrowthPercent,
    required this.exitCapPercent,
  });

  final double askingPrice;
  final double potentialRent;
  final double otherIncome;
  final double vacancyPercent;
  final double operatingExpenses;
  final double replacementReserve;
  final double marketCapPercent;
  final double downPaymentPercent;
  final double interestPercent;
  final int amortizationYears;
  final int holdingYears;
  final double annualNoiGrowthPercent;
  final double exitCapPercent;

  double get potentialGrossIncome => potentialRent + otherIncome;
  double get vacancyLoss => potentialGrossIncome * vacancyPercent / 100;
  double get effectiveGrossIncome => potentialGrossIncome - vacancyLoss;
  double get noi =>
      effectiveGrossIncome - operatingExpenses - replacementReserve;
  double get incomeValue =>
      marketCapPercent > 0 ? noi / (marketCapPercent / 100) : 0;
  double get goingInCap => safeRatio(noi, askingPrice);
  double get valueGap => incomeValue - askingPrice;
  double get loan => askingPrice * (1 - downPaymentPercent / 100);
  double get annualDebt =>
      annualDebtService(loan, interestPercent, amortizationYears);
  double get dscr => annualDebt == 0 ? 99 : safeRatio(noi, annualDebt);
  double get debtYield => safeRatio(noi, loan);
  double get cashAfterDebt => noi - annualDebt;
  double get cashOnCash => safeRatio(cashAfterDebt, askingPrice - loan);
  double get projectedNoi =>
      noi * math.pow(1 + annualNoiGrowthPercent / 100, holdingYears);
  double get projectedValue =>
      exitCapPercent > 0 ? projectedNoi / (exitCapPercent / 100) : 0;

  /// Keeps the supplied workbook's normalized, weighted-factor structure.
  /// This is an illustrative screen, not a calibrated probability.
  Map<String, double> get factorScores => {
    'Income yield': (safeRatio(goingInCap, marketCapPercent / 100) * 50)
        .clamp(0, 100)
        .toDouble(),
    'Debt coverage': ((dscr - 1) / .5 * 100).clamp(0, 100).toDouble(),
    'Occupancy': ((1 - vacancyPercent / 100) * 100).clamp(0, 100).toDouble(),
    'Value gap': ((safeRatio(incomeValue, askingPrice) - .8) / .4 * 100)
        .clamp(0, 100)
        .toDouble(),
  };
  double get opportunityScore {
    final factors = factorScores;
    return factors['Income yield']! * .35 +
        factors['Debt coverage']! * .25 +
        factors['Occupancy']! * .20 +
        factors['Value gap']! * .20;
  }

  double get riskScore {
    final vacancyRisk = (vacancyPercent / 20 * 100).clamp(0, 100);
    final leverageRisk = ((100 - downPaymentPercent - 50) / 40 * 100).clamp(
      0,
      100,
    );
    final debtRisk = ((1.5 - dscr) / .5 * 100).clamp(0, 100);
    return vacancyRisk * .35 + leverageRisk * .30 + debtRisk * .35;
  }

  double get netScore => (opportunityScore - .55 * riskScore).clamp(0, 100);

  bool get isValid =>
      askingPrice > 0 &&
      potentialGrossIncome > 0 &&
      potentialRent >= 0 &&
      otherIncome >= 0 &&
      noi > 0 &&
      operatingExpenses >= 0 &&
      replacementReserve >= 0 &&
      vacancyPercent >= 0 &&
      vacancyPercent < 100 &&
      marketCapPercent > 0 &&
      exitCapPercent > 0 &&
      downPaymentPercent >= 0 &&
      downPaymentPercent <= 100 &&
      interestPercent >= 0 &&
      amortizationYears > 0 &&
      holdingYears > 0 &&
      annualNoiGrowthPercent > -100;
}
