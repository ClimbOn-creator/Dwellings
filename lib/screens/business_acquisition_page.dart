import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/business_model.dart';
import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/business_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'platform_hub_page.dart';
import 'landing_screen.dart';
import 'local_network_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);
const _lilac = Color(0xFFBCAEFF);
const _red = Color(0xFFB42318);
const _green = Color(0xFF16825D);

class BusinessAcquisitionPage extends StatefulWidget {
  const BusinessAcquisitionPage({super.key});

  @override
  State<BusinessAcquisitionPage> createState() =>
      _BusinessAcquisitionPageState();
}

class _BusinessAcquisitionPageState extends State<BusinessAcquisitionPage> {
  final _businessName = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();
  final Map<String, TextEditingController> _fields = {};
  BusinessResult? _result;
  bool _saving = false;
  String? _assessmentId;

  static const _definitions = <_BusinessField>[
    _BusinessField(
      'askingPrice',
      'Asking price',
      'Purchase price for the operating business.',
      1200000,
    ),
    _BusinessField(
      'revenue',
      'Latest annual revenue',
      'Use revenue supported by financial statements.',
      1800000,
    ),
    _BusinessField(
      'grossProfit',
      'Gross profit',
      'Revenue less direct cost of goods or service delivery.',
      720000,
    ),
    _BusinessField(
      'ebitda',
      'Reported EBITDA',
      'Earnings before interest, tax, depreciation and amortization.',
      260000,
    ),
    _BusinessField(
      'netIncome',
      'Reported net income',
      'Accounting profit after normal expenses.',
      150000,
    ),
    _BusinessField(
      'ownerComp',
      'Seller compensation in expenses',
      'Salary, bonus and benefits paid to the seller and already deducted in reported EBITDA.',
      140000,
    ),
    _BusinessField(
      'addBacks',
      'Claimed seller add-backs',
      'Expenses the seller claims will not continue.',
      90000,
    ),
    _BusinessField(
      'verifiedAddBacks',
      'Verified add-backs',
      'Only add-backs supported by records and professional review.',
      50000,
    ),
    _BusinessField(
      'replacementSalary',
      'Required replacement salary',
      'Market compensation for the work the buyer or manager must perform.',
      120000,
    ),
    _BusinessField(
      'maintenanceCapex',
      'Annual maintenance capital',
      'Recurring equipment and technology investment required to sustain earnings.',
      35000,
    ),
    _BusinessField(
      'inventoryIncluded',
      'Inventory purchased separately',
      'Inventory paid for in addition to the asking price.',
      50000,
    ),
    _BusinessField(
      'workingCapitalIncluded',
      'Working capital included',
      'Cash, receivables and current assets transferred at closing.',
      60000,
    ),
    _BusinessField(
      'requiredWorkingCapital',
      'Required working capital',
      'Minimum capital needed to operate safely after closing.',
      150000,
    ),
    _BusinessField(
      'transactionCosts',
      'Legal, accounting and transaction costs',
      'Professional fees, lender fees and closing expenses.',
      70000,
    ),
    _BusinessField(
      'debtPercent',
      'Debt financing (%)',
      'Percentage of total acquisition cost financed with debt.',
      65,
      percent: true,
    ),
    _BusinessField(
      'interestRate',
      'Interest rate (%)',
      'Modeled annual acquisition-loan interest rate.',
      8,
      percent: true,
    ),
    _BusinessField(
      'amortizationYears',
      'Amortization (years)',
      'Years over which acquisition debt is repaid.',
      7,
    ),
    _BusinessField(
      'revenueGrowth',
      'Annual revenue growth (%)',
      'Recent normalized annual growth; use a negative number for decline.',
      3,
      percent: true,
    ),
    _BusinessField(
      'topCustomerPercent',
      'Largest customer (% of revenue)',
      'Revenue concentration attributable to the largest customer.',
      18,
      percent: true,
    ),
    _BusinessField(
      'ownerDependence',
      'Owner dependence (%)',
      'Estimated share of relationships, sales or operations dependent on the seller.',
      55,
      percent: true,
    ),
    _BusinessField(
      'leaseYearsRemaining',
      'Lease years remaining',
      'Remaining committed term for critical premises.',
      4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final definition in _definitions) {
      _fields[definition.key] = TextEditingController(
        text: definition.example.toStringAsFixed(
          definition.example == definition.example.roundToDouble() ? 0 : 1,
        ),
      );
    }
    for (final key in [
      'threeYearRevenueProvided',
      'taxReturnsReviewed',
      'bankStatementsReviewed',
      'customerListReviewed',
    ]) {
      _fields[key] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    _industry.dispose();
    _location.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(String key) =>
      double.tryParse(
        _fields[key]?.text.replaceAll(',', '').replaceAll(r'$', '').trim() ??
            '',
      ) ??
      0;

  Future<void> _goBack() async {
    if (await Navigator.of(context).maybePop()) return;
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LandingScreen()),
    );
  }

