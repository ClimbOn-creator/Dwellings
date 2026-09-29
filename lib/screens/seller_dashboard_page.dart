import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/platform_side.dart';
import '../models/seller_workspace.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/dashboard_ui.dart';
import 'local_network_page.dart';

enum _SellerView { overview, value, plan, dealPack, team, resources }

class _SellerRole {
  const _SellerRole(this.id, this.title, this.purpose, this.firstMove);
  final String id;
  final String title;
  final String purpose;
  final String firstMove;
}

const _sellerRoles = <_SellerRole>[
  _SellerRole(
    'Transaction lead',
    'Transaction lead / broker',
    'Coordinates the process, buyer outreach, diligence and timetable.',
    'Agree on sale goals, confidentiality and who can approach buyers.',
  ),
  _SellerRole(
    'CPA / tax adviser',
    'CPA and tax adviser',
    'Reconciles earnings, tests sale structures and prepares closing numbers.',
    'Review three years of statements and discuss share versus asset sale.',
  ),
  _SellerRole(
    'Legal counsel',
    'Business sale lawyer',
    'Reviews the LOI, consents, purchase agreement and closing documents.',
    'List contracts, licences and third-party approvals that may affect a transfer.',
  ),
  _SellerRole(
    'Valuation specialist',
    'Valuation specialist',
    'Tests a defensible value range and the evidence behind it.',
    'Ask for an independent valuation before setting final expectations.',
  ),
  _SellerRole(
    'Financing adviser',
    'Financing adviser',
    'Tests buyer funding, vendor notes, holdbacks and payment risk.',
    'Map how the buyer expects to fund the price and working capital.',
  ),
  _SellerRole(
    'Operations successor',
    'Operations successor',
    'Owns the knowledge transfer and day-one operating continuity.',
    'Identify the decisions and relationships still dependent on you.',
  ),
  _SellerRole(
    'People lead',
    'People and culture lead',
    'Plans retention, employment continuity and communication timing.',
    'Identify key employees and who will speak to them at each stage.',
  ),
  _SellerRole(
    'Family adviser',
    'Family transition adviser',
    'Helps clarify roles, fairness and decision rights in a family transfer.',
    'Record expectations before transaction terms are negotiated.',
  ),
];

class _SellerResource {
  const _SellerResource(
    this.title,
    this.source,
    this.summary,
    this.url,
    this.stage, {
    this.bcOnly = false,
  });
  final String title;
  final String source;
  final String summary;
  final String url;
  final SellerStage stage;
  final bool bcOnly;
}

