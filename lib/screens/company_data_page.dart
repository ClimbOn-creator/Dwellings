import '../widgets/affinity_button_gradients.dart';
import '../widgets/home_brand_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';
import '../services/company_data_service.dart';
import '../models/company_dataset.dart';
import '../widgets/company_data_chart.dart';
import 'auth_page.dart';

const _green = dataMint;
const _panel = Color(0xFF151E2A);
const _canvas = Color(0xFF0C121C);
const _line = Color(0xFF283547);

class CompanyDataPage extends StatefulWidget {
  const CompanyDataPage({super.key});
  @override
  State<CompanyDataPage> createState() => _CompanyDataPageState();
}

class _CompanyDataPageState extends State<CompanyDataPage> {
  StreamSubscription<dynamic>? _auth;
  Timer? _timer;
  CompanyDataReport? _report;
  bool _allowed = false, _loading = true, _error = false;
  int _days = 90, _generation = 0;
  @override
  void initState() {
    super.initState();
    _reload();
    _auth = BackendService.authChanges?.listen((_) {
      // Clear the previous owner's payload synchronously on any session change.
      setState(() {
        _allowed = false;
        _report = null;
        _loading = true;
      });
      _reload();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _reload());
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final user = BackendService.user?.id;
    setState(() {
      _loading = _report == null;
      _error = false;
    });
    final allowed = await CompanyDataService.isOwner();
    if (!mounted ||
        generation != _generation ||
        user != BackendService.user?.id) {
      return;
    }
    if (!allowed) {
      setState(() {
        _loading = false;
        _allowed = false;
        _report = null;
      });
      return;
    }
    try {
      final report = await CompanyDataService.load(_days);
      if (!mounted ||
          generation != _generation ||
          user != BackendService.user?.id) {
        return;
      }
      setState(() {
        _report = report;
        _allowed = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AffinityButtonGradients.apply(ThemeData.dark(useMaterial3: true)),
    child: Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: Colors.white,
        actions: const [
          HomeBrandButton(size: 44, dark: true),
          SizedBox(width: 16),
        ],
        title: const Text(
          'PACT / DATA',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_allowed || _report == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 44, color: _green),
                    const SizedBox(height: 16),
                    Text(
                      _error
                          ? 'Company data could not be loaded.'
                          : 'Private owner access',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Only the two approved owner accounts can open this area.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (BackendService.user == null)
                      FilledButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AuthPage(),
                            ),
                          );
                          if (mounted) _reload();
                        },
                        child: const Text('Sign in'),
                      ),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Check access again'),
                    ),
                  ],
                ),
              ),
            )
          : CompanyDataReportView(
              report: _report!,
              days: (_report!.data['days'] as num?)?.toInt() ?? _days,
              onDaysChanged: (days) {
                _days = days;
                _reload();
              },
              onRefresh: _reload,
            ),
    ),
  );
}

/// Isolated datasets, aligned charts and aggregate detail. Nothing enters public copy storage.
class CompanyDataReportView extends StatefulWidget {
  const CompanyDataReportView({
    super.key,
    required this.report,
    required this.days,
    required this.onDaysChanged,
    required this.onRefresh,
  });
  final CompanyDataReport report;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onRefresh;
  @override
  State<CompanyDataReportView> createState() => _CompanyDataReportViewState();
}

class _CompanyDataReportViewState extends State<CompanyDataReportView> {
  String _selected = 'accounts', _second = 'provider_profiles';
  bool _compare = false, _bars = true, _showAll = false;
  int _detail = 0;
  String? _breakdown;
  CompanyDataset get a => companyDatasets.firstWhere((d) => d.id == _selected);
  CompanyDataset get b => companyDatasets.firstWhere((d) => d.id == _second);
  DatasetValues values(CompanyDataset d) => DatasetValues(d, widget.report);
  void select(String id) {
    setState(() {
      _selected = id;
      if (_second == id) {
        _second = companyDatasets.firstWhere((d) => d.id != id).id;
      }
      _breakdown = null;
      _showAll = false;
    });
  }

