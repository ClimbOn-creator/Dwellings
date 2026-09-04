import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/buyer_comparison_profile.dart';
import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/deal_room_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import 'acquisition_support_page.dart';
import 'auth_page.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';

const _ink = Color(0xFF171717);
const _green = Color(0xFF086B4C);
const _paper = Color(0xFFF2F1ED);
const _line = Color(0xFFD8D5CE);
const _muted = Color(0xFF68635D);

class DealComparisonPage extends StatefulWidget {
  const DealComparisonPage({super.key});

  @override
  State<DealComparisonPage> createState() => _DealComparisonPageState();
}

class _DealComparisonPageState extends State<DealComparisonPage> {
  AcquisitionFoundation? _foundation;
  BuyerComparisonProfile _profile = const BuyerComparisonProfile();
  List<DealRoom> _deals = const [];
  String? _leftId;
  String? _rightId;
  int? _focusedDocument;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final foundation = await AcquisitionFoundation.load();
    final rooms = await DealRoomService.loadRooms();
    final comparison = foundation.blueprint['comparisonProfile'];
    final profile = comparison is Map
        ? BuyerComparisonProfile.fromJson(Map<String, dynamic>.from(comparison))
        : const BuyerComparisonProfile();
    final deals = rooms
        .where((room) => room.isBusiness && room.status != 'archived')
        .toList();
    if (!mounted) return;
    setState(() {
      _foundation = foundation;
      _profile = profile;
      _deals = deals;
      _leftId = deals.isEmpty ? null : deals.first.id;
      _rightId = deals.length < 2 ? null : deals[1].id;
      _loading = false;
    });
  }

  DealRoom? _deal(String? id) {
    if (id == null) return null;
    for (final deal in _deals) {
      if (deal.id == id) return deal;
    }
    return null;
  }

  Future<void> _editQuestions() async {
    final updated = await showDialog<BuyerComparisonProfile>(
      context: context,
      builder: (_) => _ComparisonQuestionsDialog(initial: _profile),
    );
    if (updated == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final foundation = _foundation ?? await AcquisitionFoundation.load();
      foundation.blueprint['comparisonProfile'] = updated.toJson();
      await foundation.save();
      if (BackendService.user == null && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      }
      if (BackendService.user != null) {
        await foundation.saveForAccount('deal_comparison');
      }
      if (!mounted) return;
      setState(() {
        _foundation = foundation;
        _profile = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BackendService.user == null
                ? 'Comparison answers saved on this device.'
                : 'Comparison answers saved to your buyer profile.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your answers: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      toolbarHeight: 76,
      backgroundColor: const Color(0xFFF8F7F3),
      surfaceTintColor: Colors.transparent,
      title: const HomeBrandButton(size: 56, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _green))
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 80),
            child: Center(
              child: SizedBox(
                width: 1180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heading(),
                    const SizedBox(height: 24),
                    _parameterStrip(),
                    const SizedBox(height: 24),
                    _comparisonWorkspace(),
                  ],
                ),
              ),
            ),
          ),
  );

  Widget _heading() => LayoutBuilder(
    builder: (context, box) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUYER DECISION DESK',
            style: TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compare & contrast',
            style: TextStyle(
              fontSize: box.maxWidth < 600 ? 38 : 50,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Put two business breakdowns beside each other, then test each one against the life, return, and operating role you actually want.',
            style: TextStyle(color: _muted, fontSize: 16, height: 1.5),
          ),
        ],
      );
      final button = FilledButton.icon(
        onPressed: _saving ? null : _editQuestions,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        icon: const Icon(Icons.tune_rounded),
        label: Text(
          _profile.complete ? 'EDIT MY 8 ANSWERS' : 'ANSWER 8 QUESTIONS',
        ),
      );
      if (box.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [text, const SizedBox(height: 18), button],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: text),
          const SizedBox(width: 30),
          button,
        ],
      );
    },
  );

  Widget _parameterStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'YOUR BUYING PARAMETERS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              '${_profile.answeredCount}/8 ANSWERED',
              style: const TextStyle(
                color: Color(0xFF8DDFC1),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ParameterChip('Goal', _profile.goal),
            _ParameterChip('Role', _profile.role),
            _ParameterChip('Hold', _profile.horizon),
            _ParameterChip('Time', _profile.weeklyTime),
            _ParameterChip('Cash flow', _profile.minimumCashFlow),
            _ParameterChip('Return', _profile.minimumReturn),
            _ParameterChip('Risk', _profile.riskTolerance),
            _ParameterChip('Limits', _profile.nonNegotiables),
          ],
        ),
      ],
    ),
  );

  Widget _comparisonWorkspace() {
    if (BackendService.user == null) {
      return const _ComparisonEmptyState(
        title: 'Sign in to compare your deals',
        message:
            'Your answers can be saved on this device, but the business breakdowns come from Deal Rooms tied to your account.',
        page: AcquisitionBlueprintPage(),
        action: 'CONTINUE BUYER SETUP',
      );
    }
    if (_deals.length < 2) {
      return _ComparisonEmptyState(
        title: 'Add two business deals',
        message:
            'Create or screen at least two business opportunities. Their saved financials and risk results become the comparison documents.',
        page: _deals.isEmpty
            ? const BusinessAcquisitionPage()
            : const DealRoomsPage(initialSide: PlatformSide.business),
        action: _deals.isEmpty ? 'SCREEN A BUSINESS' : 'OPEN PIPELINE',
      );
    }
    final left = _deal(_leftId)!;
    final right = _deal(_rightId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth < 760
                ? box.maxWidth
                : (box.maxWidth - 14) / 2;
            return Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                SizedBox(width: width, child: _dealPicker(true, left)),
                SizedBox(width: width, child: _dealPicker(false, right)),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final narrow = box.maxWidth < 760;
            final leftChild = _focusedDocument == 1
                ? _DealBreakdown(
                    key: ValueKey('breakdown-${right.id}'),
                    deal: right,
                    profile: _profile,
                  )
                : _BreakdownDocument(
                    key: ValueKey('document-${left.id}'),
                    deal: left,
                    profile: _profile,
                    selected: _focusedDocument == 0,
                    onTap: () => setState(() => _focusedDocument = 0),
                  );
            final rightChild = _focusedDocument == 0
                ? _DealBreakdown(
                    key: ValueKey('breakdown-${left.id}'),
                    deal: left,
                    profile: _profile,
                  )
                : _BreakdownDocument(
                    key: ValueKey('document-${right.id}'),
                    deal: right,
                    profile: _profile,
                    selected: _focusedDocument == 1,
                    onTap: () => setState(() => _focusedDocument = 1),
                  );
            Widget animated(Widget child) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .05, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: child,
            );
            if (narrow) {
              return Column(
                children: [
                  animated(leftChild),
                  const SizedBox(height: 14),
                  animated(rightChild),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: animated(leftChild)),
                const SizedBox(width: 14),
                Expanded(child: animated(rightChild)),
              ],
            );
          },
        ),
        if (_focusedDocument != null) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _focusedDocument = null),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('RETURN TO TWO-DOCUMENT VIEW'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dealPicker(bool left, DealRoom selected) =>
      DropdownButtonFormField<String>(
        initialValue: selected.id,
        decoration: InputDecoration(
          labelText: left ? 'LEFT DOCUMENT' : 'RIGHT DOCUMENT',
        ),
        items: _deals
            .where((deal) => deal.id != (left ? _rightId : _leftId))
            .map(
              (deal) =>
                  DropdownMenuItem(value: deal.id, child: Text(deal.title)),
            )
            .toList(),
        onChanged: (id) => setState(() {
          if (left) {
            _leftId = id;
          } else {
            _rightId = id;
          }
          _focusedDocument = null;
        }),
      );
}

