class DealIntakeField {
  const DealIntakeField(this.key, this.label, this.hint, this.stage);
  final String key, label, hint;
  final int stage;
}

const dealIntakeFields = [
  DealIntakeField(
    'source_name',
    'Where did you find this deal?',
    'Affinity, another listing site, a broker, or directly from the owner',
    0,
  ),
  DealIntakeField(
    'source_url',
    'Original listing URL',
    'Optional http/https link. Enter the facts below; links are not imported automatically.',
    0,
  ),
  DealIntakeField(
    'country',
    'Business country / jurisdiction',
    'Country and state, province or region; use Unknown if not yet confirmed',
    0,
  ),
  DealIntakeField(
    'currency',
    'Currency code for all amounts',
    'Three-letter code, such as CAD, USD, GBP, EUR or AUD. No currency conversion is applied.',
    0,
  ),
  DealIntakeField(
    'structure',
    'What is included in the sale?',
    'Assets or shares; inventory, equipment, property and excluded items; Unknown is okay',
    0,
  ),
  DealIntakeField(
    'seller_reason',
    'Seller reason and your intended role',
    'Why selling? Owner-operator, investor or manager-led? Transition support?',
    0,
  ),
  DealIntakeField(
    'financial_period',
    'Financial reporting period and evidence',
    'Year/end date, source documents, seller-reported versus independently verified',
    1,
  ),
  DealIntakeField(
    'earnings_adjustments',
    'Owner pay, SDE and earnings adjustments',
    'Salary, personal expenses, one-offs and the evidence for each proposed add-back',
    1,
  ),
  DealIntakeField(
    'balance_sheet',
    'Debt, cash, inventory and working capital',
    'What transfers? Receivables/payables, stock valuation and cash needed after closing',
    1,
  ),
  DealIntakeField(
    'customers',
    'Customers, suppliers and revenue quality',
    'Concentration, repeat revenue, key contracts, churn and dependencies',
    1,
  ),
  DealIntakeField(
    'operations',
    'People, assets and operations',
    'Key staff, owner dependence, leases, equipment condition, systems and capital spending',
    1,
  ),
  DealIntakeField(
    'legal_risks',
    'Legal, tax and regulatory questions',
    'Licences, contract consents, disputes, IP, employment, tax and environmental issues to verify locally',
    1,
  ),
  DealIntakeField(
    'funding_plan',
    'Funding and downside plan',
    'Equity, lender terms, seller financing, fees, reserves and ability to service debt',
    2,
  ),
  DealIntakeField(
    'decision_gaps',
    'Unknowns, evidence needed and walk-away limits',
    'What must be verified before you commit? Who owns each follow-up and by when?',
    2,
  ),
];
String? validateDealIntake(
  Map<String, String> values,
  List<String> amounts, {
  bool requireCountry = true,
}) {
  if (requireCountry && (values['country'] ?? '').trim().isEmpty)
    return 'Enter the country/jurisdiction, or Unknown if it is not confirmed.';
  if (!RegExp(
    r'^[A-Z]{3}$',
  ).hasMatch((values['currency'] ?? '').trim().toUpperCase()))
    return 'Enter a three-letter currency code, such as CAD or USD.';
  final source = (values['source_url'] ?? '').trim();
  if (source.isNotEmpty) {
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty)
      return 'Use a complete http or https listing URL, or leave it blank.';
  }
  for (var index = 0; index < amounts.length; index++) {
    final value = amounts[index];
    if (value.trim().isEmpty) continue;
    final number = double.tryParse(value.replaceAll(',', '').trim());
    if (number == null || !number.isFinite)
      return 'Enter numbers only for financial amounts, or leave unknown figures blank.';
    if (number < 0 && index != 2)
      return 'Price, revenue and available capital cannot be negative. Earnings may be negative.';
  }
  return null;
}