  Widget text(
    String value, {
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
  }) => Text(
    value,
    style: TextStyle(fontSize: size, color: color, fontWeight: weight),
  );
  Widget panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: AffinityButtonGradients.apply(
        ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: _canvas,
          colorScheme: const ColorScheme.dark(
            primary: dataCyan,
            secondary: dataMint,
            surface: _panel,
          ),
          textTheme: base.textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          dividerColor: _line,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: _canvas,
            border: OutlineInputBorder(borderSide: BorderSide(color: _line)),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return ColoredBox(
            color: _canvas,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) SizedBox(width: 248, child: _sidebar()),
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('data-explorer-scroll'),
                    padding: EdgeInsets.all(wide ? 30 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 16,
                          spacing: 20,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text(
                                  'OWNER WORKSPACE',
                                  size: 10,
                                  color: dataMint,
                                  weight: FontWeight.w800,
                                ),
                                const SizedBox(height: 8),
                                text(
                                  'Data monitor',
                                  size: 30,
                                  weight: FontWeight.w700,
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (!wide)
                                  OutlinedButton.icon(
                                    key: const Key('dataset-drawer'),
                                    onPressed: () => showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => SizedBox(
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                            .8,
                                        child: _sidebar(closeOnSelect: true),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.view_sidebar_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('Datasets'),
                                  ),
                                SizedBox(
                                  width: 144,
                                  child: DropdownButtonFormField<int>(
                                    key: const Key('data-period'),
                                    isExpanded: true,
                                    initialValue: widget.days,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: [
                                      for (final d in [7, 30, 90, 365])
                                        DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            'Last $d days',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) widget.onDaysChanged(v);
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onRefresh,
                                  tooltip: 'Refresh data',
                                  icon: const Icon(Icons.refresh, size: 21),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await CompanyDataService.export(
                                        widget.report,
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Export failed. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 17,
                                  ),
                                  label: const Text('Export report'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Explore a dataset'),
                              selected: !_compare,
                              onSelected: (_) =>
                                  setState(() => _compare = false),
                            ),
                            ChoiceChip(
                              key: const Key('compare-mode'),
                              label: const Text('Compare two datasets'),
                              selected: _compare,
                              onSelected: (_) =>
                                  setState(() => _compare = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_compare)
                          _comparisonSelectors()
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              text(a.title, size: 24, weight: FontWeight.w700),
                              const SizedBox(height: 7),
                              text(a.description, color: dataMuted, size: 13),
                            ],
                          ),
                        const SizedBox(height: 20),
                        _metrics(),
                        const SizedBox(height: 18),
                        _graph(),
                        const SizedBox(height: 18),
                        _details(),
                        const SizedBox(height: 20),
                        text(
                          'Private to approved owners · UTC date boundaries · ${widget.report.data['generated_at'] == null ? 'Live database report' : 'Updated ${DateFormat.yMMMd().add_jm().format(DateTime.parse(widget.report.data['generated_at']).toLocal())}'}',
                          size: 11,
                          color: dataMuted,
                        ),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sidebar({bool closeOnSelect = false}) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF101823),
      border: Border(right: BorderSide(color: _line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                'DATASETS',
                size: 11,
                color: dataMuted,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              text(
                '${companyDatasets.length} datasets',
                size: 20,
                weight: FontWeight.w700,
              ),
              const SizedBox(height: 6),
              text(
                'Current totals · choose to explore',
                size: 12,
                color: dataMuted,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              for (final group in [
                'People',
                'Network',
                'Business',
                'Learning',
                'Usage',
                'Storage',
              ]) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                  child: text(
                    group.toUpperCase(),
                    size: 10,
                    color: dataMuted,
                    weight: FontWeight.w700,
                  ),
                ),
                for (final d in companyDatasets.where((d) => d.group == group))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Material(
                      color: _selected == d.id
                          ? const Color(0xFF1C3444)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        key: Key('dataset-${d.id}'),
                        borderRadius: BorderRadius.circular(9),
                        onTap: () {
                          select(d.id);
                          if (closeOnSelect) Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: text(
                                  d.title,
                                  size: 12,
                                  color: _selected == d.id
                                      ? dataCyan
                                      : const Color(0xFFCAD5E4),
                                  weight: _selected == d.id
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 6),
                              text(
                                formatDataValue(
                                  values(d).current,
                                  bytes: d.bytes,
                                ),
                                size: 11,
                                color: _selected == d.id ? dataCyan : dataMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  Widget _selector(
    String label,
    CompanyDataset value,
    ValueChanged<String> onChanged, {
    String? excluded,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      text(
        label,
        size: 11,
        color: label == 'DATASET A' ? dataCyan : dataMint,
        weight: FontWeight.w800,
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey('$label-${value.id}'),
        initialValue: value.id,
        isExpanded: true,
        items: [
          for (final d in companyDatasets.where((d) => d.id != excluded))
            DropdownMenuItem(
              value: d.id,
              child: Text(
                d.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ],
  );
  Widget _comparisonSelectors() => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text('Compare datasets', size: 24, weight: FontWeight.w700),
        const SizedBox(height: 8),
        text(
          'View two metrics in the same period. A comparison does not prove a relationship or conversion rate.',
          size: 12,
          color: dataMuted,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth > 550
              ? Row(
                  children: [
                    Expanded(child: _selector('DATASET A', a, select)),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _selector(
                        'DATASET B',
                        b,
                        (id) => setState(() => _second = id),
                        excluded: a.id,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _selector('DATASET A', a, select),
                    const SizedBox(height: 16),
                    _selector(
                      'DATASET B',
                      b,
                      (id) => setState(() => _second = id),
                      excluded: a.id,
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
  Widget _metric(CompanyDataset d, Color color) {
    final v = values(d);
    final snapshotComparison =
        _compare && (!values(a).hasHistory || !values(b).hasHistory);
    final showPeriod = v.hasHistory && !snapshotComparison;
    final change = v.changePercent;
    final changeText = !showPeriod
        ? 'Snapshot only'
        : change != null
        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs previous ${widget.days} days'
        : v.period > 0
        ? 'Previous period: 0'
        : 'Both periods: 0';
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text(d.title, size: 13, color: dataMuted),
          const SizedBox(height: 12),
          text(
            formatDataValue(showPeriod ? v.period : v.current, bytes: d.bytes),
            size: 34,
            color: color,
            weight: FontWeight.w700,
          ),
          const SizedBox(height: 4),
          text(
            showPeriod
                ? 'New records / visits · last ${widget.days} days'
                : 'Current stored total',
            size: 11,
            color: dataMuted,
          ),
          const SizedBox(height: 16),
          text(changeText, size: 12, color: color),
          const SizedBox(height: 8),
          text(
            'Current total: ${formatDataValue(v.current, bytes: d.bytes)}',
            size: 12,
            color: dataMuted,
          ),
        ],
      ),
    );
  }

  Widget _metrics() => LayoutBuilder(
    builder: (context, c) {
      final cards = _compare
          ? [_metric(a, dataCyan), _metric(b, dataMint)]
          : [
              _metric(a, dataCyan),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text('Reading this dataset', size: 13, color: dataMuted),
                    const SizedBox(height: 14),
                    text(
                      values(a).hasHistory
                          ? 'Dated activity'
                          : 'Current snapshot',
                      size: 22,
                      weight: FontWeight.w700,
                    ),
                    const SizedBox(height: 10),
                    text(
                      values(a).hasHistory
                          ? 'The graph counts retained records by their saved date. It does not recreate deleted records or past status changes.'
                          : 'No creation-date history is stored for this dataset. The graph shows its current value only.',
                      size: 12,
                      color: dataMuted,
                    ),
                    const SizedBox(height: 10),
                    text(
                      'Examples are excluded from member and team metrics.',
                      size: 11,
                      color: dataMuted,
                    ),
                  ],
                ),
              ),
            ];
      return c.maxWidth > 620
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 18),
                Expanded(child: cards[1]),
              ],
            )
          : Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
    },
  );
  Widget _graph() {
    final av = values(a), bv = values(b);
    final snapshot = !av.hasHistory || (_compare && !bv.hasHistory);
    final now =
        (widget.report.data['generated_at']?.toString() ??
                DateTime.now().toIso8601String())
            .substring(0, 10);
    List<DataPoint> points(DatasetValues v) =>
        snapshot ? [DataPoint(now, v.current)] : v.chartPoints;
    final series = [
      ChartSeries(a.title, points(av), dataCyan, bytes: a.bytes),
      if (_compare) ChartSeries(b.title, points(bv), dataMint, bytes: b.bytes),
    ];
    final grouping = widget.days <= 31
        ? 'Daily'
        : widget.days <= 90
        ? '7-day buckets'
        : 'Monthly';
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(
                    snapshot ? 'Current snapshot' : 'Activity over time',
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: 5),
                  text(
                    snapshot
                        ? 'A current-value comparison; historical values are unavailable.'
                        : '$grouping · counts within the selected UTC period',
                    size: 11,
                    color: dataMuted,
                  ),
                ],
              ),
              if (!snapshot)
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      key: const Key('chart-bars'),
                      label: const Text('Bars'),
                      selected: _bars,
                      onSelected: (_) => setState(() => _bars = true),
                    ),
                    ChoiceChip(
                      key: const Key('chart-lines'),
                      label: const Text('Lines'),
                      selected: !_bars,
                      onSelected: (_) => setState(() => _bars = false),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          CompanyDataChart(
            key: ValueKey(
              '$_selected:$_second:$_compare:${widget.days}:$snapshot',
            ),
            series: series,
            bars: _bars,
            snapshot: snapshot,
          ),
          if (!snapshot &&
              series.every((s) => s.points.every((p) => p.value == 0)))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: text(
                'No recorded activity in this period. Zero values are shown without sample data.',
                size: 12,
                color: dataMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _details() => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text(
          _compare ? 'Comparison detail' : 'Dataset detail',
          size: 20,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                key: Key('data-detail-$i'),
                label: Text(['Breakdowns', 'Daily data', 'About this data'][i]),
                selected: _detail == i,
                onSelected: (_) => setState(() => _detail = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_detail == 0)
          _compare
              ? Column(
                  children: [
                    _breakdowns(a, dataCyan),
                    const SizedBox(height: 24),
                    _breakdowns(b, dataMint),
                  ],
                )
              : _breakdowns(a, dataCyan),
        if (_detail == 1) _dailyTable(),
        if (_detail == 2)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _about(a),
              if (_compare) ...[const SizedBox(height: 22), _about(b)],
              const Divider(height: 32),
              text('Not collected here', weight: FontWeight.w700),
              const SizedBox(height: 8),
              text(
                'Historical clicks, signed-out browsing, verified hires, attendance, payments and device-only drafts are not available. This explorer does not expose private message text, document contents or financial inputs.',
                size: 13,
                color: dataMuted,
              ),
            ],
          ),
      ],
    ),
  );
  String breakdownName(String key) => switch (key) {
    'roles' => 'Account roles',
    'locations' => 'Saved locations',
    'professions' => 'Professions',
    'member_status' => 'Member status',
    'teams' => 'Chosen professionals',
    'pipeline' => 'Pipeline stages',
    'feature_visits' => 'App areas',
    _ => key,
  };
  Widget _breakdowns(CompanyDataset d, Color color) {
    final v = values(d), keys = values(d).breakdownKeys;
    final selected = keys.contains(_breakdown) ? _breakdown : keys.firstOrNull;
    final rows = selected == null
        ? <Map<String, dynamic>>[]
        : widget.report.rows(selected);
    final max = rows.fold<double>(
      1,
      (a, r) => (r['count'] as num).toDouble() > a
          ? (r['count'] as num).toDouble()
          : a,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text(d.title, size: 14, color: color, weight: FontWeight.w700),
        const SizedBox(height: 12),
        text(
          selected == 'feature_visits'
              ? 'Breakdown for the selected period'
              : 'Current retained records · not filtered by the date range',
          size: 11,
          color: dataMuted,
        ),
        const SizedBox(height: 12),
        if (keys.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in keys)
                  ChoiceChip(
                    key: Key('breakdown-$key'),
                    label: Text(breakdownName(key)),
                    selected: selected == key,
                    onSelected: (_) => setState(() => _breakdown = key),
                  ),
              ],
            ),
          ),
        if (rows.isEmpty)
          text(
            'No category breakdown is recorded for this dataset yet.',
            size: 13,
            color: dataMuted,
          ),
        if (selected == 'locations')
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: text(
              'Top 20 saved preferences, not verified home addresses. Profiles without a saved location are omitted.',
              size: 12,
              color: dataMuted,
            ),
          ),
        if (selected == 'teams')
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: text(
              'Current selections of real professionals; not confirmed hires. Top 20.',
              size: 12,
              color: dataMuted,
            ),
          ),
        if (rows.isNotEmpty) ...[
          if (selected == 'professions')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: text(
                'Top 20 professional titles/types. Examples excluded.',
                size: 12,
                color: dataMuted,
              ),
            ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: text(
                          '${r['label']}'.replaceAll('_', ' '),
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      text(
                        formatDataValue((r['count'] as num).toDouble()),
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: (r['count'] as num) / max,
                    minHeight: 6,
                    color: color,
                    backgroundColor: _line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
        ],
        if (!v.hasHistory && rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: text(
              'Use About this data for its source and limitations.',
              size: 12,
              color: dataMuted,
            ),
          ),
      ],
    );
  }

  Widget _dailyTable() {
    final av = values(a), bv = values(b);
    if (!av.hasHistory || (_compare && !bv.hasHistory)) {
      return text(
        'Daily history is unavailable for one or both selected datasets. Their current values are shown in the snapshot graph.',
        size: 13,
        color: dataMuted,
      );
    }
    final rows = av.daily.reversed.toList(),
        other = {for (final p in bv.daily) p.day: p.value};
    final shown = _showAll ? rows : rows.take(14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text('Daily counts · UTC', size: 14, weight: FontWeight.w700),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: text('Date', size: 11, color: dataMuted)),
            Expanded(
              child: text(_compare ? 'A' : 'Count', size: 11, color: dataCyan),
            ),
            if (_compare) Expanded(child: text('B', size: 11, color: dataMint)),
          ],
        ),
        const Divider(height: 20),
        for (final p in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 2, child: text(p.day, size: 12)),
                Expanded(
                  child: text(
                    formatDataValue(p.value),
                    size: 12,
                    color: dataCyan,
                  ),
                ),
                if (_compare)
                  Expanded(
                    child: text(
                      formatDataValue(other[p.day] ?? 0),
                      size: 12,
                      color: dataMint,
                    ),
                  ),
              ],
            ),
          ),
        if (rows.length > 14)
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll ? 'Show latest 14 days' : 'Show all ${rows.length} days',
            ),
          ),
      ],
    );
  }

  Widget _about(CompanyDataset d) {
    final v = values(d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text(
          d.title,
          size: 15,
          color: d.id == a.id ? dataCyan : dataMint,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: 10),
        text(d.description, size: 13, color: dataMuted),
        const SizedBox(height: 14),
        text(
          'Source: ${d.source ?? 'Saved size metadata for tracked tables / files'}',
          size: 12,
        ),
        const SizedBox(height: 8),
        text(
          v.hasHistory
              ? 'Date field: ${d.dateField} · bucketed in UTC'
              : 'History: unavailable; current snapshot only',
          size: 12,
          color: dataMuted,
        ),
        const SizedBox(height: 8),
        if (v.hasHistory)
          text(
            'Previous period: ${formatDataValue(v.previous)} records / visits in the preceding ${widget.days} UTC days. Percent change is unavailable when that total is zero.',
            size: 12,
            color: dataMuted,
          ),
        const SizedBox(height: 8),
        text(
          'Operational counts reflect records still retained. Deleted records and historical status changes are not reconstructed.',
          size: 12,
          color: dataMuted,
        ),
      ],
    );
  }
}
