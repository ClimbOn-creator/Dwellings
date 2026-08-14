import 'package:dwelling_iq/models/platform_side.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PropertyIQ and DealIQ expose separate professional categories', () {
    final property = providerCategoriesFor(PlatformSide.property);
    final business = providerCategoriesFor(PlatformSide.business);

    expect(property, hasLength(5));
    expect(business, hasLength(10));
    expect(property.toSet().intersection(business.toSet()), isEmpty);
    expect(
      business,
      containsAll([
        ProviderCategory.businessBroker,
        ProviderCategory.maLawyer,
        ProviderCategory.qualityOfEarnings,
        ProviderCategory.commercialLender,
        ProviderCategory.taxAdvisor,
        ProviderCategory.insuranceAdvisor,
        ProviderCategory.humanResources,
        ProviderCategory.cybersecurity,
        ProviderCategory.industryAdvisor,
        ProviderCategory.wealthManager,
      ]),
    );
  });

  test('every marketplace category has a unique database value', () {
    final values = ProviderCategory.values
        .map((category) => category.databaseValue)
        .toList();
    expect(values.toSet(), hasLength(values.length));
  });

  test('Canadian city suggestions correct common misspellings', () {
    final suggestions = MarketplaceService.citySuggestions('Vancuver');
    expect(suggestions.first.city, 'Vancouver');
    expect(suggestions.first.region, 'BC');
    expect(
      MarketplaceService.resolveCanadianCity('Tornto')?.label,
      'Toronto, ON',
    );
  });

  test('headline metro municipalities are available in city search', () {
    expect(
      MarketplaceService.resolveCanadianCity('Langfrd')?.label,
      'Langford, BC',
    );
    expect(
      MarketplaceService.resolveCanadianCity('Richmond Hill')?.label,
      'Richmond Hill, ON',
    );
    expect(
      MarketplaceService.resolveCanadianCity('Okotoks')?.label,
      'Okotoks, AB',
    );
  });

  test('unrecognized locations are rejected instead of silently saved', () {
    expect(
      MarketplaceService.resolveCanadianCity('Definitely Not A City'),
      isNull,
    );
  });
}
