import 'package:dwelling_iq/services/business_sale_bulletin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('business sale bulletin parses source and conversion state', () {
    final bulletin = BusinessSaleBulletin.fromJson({
      'id': 'bulletin-1',
      'title': 'Island service company',
      'industry': 'Commercial services',
      'region': 'Victoria, BC',
      'asking_price_band': r'$1M–$2M',
      'summary': 'Recurring commercial clients and an established team.',
      'source_label': 'Broker listing',
      'source_url': 'https://example.com/listing',
      'posted_at': '2026-09-03T12:00:00Z',
      'can_convert': true,
      'converted_opportunity_id': null,
    });

    expect(bulletin.industry, 'Commercial services');
    expect(bulletin.canConvert, isTrue);
    expect(bulletin.converted, isFalse);
    expect(bulletin.sourceUrl, 'https://example.com/listing');
  });

  test('converted bulletin is visibly linked to its anonymous draft', () {
    final bulletin = BusinessSaleBulletin.fromJson({
      'id': 'bulletin-2',
      'converted_opportunity_id': 'deal-2',
    });

    expect(bulletin.converted, isTrue);
    expect(bulletin.convertedOpportunityId, 'deal-2');
    expect(bulletin.canConvert, isFalse);
  });
}
