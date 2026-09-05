import 'buyer_comparison_profile.dart';

class QuizBusiness {
  const QuizBusiness(
    this.id,
    this.name,
    this.goal,
    this.role,
    this.horizon,
    this.time,
    this.risk,
    this.strength,
    this.revenue,
    this.expenses,
    this.salary,
    this.equity,
  );
  final String id, name, goal, role, horizon, time, risk, strength;
  final double revenue, expenses, salary, equity;
  double get cash => revenue - expenses - salary;
  double get annualReturn => cash / equity * 100;
  Map<String, String> get traits => {
    'goal': goal,
    'role': role,
    'horizon': horizon,
    'weeklyTime': time,
    'minimumCashFlow': cash.toStringAsFixed(0),
    'minimumReturn': annualReturn.toStringAsFixed(1),
    'riskTolerance': risk,
    'nonNegotiables': strength,
  };
}

class QuizChoice {
  const QuizChoice(this.left, this.right, this.winner);
  final QuizBusiness left, right, winner;
  QuizBusiness get loser => winner.id == left.id ? right : left;
  Map<String, String> toJson() => {
    'left': left.id,
    'right': right.id,
    'winner': winner.id,
  };
}

/// Counts preference evidence only when the two businesses differ.
/// Ties use the most recent choice. Figures describe preferred examples,
/// not a buyer's explicitly stated financial minimums.
BuyerComparisonProfile inferQuizProfile(List<QuizChoice> choices) {
  final result = <String, dynamic>{};
  if (choices.isEmpty) return const BuyerComparisonProfile();
  for (final field in choices.last.winner.traits.keys) {
    final votes = <String, int>{};
    for (final choice in choices) {
      final value = choice.winner.traits[field]!;
      if (value != choice.loser.traits[field]) {
        votes[value] = (votes[value] ?? 0) + 1;
      }
    }
    String best = choices.last.winner.traits[field]!;
    var highest = 0;
    for (final choice in choices) {
      final value = choice.winner.traits[field]!;
      if ((votes[value] ?? 0) >= highest && votes.containsKey(value)) {
        best = value;
        highest = votes[value]!;
      }
    }
    result[field] = best;
  }
  return BuyerComparisonProfile.fromJson(result);
}

const quizTraitLabels = {
  'goal': 'Buying outcome',
  'role': 'Your role',
  'horizon': 'Holding period',
  'weeklyTime': 'Weekly involvement',
  'minimumCashFlow': 'Preferred annual cash flow (CAD)',
  'minimumReturn': 'Preferred annual return (%)',
  'riskTolerance': 'Risk preference',
  'nonNegotiables': 'Business strengths you preferred',
};

// Stable businesses: an incumbent never changes its facts between comparisons.
const quizBusinesses = [
  QuizBusiness(
    'A',
    'Evergreen Maintenance',
    'Long-term profit and independence',
    'Oversee a hired manager',
    'Long term · 10+ years',
    'Light oversight · under 10 hours',
    'Stable and proven only',
    'Recurring or repeat revenue',
    900000,
    600000,
    100000,
    1000000,
  ),
  QuizBusiness(
    'B',
    'Summit Property Services',
    'Short-term improvement and resale',
    'Run it myself',
    'Short term · under 5 years',
    'Full time · 40+ hours',
    'Open to a turnaround',
    'Low seller dependence',
    800000,
    530000,
    70000,
    650000,
  ),
  QuizBusiness(
    'C',
    'Harbour Commercial Cleaning',
    'Reliable personal income',
    'Run it myself',
    'Medium term · 5–10 years',
    'Full time · 40+ hours',
    'Stable and proven only',
    'Recurring or repeat revenue',
    560000,
    370000,
    70000,
    600000,
  ),
  QuizBusiness(
    'D',
    'Cedar Facilities Group',
    'Strategic add-on acquisition',
    'Oversee a hired manager',
    'Long term · 10+ years',
    'Active oversight · 15–30 hours',
    'Balanced risk and growth',
    'Manager already in place',
    1400000,
    980000,
    120000,
    1250000,
  ),
  QuizBusiness(
    'E',
    'Northline Grounds Care',
    'Long-term profit and independence',
    'Transition from operator to manager',
    'Long term · 10+ years',
    'Active oversight · 15–30 hours',
    'Balanced risk and growth',
    'Low seller dependence',
    760000,
    500000,
    80000,
    750000,
  ),
  QuizBusiness(
    'F',
    'Atlas Building Services',
    'Short-term improvement and resale',
    'Run it myself',
    'Short term · under 5 years',
    'Full time · 40+ hours',
    'Open to a turnaround',
    'Recurring or repeat revenue',
    1200000,
    820000,
    80000,
    850000,
  ),
  QuizBusiness(
    'G',
    'Meadow Contract Cleaning',
    'Reliable personal income',
    'Mostly passive ownership',
    'Medium term · 5–10 years',
    'Light oversight · under 10 hours',
    'Stable and proven only',
    'Manager already in place',
    720000,
    490000,
    110000,
    800000,
  ),
  QuizBusiness(
    'H',
    'Bridgeway Maintenance',
    'Strategic add-on acquisition',
    'Oversee a hired manager',
    'Medium term · 5–10 years',
    'Active oversight · 15–30 hours',
    'Balanced risk and growth',
    'Low seller dependence',
    1600000,
    1110000,
    140000,
    1400000,
  ),
  QuizBusiness(
    'I',
    'Coastline Facility Care',
    'Long-term profit and independence',
    'Oversee a hired manager',
    'Long term · 10+ years',
    'Light oversight · under 10 hours',
    'Stable and proven only',
    'No turnaround required',
    1100000,
    750000,
    130000,
    1100000,
  ),
];
