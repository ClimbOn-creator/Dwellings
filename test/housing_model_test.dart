import 'package:dwelling_iq/models/housing_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, double> _baseValues() => {
  'price': 1200000,
  'closingCosts': 30000,
  'improvements': 50000,
  'area': 6200,
  'annualRent': 180000,
  'otherIncome': 6000,
  'vacancy': 4,
  'propertyTax': 12500,
  'insurance': 5200,
  'utilities': 7200,
  'maintenance': 12000,
  'management': 5,
  'reserves': 9000,
  'otherExpenses': 4500,
  'downPayment': 30,
  'interestRate': 4.5,
  'amortization': 25,
  'holdingPeriod': 7,
  'exitCap': 5.5,
  'sellingCosts': 4,
  'rentGrowth': 3,
  'expenseGrowth': 2.5,
  'appreciation': 3.9,
  'discountRate': 8,
  'householdIncome': 180000,
  'monthlyDebt': 500,
  'walt': 4,
  'leaseRollover': 20,
  'tenantConcentration': 25,
  'conditionRisk': 24,
  'environmentRisk': 18,
  'redevelopment': 58,
  'scarcity': 64,
  'daysOnMarket': 35,
};

PropertyInputs _inputs({
  PropertyType type = PropertyType.multifamily,
  Map<String, double>? values,
}) => PropertyInputs(
  address: 'Kitsilano, Vancouver, BC',
  propertyType: type,
  profile: marketProfiles.first,
  values: values ?? _baseValues(),
);

void main() {
  test('commercial underwriting produces auditable finite metrics', () {
    final result = analyzeProperty(_inputs(), DecisionMode.invest);
    expect(result.noi, closeTo(119232, 1));
    expect(result.capRate, closeTo(result.noi / 1200000, .00001));
    expect(result.dscr.isFinite, isTrue);
    expect(result.irr.isFinite, isTrue);
    expect(result.net, inInclusiveRange(0, 100));
    expect(result.scenarios, hasLength(3));
  });

  test('downside scenario is weaker than upside scenario', () {
    final result = analyzeProperty(_inputs(), DecisionMode.invest);
    expect(result.scenarios.first.irr, lessThan(result.scenarios.last.irr));
    expect(
      result.scenarios.first.exitValue,
      lessThan(result.scenarios.last.exitValue),
    );
  });

  test('homebuyer analysis calculates debt-to-income and monthly cost', () {
    final result = analyzeProperty(
      _inputs(type: PropertyType.singleFamily),
      DecisionMode.home,
    );
    expect(result.dti, greaterThan(0));
    expect(result.monthlyCarry, greaterThan(result.monthlyMortgage));
    expect(result.projectedValue.isFinite, isTrue);
  });

  test('zero income and zero leverage remain finite', () {
    final values = _baseValues()
      ..['annualRent'] = 0
      ..['otherIncome'] = 0
      ..['downPayment'] = 100;
    final result = analyzeProperty(
      _inputs(values: values),
      DecisionMode.invest,
    );
    expect(result.dscr.isFinite, isTrue);
    expect(result.breakEvenOccupancy.isFinite, isTrue);
    expect(result.irr.isFinite, isTrue);
    expect(result.net, inInclusiveRange(0, 100));
  });
}