const _sellerResources = <_SellerResource>[
  _SellerResource(
    'Prepare your business for sale',
    'BDC',
    'A practical checklist for goals, advisers, business readiness and transfer logistics.',
    'https://www.bdc.ca/en/articles-tools/entrepreneur-toolkit/templates-business-guides/preparing-to-sell-your-business',
    SellerStage.direction,
  ),
  _SellerResource(
    'Plan your succession',
    'BDC',
    'Guides for choosing and preparing a successor and planning an owner exit.',
    'https://www.bdc.ca/en/articles-tools/change-ownership/plan-succession',
    SellerStage.direction,
  ),
  _SellerResource(
    'Selling a business',
    'Canada Revenue Agency',
    'Official overview of business numbers, payroll, GST/HST, assets and possible tax questions.',
    'https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/business-registration/maintain-business/selling-business.html',
    SellerStage.terms,
  ),
  _SellerResource(
    'Capital gains deduction',
    'Canada Revenue Agency',
    'Eligibility and reporting information to review with your tax adviser if shares may qualify.',
    'https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/about-your-tax-return/tax-return/completing-a-tax-return/deductions-credits-expenses/line-25400-capital-gains-deduction.html',
    SellerStage.terms,
  ),
  _SellerResource(
    'Employment continuity on sale',
    'Province of British Columbia',
    'B.C. employment standards guidance on continuity when all or part of a business is sold.',
    'https://www2.gov.bc.ca/gov/content/employment-business/employment-standards-advice/employment-standards/forms-resources/igm/esa-part-11-section-97',
    SellerStage.diligence,
    bcOnly: true,
  ),
  _SellerResource(
    'Sell your business and plan succession',
    'BDC',
    'A seller overview covering planning, improving value and possible sale financing.',
    'https://www.bdc.ca/en/business-transfer/selling-business',
    SellerStage.handover,
  ),
];

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  static final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static final _shortDate = DateFormat('MMM d, y');
  late String _storageKey;
  StreamSubscription<AuthState>? _authSubscription;
  final _businessController = TextEditingController();
  final Map<String, TextEditingController> _numberControllers = {};
  final Map<String, TextEditingController> _teamControllers = {};
  Future<void> _saveQueue = Future.value();
  bool _loaded = false;
  TransferPath _path = TransferPath.outsideBuyer;
  DateTime? _targetDate;
  int _handoverMonths = 3;
  final Set<String> _completedTasks = {};
  final Set<String> _readyDocuments = {};
  final Map<String, String> _teamNames = {};
  final Map<String, String> _numbers = {};
  Future<List<MarketplaceProvider>>? _linkedTeam;
  _SellerView _view = _SellerView.overview;

  @override
  void initState() {
    super.initState();
    _storageKey =
        'affinity.seller_workspace.v1.${BackendService.user?.id ?? 'guest'}';
    if (BackendService.user != null) _linkedTeam = AccountService.loadTeam();
    _authSubscription = BackendService.authChanges?.listen((_) {
      final nextKey =
          'affinity.seller_workspace.v1.${BackendService.user?.id ?? 'guest'}';
      if (!mounted || nextKey == _storageKey) return;
      setState(() {
        _storageKey = nextKey;
        _loaded = false;
        _businessController.clear();
        for (final controller in _numberControllers.values) {
          controller.clear();
        }
        for (final controller in _teamControllers.values) {
          controller.clear();
        }
        _path = TransferPath.outsideBuyer;
        _targetDate = null;
        _handoverMonths = 3;
        _completedTasks.clear();
        _readyDocuments.clear();
        _teamNames.clear();
        _numbers.clear();
        _linkedTeam = BackendService.user != null
            ? AccountService.loadTeam()
            : null;
        _view = _SellerView.overview;
      });
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _businessController.dispose();
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    for (final controller in _teamControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final key = _storageKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || key != _storageKey) return;
      final raw = prefs.getString(key);
      if (raw != null) {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          final draft = SellerWorkspaceDraft.fromJson(parsed);
          _businessController.text = draft.businessName;
          _path = draft.path;
          _targetDate = draft.targetDate;
          _handoverMonths = draft.handoverMonths;
          _completedTasks.addAll(draft.completedTasks);
          _readyDocuments.addAll(draft.readyDocuments);
          _teamNames.addAll(draft.teamNames);
          _numbers.addAll(draft.numbers);
          for (final entry in _teamControllers.entries) {
            entry.value.text = _teamNames[entry.key] ?? '';
          }
          for (final entry in _numberControllers.entries) {
            entry.value.text = _numbers[entry.key] ?? '';
          }
        }
      }
    } catch (_) {
      // A damaged local draft must not prevent access to the workspace.
    }
    if (mounted && key == _storageKey) setState(() => _loaded = true);
  }

  void _save() {
    final key = _storageKey;
    final data = jsonEncode(
      SellerWorkspaceDraft(
        businessName: _businessController.text.trim(),
        path: _path,
        targetDate: _targetDate,
        handoverMonths: _handoverMonths,
        completedTasks: Set.of(_completedTasks),
        readyDocuments: Set.of(_readyDocuments),
        teamNames: Map.of(_teamNames),
        numbers: Map.of(_numbers),
      ).toJson(),
    );
    _saveQueue = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, data);
    });
  }

  void _change(VoidCallback mutation) {
    setState(mutation);
    _save();
  }

  TextEditingController _numberController(String key) => _numberControllers
      .putIfAbsent(key, () => TextEditingController(text: _numbers[key] ?? ''));

  TextEditingController _teamController(String key) =>
      _teamControllers.putIfAbsent(
        key,
        () => TextEditingController(text: _teamNames[key] ?? ''),
      );

  double _number(String key) =>
      double.tryParse(
        (_numbers[key] ?? '').replaceAll(',', '').replaceAll(r'$', '').trim(),
      ) ??
      0;

  bool _hasNumbers(List<String> keys) => keys.every((key) {
    final value = double.tryParse(
      (_numbers[key] ?? '').replaceAll(',', '').replaceAll(r'$', '').trim(),
    );
    return value != null && value.isFinite && value >= 0;
  });

  SellerValuation get _estimate => SellerValuation(
    reportedEbitda: _number('ebitda'),
    verifiedAddbacks: _number('addbacks'),
    ownerPayInExpenses: _number('ownerPay'),
    replacementSalary: _number('replacementSalary'),
    lowMultiple: _number('lowMultiple'),
    highMultiple: _number('highMultiple'),
    tangibleAssets: _number('assets'),
    inventory: _number('inventory'),
    receivables: _number('receivables'),
    liabilities: _number('liabilities'),
    expectedPrice: _number('price'),
    vendorNote: _number('vendorNote'),
    fees: _number('fees'),
    debtPayoff: _number('debtPayoff'),
  );

  List<SellerTask> get _tasks => tasksFor(_path);
  int get _doneCount =>
      _tasks.where((t) => _completedTasks.contains(t.id)).length;
  double get _progress => _tasks.isEmpty ? 0 : _doneCount / _tasks.length;
  SellerTask? get _nextTask {
    for (final task in _tasks) {
      if (!_completedTasks.contains(task.id)) return task;
    }
    return null;
  }

  DateTime? _suggestedDate(SellerStage stage) => _targetDate?.add(
    Duration(
      days: stage == SellerStage.handover
          ? _handoverMonths * 30
          : stage.daysFromClose,
    ),
  );

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate != null && _targetDate!.isAfter(today)
          ? _targetDate!
          : today.add(const Duration(days: 180)),
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 3650)),
      helpText: 'Target transfer date',
    );
    if (selected != null) _change(() => _targetDate = selected);
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this resource.')),
      );
    }
  }

  Future<void> _openNetwork() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LocalNetworkPage(side: PlatformSide.business),
      ),
    );
    if (mounted && BackendService.user != null) {
      setState(() => _linkedTeam = AccountService.loadTeam());
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DashboardUi.theme(Theme.of(context)),
    child: Scaffold(
      backgroundColor: DashboardUi.canvas,
      appBar: AppBar(
        title: const Text('Seller dashboard'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: const [AppNavigationMenu(dark: false), SizedBox(width: 12)],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUCCESSION & TRANSFER',
                        style: TextStyle(
                          color: DashboardUi.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Your business. A clear path to its next chapter.',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: DashboardUi.ink,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Set your transfer path, build a supportable value story, prepare the evidence and guide the handover. Your plan adapts as you make decisions.',
                        style: TextStyle(
                          color: DashboardUi.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _setupCard(),
                      const SizedBox(height: 18),
                      _navigation(),
                      const SizedBox(height: 20),
                      switch (_view) {
                        _SellerView.overview => _overview(),
                        _SellerView.value => _valuation(),
                        _SellerView.plan => _plan(),
                        _SellerView.dealPack => _dealPack(),
                        _SellerView.team => _team(),
                        _SellerView.resources => _resources(),
                      },
                      const SizedBox(height: 22),
                      const Text(
                        'Draft progress is saved on this device for this account. Keep confidential records in an adviser-approved secure room, not in these summary fields. Confirm valuation, tax and legal decisions with qualified advisers.',
                        style: TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _setupCard() => DashboardUi.panel(
    child: LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 700;
        final fields = <Widget>[
          _setupField(
            'Business or project name',
            TextField(
              key: const Key('seller_business_name'),
              controller: _businessController,
              decoration: const InputDecoration(
                hintText: 'Example → Harbour Advisory',
              ),
              onChanged: (_) => _change(() {}),
            ),
          ),
          _setupField(
            'Transfer path',
            DropdownButtonFormField<TransferPath>(
              key: const Key('seller_transfer_path'),
              initialValue: _path,
              isExpanded: true,
              items: [
                for (final path in TransferPath.values)
                  DropdownMenuItem(value: path, child: Text(path.label)),
              ],
              onChanged: (path) {
                if (path != null) _change(() => _path = path);
              },
            ),
          ),
          _setupField(
            'Target transfer date',
            OutlinedButton.icon(
              key: const Key('seller_target_date'),
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _targetDate == null
                    ? 'Choose a date'
                    : _shortDate.format(_targetDate!),
              ),
            ),
          ),
          _setupField(
            'Handover support',
            DropdownButtonFormField<int>(
              key: const Key('seller_handover_months'),
              initialValue: _handoverMonths,
              items: const [1, 3, 6, 12]
                  .map(
                    (months) => DropdownMenuItem(
                      value: months,
                      child: Text(
                        '$months ${months == 1 ? 'month' : 'months'}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (months) {
                if (months != null) _change(() => _handoverMonths = months);
              },
            ),
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardUi.sectionTitle(
              'Shape your transition',
              subtitle:
                  'These choices personalize the plan and suggested dates.',
            ),
            const SizedBox(height: 15),
            if (compact)
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: field,
                ),
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final field in fields)
                    SizedBox(width: (box.maxWidth - 14) / 2, child: field),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              _path.summary,
              style: const TextStyle(
                color: DashboardUi.blue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _setupField(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 7),
      child,
    ],
  );

  Widget _navigation() {
    const entries = <(_SellerView, String, IconData)>[
      (_SellerView.overview, 'Overview', Icons.dashboard_outlined),
      (_SellerView.value, 'Calculators', Icons.calculate_outlined),
      (_SellerView.plan, 'Transaction plan', Icons.route_outlined),
      (_SellerView.dealPack, 'Deal pack', Icons.folder_copy_outlined),
      (_SellerView.team, 'My team', Icons.groups_outlined),
      (_SellerView.resources, 'Resources', Icons.menu_book_outlined),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (view, label, icon) in entries)
          ChoiceChip(
            key: Key('seller_tab_${view.name}'),
            selected: _view == view,
            onSelected: (_) => setState(() => _view = view),
            avatar: Icon(
              icon,
              size: 17,
              color: _view == view ? Colors.white : DashboardUi.blue,
            ),
            label: Text(label),
            selectedColor: DashboardUi.blue,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: _view == view ? Colors.white : DashboardUi.ink,
              fontWeight: FontWeight.w700,
            ),
            side: const BorderSide(color: DashboardUi.line),
            showCheckmark: false,
          ),
      ],
    );
  }

  Widget _overview() {
    final next = _nextTask;
    final teamCount = _teamNames.values
        .where((name) => name.trim().isNotEmpty)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth < 650
                ? (box.maxWidth - 10) / 2
                : (box.maxWidth - 30) / 4;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: DashboardUi.metric(
                    'Plan complete',
                    '${(_progress * 100).round()}%',
                    '$_doneCount of ${_tasks.length} steps',
                    Icons.checklist_rounded,
                    DashboardUi.paleBlue,
                    DashboardUi.blue,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardUi.metric(
                    'Deal pack ready',
                    '${_readyDocuments.length}/${sellerDealPack.length}',
                    'Evidence prepared',
                    Icons.folder_outlined,
                    DashboardUi.paleGreen,
                    const Color(0xFF34785A),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardUi.metric(
                    'Advisers named',
                    '$teamCount',
                    'Roles assigned',
                    Icons.groups_outlined,
                    DashboardUi.paleGold,
                    const Color(0xFF9A6A16),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DashboardUi.metric(
                    'Target transfer',
                    _targetDate == null
                        ? 'Set date'
                        : DateFormat('MMM y').format(_targetDate!),
                    'Planning target',
                    Icons.event_outlined,
                    DashboardUi.paleViolet,
                    const Color(0xFF7164A4),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        DashboardUi.panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardUi.sectionTitle(
                'Your next move',
                subtitle: next == null
                    ? 'The current plan is complete.'
                    : 'The next unfinished step in your ${_path.label.toLowerCase()} plan.',
              ),
              const SizedBox(height: 12),
              if (next != null) ...[
                Text(
                  next.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  next.detail,
                  style: const TextStyle(
                    color: DashboardUi.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Lead: ${_assignedName(next.role)} · ${next.stage.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: DashboardUi.blue,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() => _view = _SellerView.plan),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Open transaction plan'),
                ),
              ] else
                const Text(
                  'Review the handover and remaining adviser obligations before considering the transfer complete.',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashboardUi.panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardUi.sectionTitle(
                _businessController.text.trim().isEmpty
                    ? 'Your route to closing'
                    : '${_businessController.text.trim()} · route to closing',
                subtitle:
                    'Planning dates are suggestions, not legal or contractual deadlines.',
              ),
              const SizedBox(height: 15),
              for (final stage in SellerStage.values) ...[
                _stageSummary(stage),
                if (stage != SellerStage.values.last) const Divider(height: 20),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) {
            final cards = <Widget>[
              _quickAction(
                'Estimate a value range',
                'Compare maintainable earnings with your market multiples.',
                Icons.calculate_outlined,
                _SellerView.value,
              ),
              _quickAction(
                'Build your deal pack',
                'See the evidence buyers and advisers are likely to ask for.',
                Icons.folder_copy_outlined,
                _SellerView.dealPack,
              ),
              _quickAction(
                'Assign your team',
                'Give each major decision a clear lead.',
                Icons.groups_outlined,
                _SellerView.team,
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: box.maxWidth < 780
                        ? box.maxWidth
                        : (box.maxWidth - 24) / 3,
                    child: card,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _quickAction(
    String title,
    String detail,
    IconData icon,
    _SellerView view,
  ) => DashboardUi.panel(
    child: InkWell(
      onTap: () => setState(() => _view = view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DashboardUi.blue, size: 27),
          const SizedBox(height: 11),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            style: const TextStyle(
              color: DashboardUi.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Open →',
            style: TextStyle(
              color: DashboardUi.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  String _assignedName(String role) {
    final name = _teamNames[role]?.trim() ?? '';
    return name.isEmpty ? role : '$name ($role)';
  }

  Widget _stageSummary(SellerStage stage) {
    final stageTasks = _tasks.where((task) => task.stage == stage).toList();
    final done = stageTasks
        .where((task) => _completedTasks.contains(task.id))
        .length;
    final suggested = _suggestedDate(stage);
    return InkWell(
      onTap: () => setState(() => _view = _SellerView.plan),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: done == stageTasks.length
                  ? DashboardUi.paleGreen
                  : DashboardUi.paleBlue,
              child: Text(
                '${stage.index + 1}',
                style: const TextStyle(
                  color: DashboardUi.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    suggested == null
                        ? 'Set a target date for suggested timing'
                        : 'Suggested around ${_shortDate.format(suggested)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: DashboardUi.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$done/${stageTasks.length}',
              style: const TextStyle(
                color: DashboardUi.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: DashboardUi.muted),
          ],
        ),
      ),
    );
  }

  Widget _valuation() {
    final estimate = _estimate;
    final earningsComplete = _hasNumbers(const [
      'ebitda',
      'addbacks',
      'ownerPay',
      'replacementSalary',
      'lowMultiple',
      'highMultiple',
    ]);
    final assetsComplete = _hasNumbers(const [
      'assets',
      'inventory',
      'receivables',
      'liabilities',
    ]);
    final proceedsComplete = _hasNumbers(const [
      'price',
      'vendorNote',
      'fees',
      'debtPayoff',
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(
          'Seller calculators',
          subtitle:
              'Three connected views: earnings value, asset reference and cash at closing.',
        ),
        const SizedBox(height: 14),
        _calculatorPanel(
          '1 · Business value range',
          'Use verified earnings and comparable market multiples. The range is an estimate, not an appraisal.',
          [
            _numberField(
              'ebitda',
              'Reported annual EBITDA',
              '260,000',
              'Annual earnings before interest, tax, depreciation and amortization.',
            ),
            _numberField(
              'addbacks',
              'Verified add-backs',
              '20,000',
              'Documented costs that will not recur for a new owner. Enter 0 if none.',
            ),
            _numberField(
              'ownerPay',
              'Owner pay in expenses',
              '80,000',
              'Your salary and benefits already deducted in reported EBITDA. Enter 0 if EBITDA excludes it.',
            ),
            _numberField(
              'replacementSalary',
              'Replacement leader pay',
              '95,000',
              'Annual cost for someone else to perform your operating role.',
            ),
            _numberField(
              'lowMultiple',
              'Low comparable multiple',
              '3',
              'Lower EBITDA multiple supported by similar business sales.',
            ),
            _numberField(
              'highMultiple',
              'High comparable multiple',
              '5',
              'Upper EBITDA multiple supported by similar business sales.',
            ),
          ],
          earningsComplete && estimate.earningsReady
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _result(
                      'Maintainable EBITDA',
                      _money.format(estimate.maintainableEbitda),
                    ),
                    const SizedBox(height: 12),
                    _result(
                      'Indicative enterprise value',
                      '${_money.format(estimate.lowEnterpriseValue)} – ${_money.format(estimate.highEnterpriseValue)}',
                      prominent: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enterprise value excludes cash, debt and negotiated working-capital adjustments.',
                      style: TextStyle(fontSize: 12, color: DashboardUi.muted),
                    ),
                  ],
                )
              : _waiting('Enter all earnings assumptions to see a range.'),
        ),
        const SizedBox(height: 15),
        _calculatorPanel(
          '2 · Asset reference',
          'A separate view of included assets and liabilities. It does not add to the earnings value automatically.',
          [
            _numberField(
              'assets',
              'Equipment and other tangible assets',
              '500,000',
              'Supportable market value of included physical assets.',
            ),
            _numberField(
              'inventory',
              'Saleable inventory',
              '180,000',
              'Usable stock included in the proposed transaction.',
            ),
            _numberField(
              'receivables',
              'Collectible receivables',
              '120,000',
              'Customer balances expected to transfer and be collected.',
            ),
            _numberField(
              'liabilities',
              'Liabilities to be assumed',
              '150,000',
              'Debt and obligations the buyer would take over.',
            ),
          ],
          assetsComplete && estimate.assetsReady
              ? _result(
                  'Net asset reference',
                  _money.format(estimate.netAssetReference),
                  prominent: true,
                )
              : _waiting('Enter the included assets and assumed liabilities.'),
        ),
        const SizedBox(height: 15),
        _calculatorPanel(
          '3 · Cash at closing',
          'Test how deferred payments, fees and debt repayment change the cash you receive at closing.',
          [
            _numberField(
              'price',
              'Expected sale price',
              '1,200,000',
              'The agreed or proposed gross price before closing adjustments.',
            ),
            _numberField(
              'vendorNote',
              'Vendor financing / deferred amount',
              '150,000',
              'Part of the price paid after closing. Enter 0 if none.',
            ),
            _numberField(
              'fees',
              'Selling and closing fees',
              '45,000',
              'Broker, legal, valuation and other transaction fees. Enter 0 if none.',
            ),
            _numberField(
              'debtPayoff',
              'Debt paid at closing',
              '250,000',
              'Business debt discharged from sale proceeds. Enter 0 if none.',
            ),
          ],
          proceedsComplete && estimate.proceedsReady
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _result(
                      'Cash at closing, before tax',
                      _money.format(estimate.cashAtCloseBeforeTax),
                      prominent: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Excludes tax, working-capital true-ups, escrow, holdbacks and earn-outs. Ask your CPA and lawyer to model your actual structure.',
                      style: TextStyle(
                        color: DashboardUi.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                )
              : _waiting(
                  proceedsComplete
                      ? 'The deferred amount cannot exceed the sale price.'
                      : 'Enter price and payment assumptions, using 0 where none apply.',
                ),
        ),
      ],
    );
  }

  Widget _calculatorPanel(
    String title,
    String description,
    List<Widget> fields,
    Widget result,
  ) => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(title, subtitle: description),
        const SizedBox(height: 17),
        LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 800) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _fieldGrid(fields, box.maxWidth),
                  const SizedBox(height: 10),
                  Container(
                    key: const Key('seller_calculator_result'),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: DashboardUi.paleBlue,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: result,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _fieldGrid(fields, (box.maxWidth - 18) * 3 / 5),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DashboardUi.paleBlue,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: result,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _fieldGrid(List<Widget> fields, double width) => Wrap(
    spacing: 12,
    runSpacing: 2,
    children: [
      for (final field in fields)
        SizedBox(width: width < 530 ? width : (width - 12) / 2, child: field),
    ],
  );

  Widget _numberField(String key, String label, String example, String help) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message: help,
                  child: const Icon(
                    Icons.info_rounded,
                    size: 17,
                    color: Color(0xFF0AA9F4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: Key('seller_$key'),
              controller: _numberController(key),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Example → $example',
                hintStyle: const TextStyle(color: Color(0xFF8796AB)),
              ),
              onChanged: (value) => _change(() => _numbers[key] = value),
            ),
          ],
        ),
      );

  Widget _waiting(String message) => Text(
    message,
    style: const TextStyle(color: DashboardUi.muted, height: 1.5),
  );

  Widget _result(String label, String value, {bool prominent = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DashboardUi.blue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: prominent ? 24 : 19,
              fontWeight: FontWeight.w900,
              color: DashboardUi.ink,
            ),
          ),
        ],
      );

  Widget _plan() {
    final nextStage = _nextTask?.stage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(
          'Your transaction plan',
          subtitle:
              '${_tasks.length} steps tailored to ${_path.label.toLowerCase()}, with $_handoverMonths months of handover support. Mark work complete as your advisers confirm it.',
        ),
        const SizedBox(height: 12),
        DashboardUi.panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 9),
              Text(
                '$_doneCount of ${_tasks.length} steps complete · ${(_progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Suggested dates help sequence work. Confirm real deadlines in your agreements.',
                style: TextStyle(color: DashboardUi.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        for (final stage in SellerStage.values) ...[
          DashboardUi.panel(
            child: Material(
              color: Colors.transparent,
              child: _stagePlan(stage, initiallyExpanded: stage == nextStage),
            ),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _stagePlan(SellerStage stage, {required bool initiallyExpanded}) {
    final stageTasks = _tasks.where((task) => task.stage == stage).toList();
    final done = stageTasks
        .where((task) => _completedTasks.contains(task.id))
        .length;
    final suggested = _suggestedDate(stage);
    return ExpansionTile(
      key: PageStorageKey('seller_stage_${stage.name}'),
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        '${stage.index + 1}. ${stage.label}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        suggested == null
            ? '$done of ${stageTasks.length} complete'
            : '$done of ${stageTasks.length} complete · plan around ${_shortDate.format(suggested)}',
        style: const TextStyle(fontSize: 12, color: DashboardUi.muted),
      ),
      children: [
        for (final task in stageTasks)
          CheckboxListTile(
            key: Key('seller_task_${task.id}'),
            value: _completedTasks.contains(task.id),
            onChanged: (done) => _change(() {
              if (done == true) {
                _completedTasks.add(task.id);
              } else {
                _completedTasks.remove(task.id);
              }
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.detail, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  'Lead: ${_assignedName(task.role)}',
                  style: const TextStyle(color: DashboardUi.blue, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dealPack() {
    const groups = ['Financial', 'Legal', 'People', 'Operations', 'Transfer'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(
          'Deal pack',
          subtitle:
              'Prepare evidence before a buyer asks. Mark an item ready only after an adviser has reviewed it.',
        ),
        const SizedBox(height: 12),
        DashboardUi.panel(
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: DashboardUi.blue),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'This is a preparation tracker. It does not upload or share files. Use a secure room approved by your advisers for confidential records.',
                  style: TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        for (final group in groups) ...[
          DashboardUi.panel(
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: PageStorageKey('seller_pack_$group'),
                initiallyExpanded: group == 'Financial',
                tilePadding: EdgeInsets.zero,
                title: Text(
                  group,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${sellerDealPack.where((item) => item.group == group && _readyDocuments.contains(item.id)).length} of ${sellerDealPack.where((item) => item.group == group).length} ready',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashboardUi.muted,
                  ),
                ),
                children: [
                  for (final item in sellerDealPack.where(
                    (item) => item.group == group,
                  ))
                    CheckboxListTile(
                      key: Key('seller_pack_${item.id}'),
                      value: _readyDocuments.contains(item.id),
                      onChanged: (ready) => _change(() {
                        if (ready == true) {
                          _readyDocuments.add(item.id);
                        } else {
                          _readyDocuments.remove(item.id);
                        }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(item.detail),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _team() {
    final roles = _sellerRoles
        .where(
          (role) => role.id != 'Family adviser' || _path == TransferPath.family,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardUi.sectionTitle(
          'Your transfer team',
          subtitle:
              'Name the person leading each role. Their name then appears beside relevant plan steps.',
        ),
        const SizedBox(height: 13),
        DashboardUi.panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardUi.sectionTitle(
                'Connected professionals',
                subtitle:
                    'Browse the Affinity network or review providers already saved to your account.',
              ),
              const SizedBox(height: 10),
              if (_linkedTeam != null)
                FutureBuilder<List<MarketplaceProvider>>(
                  future: _linkedTeam,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Could not load saved professionals right now.',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Text(
                        'No professionals saved to your account yet.',
                        style: TextStyle(color: DashboardUi.muted),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final provider in snapshot.data!)
                          Chip(
                            label: Text(
                              '${provider.name} · ${provider.specialty}',
                            ),
                          ),
                      ],
                    );
                  },
                )
              else
                const Text(
                  'Your role assignments below are saved on this device. Sign in to save professionals from the network to your account.',
                  style: TextStyle(color: DashboardUi.muted, height: 1.4),
                ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: _openNetwork,
                icon: const Icon(Icons.people_outline_rounded),
                label: const Text('Browse professional network'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final role in roles)
                SizedBox(
                  width: box.maxWidth < 760
                      ? box.maxWidth
                      : (box.maxWidth - 12) / 2,
                  child: DashboardUi.panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          role.purpose,
                          style: const TextStyle(
                            color: DashboardUi.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          key: Key('seller_team_${role.id}'),
                          controller: _teamController(role.id),
                          decoration: const InputDecoration(
                            labelText: 'Adviser or lead name',
                            hintText: 'Add a name when appointed',
                          ),
                          onChanged: (name) =>
                              _change(() => _teamNames[role.id] = name),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          'First move: ${role.firstMove}',
                          style: const TextStyle(fontSize: 12, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resources() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DashboardUi.sectionTitle(
        'Trusted resources',
        subtitle:
            'Official Canadian guidance to bring into conversations with your advisers.',
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, box) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final resource in _sellerResources)
              SizedBox(
                width: box.maxWidth < 760
                    ? box.maxWidth
                    : (box.maxWidth - 12) / 2,
                child: DashboardUi.panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.stage.label.toUpperCase(),
                        style: const TextStyle(
                          color: DashboardUi.blue,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        resource.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${resource.source}${resource.bcOnly ? ' · B.C. only' : ''}',
                        style: const TextStyle(
                          color: DashboardUi.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resource.summary,
                        style: const TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 11),
                      TextButton.icon(
                        onPressed: () => _openResource(resource.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: const Text('Open official resource'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
