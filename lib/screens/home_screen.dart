import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/housing_model.dart';
import '../services/backend_service.dart';

const _ink = Color(0xFF090909);
const _green = Color(0xFF6D28D9);
const _lime = Color(0xFFD6A94B);
const _paper = Color(0xFFF7F7F7);
const _card = Color(0xFFFFFFFF);
const _muted = Color(0xFF666666);
const _line = Color(0xFFDADADA);
const _risk = Color(0xFFD92D20);
const _success = Color(0xFF16825D);
const _copper = Color(0xFF5B21B6);
const _monochrome = ColorFilter.matrix(<double>[
  .33,
  .33,
  .33,
  0,
  0,
  .33,
  .33,
  .33,
  0,
  0,
  .33,
  .33,
  .33,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  DecisionMode _mode = DecisionMode.invest;
  PropertyType _propertyType = PropertyType.multifamily;
  MarketProfile _profile = marketProfiles.first;
  AnalysisResult? _result;
  bool _scanning = false;
  bool _saved = false;
  final _address = TextEditingController(text: 'Kitsilano, Vancouver, BC');
  final Map<String, TextEditingController> _fields = {
    'price': TextEditingController(text: '1200000'),
    'closingCosts': TextEditingController(text: '30000'),
    'improvements': TextEditingController(text: '50000'),
    'area': TextEditingController(text: '6200'),
    'lot': TextEditingController(text: '6500'),
    'units': TextEditingController(text: '6'),
    'yearBuilt': TextEditingController(text: '1988'),
    'buildable': TextEditingController(text: '9000'),
    'annualRent': TextEditingController(text: '180000'),
    'otherIncome': TextEditingController(text: '6000'),
    'vacancy': TextEditingController(text: '4'),
    'propertyTax': TextEditingController(text: '12500'),
    'insurance': TextEditingController(text: '5200'),
    'utilities': TextEditingController(text: '7200'),
    'maintenance': TextEditingController(text: '12000'),
    'management': TextEditingController(text: '5'),
    'reserves': TextEditingController(text: '9000'),
    'otherExpenses': TextEditingController(text: '4500'),
    'downPayment': TextEditingController(text: '30'),
    'interestRate': TextEditingController(text: '4.5'),
    'amortization': TextEditingController(text: '25'),
    'loanTerm': TextEditingController(text: '5'),
    'interestOnly': TextEditingController(text: '0'),
    'holdingPeriod': TextEditingController(text: '7'),
    'exitCap': TextEditingController(text: '5.5'),
    'sellingCosts': TextEditingController(text: '4'),
    'rentGrowth': TextEditingController(text: '3'),
    'expenseGrowth': TextEditingController(text: '2.5'),
    'appreciation': TextEditingController(text: '3.9'),
    'discountRate': TextEditingController(text: '8'),
    'householdIncome': TextEditingController(text: '180000'),
    'monthlyDebt': TextEditingController(text: '500'),
    'walt': TextEditingController(text: '4'),
    'leaseRollover': TextEditingController(text: '20'),
    'tenantConcentration': TextEditingController(text: '25'),
    'conditionRisk': TextEditingController(text: '24'),
    'environmentRisk': TextEditingController(text: '18'),
    'redevelopment': TextEditingController(text: '58'),
    'scarcity': TextEditingController(text: '64'),
    'daysOnMarket': TextEditingController(text: '35'),
  };

  double _number(String key) =>
      double.tryParse(_fields[key]?.text.replaceAll(',', '') ?? '') ?? 0;

  PropertyInputs get _inputs => PropertyInputs(
    address: _address.text.trim().isEmpty
        ? 'Untitled property'
        : _address.text.trim(),
    propertyType: _propertyType,
    profile: _profile,
    values: {
      for (final entry in _fields.entries) entry.key: _number(entry.key),
    },
  );

  @override
  void dispose() {
    _scroll.dispose();
    _address.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _scanLocation() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _profile = profileForAddress(_address.text);
      _fields['interestRate']!.text = (_profile.mortgage * 100).toStringAsFixed(
        2,
      );
      _fields['appreciation']!.text = (_profile.appreciation * 100)
          .toStringAsFixed(1);
      _scanning = false;
    });
  }

  void _analyze() {
    if (_number('price') <= 0 || _number('area') <= 0) {
      _message(
        'Add a purchase price and property area before running the model.',
      );
      return;
    }
    setState(() {
      _result = analyzeProperty(_inputs, _mode);
      _saved = false;
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    try {
      final cloud = await BackendService.saveAnalysis(_inputs, result, _mode);
      if (!mounted) return;
      setState(() => _saved = true);
      _message(
        cloud
            ? 'Analysis saved to your DwellingsIQ account.'
            : 'Analysis saved on this device.',
      );
    } catch (error) {
      _message('Could not save: $error');
    }
  }

  Future<void> _account() async {
    if (!BackendService.configured) {
      _message(
        'Demo mode is active. Connect Supabase to enable accounts and cloud history.',
      );
      return;
    }
    if (BackendService.user != null) {
      await BackendService.signOut();
      if (mounted) setState(() {});
      return;
    }
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in to DwellingsIQ'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send secure link'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    await BackendService.sendMagicLink(email);
    _message('Check your email for the secure sign-in link.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _ink.withValues(alpha: .97),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 26,
              title: const _Brand(),
              actions: [
                TextButton(
                  onPressed: _account,
                  child: Text(
                    BackendService.user?.email ??
                        (BackendService.configured ? 'SIGN IN' : 'DEMO MODE'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
            SliverToBoxAdapter(child: _hero()),
            const SliverToBoxAdapter(child: _SignalStrip()),
            const SliverToBoxAdapter(child: _FuturistManifesto()),
            SliverToBoxAdapter(child: _workspace()),
            SliverToBoxAdapter(
              child: _EditorialSection(
                controller: _scroll,
                image: 'assets/images/commercial-atrium.jpg',
                kicker: 'COMMERCIAL INTELLIGENCE',
                title: 'Underwrite the income.\nInterrogate the lease.',
                body:
                    'From rent roll durability and tenant concentration to debt yield, break-even occupancy, rollover exposure and exit-cap sensitivity—the model turns operating assumptions into an auditable investment case.',
                dark: true,
              ),
            ),
            SliverToBoxAdapter(
              child: _EditorialSection(
                controller: _scroll,
                image: 'assets/images/residential-courtyard.jpg',
                kicker: 'RESIDENTIAL CLARITY',
                title:
                    'A home is a life decision\nand a balance-sheet decision.',
                body:
                    'See monthly ownership cost, debt-to-income pressure, location fundamentals, physical risk, resale liquidity and long-term value without pretending a forecast is a guarantee.',
                reverse: true,
              ),
            ),
            const SliverToBoxAdapter(child: _Methodology()),
          ],
        ),
      ),
    );
  }

  Widget _hero() => AnimatedBuilder(
    animation: _scroll,
    builder: (context, _) {
      final offset = _scroll.hasClients
          ? _scroll.offset.clamp(0, 700).toDouble()
          : 0.0;
      return SizedBox(
        height: MediaQuery.sizeOf(context).width < 700 ? 650 : 720,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Transform.translate(
                offset: Offset(0, offset * .045),
                child: Transform.scale(
                  scale: 1.025,
                  child: ColorFiltered(
                    colorFilter: _monochrome,
                    child: Image.asset(
                      'assets/images/hero-city.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF2090909),
                    Color(0xB0090909),
                    Color(0x333B1678),
                  ],
                  stops: [0, .47, 1],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('PROPERTY UNDERWRITING, REBUILT'),
                          const SizedBox(height: 22),
                          Text(
                            'THE PROPERTY.\nTHE NUMBERS.\nTHE TRUTH.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.sizeOf(context).width < 700
                                  ? 47
                                  : 76,
                              height: .88,
                              letterSpacing: -4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'A complete decision engine for residential and commercial real estate—built to expose the assumptions behind every return.',
                            style: TextStyle(
                              color: Color(0xFFE4E4E4),
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 34),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              'NOI',
                              'DSCR',
                              'IRR',
                              'DEBT YIELD',
                              'EXIT STRESS',
                            ].map((label) => _HeroChip(label)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 28,
              bottom: 26,
              child: Text(
                'SCROLL TO UNDERWRITE  ↓',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (MediaQuery.sizeOf(context).width >= 920)
              const Positioned(right: 34, top: 80, child: _HeroSystemCard()),
          ],
        ),
      );
    },
  );

  Widget _workspace() => Container(
    color: _ink,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Kicker('THE ANALYSIS ENGINE'),
              const SizedBox(height: 12),
              const Text(
                'Put every assumption on the table.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start with the essentials. Open the deeper sections when you have inspection, rent-roll, lease or financing data.',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
              ),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 980;
                  return desktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 10, child: _inputPanel()),
                            const SizedBox(width: 20),
                            Expanded(flex: 11, child: _resultPanel()),
                          ],
                        )
                      : Column(
                          children: [
                            _inputPanel(),
                            const SizedBox(height: 20),
                            _resultPanel(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _inputPanel() => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('01  ·  STRATEGY', style: _eyebrow),
        const SizedBox(height: 8),
        const Text(
          'What are you evaluating?',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                active: _mode == DecisionMode.home,
                icon: Icons.home_work_outlined,
                label: 'LIVE IN IT',
                onTap: () => setState(() {
                  _mode = DecisionMode.home;
                  if (!_propertyType.isResidential)
                    _propertyType = PropertyType.singleFamily;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeButton(
                active: _mode == DecisionMode.invest,
                icon: Icons.query_stats,
                label: 'INVEST IN IT',
                onTap: () => setState(() => _mode = DecisionMode.invest),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<PropertyType>(
          initialValue: _propertyType,
          decoration: const InputDecoration(labelText: 'Asset class'),
          items: PropertyType.values
              .where(
                (type) => _mode == DecisionMode.invest || type.isResidential,
              )
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) =>
              value == null ? null : setState(() => _propertyType = value),
        ),
        const SizedBox(height: 28),
        const Text('02  ·  LOCATION', style: _eyebrow),
        const SizedBox(height: 10),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: 'Address or neighbourhood',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(6),
              child: FilledButton(
                onPressed: _scanning ? null : _scanLocation,
                child: Text(_scanning ? 'Scanning…' : 'Scan'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _LocationStrip(profile: _profile),
        const SizedBox(height: 20),
        _InputSection(
          title: 'ACQUISITION & PHYSICAL',
          subtitle: 'Basis, size, condition and development potential',
          initiallyExpanded: true,
          children: _fieldGrid([
            _Spec('price', 'Purchase price', '\$'),
            _Spec('closingCosts', 'Closing costs', '\$'),
            _Spec('improvements', 'Immediate improvements', '\$'),
            _Spec('area', 'Rentable / finished area', 'sq ft'),
            _Spec('lot', 'Lot area', 'sq ft'),
            _Spec('units', 'Units / keys', ''),
            _Spec('yearBuilt', 'Year built', ''),
            _Spec('buildable', 'Buildable floor area', 'sq ft'),
          ]),
        ),
        _InputSection(
          title: 'INCOME & OPERATIONS',
          subtitle: 'Revenue leakage and every recurring operating cost',
          initiallyExpanded: true,
          children: _fieldGrid([
            _Spec('annualRent', 'Annual base rent / income', '\$'),
            _Spec('otherIncome', 'Other annual income', '\$'),
            _Spec('vacancy', 'Vacancy & credit loss', '%'),
            _Spec('propertyTax', 'Property tax', '\$/yr'),
            _Spec('insurance', 'Insurance', '\$/yr'),
            _Spec('utilities', 'Owner-paid utilities', '\$/yr'),
            _Spec('maintenance', 'Repairs & maintenance', '\$/yr'),
            _Spec('management', 'Management fee', '% EGI'),
            _Spec('reserves', 'Replacement reserves', '\$/yr'),
            _Spec('otherExpenses', 'Other operating expenses', '\$/yr'),
          ]),
        ),
        _InputSection(
          title: 'CAPITAL STACK & EXIT',
          subtitle: 'Debt terms, growth, hold and terminal valuation',
          children: _fieldGrid([
            _Spec('downPayment', 'Equity / down payment', '%'),
            _Spec('interestRate', 'Interest rate', '%'),
            _Spec('amortization', 'Amortization', 'years'),
            _Spec('loanTerm', 'Loan term', 'years'),
            _Spec('interestOnly', 'Interest-only period', 'years'),
            _Spec('holdingPeriod', 'Holding period', 'years'),
            _Spec('exitCap', 'Exit capitalization rate', '%'),
            _Spec('sellingCosts', 'Selling costs', '%'),
            _Spec('rentGrowth', 'Annual income growth', '%'),
            _Spec('expenseGrowth', 'Annual expense growth', '%'),
            _Spec('appreciation', 'Home appreciation', '%'),
            _Spec('discountRate', 'Required return / discount rate', '%'),
          ]),
        ),
        if (_mode == DecisionMode.home)
          _InputSection(
            title: 'HOUSEHOLD AFFORDABILITY',
            subtitle: 'Income and obligations for the live-in decision',
            children: _fieldGrid([
              _Spec('householdIncome', 'Gross household income', '\$/yr'),
              _Spec('monthlyDebt', 'Other monthly debt payments', '\$/mo'),
            ]),
          ),
        _InputSection(
          title: 'LEASE, SITE & RISK',
          subtitle: 'Rollover, concentration, liquidity and physical exposure',
          children: _fieldGrid([
            _Spec('walt', 'Weighted average lease term', 'years'),
            _Spec('leaseRollover', 'Income rolling during hold', '%'),
            _Spec('tenantConcentration', 'Largest tenant / payer share', '%'),
            _Spec('daysOnMarket', 'Expected sale liquidity', 'days'),
            _Spec('conditionRisk', 'Condition / capex risk', '0–100'),
            _Spec('environmentRisk', 'Site environmental risk', '0–100'),
            _Spec('redevelopment', 'Redevelopment feasibility', '0–100'),
            _Spec('scarcity', 'Comparable scarcity', '0–100'),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: _analyze,
            style: FilledButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: _ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            icon: const Icon(Icons.arrow_outward),
            label: const Text(
              'RUN INSTITUTIONAL ANALYSIS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _fieldGrid(List<_Spec> specs) => [
    LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 520
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: specs
              .map(
                (spec) => SizedBox(
                  width: width,
                  child: TextField(
                    controller: _fields[spec.key],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: spec.label,
                      suffixText: spec.suffix,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  ];

  Widget _resultPanel() {
    final result = _result;
    if (result == null) {
      return _Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: ColorFiltered(
                  colorFilter: _monochrome,
                  child: Image.asset(
                    'assets/images/residential-courtyard.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(34),
              child: Column(
                children: [
                  Text(
                    'YOUR INVESTMENT MEMO STARTS HERE',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Enter the facts you know. The model will calculate returns, expose missing evidence and stress the assumptions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final strong = result.net >= 55;
    final cautious = result.net < 42;
    final verdict = strong
        ? 'INVESTMENT CASE HOLDS'
        : cautious
        ? 'DOWNSIDE NEEDS WORK'
        : 'MERITS DILIGENCE';
    final verdictColor = strong
        ? _success
        : cautious
        ? const Color(0xFFFFA98F)
        : const Color(0xFFFFD66B);
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verdict,
                            style: TextStyle(
                              color: verdictColor,
                              fontSize: 11,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            _inputs.address,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_propertyType.label} · ${_profile.city}, ${_profile.region}',
                            style: const TextStyle(
                              color: Color(0xFFB7B7B7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Score(result.net),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '${(result.probability * 100).round()}% modelled probability of outperforming the local benchmark. ${(result.dataCompleteness * 100).round()}% of core underwriting fields are populated.',
                  style: const TextStyle(
                    color: Color(0xFFD6D6D6),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _save,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF777777)),
                  ),
                  icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(_saved ? 'SAVED' : 'SAVE ANALYSIS'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CORE RETURNS & CREDIT', style: _eyebrow),
                const SizedBox(height: 12),
                _Metrics(result: result, mode: _mode),
                const SizedBox(height: 26),
                const Text('THREE-CASE STRESS TEST', style: _eyebrow),
                const SizedBox(height: 10),
                _ScenarioTable(scenarios: result.scenarios),
                const SizedBox(height: 26),
                const Text('UNDERWRITING FLAGS', style: _eyebrow),
                const SizedBox(height: 10),
                ...result.flags.map((flag) => _Flag(flag)),
                const SizedBox(height: 24),
                const Text('BIGGEST SCORE DRIVERS', style: _eyebrow),
                const SizedBox(height: 8),
                ...result.drivers.take(7).map((driver) => _Driver(driver)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  color: const Color(0xFFF1EFF7),
                  child: const Text(
                    'Decision support—not an appraisal, lending commitment, tax opinion or guarantee. Validate rent roll, leases, title, zoning, environmental condition, inspection, taxes, insurance and financing with qualified professionals.',
                    style: TextStyle(color: _muted, fontSize: 10, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _eyebrow = TextStyle(
  color: _muted,
  fontSize: 10,
  letterSpacing: 1.35,
  fontWeight: FontWeight.w900,
);

class _Spec {
  const _Spec(this.key, this.label, this.suffix);
  final String key;
  final String label;
  final String suffix;
}

class _HeroSystemCard extends StatelessWidget {
  const _HeroSystemCard();
  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .62),
      border: Border.all(color: Colors.white38),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: _success),
            SizedBox(width: 8),
            Text(
              'DWELLINGS IQ / LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Text(
          '40+',
          style: TextStyle(
            color: _lime,
            fontSize: 38,
            height: .9,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'CONNECTED ASSUMPTIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'Residential + commercial\nThree-case stress engine',
          style: TextStyle(
            color: Color(0xFFBEBEBE),
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _SignalStrip extends StatelessWidget {
  const _SignalStrip();
  @override
  Widget build(BuildContext context) {
    const cells = [
      _SignalCell('01', 'ADDRESS', '→', 'MARKET', _ink, Colors.white),
      _SignalCell('02', 'INCOME', '→', 'NOI', _green, Colors.white),
      _SignalCell('03', 'DEBT', '→', 'DSCR', _lime, _ink),
      _SignalCell('04', 'EXIT', '→', 'IRR', Colors.white, _ink),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SizedBox(
            height: 82,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: cells
                  .map((cell) => SizedBox(width: 245, child: cell))
                  .toList(),
            ),
          );
        }
        return SizedBox(
          height: 82,
          child: Row(
            children: cells.map((cell) => Expanded(child: cell)).toList(),
          ),
        );
      },
    );
  }
}

class _SignalCell extends StatelessWidget {
  const _SignalCell(
    this.number,
    this.from,
    this.arrow,
    this.to,
    this.background,
    this.foreground,
  );
  final String number;
  final String from;
  final String arrow;
  final String to;
  final Color background;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    color: background,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Row(
      children: [
        Text(
          number,
          style: TextStyle(
            color: foreground.withValues(alpha: .55),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          from,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(arrow, style: TextStyle(color: foreground, fontSize: 18)),
        ),
        Text(
          to,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    ),
  );
}

class _FuturistManifesto extends StatelessWidget {
  const _FuturistManifesto();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            if (narrow) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ONE PROPERTY.',
                      style: TextStyle(
                        fontSize: 48,
                        height: .9,
                        letterSpacing: -2.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'EVERY ANGLE.',
                      style: TextStyle(
                        color: _green,
                        fontSize: 48,
                        height: .9,
                        letterSpacing: -2.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: ColorFiltered(
                        colorFilter: _monochrome,
                        child: Image.asset(
                          'assets/images/commercial-atrium.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'DwellingsIQ connects the place, the income, the debt, the exit and the risk in one visible system.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 650,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 72,
                    child: Text(
                      'ONE PROPERTY.',
                      style: TextStyle(
                        fontSize: 92,
                        height: .9,
                        letterSpacing: -5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 205,
                    child: Text(
                      'EVERY ANGLE.',
                      style: TextStyle(
                        color: _green,
                        fontSize: 92,
                        height: .9,
                        letterSpacing: -5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 338,
                    child: Text(
                      'ZERO BLIND SPOTS.',
                      style: TextStyle(
                        fontSize: 82,
                        height: .9,
                        letterSpacing: -4.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 54,
                    top: 45,
                    child: Container(
                      width: 250,
                      height: 112,
                      decoration: const BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: _ink, width: 5),
                        ),
                      ),
                      child: ColorFiltered(
                        colorFilter: _monochrome,
                        child: Image.asset(
                          'assets/images/commercial-atrium.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 190,
                    top: 185,
                    child: Container(
                      width: 190,
                      height: 88,
                      decoration: const BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: _lime, width: 5),
                        ),
                      ),
                      child: ColorFiltered(
                        colorFilter: _monochrome,
                        child: Image.asset(
                          'assets/images/residential-courtyard.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 4,
                    bottom: 58,
                    child: SizedBox(
                      width: 520,
                      child: Text(
                        'A single system for the physical property, market, income, financing, exit and downside.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 56,
                    child: Container(width: 180, height: 12, color: _lime),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(26)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.zero,
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(color: Color(0x12102218), blurRadius: 0, offset: Offset.zero),
      ],
    ),
    child: child,
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 31,
        height: 31,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _lime),
          child: Icon(Icons.domain, color: _ink, size: 19),
        ),
      ),
      SizedBox(width: 10),
      Text(
        'DWELLINGS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      Text(
        'IQ',
        style: TextStyle(
          color: _lime,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text, {this.darkText = false});
  final String text;
  final bool darkText;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 36, height: 3, color: _lime),
      const SizedBox(width: 12),
      Text(
        text,
        style: TextStyle(
          color: darkText ? _green : _lime,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.7,
        ),
      ),
    ],
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.black26,
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: active ? _ink : const Color(0xFFF7F7F7),
        border: Border.all(color: active ? _ink : _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: active ? _lime : _green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocationStrip extends StatelessWidget {
  const _LocationStrip({required this.profile});
  final MarketProfile profile;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    color: const Color(0xFFF0EBFF),
    child: Row(
      children: [
        const Icon(Icons.radar, color: _green),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.city}, ${profile.region} · DEMO MARKET PROFILE',
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${profile.inventory} months inventory  ·  ${(profile.mortgage * 100).toStringAsFixed(2)}% debt rate  ·  ${profile.transit.round()}/100 transit',
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(border: Border.all(color: _line)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 9),
        ),
        children: children,
      ),
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score(this.score);
  final double score;
  @override
  Widget build(BuildContext context) => Container(
    width: 78,
    height: 78,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _lime, width: 5),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          score.round().toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          '/ 100',
          style: TextStyle(color: Color(0xFF999999), fontSize: 8),
        ),
      ],
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.result, required this.mode});
  final AnalysisResult result;
  final DecisionMode mode;
  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String, String, bool)>[
      ('NOI', _money(result.noi), 'annual', result.noi < 0),
      (
        'CAP RATE',
        _percent(result.capRate),
        'unlevered',
        result.capRate < .035,
      ),
      (
        'DSCR',
        '${result.dscr.toStringAsFixed(2)}×',
        'lender coverage',
        result.dscr < 1.25,
      ),
      (
        'DEBT YIELD',
        _percent(result.debtYield),
        'NOI ÷ debt',
        result.debtYield < .08,
      ),
      (
        'CASH-ON-CASH',
        _percent(result.cashOnCash),
        'year one',
        result.cashOnCash < 0,
      ),
      ('LEVERED IRR', _percent(result.irr), 'base case', result.irr < .08),
      (
        'EQUITY MULTIPLE',
        '${result.equityMultiple.toStringAsFixed(2)}×',
        'total distributions',
        result.equityMultiple < 1,
      ),
      (
        'BREAK-EVEN OCC.',
        _percent(result.breakEvenOccupancy),
        'cost coverage',
        result.breakEvenOccupancy > .85,
      ),
      ('PROJECTED EXIT', _money(result.projectedValue), 'end of hold', false),
      ('NPV', _money(result.npv), 'at required return', result.npv < 0),
      (
        mode == DecisionMode.home ? 'MONTHLY COST' : 'MONTHLY CASH FLOW',
        _money(result.monthlyCarry),
        mode == DecisionMode.home ? 'debt + operations' : 'after debt service',
        result.monthlyCarry < 0,
      ),
      (
        mode == DecisionMode.home ? 'HOUSEHOLD DTI' : 'LOAN-TO-VALUE',
        _percent(mode == DecisionMode.home ? result.dti : result.ltv),
        mode == DecisionMode.home ? 'incl. other debt' : 'acquisition leverage',
        mode == DecisionMode.home ? result.dti > .39 : result.ltv > .75,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 540 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: _line, width: .5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metric.$1,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 8,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      metric.$2,
                      style: TextStyle(
                        color: metric.$4 ? _risk : _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    metric.$3,
                    style: const TextStyle(color: _muted, fontSize: 8),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScenarioTable extends StatelessWidget {
  const _ScenarioTable({required this.scenarios});
  final List<ScenarioResult> scenarios;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: Border.all(color: _line)),
    child: Column(
      children: [
        const _ScenarioRow(['CASE', 'NOI', 'DSCR', 'IRR'], header: true),
        ...scenarios.map(
          (s) => _ScenarioRow([
            s.name.toUpperCase(),
            _money(s.noi),
            '${s.dscr.toStringAsFixed(2)}×',
            _percent(s.irr),
          ], risk: s.name == 'Downside'),
        ),
      ],
    ),
  );
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow(this.values, {this.header = false, this.risk = false});
  final List<String> values;
  final bool header;
  final bool risk;
  @override
  Widget build(BuildContext context) => Container(
    color: header
        ? _ink
        : risk
        ? const Color(0xFFFFF0EA)
        : Colors.transparent,
    child: Row(
      children: values
          .map(
            (value) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: header
                        ? Colors.white
                        : risk
                        ? _risk
                        : _ink,
                    fontSize: header ? 8 : 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _Flag extends StatelessWidget {
  const _Flag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final safe = text.startsWith('No major');
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      color: safe ? const Color(0xFFEAF7F1) : const Color(0xFFFFEFED),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            safe ? Icons.check_circle_outline : Icons.report_gmailerrorred,
            color: safe ? _success : _risk,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Driver extends StatelessWidget {
  const _Driver(this.driver);
  final FactorResult driver;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 25,
          height: 25,
          color: driver.isRisk
              ? const Color(0xFFFFE7DE)
              : const Color(0xFFE0EDD9),
          child: Icon(
            driver.isRisk ? Icons.south_east : Icons.north_east,
            size: 14,
            color: driver.isRisk ? _risk : _green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            driver.name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${driver.impact >= 0 ? '+' : '−'}${driver.impact.abs().toStringAsFixed(1)}',
          style: TextStyle(
            color: driver.isRisk ? _risk : _green,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _EditorialSection extends StatelessWidget {
  const _EditorialSection({
    required this.controller,
    required this.image,
    required this.kicker,
    required this.title,
    required this.body,
    this.reverse = false,
    this.dark = false,
  });
  final ScrollController controller;
  final String image;
  final String kicker;
  final String title;
  final String body;
  final bool reverse;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    color: dark ? _ink : const Color(0xFFF0ECFA),
    padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 780;
            final picture = SizedBox(
              height: narrow ? 420 : 610,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final movement = controller.hasClients
                        ? ((controller.offset % 900) - 450) * .022
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(0, movement),
                      child: SizedBox(
                        height: narrow ? 460 : 650,
                        width: double.infinity,
                        child: ColorFiltered(
                          colorFilter: _monochrome,
                          child: Image.asset(image, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
            final copy = Padding(
              padding: EdgeInsets.all(narrow ? 10 : 58),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: TextStyle(
                      color: dark ? _lime : _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      color: dark ? Colors.white : _ink,
                      fontSize: narrow ? 34 : 48,
                      height: 1.02,
                      letterSpacing: -1.7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    body,
                    style: TextStyle(
                      color: dark ? const Color(0xFFBDBDBD) : _muted,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
            if (narrow)
              return Column(
                children: [picture, const SizedBox(height: 30), copy],
              );
            final children = [
              Expanded(flex: 10, child: picture),
              Expanded(flex: 9, child: copy),
            ];
            return Row(
              children: reverse ? children.reversed.toList() : children,
            );
          },
        ),
      ),
    ),
  );
}

class _Methodology extends StatelessWidget {
  const _Methodology();
  @override
  Widget build(BuildContext context) => Container(
    color: _copper,
    padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EXPLAINABLE BY DESIGN',
              style: TextStyle(
                color: _lime,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'The answer is only as strong\nas the assumptions beneath it.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                height: 1.05,
                letterSpacing: -1.7,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  const _MethodCard(
                    '01',
                    'RAW INPUTS',
                    'Keep purchase, lease, operating, debt and market assumptions visible.',
                  ),
                  const _MethodCard(
                    '02',
                    'AUDITABLE MATH',
                    'Trace NOI, debt service, exit proceeds, IRR and risk scoring.',
                  ),
                  const _MethodCard(
                    '03',
                    'STRESS BEFORE BUYING',
                    'Compare downside, base and upside cases before committing capital.',
                  ),
                ];
                return constraints.maxWidth < 700
                    ? Column(children: cards)
                    : Row(
                        children: cards
                            .map((card) => Expanded(child: card))
                            .toList(),
                      );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _MethodCard extends StatelessWidget {
  const _MethodCard(this.number, this.title, this.body);
  final String number;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 190),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withValues(alpha: .38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(color: _lime, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 42),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFD8D0EB),
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
String _money(double value) {
  if (!value.isFinite) return '—';
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final chunks = <String>[];
  for (var i = digits.length; i > 0; i -= 3) {
    chunks.insert(0, digits.substring(math.max(0, i - 3), i));
  }
  return '${negative ? '−' : ''}\$${chunks.join(',')}';
}