class _ParameterChip extends StatelessWidget {
  const _ParameterChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 280),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF292929),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$label · ${value.trim().isEmpty ? 'Not answered' : value}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    ),
  );
}

class _BreakdownDocument extends StatelessWidget {
  const _BreakdownDocument({
    super.key,
    required this.deal,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final DealRoom deal;
  final BuyerComparisonProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = _DealComparisonData(deal, profile);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Open business breakdown for ${deal.title}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 590),
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 34),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F5EE) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? _green : _line,
              width: selected ? 3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: selected ? _green : _ink,
                  ),
                  const Spacer(),
                  Text(
                    'BUSINESS BREAKDOWN',
                    style: TextStyle(
                      color: selected ? _green : _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                deal.title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.industry} · ${deal.city.isEmpty ? 'Location not entered' : deal.city}',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 24),
              _DocumentMetric('ASKING PRICE', data.money(data.askingPrice)),
              _DocumentMetric('ANNUAL REVENUE', data.money(data.revenue)),
              _DocumentMetric(
                'CASH AFTER OWNER / MANAGER',
                data.money(data.cashAfterOwner),
              ),
              _DocumentMetric('MODELLED RETURN', data.percent(data.roic)),
              _DocumentMetric(
                'RISK SCORE',
                data.riskScore == 0
                    ? 'Not scored'
                    : '${data.riskScore.round()}/100',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: selected ? Colors.white : const Color(0xFFF5F4F0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.fitScore}% PERSONAL FIT',
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(data.fitSummary, style: const TextStyle(height: 1.45)),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    selected ? 'SELECTED' : 'CLICK TO OPEN',
                    style: TextStyle(
                      color: selected ? _green : _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: selected ? _green : _ink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentMetric extends StatelessWidget {
  const _DocumentMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _DealBreakdown extends StatelessWidget {
  const _DealBreakdown({super.key, required this.deal, required this.profile});
  final DealRoom deal;
  final BuyerComparisonProfile profile;

  @override
  Widget build(BuildContext context) {
    final data = _DealComparisonData(deal, profile);
    return Container(
      constraints: const BoxConstraints(minHeight: 590),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL FIT BREAKDOWN',
            style: TextStyle(
              color: Color(0xFF8DDFC1),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            deal.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          ...data.fitChecks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    check.$1 ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: check.$1
                        ? const Color(0xFF67D5AC)
                        : const Color(0xFFF0B85B),
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      check.$2,
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF3B3B3B)),
          const SizedBox(height: 12),
          const Text(
            'QUESTIONS TO PRESS',
            style: TextStyle(
              color: Color(0xFF8DDFC1),
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 10),
          for (final question in data.questions.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                '— $question',
                style: const TextStyle(color: Color(0xFFD4D4D4), height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _DealComparisonData {
  _DealComparisonData(this.deal, this.profile);
  final DealRoom deal;
  final BuyerComparisonProfile profile;

  Map<String, dynamic> get input {
    final values = deal.propertySnapshot['values'];
    return values is Map
        ? Map<String, dynamic>.from(values)
        : deal.propertySnapshot;
  }

  double n(Map<String, dynamic> source, String key) =>
      (source[key] as num?)?.toDouble() ?? 0;
  double get askingPrice =>
      deal.purchasePrice > 0 ? deal.purchasePrice : n(input, 'askingPrice');
  double get revenue => n(input, 'revenue');
  double get cashAfterOwner => n(deal.riskSnapshot, 'cash_after_owner_salary');
  double get roic => n(deal.riskSnapshot, 'roic');
  double get riskScore => n(deal.riskSnapshot, 'risk_score');
  double get ownerDependence => n(input, 'ownerDependence');
  String get industry =>
      '${deal.propertySnapshot['industry'] ?? 'Industry not entered'}';

  List<(bool, String)> get fitChecks {
    final checks = <(bool, String)>[];
    if (profile.cashFlowTarget > 0 && cashAfterOwner != 0) {
      checks.add((
        cashAfterOwner >= profile.cashFlowTarget,
        '${money(cashAfterOwner)} cash after owner/manager pay versus your ${money(profile.cashFlowTarget)} target.',
      ));
    }
    if (profile.returnTarget > 0 && roic != 0) {
      checks.add((
        roic >= profile.returnTarget,
        '${percent(roic)} modelled return versus your ${percent(profile.returnTarget)} minimum.',
      ));
    }
    if (profile.role.isNotEmpty && ownerDependence != 0) {
      final managed =
          profile.role.toLowerCase().contains('manager') ||
          profile.role.toLowerCase().contains('passive');
      checks.add((
        !managed || ownerDependence <= 50,
        '${ownerDependence.round()}% owner dependence tested against your ${profile.role.toLowerCase()} plan.',
      ));
    }
    if (profile.riskTolerance.isNotEmpty && riskScore != 0) {
      final tolerance = profile.riskTolerance.toLowerCase();
      final limit = tolerance.contains('stable')
          ? 35
          : tolerance.contains('balanced')
          ? 60
          : 100;
      checks.add((
        riskScore <= limit,
        '${riskScore.round()}/100 risk score versus your ${profile.riskTolerance.toLowerCase()} preference.',
      ));
    }
    if (profile.horizon.isNotEmpty) {
      final growth = n(input, 'revenueGrowth');
      checks.add((
        !profile.horizon.toLowerCase().contains('long') || growth >= 0,
        '${percent(growth)} recent growth considered against a ${profile.horizon.toLowerCase()} hold.',
      ));
    }
    if (profile.weeklyTime.isNotEmpty) {
      checks.add((
        ownerDependence <= 65 ||
            profile.weeklyTime.toLowerCase().contains('full'),
        'Operating intensity considered against ${profile.weeklyTime.toLowerCase()} availability.',
      ));
    }
    if (checks.isEmpty) {
      checks.add((
        false,
        'Complete the eight buyer questions to calculate personal fit.',
      ));
    }
    return checks;
  }

  int get fitScore {
    final checks = fitChecks;
    final applicable = checks
        .where((check) => !check.$2.startsWith('Complete'))
        .toList();
    if (applicable.isEmpty) return 0;
    return (applicable.where((check) => check.$1).length /
            applicable.length *
            100)
        .round();
  }

  String get fitSummary => fitScore == 0
      ? 'Answer the eight comparison questions to turn this into a personal fit score.'
      : fitScore >= 75
      ? 'This deal aligns with most of your stated buying parameters.'
      : fitScore >= 50
      ? 'This deal has a mixed fit. Open the breakdown before advancing it.'
      : 'Several deal characteristics conflict with the way you want to buy and operate.';

  List<String> get questions {
    final flags =
        (deal.riskSnapshot['flags'] as List?)
            ?.map((value) => '$value')
            .toList() ??
        const <String>[];
    return [
      if (profile.role.toLowerCase().contains('manager'))
        'What management team and replacement salary are truly required?',
      if (profile.horizon.toLowerCase().contains('long'))
        'What protects durable cash flow over your intended holding period?',
      if (ownerDependence > 50)
        'How quickly can seller-dependent relationships and decisions transfer?',
      if (profile.nonNegotiables.isNotEmpty)
        'Does the evidence satisfy this limit: ${profile.nonNegotiables}?',
      ...flags,
      'Which assumption would most change the cash available after debt and management?',
    ];
  }

  String money(double value) => value == 0
      ? 'Not entered'
      : NumberFormat.simpleCurrency(
          name: 'CAD',
          decimalDigits: 0,
        ).format(value);
  String percent(double value) =>
      value == 0 ? 'Not entered' : '${value.toStringAsFixed(1)}%';
}

class _ComparisonQuestionsDialog extends StatefulWidget {
  const _ComparisonQuestionsDialog({required this.initial});
  final BuyerComparisonProfile initial;

  @override
  State<_ComparisonQuestionsDialog> createState() =>
      _ComparisonQuestionsDialogState();
}

class _ComparisonQuestionsDialogState
    extends State<_ComparisonQuestionsDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _goal;
  late String _role;
  late String _horizon;
  late String _weeklyTime;
  late String _risk;
  late final TextEditingController _cashFlow;
  late final TextEditingController _return;
  late final TextEditingController _limits;

  @override
  void initState() {
    super.initState();
    _goal = widget.initial.goal;
    _role = widget.initial.role;
    _horizon = widget.initial.horizon;
    _weeklyTime = widget.initial.weeklyTime;
    _risk = widget.initial.riskTolerance;
    _cashFlow = TextEditingController(text: widget.initial.minimumCashFlow);
    _return = TextEditingController(text: widget.initial.minimumReturn);
    _limits = TextEditingController(text: widget.initial.nonNegotiables);
  }

  @override
  void dispose() {
    _cashFlow.dispose();
    _return.dispose();
    _limits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Your 8 comparison questions'),
    content: SizedBox(
      width: 680,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _choice(
                1,
                'What is the main outcome you want?',
                _goal,
                const [
                  'Long-term profit and independence',
                  'Short-term improvement and resale',
                  'Reliable personal income',
                  'Strategic add-on acquisition',
                ],
                (value) => _goal = value,
              ),
              _choice(
                2,
                'How do you want the business operated?',
                _role,
                const [
                  'Run it myself',
                  'Oversee a hired manager',
                  'Mostly passive ownership',
                  'Transition from operator to manager',
                ],
                (value) => _role = value,
              ),
              _choice(
                3,
                'How long do you expect to own it?',
                _horizon,
                const [
                  'Long term · 10+ years',
                  'Medium term · 5–10 years',
                  'Short term · under 5 years',
                  'Not sure yet',
                ],
                (value) => _horizon = value,
              ),
              _choice(
                4,
                'How much time can you give it each week?',
                _weeklyTime,
                const [
                  'Full time · 40+ hours',
                  'Active oversight · 15–30 hours',
                  'Light oversight · under 10 hours',
                  'Manager-led from day one',
                ],
                (value) => _weeklyTime = value,
              ),
              _text(
                5,
                'Minimum annual cash flow after owner or manager pay',
                _cashFlow,
                prefix: r'$',
              ),
              _text(
                6,
                'Minimum annual return on your invested equity',
                _return,
                suffix: '%',
              ),
              _choice(7, 'What level of risk fits you?', _risk, const [
                'Stable and proven only',
                'Balanced risk and growth',
                'Open to a turnaround',
                'Not sure yet',
              ], (value) => _risk = value),
              _text(
                8,
                'What are your deal-breaking non-negotiables?',
                _limits,
                lines: 3,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            BuyerComparisonProfile(
              goal: _goal,
              role: _role,
              horizon: _horizon,
              weeklyTime: _weeklyTime,
              minimumCashFlow: _cashFlow.text.trim(),
              minimumReturn: _return.text.trim(),
              riskTolerance: _risk,
              nonNegotiables: _limits.text.trim(),
            ),
          );
        },
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: const Text('SAVE MY PARAMETERS'),
      ),
    ],
  );

  Widget _choice(
    int number,
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(labelText: '$number. $label'),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
      validator: (selected) => selected == null ? 'Choose an answer' : null,
    ),
  );

  Widget _text(
    int number,
    String label,
    TextEditingController controller, {
    String? prefix,
    String? suffix,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: prefix != null || suffix != null
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: '$number. $label',
        prefixText: prefix,
        suffixText: suffix,
      ),
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'Add an answer' : null,
    ),
  );
}

class _ComparisonEmptyState extends StatelessWidget {
  const _ComparisonEmptyState({
    required this.title,
    required this.message,
    required this.page,
    required this.action,
  });
  final String title;
  final String message;
  final Widget page;
  final String action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        const Icon(Icons.compare_arrows_rounded, color: _green, size: 38),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => page)),
          style: FilledButton.styleFrom(backgroundColor: _green),
          child: Text(action),
        ),
      ],
    ),
  );
}
