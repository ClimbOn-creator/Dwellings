import 'package:dwelling_iq/services/business_sale_bulletin_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('four fictional examples are distinct and cannot contact or convert', () async {
    SharedPreferences.setMockInitialValues({});
    final examples = await BusinessSaleBulletinService.examples();
    expect(examples.length, 4);
    expect(examples.map((b) => b.id).toSet().length, 4);
    for (final b in examples) {
      expect(b.isExample, isTrue);
      expect(b.canConvert, isFalse);
      expect(b.canEdit, isFalse);
      expect(b.sourceUrl, isEmpty);
      expect(b.exampleAsset, startsWith('assets/images/'));
      expect((await BusinessSaleBulletinService.loadOne(b.id))?.title, b.title);
    }
  });
  test('example bookmarks persist across reload and can be removed', () async {
    SharedPreferences.setMockInitialValues({});
    const id = 'example-advisory';
    await BusinessSaleBulletinService.setSaved(id, true);
    expect((await BusinessSaleBulletinService.loadOne(id))!.isSaved, isTrue);
    expect((await BusinessSaleBulletinService.loadOne('example-workspace'))!.isSaved, isFalse);
    await BusinessSaleBulletinService.setSaved(id, false);
    expect((await BusinessSaleBulletinService.loadOne(id))!.isSaved, isFalse);
  });
  test(
    'rich listings preserve edit, saved and financial details with safe photos',
    () {
      final b = BusinessSaleBulletin.fromJson({
        'id': 'rich',
        'can_edit': true,
        'is_saved': true,
        'updated_at': '2026-09-05T01:00:00Z',
        'details': {
          'revenue': r'$900,000',
          'real_estate': 'Lease',
          'photos': ['https://example.com/photo.jpg', 'javascript:alert(1)'],
        },
      });
      expect(b.canEdit, true);
      expect(b.isSaved, true);
      expect(b.detail('revenue'), r'$900,000');
      expect(b.updatedAt!.isUtc, true);
      expect(b.photos, ['https://example.com/photo.jpg']);
    },
  );
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
