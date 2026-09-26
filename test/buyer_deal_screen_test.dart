import 'package:dwelling_iq/models/buyer_deal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('business range adjusts for verified add-backs and manager salary', () {
    const screen = BusinessPriceScreen(
      askingPrice: 1200000,
      revenue: 1800000,
      reportedEbitda: 260000,
      verifiedAddbacks: 20000,
      ownerCompensation: 80000,
      replacementSalary: 100000,
      maintenanceCapex: 30000,
      lowMultiple: 3,
      highMultiple: 5,
      downPaymentPercent: 25,
      interestPercent: 7,
      amortizationYears: 7,
    );
    expect(screen.isValid, isTrue);
    expect(screen.maintainableEbitda, 260000);
    expect(screen.lowValue, 780000);
    expect(screen.highValue, 1300000);
    expect(screen.annualDebt, greaterThan(0));
    expect(screen.dscr, closeTo(230000 / screen.annualDebt, .0001));
  });

  test('asset value separates adjusted assets from acquisition cost', () {
    const screen = AssetDealScreen(
      askingPrice: 850000,
      equipment: 500000,
      inventory: 180000,
      receivables: 120000,
      intangibles: 100000,
      cash: 40000,
      liabilities: 150000,
      deferredMaintenance: 30000,
      transactionCosts: 20000,
      recoveryPercent: 60,
    );
    expect(screen.isValid, isTrue);
    expect(screen.adjustedNetAssets, 760000);
    expect(screen.totalBuyerCost, 900000);
    expect(screen.liquidationFloor, 380000);
  });

  test(
    'commercial income bridge, cap value, debt coverage, and score react',
    () {
      const base = CommercialRealEstateScreen(
        askingPrice: 5000000,
        potentialRent: 480000,
        otherIncome: 20000,
        vacancyPercent: 5,
        operatingExpenses: 140000,
        replacementReserve: 20000,
        marketCapPercent: 6,
        downPaymentPercent: 30,
        interestPercent: 6.5,
        amortizationYears: 25,
        holdingYears: 5,
        annualNoiGrowthPercent: 2,
        exitCapPercent: 6.5,
      );
      expect(base.isValid, isTrue);
      expect(base.effectiveGrossIncome, 475000);
      expect(base.noi, 315000);
      expect(base.incomeValue, 5250000);
      expect(base.goingInCap, closeTo(.063, .00001));
      expect(base.dscr, closeTo(base.noi / base.annualDebt, .00001));
      expect(base.opportunityScore, inInclusiveRange(0, 100));
      expect(base.riskScore, inInclusiveRange(0, 100));

      const weaker = CommercialRealEstateScreen(
        askingPrice: 5000000,
        potentialRent: 480000,
        otherIncome: 20000,
        vacancyPercent: 15,
        operatingExpenses: 140000,
        replacementReserve: 20000,
        marketCapPercent: 6,
        downPaymentPercent: 30,
        interestPercent: 6.5,
        amortizationYears: 25,
        holdingYears: 5,
        annualNoiGrowthPercent: 2,
        exitCapPercent: 6.5,
      );
      expect(weaker.noi, lessThan(base.noi));
      expect(weaker.incomeValue, lessThan(base.incomeValue));
      expect(weaker.netScore, lessThan(base.netScore));
    },
  );
}
