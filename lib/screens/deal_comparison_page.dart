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
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
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
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            Text(
              '${_profile.answeredCount}/8 ANSWERED',
              style: const TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: _profile.answeredCount / 8,
            minHeight: 6,
            backgroundColor: const Color(0xFFE8E6DF),
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
          ),
        ),
        const SizedBox(height: 16),
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

  Widget _dealPicker(bool left, DealRoom selected) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          left ? 'DEAL A' : 'DEAL B',
          style: const TextStyle(
            color: _green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _deals
              .where((deal) => deal.id != (left ? _rightId : _leftId))
              .map((deal) {
                final active = deal.id == selected.id;
                return ChoiceChip(
                  selected: active,
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: active ? Colors.white : _green,
                  ),
                  label: Text(deal.title),
                  labelStyle: TextStyle(
                    color: active ? Colors.white : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedColor: _green,
                  backgroundColor: const Color(0xFFF5F4F0),
                  side: BorderSide(
                    color: active ? _green : const Color(0xFFE2E0D9),
                  ),
                  onSelected: (_) => setState(() {
                    if (left) {
                      _leftId = deal.id;
                    } else {
                      _rightId = deal.id;
                    }
                    _focusedDocument = null;
                  }),
                );
              })
              .toList(),
        ),
      ],
    ),
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
      color: const Color(0xFFF5F4F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E2DB)),
    ),
    child: Text(
      '$label · ${value.trim().isEmpty ? 'Not answered' : value}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: _ink, fontSize: 13),
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
  int _step = 0;
  late String _goal;
  late String _role;
  late String _horizon;
  late String _weeklyTime;
  late String _risk;
  late String _cashFlow;
  late String _return;
  late String _limits;

  @override
  void initState() {
    super.initState();
    _goal = widget.initial.goal;
    _role = widget.initial.role;
    _horizon = widget.initial.horizon;
    _weeklyTime = widget.initial.weeklyTime;
    _risk = widget.initial.riskTolerance;
    _cashFlow = widget.initial.minimumCashFlow;
    _return = widget.initial.minimumReturn;
    _limits = widget.initial.nonNegotiables;
  }

  static const _questions = <_AnimatedQuestion>[
    _AnimatedQuestion(
      title: 'What kind of win are you buying?',
      detail: 'Choose the deal outcome that matters most to you.',
      icon: Icons.flag_outlined,
      options: [
        (
          'Long-term profit and independence',
          'Build durable wealth and keep the business.',
        ),
        (
          'Short-term improvement and resale',
          'Improve operations, then sell on a shorter horizon.',
        ),
        (
          'Reliable personal income',
          'Prioritize steady cash flow over aggressive growth.',
        ),
        (
          'Strategic add-on acquisition',
          'Add capabilities or customers to an existing company.',
        ),
      ],
    ),
    _AnimatedQuestion(
      title: 'How should the right deal run?',
      detail: 'Picture your role after the handover is complete.',
      icon: Icons.groups_2_outlined,
      options: [
        ('Run it myself', 'You lead the operation and make daily decisions.'),
        (
          'Oversee a hired manager',
          'A manager runs the team while you steer performance.',
        ),
        (
          'Mostly passive ownership',
          'The business operates with limited weekly involvement.',
        ),
        (
          'Transition from operator to manager',
          'Start hands-on, then replace yourself over time.',
        ),
      ],
    ),
    _AnimatedQuestion(
      title: 'How long should this deal stay in your portfolio?',
      detail: 'Your holding period changes which risks and returns matter.',
      icon: Icons.calendar_month_outlined,
      options: [
        ('Long term · 10+ years', 'Optimize for resilience and compounding.'),
        ('Medium term · 5–10 years', 'Balance cash flow with a future exit.'),
        (
          'Short term · under 5 years',
          'Prioritize a clear improvement and resale plan.',
        ),
        ('Not sure yet', 'Keep the exit timeline flexible.'),
      ],
    ),
    _AnimatedQuestion(
      title: 'How much of your week can the deal use?',
      detail: 'Choose the operating demand that fits your real life.',
      icon: Icons.schedule_outlined,
      options: [
        ('Full time · 40+ hours', 'You can be the full-time operator.'),
        (
          'Active oversight · 15–30 hours',
          'You can lead priorities and review execution.',
        ),
        (
          'Light oversight · under 10 hours',
          'The team must handle most operating work.',
        ),
        (
          'Manager-led from day one',
          'A capable manager must already be in place.',
        ),
      ],
    ),
    _AnimatedQuestion(
      title: 'What annual cash flow makes a deal worthwhile?',
      detail: 'Use cash remaining after a fair owner or manager salary.',
      icon: Icons.payments_outlined,
      options: [
        (r'$75,000', 'A smaller, accessible acquisition target.'),
        (r'$125,000', 'Meaningful income with room to reinvest.'),
        (r'$200,000', 'A stronger earnings floor for the acquisition.'),
        (r'$300,000', 'Focus on larger, established cash-flow businesses.'),
      ],
    ),
    _AnimatedQuestion(
      title: 'What return should your invested equity earn?',
      detail: 'Set the minimum annual return you want the deal to support.',
      icon: Icons.trending_up_rounded,
      options: [
        ('15%', 'A lower return threshold for a stable deal.'),
        ('20%', 'A balanced return target.'),
        ('25%', 'A stronger return hurdle.'),
        ('30%', 'Only advance high-return opportunities.'),
      ],
    ),
    _AnimatedQuestion(
      title: 'Which deal risk feels right?',
      detail: 'Choose the amount of uncertainty you are prepared to manage.',
      icon: Icons.shield_outlined,
      options: [
        (
          'Stable and proven only',
          'Predictable history and limited operational repair.',
        ),
        (
          'Balanced risk and growth',
          'Some upside and manageable execution risk.',
        ),
        (
          'Open to a turnaround',
          'You will accept complexity for greater upside.',
        ),
        ('Not sure yet', 'Let the evidence guide the risk decision.'),
      ],
    ),
    _AnimatedQuestion(
      title: 'What must the winning deal have?',
      detail: 'Pick the non-negotiable that should eliminate a poor fit.',
      icon: Icons.rule_folder_outlined,
      options: [
        (
          'Manager already in place',
          'The company cannot depend on you as daily operator.',
        ),
        (
          'Recurring or repeat revenue',
          'Revenue quality matters more than one-off sales.',
        ),
        (
          'Low seller dependence',
          'Customers and decisions must transfer cleanly.',
        ),
        (
          'No turnaround required',
          'The company must be healthy before acquisition.',
        ),
      ],
    ),
  ];

  String get _answer => switch (_step) {
    0 => _goal,
    1 => _role,
    2 => _horizon,
    3 => _weeklyTime,
    4 => _cashFlow,
    5 => _return,
    6 => _risk,
    _ => _limits,
  };

  void _setAnswer(String value) {
    setState(() {
      switch (_step) {
        case 0:
          _goal = value;
        case 1:
          _role = value;
        case 2:
          _horizon = value;
        case 3:
          _weeklyTime = value;
        case 4:
          _cashFlow = value;
        case 5:
          _return = value;
        case 6:
          _risk = value;
        case 7:
          _limits = value;
      }
    });
  }

  BuyerComparisonProfile get _result => BuyerComparisonProfile(
    goal: _goal,
    role: _role,
    horizon: _horizon,
    weeklyTime: _weeklyTime,
    minimumCashFlow: _cashFlow,
    minimumReturn: _return,
    riskTolerance: _risk,
    nonNegotiables: _limits,
  );

  @override
  Widget build(BuildContext context) {
    final question = _questions[_step];
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 12 : 28),
      backgroundColor: const Color(0xFFF7F6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(compact ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'BUILD YOUR BUYER PROFILE',
                    style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_step + 1} OF 8',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close questionnaire',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 8,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE2E0D9),
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(question.icon, color: _green, size: 34),
                        const SizedBox(height: 14),
                        Text(
                          question.title,
                          style: TextStyle(
                            color: _ink,
                            fontSize: compact ? 27 : 34,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.detail,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, box) {
                            final width = box.maxWidth < 620
                                ? box.maxWidth
                                : (box.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: question.options.map((option) {
                                final selected = _answer == option.$1;
                                return SizedBox(
                                  width: width,
                                  child: _AnswerCard(
                                    title: option.$1,
                                    detail: option.$2,
                                    selected: selected,
                                    onTap: () => _setAnswer(option.$1),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_step > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('BACK'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _answer.isEmpty
                        ? null
                        : () {
                            if (_step < 7) {
                              setState(() => _step++);
                            } else {
                              Navigator.pop(context, _result);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 17,
                      ),
                    ),
                    label: Text(_step == 7 ? 'SAVE MY PROFILE' : 'NEXT'),
                    icon: Icon(
                      _step == 7
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
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

class _AnimatedQuestion {
  const _AnimatedQuestion({
    required this.title,
    required this.detail,
    required this.icon,
    required this.options,
  });
  final String title;
  final String detail;
  final IconData icon;
  final List<(String, String)> options;
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 114),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5F4ED) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _green : _line,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1A086B4C),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? _green : const Color(0xFFF0EEE8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                color: selected ? Colors.white : _muted,
                size: 18,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
