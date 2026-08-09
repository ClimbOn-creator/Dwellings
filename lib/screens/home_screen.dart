import 'package:flutter/material.dart';

import '../models/housing_model.dart';
import '../services/backend_service.dart';

const _ink = Color(0xFF10231B);
const _green = Color(0xFF1B5E45);
const _lime = Color(0xFFC9F55B);
const _paper = Color(0xFFF5F2E9);
const _card = Color(0xFFFFFDF8);
const _muted = Color(0xFF65766E);
const _line = Color(0xFFDDE2DA);
const _risk = Color(0xFFB7553D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DecisionMode _mode = DecisionMode.home;
  MarketProfile _profile = marketProfiles.first;
  AnalysisResult? _result;
  bool _scanning = false;
  bool _saved = false;

  final _address = TextEditingController(text: 'Kitsilano, Vancouver, BC');
  final Map<String, TextEditingController> _fields = {
    'price': TextEditingController(text: '1200000'),
    'finishedArea': TextEditingController(text: '1800'),
    'lotArea': TextEditingController(text: '6500'),
    'buildable': TextEditingController(text: '0'),
    'bedrooms': TextEditingController(text: '3'),
    'bathrooms': TextEditingController(text: '2'),
    'yearBuilt': TextEditingController(text: '1988'),
    'repairs': TextEditingController(text: '25000'),
    'rent': TextEditingController(text: '5000'),
    'operatingCosts': TextEditingController(text: '12500'),
    'redevelopment': TextEditingController(text: '55'),
    'scarcity': TextEditingController(text: '64'),
    'daysOnMarket': TextEditingController(text: '28'),
    'downPayment': TextEditingController(text: '20'),
    'amortization': TextEditingController(text: '25'),
    'holdingPeriod': TextEditingController(text: '5'),
  };

  double _number(String key) => double.tryParse(_fields[key]?.text ?? '') ?? 0;

  PropertyInputs get _inputs => PropertyInputs(
    address: _address.text.trim().isEmpty
        ? 'Untitled property'
        : _address.text.trim(),
    price: _number('price'),
    finishedArea: _number('finishedArea'),
    lotArea: _number('lotArea'),
    buildable: _number('buildable'),
    bedrooms: _number('bedrooms'),
    bathrooms: _number('bathrooms'),
    yearBuilt: _number('yearBuilt'),
    repairs: _number('repairs'),
    rent: _number('rent'),
    operatingCosts: _number('operatingCosts'),
    redevelopment: _number('redevelopment'),
    scarcity: _number('scarcity'),
    daysOnMarket: _number('daysOnMarket'),
    downPayment: _number('downPayment'),
    amortization: _number('amortization'),
    holdingPeriod: _number('holdingPeriod'),
    profile: _profile,
  );

  Future<void> _scanLocation() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _profile = profileForAddress(_address.text);
      _scanning = false;
    });
  }

  void _analyze() {
    if (_number('price') <= 0 || _number('rent') < 0) {
      _message('Add a valid purchase price before running the analysis.');
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
            ? 'Analysis saved to your account.'
            : 'Analysis saved securely on this device.',
      );
    } catch (error) {
      _message('Could not save: $error');
    }
  }

  Future<void> _account() async {
    if (!BackendService.configured) {
      _message(
        'Demo mode is active. Supabase will enable accounts after deployment setup.',
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
        title: const Text('Sign in to DwellingIQ'),
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
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _paper.withValues(alpha: .96),
              surfaceTintColor: Colors.transparent,
              titleSpacing: 28,
              title: const _Brand(),
              actions: [
                TextButton(
                  onPressed: _account,
                  child: Text(
                    BackendService.user?.email ??
                        (BackendService.configured ? 'Sign in' : 'Demo'),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _workspace()),
            const SliverToBoxAdapter(child: _HowItWorks()),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1160),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 72, 28, 54),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Divider(color: _green, thickness: 3),
                ),
                SizedBox(width: 10),
                Text(
                  'PROPERTY DECISION INTELLIGENCE',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Know the property.\nSee the whole picture.',
              style: TextStyle(
                fontSize: MediaQuery.sizeOf(context).width < 650 ? 43 : 68,
                height: .98,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.7,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: const Text(
                'Location-aware analysis for buying a home or evaluating an investment—built from transparent fundamentals, not sales language.',
                style: TextStyle(fontSize: 18, height: 1.55, color: _muted),
              ),
            ),
            const SizedBox(height: 30),
            const Wrap(
              spacing: 34,
              runSpacing: 14,
              children: [
                _HeroStat('22', 'FACTORS SCORED'),
                _HeroStat('2', 'DECISION LENSES'),
                _HeroStat('100%', 'EXPLAINABLE'),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _workspace() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final form = _inputPanel();
            final result = _resultPanel();
            return desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 9, child: result),
                    ],
                  )
                : Column(children: [form, const SizedBox(height: 20), result]);
          },
        ),
      ),
    ),
  );

  Widget _inputPanel() => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          kicker: '01 / SET YOUR GOAL',
          title: 'What are you buying?',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                active: _mode == DecisionMode.home,
                icon: Icons.home_outlined,
                title: 'A home to live in',
                subtitle: 'Affordability + long-term value',
                onTap: () => setState(() => _mode = DecisionMode.home),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                active: _mode == DecisionMode.invest,
                icon: Icons.trending_up,
                title: 'An investment',
                subtitle: 'Yield + risk-adjusted growth',
                onTap: () => setState(() => _mode = DecisionMode.invest),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _StepLabel(
          number: '02',
          title: 'PROPERTY LOCATION',
          subtitle: 'Let the location do the heavy lifting',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: 'Address or neighbourhood',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(6),
              child: FilledButton.icon(
                onPressed: _scanning ? null : _scanLocation,
                icon: Icon(
                  _scanning ? Icons.hourglass_top : Icons.auto_awesome,
                  size: 15,
                ),
                label: Text(_scanning ? 'Scanning…' : 'Scan'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LocationCard(profile: _profile),
        const SizedBox(height: 28),
        const _StepLabel(
          number: '03',
          title: 'PROPERTY DETAILS',
          subtitle: 'Add what you know — estimates are okay',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 530
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _field('price', 'Purchase price', '\$ CAD', width),
                _field('downPayment', 'Down payment', '%', width),
                _field('finishedArea', 'Finished area', 'sq ft', width),
                _field('lotArea', 'Lot size', 'sq ft', width),
                _field('bedrooms', 'Bedrooms', '', width),
                _field('bathrooms', 'Bathrooms', '', width),
                _field('yearBuilt', 'Year built', '', width),
                _field('repairs', 'Immediate repairs', '\$ CAD', width),
                _field('rent', 'Monthly market rent', '\$ CAD', width),
                _field(
                  'operatingCosts',
                  'Annual operating costs',
                  '\$ CAD',
                  width,
                ),
                _field('holdingPeriod', 'Holding period', 'years', width),
                _field(
                  'buildable',
                  'Buildable floor area (optional)',
                  'sq ft',
                  width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: _analyze,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'Run full analysis',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Location is used for this analysis only. Demo market data is clearly identified.',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  Widget _field(String key, String label, String suffix, double width) =>
      SizedBox(
        width: width,
        child: TextField(
          controller: _fields[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: suffix),
        ),
      );

  Widget _resultPanel() {
    final result = _result;
    if (result == null) {
      return const _Panel(
        child: SizedBox(
          height: 610,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: _green,
                    child: Icon(Icons.query_stats, size: 46, color: _lime),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Your decision brief will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Scan a location, add property details, and run the model.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final verdict = result.net >= 55
        ? 'Strong candidate'
        : result.net >= 42
        ? 'Worth a closer look'
        : 'Proceed with caution';
    final tone = result.net >= 55
        ? const Color(0xFFE7F2E8)
        : result.net >= 42
        ? const Color(0xFFF7F0D9)
        : const Color(0xFFF7E7DF);
    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DECISION BRIEF',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.3,
                          color: _muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _inputs.address,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_profile.city}, ${_profile.region} · ${_mode == DecisionMode.home ? 'Homebuyer' : 'Investor'} lens',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _save,
                  icon: Icon(_saved ? Icons.star : Icons.star_border, size: 17),
                  label: Text(_saved ? 'Saved' : 'Save'),
                ),
              ],
            ),
          ),
          Container(
            color: tone,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verdict,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(result.probability * 100).round()}% modelled chance of outperforming the local benchmark over ${_inputs.holdingPeriod.round()} years.',
                        style: const TextStyle(color: _muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ScoreCircle(result.net),
              ],
            ),
          ),
          _KpiGrid(result: result, mode: _mode),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "WHAT'S DRIVING THE SCORE",
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...result.drivers.take(5).map((driver) => _DriverRow(driver)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: _lime, size: 18),
                      SizedBox(width: 9),
                      Text(
                        'AI DILIGENCE COACH',
                        style: TextStyle(
                          color: _lime,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your next three questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _question(
                    _inputs.buildable <= 0
                        ? 'Confirm buildable floor area and permitted density with the municipality.'
                        : 'Verify achievable floor area after setbacks and servicing.',
                  ),
                  _question(
                    'Request an insurance quote covering the mapped local hazards.',
                  ),
                  _question(
                    _mode == DecisionMode.invest
                        ? 'Validate rent and costs with three recent comparables.'
                        : 'Stress-test your budget at a mortgage rate two points higher.',
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              'Prototype estimate · Market profiles are illustrative seed data. Model weights require historical calibration. Verify financing, inspection, title, zoning, tax and insurance details.',
              style: TextStyle(color: _muted, fontSize: 9, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: _lime)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD7E3DC),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: _green,
        child: Icon(Icons.bar_chart_rounded, color: _lime, size: 20),
      ),
      SizedBox(width: 10),
      Text(
        'Dwelling',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      Text(
        'IQ',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _green,
        ),
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(28)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C1E2F25),
          blurRadius: 40,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.kicker, required this.title});
  final String kicker;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        kicker,
        style: const TextStyle(
          color: _muted,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.active,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEDF4EC) : const Color(0xFFFAFAF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? _green : _line,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: _ink,
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: _muted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ],
  );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.profile});
  final MarketProfile profile;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF3EC),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Container(
          width: 70,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFD8E5D8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.map_outlined, color: _green, size: 31),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOCATION PROFILE · DEMO DATA',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.1,
                  color: _muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${profile.city}, ${profile.region}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${profile.transit.round()}/100 transit · ${profile.inventory} months inventory · ${(profile.appreciation * 100).toStringAsFixed(1)}% benchmark',
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
        ),
        const Icon(Icons.verified, color: _green, size: 18),
      ],
    ),
  );
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle(this.score);
  final double score;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    height: 78,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CircularProgressIndicator(
          value: score / 100,
          strokeWidth: 8,
          color: _green,
          backgroundColor: const Color(0xFFD5DED5),
          strokeCap: StrokeCap.round,
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.round().toString(),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('/100', style: TextStyle(fontSize: 9, color: _muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.result, required this.mode});
  final AnalysisResult result;
  final DecisionMode mode;
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 1.75,
    children: [
      _Kpi(
        'Expected growth',
        '${(result.annualAppreciation * 100).toStringAsFixed(1)}%',
        'annualized estimate',
      ),
      _Kpi(
        mode == DecisionMode.invest
            ? 'Monthly cash flow'
            : 'Monthly housing cost',
        _money(result.monthlyCarry),
        mode == DecisionMode.invest
            ? 'after mortgage + expenses'
            : 'mortgage + operating costs',
        negative: result.monthlyCarry < 0,
      ),
      _Kpi(
        'Projected value',
        _money(result.projectedValue),
        'at the selected horizon',
      ),
      _Kpi(
        mode == DecisionMode.invest ? 'Net cap rate' : 'Mortgage payment',
        mode == DecisionMode.invest
            ? '${(result.capRate * 100).toStringAsFixed(1)}%'
            : _money(result.monthlyMortgage),
        mode == DecisionMode.invest ? 'before financing' : 'per month',
      ),
    ],
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.note, {this.negative = false});
  final String label;
  final String value;
  final String note;
  final bool negative;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(border: Border.all(color: _line, width: .5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: negative ? _risk : _ink,
            ),
          ),
        ),
        Text(note, style: const TextStyle(color: _muted, fontSize: 8)),
      ],
    ),
  );
}

