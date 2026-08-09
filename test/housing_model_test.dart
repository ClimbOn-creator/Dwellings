import 'package:dwelling_iq/models/housing_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('model produces finite results when buildable area is missing', () {
    final inputs = PropertyInputs(
      address: 'Kitsilano, Vancouver, BC',
      price: 1200000,
      finishedArea: 1800,
      lotArea: 6500,
      buildable: 0,
      bedrooms: 3,
      bathrooms: 2,
      yearBuilt: 1988,
      repairs: 25000,
      rent: 5000,
      operatingCosts: 12500,
      redevelopment: 55,
      scarcity: 64,
      daysOnMarket: 28,
      downPayment: 20,
      amortization: 25,
      holdingPeriod: 5,
      profile: marketProfiles.first,
    );
    final result = analyzeProperty(inputs, DecisionMode.home);
    expect(result.net.isFinite, isTrue);
    expect(result.projectedValue.isFinite, isTrue);
    expect(result.net, inInclusiveRange(0, 100));
    expect(result.drivers, isNotEmpty);
  });
}
