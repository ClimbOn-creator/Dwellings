import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/buyer_comparison_profile.dart';
import '../services/backend_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'acquisition_support_page.dart';
import 'auth_page.dart';
import 'member_deal_marketplace_page.dart';

const _green = Color(0xFF086B4C);
const _ink = Color(0xFF203435);
const _muted = Color(0xFF607172);
const _line = Color(0xFFDCE3E2);

/// A complete choice exercise independent of the user's deal pipeline.
class DealComparisonPage extends StatefulWidget {
  const DealComparisonPage({super.key});

  @override
  State<DealComparisonPage> createState() => _DealComparisonPageState();
}

class _DealComparisonPageState extends State<DealComparisonPage> {
  AcquisitionFoundation? _foundation;
  final Map<String, dynamic> _answers = {};
  int _step = 0;
  int? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _savedToAccount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final foundation = await AcquisitionFoundation.load();
      if (!mounted) return;
      setState(() {
        _foundation = foundation;
        final stored = foundation.blueprint['comparisonProfile'];
        if (stored is Map) _answers.addAll(Map<String, dynamic>.from(stored));
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Your saved preferences could not be loaded. Please retry.';
        });
    }
  }

  Future<void> _choose(int index) async {
    if (_selected != null || _saving) return;
    final round = _rounds[_step];
    setState(() {
      _selected = index;
      _answers[round.field] = round.options[index].answer;
    });
    if (!MediaQuery.of(context).disableAnimations) {
      await Future<void>.delayed(const Duration(milliseconds: 680));
    }
    if (!mounted) return;
    setState(() {
      _selected = null;
      _step++;
    });
    if (_step == _rounds.length) await _save();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final foundation = _foundation ?? await AcquisitionFoundation.load();
      foundation.blueprint['comparisonProfile'] =
          BuyerComparisonProfile.fromJson(_answers).toJson();
      await foundation.save();
      final signedIn = BackendService.user != null;
      if (signedIn) await foundation.saveForAccount('deal_comparison');
      if (mounted)
        setState(() {
          _foundation = foundation;
          _savedToAccount = signedIn;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Your choices are still here. Saving failed; please try again.';
        });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F4F3),
    appBar: AppBar(
      toolbarHeight: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 50, dark: false),
      actions: const [AppNavigationMenu(dark: false), SizedBox(width: 12)],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _green))
        : _foundation == null && _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              padding: EdgeInsets.all(viewport.maxWidth < 600 ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1380,
                    minHeight: (viewport.maxHeight - 56).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: _step == _rounds.length ? _complete() : _quiz(),
                ),
              ),
            ),
          ),
  );

  Widget _quiz() {
    final round = _rounds[_step];
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'QUIZ',
                style: TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            Text(
              '${_step + 1} / 8',
              style: const TextStyle(
                color: _muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            8,
            (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: i <= _step ? _green : _line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          round.question,
          style: const TextStyle(
            color: _ink,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the business you would rather own. The highlighted rows show the trade-off.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: Duration(milliseconds: reducedMotion ? 0 : 350),
          child: LayoutBuilder(
            key: ValueKey(_step),
            builder: (context, box) {
              Widget document(int index) => AnimatedScale(
                scale: _selected != null && _selected != index ? .02 : 1,
                duration: Duration(milliseconds: reducedMotion ? 0 : 480),
                curve: Curves.easeInOutCubic,
                child: AnimatedOpacity(
                  opacity: _selected != null && _selected != index ? 0 : 1,
                  duration: Duration(milliseconds: reducedMotion ? 0 : 380),
                  child: _BusinessDocument(
                    letter: index == 0 ? 'A' : 'B',
                    option: round.options[index],
                    focus: round.focus,
                    selected: _selected == index,
                    enabled: _selected == null,
                    onChoose: () => _choose(index),
                  ),
                ),
              );
              const versus = Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
              if (box.maxWidth < 700) {
                return Column(children: [document(0), versus, document(1)]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: document(0)),
                  versus,
                  Expanded(child: document(1)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: _selected == null
                    ? () => setState(() => _step--)
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous comparison'),
              ),
            const Expanded(
              child: Text(
                'Illustrative businesses · CAD · Figures are examples, not live listings.',
                textAlign: TextAlign.end,
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _complete() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle_outline, color: _green, size: 44),
      const SizedBox(height: 18),
      const Text(
        'Your buying preferences, defined.',
        style: TextStyle(
          color: _ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _saving
            ? 'Saving your choices…'
            : _savedToAccount
            ? 'Saved to your account for personalized scores on the bulletin board.'
            : 'Saved on this device. Sign in to keep these preferences across devices.',
        style: const TextStyle(color: _muted, fontSize: 16),
      ),
      const SizedBox(height: 24),
      for (final round in _rounds)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            round.focus,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          subtitle: Text(
            '${_answers[round.field] ?? ''}',
            style: const TextStyle(color: _ink, fontSize: 18),
          ),
        ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_error != null) {
                      await _save();
                      return;
                    }
                    if (!_savedToAccount) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuthPage(),
                        ),
                      );
                      if (!mounted || BackendService.user == null) return;
                      await _save();
                      if (!mounted || _error != null) return;
                    }
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BusinessSaleBulletinPage(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(
              _error != null
                  ? 'Retry saving'
                  : _savedToAccount
                  ? 'Find matching businesses'
                  : 'Sign in & save to my account',
            ),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _step = 0;
                    _selected = null;
                    _error = null;
                  }),
            child: const Text('Retake the quiz'),
          ),
        ],
      ),
    ],
  );
}

