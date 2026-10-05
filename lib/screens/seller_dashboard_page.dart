import '../widgets/nova_target.dart';
import '../widgets/nova_panel.dart';
import '../services/nova_service.dart';
import '../widgets/team_workspace.dart';
import '../widgets/team_member_portrait.dart';
import 'buyer_resources_page.dart';
import 'page_flow.dart';
import 'bulletin_listing_pages.dart';
import 'deal_rooms_page.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/platform_side.dart';
import '../models/seller_workspace.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/dashboard_ui.dart';
import '../widgets/home_brand_button.dart';
import 'auth_page.dart';
import 'member_deal_marketplace_page.dart';
import 'member_profile_page.dart';

enum SellerDashboardView {
  overview,
  value,
  plan,
  dealPack,
  resources,
  team,
  settings,
}

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({
    super.key,
    this.initialView = SellerDashboardView.overview,
    this.learning = false,
  });
  final SellerDashboardView initialView;
  final bool learning;

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
  String _pipelineQuery = '';
  String? _resourceBusyId;
  SellerDashboardView _view = SellerDashboardView.overview;
  late bool _learning;

  @override
  void initState() {
    super.initState();
    _view = switch (widget.initialView) {
      SellerDashboardView.settings ||
      SellerDashboardView.dealPack => SellerDashboardView.plan,
      _ => widget.initialView,
    };
    _learning = widget.learning;
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
        _resourceBusyId = null;
        _view = SellerDashboardView.overview;
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

  void _showView(SellerDashboardView view) {
    setState(() {
      _view = switch (view) {
        SellerDashboardView.settings ||
        SellerDashboardView.dealPack => SellerDashboardView.plan,
        _ => view,
      };
      if (view == SellerDashboardView.overview) _learning = false;
    });
  }

  Future<void> _openProvider(MarketplaceProvider provider) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfilePage(
          provider: provider,
          messageDestinationBuilder: provider.isExample
              ? null
              : (_) => MemberDealMarketplacePage(initialChatProvider: provider),
        ),
      ),
    );
    if (mounted && BackendService.user != null) {
      setState(() => _linkedTeam = AccountService.loadTeam());
    }
  }

  Future<void> _saveProvider(MarketplaceProvider provider, bool saved) async {
    if (provider.isExample || _resourceBusyId != null) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    setState(() => _resourceBusyId = provider.id);
    try {
      if (saved) {
        await MarketplaceService.removeFromTeam(provider.id);
      } else {
        await MarketplaceService.addToTeam(provider);
      }
      if (mounted) setState(() => _linkedTeam = AccountService.loadTeam());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update your team. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resourceBusyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DashboardUi.theme(Theme.of(context)),
    child: Scaffold(
      backgroundColor: DashboardUi.canvas,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF7F5F0),
        surfaceTintColor: Colors.transparent,
        foregroundColor: DashboardUi.ink,
        title: MediaQuery.sizeOf(context).width < 700
            ? const HomeBrandButton(size: 48, dark: false)
            : const Row(
                children: [
                  HomeBrandButton(size: 48, dark: false),
                  SizedBox(width: 18),
                  Text(
                    'DEAL OS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
        actions: const [
          AppNavigationMenu(side: PlatformSide.business, dark: false),
          SizedBox(width: 12),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, box) => box.maxWidth >= 800
                  ? Row(
                      children: [
                        NovaTarget(id: 'seller.workspace', child: _sidebar()),
                        const VerticalDivider(
                          width: 1,
                          color: DashboardUi.line,
                        ),
                        Expanded(child: _workspace(compact: false)),
                      ],
                    )
                  : _workspace(compact: true),
            ),
    ),
  );

  static const _views = <(SellerDashboardView, String, IconData)>[
    (SellerDashboardView.overview, 'Home', Icons.home_outlined),
    (SellerDashboardView.value, 'Deal screen', Icons.calculate_outlined),
    (SellerDashboardView.resources, 'Resources', Icons.library_books_outlined),
    (SellerDashboardView.team, 'My team', Icons.groups_outlined),
    (SellerDashboardView.plan, 'Transaction plan', Icons.event_note_outlined),
  ];

  Widget _sidebar() => Container(
    width: 212,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(13, 24, 13, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(13, 0, 0, 17),
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      color: DashboardUi.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                for (final (view, label, icon) in _views) ...[
                  KeyedSubtree(
                    key: Key('seller_tab_${view.name}'),
                    child: DashboardUi.nav(
                      label,
                      icon,
                      _view == view,
                      () => _showView(view),
                    ),
                  ),
                  if (view == SellerDashboardView.overview)
                    DashboardUi.nav(
                      'Pipeline',
                      Icons.view_kanban_outlined,
                      _view == SellerDashboardView.overview,
                      () => _showView(SellerDashboardView.overview),
                    ),
                ],
              ],
            ),
          ),
        ),
        DashboardUi.nav(
          'Deal workspaces',
          Icons.folder_open,
          false,
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const DealRoomsPage(initialSide: PlatformSide.business),
            ),
          ),
        ),
        DashboardUi.nav('Refresh', Icons.refresh_rounded, false, () {
          setState(() {
            if (BackendService.user != null) {
              _linkedTeam = AccountService.loadTeam();
            }
          });
        }),
      ],
    ),
  );

  Widget _workspace({required bool compact}) => Column(
    children: [
      if (compact) _navigation(),
      Expanded(
        child: _view == SellerDashboardView.team
            ? TeamWorkspace(
                seller: true,
                onChanged: () {
                  if (mounted && BackendService.user != null)
                    setState(() => _linkedTeam = AccountService.loadTeam());
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _view == SellerDashboardView.overview
                          ? double.infinity
                          : 1220,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_view != SellerDashboardView.overview) ...[
                          _viewHeader(),
                          const SizedBox(height: 24),
                        ],
                        NovaPanel(
                          key: ValueKey('nova.seller.${_view.name}'),
                          context: _novaContext(),
                          contextProvider: _novaContext,
                          tourRole: 'seller',
                          onTourNavigate: (destination) => _showView(
                            SellerDashboardView.values.firstWhere(
                              (v) => v.name == destination,
                            ),
                          ),
                        ),
                        switch (_view) {
                          SellerDashboardView.overview => _overview(),
                          SellerDashboardView.value => _valuation(),
                          SellerDashboardView.plan => _plan(),
                          SellerDashboardView.dealPack => _plan(),
                          SellerDashboardView.resources =>
                            const BuyerResourcesPanel(),
                          SellerDashboardView.team => const SizedBox.shrink(),
                          SellerDashboardView.settings => _plan(),
                        },
                        const SizedBox(height: 24),
                        _nextPageAction(),
                        const SizedBox(height: 16),
                        const Text(
                          'Draft progress is saved on this device for this account. Keep confidential records in an adviser-approved secure room. Confirm valuation, tax and legal decisions with qualified advisers.',
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
    ],
  );

  NovaContext _novaContext() => NovaContext(
    area: 'seller',
    label: _businessController.text.trim().isEmpty
        ? 'Seller workspace'
        : _businessController.text.trim(),
    lesson: _view == SellerDashboardView.resources ? 'resources' : 'seller',
    facts: {
      'view': _view.name,
      'transferPath': _path.name,
      'targetCloseDate': _targetDate?.toIso8601String(),
      'handoverMonths': _handoverMonths,
      'figures': {
        for (final e in _numberControllers.entries) e.key: e.value.text,
      },
      'completedTasks': _completedTasks.toList(),
      'documentsMarkedReady': _readyDocuments.toList(),
      'progressStoredOnDevice': true,
    },
  );

  Widget _nextPageAction() {
    if (_view == SellerDashboardView.overview)
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => startSellerLearning(context),
          child: const Text(
            'New to selling or succession? Start with your goals',
          ),
        ),
      );
    if (_view == SellerDashboardView.plan && !_learning)
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Next: create business listing'),
          onPressed: () async {
            if (BackendService.user == null) {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
              if (!mounted || BackendService.user == null) return;
            }
            final id = await Navigator.of(context).push<String>(
              MaterialPageRoute<String>(
                builder: (_) => const BulletinListingEditor(),
              ),
            );
            if (id != null && mounted)
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessListingDetailPage(bulletinId: id),
                ),
              );
          },
        ),
      );
    final next = switch (_view) {
      SellerDashboardView.plan => SellerDashboardView.value,
      SellerDashboardView.settings => SellerDashboardView.value,
      SellerDashboardView.value =>
        _learning ? SellerDashboardView.resources : SellerDashboardView.plan,
      SellerDashboardView.resources => SellerDashboardView.overview,
      SellerDashboardView.team => SellerDashboardView.plan,
      _ => SellerDashboardView.plan,
    };
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: () => _showView(next),
        icon: const Icon(Icons.arrow_forward),
        label: Text(switch (next) {
          SellerDashboardView.value => 'Next: pricing calculators',
          SellerDashboardView.resources => 'Next: government programs',
          SellerDashboardView.overview => 'Continue to seller dashboard',
          SellerDashboardView.plan => 'Next: transaction plan',
          _ => 'Next: transaction plan',
        }),
      ),
    );
  }

  Widget _viewHeader() {
    final (title, subtitle) = switch (_view) {
      SellerDashboardView.overview => (
        _businessController.text.trim().isEmpty
            ? 'Your business, next chapter.'
            : '${_businessController.text.trim()}, next chapter.',
        'Keep your transfer moving, one clear decision at a time.',
      ),
      SellerDashboardView.value => (
        'Seller deal screen',
        'Explore value, assets and closing cash with your own figures.',
      ),
      SellerDashboardView.plan => (
        'Transaction plan',
        'A path-specific plan with owners, milestones and suggested dates.',
      ),
      SellerDashboardView.dealPack => (
        'Documents & preparation',
        'Know what to prepare before your advisers open a secure room.',
      ),
      SellerDashboardView.resources => (
        'Resources',
        'Explore government programs, grants and community support.',
      ),
      SellerDashboardView.team => (
        'My team',
        'Keep the right people close and give each decision a lead.',
      ),
      SellerDashboardView.settings => (
        'Transaction plan',
        'A few choices tailor your plan and planning dates.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUCCESSION & TRANSFER',
          style: TextStyle(
            color: DashboardUi.blue,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: DashboardUi.ink,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: DashboardUi.muted)),
      ],
    );
  }

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

  Widget _navigation() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (view, label, icon) in _views)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('seller_tab_${view.name}'),
                selected: _view == view,
                onSelected: (_) => _showView(view),
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
            ),
        ],
      ),
    ),
  );

  Widget _overview() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name = _businessController.text.trim();
    final active = name.isNotEmpty;
    final next = _nextTask;
    final stage = next?.stage ?? SellerStage.handover;
    final column = switch (stage) {
      SellerStage.direction || SellerStage.prepare => 0,
      SellerStage.successor => 1,
      SellerStage.terms || SellerStage.diligence => 2,
      SellerStage.closing || SellerStage.handover => 3,
    };
    final visible =
        active &&
        name.toLowerCase().contains(_pipelineQuery.trim().toLowerCase());
    final now = DateTime.now();
    final dueSoon = _tasks.where((task) {
      final date = _suggestedDate(task.stage);
      return active &&
          !_completedTasks.contains(task.id) &&
          date != null &&
          !date.isBefore(DateTime(now.year, now.month, now.day)) &&
          date.isBefore(now.add(const Duration(days: 8)));
    }).length;
    final overdue = _tasks.where((task) {
      final date = _suggestedDate(task.stage);
      return active &&
          !_completedTasks.contains(task.id) &&
          date != null &&
          date.isBefore(DateTime(now.year, now.month, now.day));
    }).length;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 740;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting 👋',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Keep every transfer moving.',
              style: TextStyle(color: DashboardUi.muted),
            ),
          ],
        );
        final search = TextFormField(
          initialValue: _pipelineQuery,
          key: const Key('seller_pipeline_search'),
          onChanged: (value) => setState(() => _pipelineQuery = value),
          decoration: InputDecoration(
            hintText: 'Search your transfers...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DashboardUi.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DashboardUi.line),
            ),
          ),
        );
        final metricWidth = narrow
            ? (box.maxWidth - 12) / 2
            : (box.maxWidth - 36) / 4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              heading,
              const SizedBox(height: 17),
              search,
            ] else
              Row(
                children: [
                  Expanded(child: heading),
                  SizedBox(width: 255, child: search),
                ],
              ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: metricWidth,
                  child: DashboardUi.metric(
                    'Active transfers',
                    active ? '1' : '0',
                    'In your pipeline',
                    Icons.bar_chart_rounded,
                    DashboardUi.paleBlue,
                    const Color(0xFF5F91DC),
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: DashboardUi.metric(
                    'Plan complete',
                    '${(_progress * 100).round()}%',
                    '$_doneCount of ${_tasks.length} steps',
                    Icons.trending_up_rounded,
                    DashboardUi.paleGreen,
                    const Color(0xFF3C9764),
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: DashboardUi.metric(
                    'Due soon',
                    '$dueSoon',
                    'Next 7 days',
                    Icons.event_note_outlined,
                    DashboardUi.paleGold,
                    const Color(0xFFB88016),
                  ),
                ),
                SizedBox(
                  width: metricWidth,
                  child: DashboardUi.metric(
                    'Needs attention',
                    '$overdue',
                    'Past suggested dates',
                    Icons.notifications_active_outlined,
                    DashboardUi.paleViolet,
                    const Color(0xFF8A79D5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DashboardUi.panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DashboardUi.sectionTitle(
                          'Your pipeline',
                          subtitle:
                              'Follow your transfer from preparation to handover.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showView(SellerDashboardView.plan),
                        child: Text(active ? 'Edit plan' : 'Set up plan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(4, (index) {
                        const titles = [
                          'Preparation',
                          'Successor search',
                          'Terms / diligence',
                          'Closing / handover',
                        ];
                        final hasTransfer = visible && column == index;
                        return Container(
                          key: Key('seller_pipeline_column_$index'),
                          width: narrow ? 214 : (box.maxWidth - 78) / 4,
                          constraints: const BoxConstraints(minWidth: 185),
                          margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(3, 2, 3, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        titles[index],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      hasTransfer ? '1' : '0',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: DashboardUi.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!hasTransfer)
                                const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    'No transfers here yet',
                                    style: TextStyle(
                                      color: DashboardUi.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              else
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () =>
                                        _showView(SellerDashboardView.plan),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            _path.label,
                                            style: const TextStyle(
                                              color: DashboardUi.muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            next?.title ?? 'Plan complete',
                                            style: const TextStyle(
                                              color: DashboardUi.blue,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showView(SellerDashboardView.resources),
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Resources — grants & government programs'),
            ),
            const SizedBox(height: 16),
            _overviewTeam(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: narrow ? box.maxWidth : (box.maxWidth - 12) / 2,
                  child: _quickAction(
                    'Deal screen',
                    'Explore business value, assets and cash at closing.',
                    Icons.calculate_outlined,
                    SellerDashboardView.value,
                  ),
                ),
                SizedBox(
                  width: narrow ? box.maxWidth : (box.maxWidth - 12) / 2,
                  child: _quickAction(
                    'Transaction plan',
                    'Schedule and complete your transfer checklist. 📅',
                    Icons.event_note_outlined,
                    SellerDashboardView.plan,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _overviewTeam() => DashboardUi.panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardUi.sectionTitle(
                'My personal team',
                subtitle: 'Your advisers, available throughout your transfer.',
              ),
            ),
            TextButton(
              onPressed: () => _showView(SellerDashboardView.team),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MarketplaceProvider>>(
          future: _linkedTeam,
          builder: (context, snapshot) {
            final team = snapshot.data ?? const <MarketplaceProvider>[];
            if (snapshot.hasError) {
              return const Text(
                'Could not load your team. Use Refresh to try again.',
                style: TextStyle(color: DashboardUi.muted, fontSize: 11),
              );
            }
            if (_linkedTeam != null && !snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            if (team.isEmpty) {
              return const Text(
                'Add professionals to build your transfer team.',
                style: TextStyle(color: DashboardUi.muted, fontSize: 11),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final provider in team)
                  SizedBox(
                    width: 160,
                    child: TeamMemberPortrait(
                      provider: provider,
                      selected: true,
                      busy: _resourceBusyId == provider.id,
                      onProfile: () => _openProvider(provider),
                      onToggle: _resourceBusyId == null
                          ? () => _saveProvider(provider, true)
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _quickAction(
    String title,
    String detail,
    IconData icon,
    SellerDashboardView view,
  ) => DashboardUi.panel(
    child: InkWell(
      onTap: () => _showView(view),
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
        const SizedBox(height: 16),
        _setupCard(),
        const SizedBox(height: 16),
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
        const SizedBox(height: 20),
        _dealPack(),
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
          'Documents & preparation',
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
}
