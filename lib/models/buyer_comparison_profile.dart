class BuyerComparisonProfile {
  const BuyerComparisonProfile({
    this.goal = '',
    this.role = '',
    this.horizon = '',
    this.weeklyTime = '',
    this.minimumCashFlow = '',
    this.minimumReturn = '',
    this.riskTolerance = '',
    this.nonNegotiables = '',
  });

  final String goal;
  final String role;
  final String horizon;
  final String weeklyTime;
  final String minimumCashFlow;
  final String minimumReturn;
  final String riskTolerance;
  final String nonNegotiables;

  factory BuyerComparisonProfile.fromJson(Map<String, dynamic> row) =>
      BuyerComparisonProfile(
        goal: '${row['goal'] ?? ''}',
        role: '${row['role'] ?? ''}',
        horizon: '${row['horizon'] ?? ''}',
        weeklyTime: '${row['weeklyTime'] ?? ''}',
        minimumCashFlow: '${row['minimumCashFlow'] ?? ''}',
        minimumReturn: '${row['minimumReturn'] ?? ''}',
        riskTolerance: '${row['riskTolerance'] ?? ''}',
        nonNegotiables: '${row['nonNegotiables'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
    'goal': goal,
    'role': role,
    'horizon': horizon,
    'weeklyTime': weeklyTime,
    'minimumCashFlow': minimumCashFlow,
    'minimumReturn': minimumReturn,
    'riskTolerance': riskTolerance,
    'nonNegotiables': nonNegotiables,
  };

  int get answeredCount =>
      toJson().values.where((value) => '$value'.trim().isNotEmpty).length;

  bool get complete => answeredCount == 8;

  double get cashFlowTarget => number(minimumCashFlow);
  double get returnTarget => number(minimumReturn);

  static double number(String value) =>
      double.tryParse(
        value
            .replaceAll(',', '')
            .replaceAll(r'$', '')
            .replaceAll('%', '')
            .trim(),
      ) ??
      0;
}

class BuyerDealMatcher {
  const BuyerDealMatcher({required this.profile, required this.blueprint});

  final BuyerComparisonProfile profile;
  final Map<String, dynamic> blueprint;

  int score({
    required String title,
    required String industry,
    required String region,
    required String askingPriceBand,
    required String summary,
  }) {
    final text = '$title $industry $region $summary'.toLowerCase();
    var earned = 0.0;
    var possible = 0.0;

    void criterion(double weight, bool matches) {
      possible += weight;
      if (matches) earned += weight;
    }

    final wantedIndustries = '${blueprint['industries'] ?? ''}'.trim();
    if (wantedIndustries.isNotEmpty) {
      final terms = _terms(wantedIndustries);
      criterion(24, terms.any(text.contains));
    }

    final wantedGeography = '${blueprint['geography'] ?? ''}'.trim();
    if (wantedGeography.isNotEmpty) {
      final regionText = region.toLowerCase();
      criterion(20, _terms(wantedGeography).any(regionText.contains));
    }

    final minPrice = BuyerComparisonProfile.number(
      '${blueprint['minPrice'] ?? ''}',
    );
    final maxPrice = BuyerComparisonProfile.number(
      '${blueprint['maxPrice'] ?? ''}',
    );
    final listingRange = priceRange(askingPriceBand);
    if ((minPrice > 0 || maxPrice > 0) && listingRange != null) {
      final wantedLow = minPrice > 0 ? minPrice : 0;
      final wantedHigh = maxPrice > 0 ? maxPrice : double.infinity;
      criterion(
        22,
        listingRange.$2 >= wantedLow && listingRange.$1 <= wantedHigh,
      );
    }

    final goal = profile.goal.toLowerCase();
    if (goal.isNotEmpty) {
      final keywords = goal.contains('long-term')
          ? const ['recurring', 'established', 'durable', 'stable', 'proven']
          : goal.contains('short-term')
          ? const ['growth', 'turnaround', 'improvement', 'value-add', 'expand']
          : goal.contains('income')
          ? const ['cash flow', 'profitable', 'recurring', 'income']
          : const ['strategic', 'add-on', 'adjacent', 'platform'];
      criterion(14, keywords.any(text.contains));
    }

    final role = profile.role.toLowerCase();
    if (role.isNotEmpty) {
      final managerLed = role.contains('manager') || role.contains('passive');
      criterion(
        12,
        managerLed
            ? ['team', 'manager', 'management', 'staff'].any(text.contains)
            : !text.contains('absentee'),
      );
    }

    final risk = profile.riskTolerance.toLowerCase();
    if (risk.isNotEmpty) {
      final turnaround =
          text.contains('turnaround') ||
          text.contains('distressed') ||
          text.contains('restructur');
      criterion(8, risk.contains('turnaround') || !turnaround);
    }

    if (possible == 0) return 0;
    return ((earned / possible) * 98).round().clamp(1, 98);
  }

  static List<String> _terms(String value) => value
      .toLowerCase()
      .split(RegExp(r'[,;/]|\band\b'))
      .map((term) => term.trim())
      .where((term) => term.length >= 3)
      .toList();

  static (double, double)? priceRange(String label) {
    final matches = RegExp(
      r'(\d+(?:\.\d+)?)\s*([mk]?)',
      caseSensitive: false,
    ).allMatches(label.replaceAll(',', '')).toList();
    if (matches.isEmpty) return null;
    double value(RegExpMatch match) {
      final amount = double.parse(match.group(1)!);
      return switch (match.group(2)!.toLowerCase()) {
        'm' => amount * 1000000,
        'k' => amount * 1000,
        _ => amount,
      };
    }

    final values = matches.map(value).toList()..sort();
    return (values.first, label.contains('+') ? double.infinity : values.last);
  }

  static bool matchesPriceFilter(String label, String filter) {
    if (filter == 'all') return true;
    final range = priceRange(label);
    if (range == null) return filter == 'unlisted';
    final bucket = switch (filter) {
      'under-500k' => (0.0, 500000.0),
      '500k-1m' => (500000.0, 1000000.0),
      '1m-2m' => (1000000.0, 2000000.0),
      '2m-5m' => (2000000.0, 5000000.0),
      '5m-plus' => (5000000.0, double.infinity),
      _ => (0.0, double.infinity),
    };
    return range.$2 >= bucket.$1 && range.$1 < bucket.$2;
  }
}