class _BusinessDocument extends StatelessWidget {
  const _BusinessDocument({
    required this.letter,
    required this.option,
    required this.focus,
    required this.selected,
    required this.enabled,
    required this.onChoose,
  });
  final String letter;
  final _Option option;
  final String focus;
  final bool selected;
  final bool enabled;
  final VoidCallback onChoose;

  String money(double value) =>
      NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(value);

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onChoose : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: MediaQuery.of(context).disableAnimations ? 0 : 220,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE1F4E9) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _green : _line, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C203435),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle : Icons.description_outlined,
                    color: _green,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'BUSINESS $letter',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Text(
                    'ILLUSTRATIVE',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                option.name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Commercial maintenance services',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EF),
                  border: Border(left: BorderSide(color: _green, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focus.toUpperCase(),
                      style: const TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.highlight,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _row('Acquisition price', money(option.equity)),
              _row('Ownership plan', option.plan),
              _row('Your operating role', option.role),
              _row('Weekly involvement', option.hours),
              const SizedBox(height: 20),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.6),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  _financialRow(
                    'Operating breakdown',
                    'Monthly',
                    'Yearly',
                    header: true,
                  ),
                  _financialRow(
                    'Revenue',
                    money(option.revenue / 12),
                    money(option.revenue),
                  ),
                  _financialRow(
                    'Operating expenses',
                    money(option.expenses / 12),
                    money(option.expenses),
                    shaded: true,
                  ),
                  _financialRow(
                    'Owner / manager pay',
                    money(option.salary / 12),
                    money(option.salary),
                  ),
                  _financialRow(
                    'Cash remaining',
                    money(option.cash / 12),
                    money(option.cash),
                    total: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(
                'Annual equity return',
                '${(option.cash / option.equity * 100).round()}%',
              ),
              const Text(
                'Illustrative all-cash purchase; before tax and financing.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enabled ? onChoose : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: _green,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(
                    selected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    selected ? 'Selected' : 'I would choose business $letter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  TableRow _financialRow(
    String label,
    String monthly,
    String yearly, {
    bool header = false,
    bool total = false,
    bool shaded = false,
  }) => TableRow(
    decoration: BoxDecoration(
      color: header
          ? const Color(0xFF45666C)
          : total
          ? const Color(0xFFE4F2EB)
          : shaded
          ? const Color(0xFFF2F5F5)
          : Colors.white,
    ),
    children: [label, monthly, yearly]
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              entry.value,
              textAlign: entry.key == 0 ? TextAlign.start : TextAlign.end,
              style: TextStyle(
                color: header ? Colors.white : _ink,
                fontSize: 13,
                fontWeight: header || total ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _Option {
  const _Option(
    this.answer,
    this.highlight, {
    this.name = 'Evergreen Maintenance',
    this.plan = 'Hold for 10+ years',
    this.role = 'Oversee a hired manager',
    this.hours = '8 hours',
    this.revenue = 900000,
    this.expenses = 600000,
    this.salary = 100000,
    this.equity = 1000000,
  });
  final String answer, highlight, name, plan, role, hours;
  final double revenue, expenses, salary, equity;
  double get cash => revenue - expenses - salary;
}

class _Round {
  const _Round(this.field, this.focus, this.question, this.options);
  final String field, focus, question;
  final List<_Option> options;
}

const _rounds = <_Round>[
  _Round(
    'goal',
    'Buying outcome',
    'Build lasting income or improve and resell?',
    [
      _Option(
        'Long-term profit and independence',
        'Keep the business and collect recurring cash flow.',
      ),
      _Option(
        'Short-term improvement and resale',
        'Improve operations, then pursue a resale.',
        name: 'Summit Maintenance',
        plan: 'Improve and sell in 3 years',
      ),
    ],
  ),
  _Round(
    'role',
    'Your role',
    'Run the business yourself or lead through a manager?',
    [
      _Option(
        'Run it myself',
        'You take the operating role and earn the owner salary.',
        role: 'Owner-operator',
        hours: '40+ hours',
      ),
      _Option(
        'Oversee a hired manager',
        'A hired manager earns the salary and runs daily operations.',
        name: 'Summit Maintenance',
      ),
    ],
  ),
  _Round(
    'horizon',
    'Holding period',
    'Commit for a decade or plan an earlier exit?',
    [
      _Option(
        'Long term · 10+ years',
        'Build value over a ten-year ownership period.',
      ),
      _Option(
        'Short term · under 5 years',
        'Aim for an exit within three years.',
        name: 'Summit Maintenance',
        plan: 'Sell in 3 years',
      ),
    ],
  ),
  _Round(
    'weeklyTime',
    'Time commitment',
    'More involvement or more time back?',
    [
      _Option(
        'Active oversight · 15–30 hours',
        'Spend about 25 hours each week guiding the team.',
        hours: '25 hours',
        salary: 75000,
      ),
      _Option(
        'Light oversight · under 10 hours',
        'Pay for stronger management and keep involvement under 10 hours.',
        name: 'Summit Maintenance',
        salary: 125000,
      ),
    ],
  ),
  _Round(
    'minimumCashFlow',
    'Cash-flow target',
    'A smaller investment or a larger income target?',
    [
      _Option(
        r'$100,000',
        r'Target $100,000 annual cash after management pay.',
        revenue: 600000,
        expenses: 400000,
        equity: 500000,
      ),
      _Option(
        r'$200,000',
        r'Target $200,000 annual cash with twice the investment.',
        name: 'Summit Maintenance',
      ),
    ],
  ),
  _Round(
    'minimumReturn',
    'Return target',
    'A 15% return floor or a 25% return hurdle?',
    [
      _Option(
        '15%',
        'Accept a 15% annual equity return from the illustrated cash flow.',
        expenses: 650000,
      ),
      _Option(
        '25%',
        'Require a 25% annual equity return to advance this deal.',
        name: 'Summit Maintenance',
        expenses: 550000,
      ),
    ],
  ),
  _Round(
    'riskTolerance',
    'Operating risk',
    'Proven operations or a turnaround opportunity?',
    [
      _Option(
        'Stable and proven only',
        'Established processes and steady recent earnings.',
      ),
      _Option(
        'Open to a turnaround',
        'Uneven earnings; operations need repair before growth.',
        name: 'Summit Maintenance',
        equity: 750000,
        plan: 'Repair and grow',
        role: 'Lead the turnaround',
        hours: '30+ hours',
      ),
    ],
  ),
  _Round(
    'nonNegotiables',
    'Your non-negotiable',
    'Prioritize repeat revenue or low seller dependence?',
    [
      _Option(
        'Recurring or repeat revenue',
        '80% repeat revenue; the seller holds key customer relationships.',
      ),
      _Option(
        'Low seller dependence',
        'Team-owned relationships; only 30% of revenue repeats.',
        name: 'Summit Maintenance',
      ),
    ],
  ),
];