  void _openSide(PlatformSide side) {
    if (side == PlatformSide.business) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PlatformHubPage(side: PlatformSide.property),
      ),
    );
  }

  void _openNetwork() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LocalNetworkPage(
        side: PlatformSide.business,
        initialCity: MarketplaceService.inferCity(_location.text),
      ),
    ),
  );

  BusinessInputs get _inputs => BusinessInputs(
    businessName: _businessName.text,
    industry: _industry.text,
    location: _location.text,
    values: {
      for (final entry in _fields.entries) entry.key: _number(entry.key),
    },
  );

  void _analyze() {
    if (_number('askingPrice') <= 0 || _number('revenue') <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an asking price and annual revenue.'),
        ),
      );
      return;
    }
    setState(() {
      _result = analyzeBusiness(_inputs);
      _assessmentId = null;
    });
  }

  Future<void> _save({bool openRoom = false}) async {
    final result = _result;
    if (result == null) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _saving = true);
    try {
      final id =
          _assessmentId ??
          await BusinessService.saveAssessment(_inputs, result);
      _assessmentId = id;
      if (openRoom) {
        final room = await BusinessService.createAcquisitionRoom(
          assessmentId: id,
          inputs: _inputs,
          result: result,
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => DealRoomPage(room: room)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business assessment saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 52),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _securityBoundary(),
                    const SizedBox(height: 22),
                    _identity(),
                    const SizedBox(height: 22),
                    _financialForm(),
                    const SizedBox(height: 22),
                    _evidenceForm(),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _analyze,
                        style: FilledButton.styleFrom(
                          backgroundColor: _purple,
                          padding: const EdgeInsets.symmetric(vertical: 21),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('RUN INITIAL VIABILITY ASSESSMENT'),
                      ),
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: 42),
                      _results(_result!),
                    ],
                    const SizedBox(height: 54),
                    _processGuide(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    color: _ink,
    padding: const EdgeInsets.fromLTRB(26, 22, 26, 62),
    child: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HomeBrandButton(size: 46),
                  const Spacer(),
                  const AppNavigationMenu(side: PlatformSide.business),
                ],
              ),
              const SizedBox(height: 70),
              const Text(
                'DEALIQ / ACQUISITIONIQ · PLACEHOLDER',
                style: TextStyle(
                  color: _lilac,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Know whether the business\ncan support the buyer.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.sizeOf(context).width < 700 ? 46 : 68,
                  height: .95,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 720,
                child: Text(
                  'Normalize earnings, finance the acquisition, pay a real owner salary, reserve working capital and expose the questions that must be answered before an offer.',
                  style: TextStyle(
                    color: Color(0xFFC5C5D0),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _securityBoundary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF2C879)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFF8A5800)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'CONFIDENTIAL DATA BOUNDARY · Use summarized figures only. Do not upload tax returns, payroll, customer lists, employee records or confidential seller documents. The hardened M&A vault—mandatory MFA, malware scanning, audit logging, watermarks and expiring downloads—is not yet active.',
            style: TextStyle(
              color: Color(0xFF6D4805),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _identity() => _card(
    'Opportunity overview',
    LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: TextField(
                controller: _businessName,
                decoration: const InputDecoration(
                  labelText: 'Business or project name',
                  hintText: 'Use an alias if confidential',
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: TextField(
                controller: _industry,
                decoration: const InputDecoration(labelText: 'Industry'),
              ),
            ),
            SizedBox(
              width: width,
              child: TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'City / province'),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _financialForm() => _card(
    'Financial and operational inputs',
    LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth >= 520
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _definitions
              .map(
                (definition) => SizedBox(
                  width: width,
                  child: TextField(
                    controller: _fields[definition.key],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: definition.label,
                      helperText: definition.help,
                      helperMaxLines: 3,
                      prefixText:
                          definition.percent ||
                              definition.key == 'amortizationYears' ||
                              definition.key == 'leaseYearsRemaining'
                          ? null
                          : r'$ ',
                      suffixText: definition.percent
                          ? '%'
                          : definition.key == 'amortizationYears' ||
                                definition.key == 'leaseYearsRemaining'
                          ? ' years'
                          : null,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );

  Widget _evidenceForm() => _card(
    'Evidence available',
    Column(
      children: [
        _evidence(
          'threeYearRevenueProvided',
          'Three years of financial statements',
        ),
        _evidence('taxReturnsReviewed', 'Corporate tax returns'),
        _evidence(
          'bankStatementsReviewed',
          'Bank statements reconciled to revenue',
        ),
        _evidence('customerListReviewed', 'Customer concentration schedule'),
      ],
    ),
  );

  Widget _evidence(String key, String label) => CheckboxListTile(
    value: _number(key) == 1,
    onChanged: (value) =>
        setState(() => _fields[key]!.text = value == true ? '1' : '0'),
    title: Text(label),
    contentPadding: EdgeInsets.zero,
    activeColor: _purple,
    controlAffinity: ListTileControlAffinity.leading,
  );

  Widget _results(BusinessResult result) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INITIAL ACQUISITION SCREEN',
              style: TextStyle(
                color: _lilac,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.verdict,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 31,
                height: 1.08,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _darkMetric(
                  'VIABILITY',
                  '${result.viabilityScore.round()}/100',
                ),
                _darkMetric('RISK', '${result.riskScore.round()}/100'),
                _darkMetric('DATA', '${result.dataCompleteness.round()}%'),
                _darkMetric('DSCR', '${result.dscr.toStringAsFixed(2)}×'),
                _darkMetric(
                  'PRICE / EBITDA',
                  '${result.priceToEbitda.toStringAsFixed(2)}×',
                ),
                _darkMetric(
                  'CASH AFTER OWNER',
                  _money(result.cashAfterOwnerSalary),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 820;
          final warnings = _findingCard(
            'Material concerns',
            result.flags,
            _red,
            Icons.warning_amber_rounded,
          );
          final evidence = _findingCard(
            'Evidence still needed',
            result.missingEvidence,
            _purple,
            Icons.fact_check_outlined,
          );
          return desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: warnings),
                    const SizedBox(width: 18),
                    Expanded(child: evidence),
                  ],
                )
              : Column(
                  children: [warnings, const SizedBox(height: 18), evidence],
                );
        },
      ),
      if (result.strengths.isNotEmpty) ...[
        const SizedBox(height: 18),
        _findingCard(
          'Positive signals',
          result.strengths,
          _green,
          Icons.check_circle_outline,
        ),
      ],
      const SizedBox(height: 18),
      _scenarioTable(result),
      const SizedBox(height: 18),
      _card(
        'Core acquisition economics',
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _lightMetric('Normalized EBITDA', _money(result.normalizedEbitda)),
            _lightMetric(
              'Owner earnings',
              _money(result.normalizedOwnerEarnings),
            ),
            _lightMetric(
              'Total acquisition cost',
              _money(result.totalAcquisitionCost),
            ),
            _lightMetric('Buyer equity required', _money(result.buyerEquity)),
            _lightMetric(
              'Annual debt service',
              _money(result.annualDebtService),
            ),
            _lightMetric('Break-even revenue', _money(result.breakEvenRevenue)),
            _lightMetric(
              'Payback',
              result.paybackYears >= 99
                  ? 'Not achieved'
                  : '${result.paybackYears.toStringAsFixed(1)} years',
            ),
            _lightMetric(
              'Return on equity',
              '${result.roic.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(),
            icon: const Icon(Icons.save_outlined),
            label: const Text('SAVE ASSESSMENT'),
          ),
          OutlinedButton.icon(
            onPressed: _saving ? null : () => _save(openRoom: true),
            icon: const Icon(Icons.meeting_room_outlined),
            label: const Text('CREATE ACQUISITION WORKSPACE'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Educational screening only. This is not a formal valuation, quality-of-earnings report, legal opinion, tax advice or financing commitment.',
        style: TextStyle(color: Color(0xFF777785), fontSize: 11),
      ),
    ],
  );

  Widget _scenarioTable(BusinessResult result) => _card(
    'Revenue sensitivity',
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Scenario')),
          DataColumn(label: Text('Revenue')),
          DataColumn(label: Text('Cash after owner')),
          DataColumn(label: Text('DSCR')),
          DataColumn(label: Text('Payback')),
        ],
        rows: result.scenarios
            .map(
              (scenario) => DataRow(
                cells: [
                  DataCell(Text(scenario.name)),
                  DataCell(Text(_money(scenario.revenue))),
                  DataCell(Text(_money(scenario.cashAfterOwner))),
                  DataCell(Text('${scenario.dscr.toStringAsFixed(2)}×')),
                  DataCell(
                    Text(
                      scenario.paybackYears >= 99
                          ? 'N/A'
                          : '${scenario.paybackYears.toStringAsFixed(1)} yrs',
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _processGuide() {
    const steps = [
      (
        '01',
        'Buyer criteria',
        'Define industry, geography, size, skills, capital and risk tolerance.',
      ),
      (
        '02',
        'Confidentiality',
        'Use an NDA and controlled information sharing before receiving seller records.',
      ),
      (
        '03',
        'Initial screening',
        'Normalize earnings, test price, debt, salary, working capital and downside.',
      ),
      (
        '04',
        'Seller meeting',
        'Understand operations, owner role, customers, suppliers and reason for sale.',
      ),
      (
        '05',
        'Letter of intent',
        'Set price, structure, exclusivity, conditions and diligence access.',
      ),
      (
        '06',
        'Financial diligence',
        'Reconcile statements, tax returns, bank activity, add-backs and working capital.',
      ),
      (
        '07',
        'Commercial diligence',
        'Validate customers, market, competition, pricing and supplier dependencies.',
      ),
      (
        '08',
        'Legal and people',
        'Review corporate records, contracts, employment, disputes, licences and compliance.',
      ),
      (
        '09',
        'Technology and cyber',
        'Assess systems, data protection, intellectual property and operational resilience.',
      ),
      (
        '10',
        'Financing and tax',
        'Confirm lending, buyer equity, tax structure and post-closing liquidity.',
      ),
      (
        '11',
        'Definitive agreement',
        'Negotiate representations, indemnities, adjustments and closing conditions.',
      ),
      (
        '12',
        'Transition',
        'Plan communication, knowledge transfer, leadership and the first 100 days.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The acquisition path',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'A guided map of what happens, why it matters and who should help.',
          style: TextStyle(color: Color(0xFF666674)),
        ),
        const SizedBox(height: 18),
        ...steps.map(
          (step) => ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 5,
            ),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Text(
              step.$1,
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.w900,
              ),
            ),
            title: Text(
              step.$2,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(62, 0, 22, 18),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(step.$3, style: const TextStyle(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _findingCard(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Text(
            'Nothing material identified from the information entered.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E2E8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 17),
        child,
      ],
    ),
  );

  Widget _darkMetric(String label, String value) => Container(
    width: 170,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: _lilac,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _lightMetric(String label, String value) => Container(
    width: 205,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF666674), fontSize: 9),
        ),
      ],
    ),
  );

  String _money(double value) =>
      NumberFormat.simpleCurrency(name: 'CAD', decimalDigits: 0).format(value);
}

class _BusinessField {
  const _BusinessField(
    this.key,
    this.label,
    this.help,
    this.example, {
    this.percent = false,
  });
  final String key;
  final String label;
  final String help;
  final double example;
  final bool percent;
}
