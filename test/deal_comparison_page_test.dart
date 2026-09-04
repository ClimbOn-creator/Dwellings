import 'package:dwelling_iq/models/buyer_comparison_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buyer comparison profile preserves all eight answers', () {
    final profile = BuyerComparisonProfile.fromJson({
      'goal': 'Long-term profit and independence',
      'role': 'Oversee a hired manager',
      'horizon': 'Long term · 10+ years',
      'weeklyTime': 'Light oversight · under 10 hours',
      'minimumCashFlow': '180000',
      'minimumReturn': '20',
      'riskTolerance': 'Stable and proven only',
      'nonNegotiables': 'No customer concentration above 25%',
    });

    expect(profile.answeredCount, 8);
    expect(profile.complete, isTrue);
    expect(profile.cashFlowTarget, 180000);
    expect(profile.returnTarget, 20);
    expect(profile.toJson()['role'], 'Oversee a hired manager');
  });

  test('incomplete profile reports the unanswered comparison questions', () {
    const profile = BuyerComparisonProfile(
      goal: 'Reliable personal income',
      role: 'Run it myself',
    );

    expect(profile.answeredCount, 2);
    expect(profile.complete, isFalse);
  });

  test('bulletin deal score rewards matching buyer criteria', () {
    const matcher = BuyerDealMatcher(
      profile: BuyerComparisonProfile(
        goal: 'Long-term profit and independence',
        role: 'Oversee a hired manager',
        riskTolerance: 'Stable and proven only',
      ),
      blueprint: {
        'industries': 'Commercial services',
        'geography': 'Victoria, BC',
        'minPrice': '500000',
        'maxPrice': '2000000',
      },
    );

    final strong = matcher.score(
      title: 'Established service company',
      industry: 'Commercial services',
      region: 'Victoria, BC',
      askingPriceBand: r'$1M–$1.5M',
      summary: 'Stable recurring revenue with an experienced management team.',
    );
    final weak = matcher.score(
      title: 'Distressed restaurant turnaround',
      industry: 'Hospitality',
      region: 'Calgary, AB',
      askingPriceBand: r'$5M+',
      summary: 'Owner-dependent turnaround opportunity.',
    );

    expect(strong, greaterThan(weak));
  });

  test('price dropdown matches overlapping bulletin price bands', () {
    expect(
      BuyerDealMatcher.matchesPriceFilter(r'$750K–$1.25M', '500k-1m'),
      isTrue,
    );
    expect(
      BuyerDealMatcher.matchesPriceFilter(r'$2M–$3M', 'under-500k'),
      isFalse,
    );
    expect(
      BuyerDealMatcher.matchesPriceFilter('Contact seller', 'unlisted'),
      isTrue,
    );
  });
}
