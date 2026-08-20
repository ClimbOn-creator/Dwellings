import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/business_model.dart';
import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/business_service.dart';
import '../services/marketplace_service.dart';
import '../services/account_service.dart';
import '../services/device_location_service.dart';
import '../services/site_content_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/canadian_city_field.dart';
import '../widgets/topo_background.dart';
import '../widgets/acquisition_editorial_header.dart';
import '../widgets/membership_footer.dart';
import '../widgets/fixed_editorial_background.dart';
import 'acquisition_support_page.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'platform_hub_page.dart';
import 'landing_screen.dart';
import 'local_network_page.dart';

const _ink = Color(0xFF171717);
const _paper = Color(0xFFF4F1EB);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);
const _purple = Color(0xFF252525);
const _lilac = Color(0xFF9B9B98);
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
  MarketplaceCity _selectedCity = MarketplaceService.cities.first;
  final Map<String, TextEditingController> _fields = {};
  BusinessResult? _result;
  bool _saving = false;
  bool _locating = false;
  String? _assessmentId;
  int _inputStage = 0;

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
      _fields[definition.key] = TextEditingController();
    }
    for (final key in [
      'threeYearRevenueProvided',
      'taxReturnsReviewed',
      'bankStatementsReviewed',
      'customerListReviewed',
    ]) {
      _fields[key] = TextEditingController(text: '0');
    }
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final foundation = await AcquisitionFoundation.load();
    final draft = foundation.dealScreen;
    if (draft.isEmpty || !mounted) return;
    _businessName.text = '${draft['businessName'] ?? ''}';
    _industry.text = '${draft['industry'] ?? ''}';
    _location.text = '${draft['location'] ?? ''}';
    final values = draft['values'];
    if (values is Map) {
      for (final entry in values.entries) {
        final controller = _fields['${entry.key}'];
        if (controller != null) controller.text = '${entry.value}';
      }
    }
    setState(() {});
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
        initialCity: _selectedCity,
      ),
    ),
  );

  void _selectCity(MarketplaceCity city) {
    setState(() {
      _selectedCity = city;
      _location.text = city.city;
    });
    AccountService.savePreferredLocation(city);
  }

  void _goStep(int step) {
    if (step == 2) return;
    final page = switch (step) {
      0 => const AcquisitionBlueprintPage(),
      1 => const BuyerReadinessPage(),
      _ => const DealRoomsPage(initialSide: PlatformSide.business),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _useDeviceLocation() async {
    setState(() => _locating = true);
    try {
      final located = await DeviceLocationService.locateCanadianCity();
      if (!mounted) return;
      _selectCity(located.city);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matched to ${located.city.label}.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

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
    final foundation = await AcquisitionFoundation.load();
    foundation.dealScreen
      ..clear()
      ..addAll(_inputs.toJson());
    await foundation.save();
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _saving = true);
    try {
      await foundation.saveForAccount('deal_screen');
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
          const SnackBar(content: Text('Step 3 saved to your profile.')),
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
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: const ColorScheme.light(
          primary: _purple,
          surface: _surface,
        ),
        textTheme: base.textTheme.apply(bodyColor: _ink, displayColor: _ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF85817A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF244E43), width: 2),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(
          toolbarHeight: 78,
          backgroundColor: const Color(0xFFF7F5F0),
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          title: const HomeBrandButton(size: 58, dark: false),
          actions: const [
            AppNavigationMenu(side: PlatformSide.business, dark: false),
            SizedBox(width: 12),
          ],
        ),
        body: FixedEditorialBackground(
          imagePath: 'assets/images/affinity-deal-screen.jpg',
          wash: _paper,
          washOpacity: .32,
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 90),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AcquisitionEditorialHeader(
                            currentStep: 2,
                            onSelected: _goStep,
                            kicker: 'PAGE 3 OF 4 · DEAL SCREEN',
                            title: SiteContentService.text(
                              'screen.title',
                              'Initial Deal Screen',
                            ),
                            subtitle: SiteContentService.text(
                              'screen.subtitle',
                              'Test whether a specific business fits your Blueprint and whether its cash flow can support you.',
                            ),
                            accent: Color(0xFF805A35),
                          ),
                          const SizedBox(height: 42),
                          _securityBoundary(),
                          const SizedBox(height: 18),
                          _dealCommandBar(),
                          const SizedBox(height: 22),
                          _identity(),
                          const SizedBox(height: 22),
                          _financialForm(),
                          if (_inputStage == 3) ...[
                            const SizedBox(height: 22),
                            _evidenceForm(),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _analyze,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 21,
                                  ),
                                ),
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text(
                                  'RUN INITIAL VIABILITY ASSESSMENT',
                                ),
                              ),
                            ),
                          ],
                          if (_result != null) ...[
                            const SizedBox(height: 42),
                            _results(_result!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const MembershipFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() => TopoBackground(
    color: _ink,
    opacity: .06,
    child: Padding(
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
    ),
  );

  Widget _dealCommandBar() => TopoCard(
    color: Colors.white,
    padding: const EdgeInsets.all(18),
    borderRadius: BorderRadius.zero,
    child: const Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _DealStatus(
          icon: Icons.radar_rounded,
          label: 'VIABILITY ENGINE ACTIVE',
        ),
        _DealStatus(icon: Icons.payments_outlined, label: 'OWNER PAY TEST'),
        _DealStatus(icon: Icons.shield_outlined, label: 'DOWNSIDE SCREEN'),
        _DealStatus(icon: Icons.groups_outlined, label: 'ADVISER READY'),
      ],
    ),
  );

  Widget _securityBoundary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      border: const Border(
        left: BorderSide(color: Color(0xFF805A35), width: 6),
        bottom: BorderSide(color: Color(0xFFF2C879)),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFF8A5800)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            SiteContentService.text(
              'screen.privacy',
              'CONFIDENTIAL DATA BOUNDARY · Use summarized figures only. Do not upload tax returns, payroll, customer lists, employee records or confidential seller documents.',
            ),
            style: const TextStyle(
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
              child: _plainInput(
                'Business or project name',
                _businessName,
                'Use an alias if confidential',
              ),
            ),
            SizedBox(
              width: width,
              child: _plainInput('Industry', _industry, 'e.g. HVAC services'),
            ),
            SizedBox(
              width: width,
              child: CanadianCityField(
                controller: _location,
                label: 'Canadian city or community',
                onSelected: _selectCity,
              ),
            ),
            SizedBox(
              width: width,
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useDeviceLocation,
                icon: Icon(
                  _locating ? Icons.radar_rounded : Icons.my_location_rounded,
                ),
                label: Text(_locating ? 'LOCATING…' : 'USE MY LOCATION'),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _plainInput(
    String label,
    TextEditingController controller,
    String hint,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );

  Widget _financialForm() {
    const titles = [
      'Price and headline performance',
      'Normalizing owner earnings',
      'Closing capital and financing',
      'Operating risk signals',
    ];
    final start = _inputStage * 6;
    final visible = _definitions.skip(start).take(6).toList();
    return _card(
      titles[_inputStage],
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCIAL MOMENT ${_inputStage + 1} OF 4',
            style: const TextStyle(
              color: _lilac,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SiteContentService.text(
              'screen.form_help',
              'Use only the figures you have. Blank fields remain unknown and become questions for diligence.',
            ),
            style: const TextStyle(color: Color(0xFFA5A5B5), height: 1.45),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth >= 520
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: visible
                    .map((definition) => _businessInput(definition, width))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              if (_inputStage > 0)
                TextButton.icon(
                  onPressed: () => setState(() => _inputStage--),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              const Spacer(),
              if (_inputStage < 3)
                FilledButton.icon(
                  onPressed: () => setState(() => _inputStage++),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('NEXT FINANCIAL MOMENT'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _businessInput(_BusinessField definition, double width) {
    final years =
        definition.key == 'amortizationYears' ||
        definition.key == 'leaseYearsRemaining';
    final unit = definition.percent
        ? '%'
        : years
        ? 'YEARS'
        : r'$ CAD';
    final example = definition.example.toStringAsFixed(
      definition.example == definition.example.roundToDouble() ? 0 : 1,
    );
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  definition.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            definition.help,
            style: const TextStyle(
              color: Color(0xFFA5A5B5),
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fields[definition.key],
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              hintText: 'Enter value · example $example',
              prefixText: definition.percent || years ? null : r'$ ',
              suffixText: definition.percent
                  ? '%'
                  : years
                  ? ' years'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

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
      TopoCard(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        borderRadius: BorderRadius.circular(22),
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

  Widget _findingCard(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _surface,
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
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
    decoration: const BoxDecoration(
      color: _surface,
      border: Border(
        top: BorderSide(color: Color(0xFF244E43), width: 5),
        bottom: BorderSide(color: _line),
      ),
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
      color: const Color(0xFF1A1A2E),
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
          style: const TextStyle(color: Color(0xFFA5A5B5), fontSize: 9),
        ),
      ],
    ),
  );

  String _money(double value) =>
      NumberFormat.simpleCurrency(name: 'CAD', decimalDigits: 0).format(value);
}

class _DealStatus extends StatelessWidget {
  const _DealStatus({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _lilac, size: 17),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .85,
        ),
      ),
    ],
  );
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
