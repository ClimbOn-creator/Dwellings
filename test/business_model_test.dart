import 'package:dwelling_iq/models/business_model.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessInputs inputs(Map<String, double> overrides) => BusinessInputs(
  businessName: 'Test business',
  industry: 'Services',
  location: 'Vancouver, BC',
  values: {
    'askingPrice': 1200000,
    'revenue': 1800000,
    'grossProfit': 720000,
    'ebitda': 260000,
    'netIncome': 150000,
    'ownerComp': 140000,
    'addBacks': 90000,
    'verifiedAddBacks': 50000,
    'replacementSalary': 120000,
    'maintenanceCapex': 35000,
    'inventoryIncluded': 50000,
    'workingCapitalIncluded': 60000,
    'requiredWorkingCapital': 150000,
    'transactionCosts': 70000,
    'debtPercent': 65,
    'interestRate': 8,
    'amortizationYears': 7,
    'revenueGrowth': 3,
    'topCustomerPercent': 18,
    'ownerDependence': 55,
    'leaseYearsRemaining': 4,
    'threeYearRevenueProvided': 1,
    'taxReturnsReviewed': 1,
    'bankStatementsReviewed': 1,
    'customerListReviewed': 1,
    ...overrides,
  },
);

void main() {
  test('calculates normalized acquisition economics', () {
    final result = analyzeBusiness(inputs({}));
    expect(result.normalizedEbitda, 450000);
    expect(result.totalAcquisitionCost, 1410000);
    expect(result.annualDebtService, greaterThan(0));
    expect(result.scenarios, hasLength(3));
    expect(result.riskScore.isFinite, isTrue);
    expect(result.viabilityScore, inInclusiveRange(0, 100));
  });

  test('warns when acquisition cannot pay the owner', () {
    final result = analyzeBusiness(
      inputs({'askingPrice': 2500000, 'ebitda': 150000, 'debtPercent': 80}),
    );
    expect(result.cashAfterOwnerSalary, lessThan(0));
    expect(
      result.flags.any((flag) => flag.contains('negative annual cash flow')),
      isTrue,
    );
  });

  test('downside scenario produces less cash than expected', () {
    final result = analyzeBusiness(inputs({}));
    expect(
      result.scenarios.first.cashAfterOwner,
      lessThan(result.scenarios[1].cashAfterOwner),
    );
  });

  test('high concentration and owner dependence increase risk', () {
    final baseline = analyzeBusiness(inputs({}));
    final concentrated = analyzeBusiness(
      inputs({'topCustomerPercent': 55, 'ownerDependence': 95}),
    );
    expect(concentrated.riskScore, greaterThan(baseline.riskScore));
    expect(
      concentrated.flags.any((flag) => flag.contains('largest customer')),
      isTrue,
    );
  });
}