class _DriverRow extends StatelessWidget {
  const _DriverRow(this.driver);
  final FactorResult driver;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFEDF0EB))),
    ),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: driver.isRisk
                ? const Color(0xFFF5E6DF)
                : const Color(0xFFE3F1E4),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            driver.isRisk ? Icons.priority_high : Icons.trending_up,
            size: 15,
            color: driver.isRisk ? _risk : _green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            driver.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${driver.impact >= 0 ? '+' : '−'}${driver.impact.abs().toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 14),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: Color(0xFFCCD3C9))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1.1,
            color: _muted,
          ),
        ),
      ],
    ),
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0C2B20),
    padding: const EdgeInsets.symmetric(vertical: 68, horizontal: 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BUILT FOR BETTER QUESTIONS',
              style: TextStyle(
                color: Color(0xFFA9C9B6),
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'AI helps with the research.\nYou stay in control of the decision.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 700;
                final cards = [
                  const _MethodCard(
                    '01',
                    'Scan the location',
                    'Connect market, transit, hazard and demographic evidence to the property.',
                  ),
                  const _MethodCard(
                    '02',
                    'Score fundamentals',
                    'Normalize upside and risk factors using transparent benchmarks.',
                  ),
                  const _MethodCard(
                    '03',
                    'Explain the result',
                    'Show assumptions, strongest drivers, missing data and diligence questions.',
                  ),
                ];
                return narrow
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
    constraints: const BoxConstraints(minHeight: 180),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF335145)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(color: _lime, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFFAABEB3),
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

String _money(double value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final parts = <String>[];
  for (var i = digits.length; i > 0; i -= 3) {
    parts.insert(0, digits.substring(mathMax(0, i - 3), i));
  }
  return '${negative ? '−' : ''}\$${parts.join(',')}';
}

int mathMax(int a, int b) => a > b ? a : b;
