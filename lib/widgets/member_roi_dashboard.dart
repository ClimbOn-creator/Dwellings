import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';
import '../services/member_roi_service.dart';
import '../services/pact_messaging_service.dart' show pactMessageId;

const _purple = Color(0xFF6255DC),
    _ink = Color(0xFF252333),
    _muted = Color(0xFF817C8E);

class MemberRoiDashboard extends StatefulWidget {
  const MemberRoiDashboard({super.key, this.service});
  final MemberRoiService? service;
  @override
  State<MemberRoiDashboard> createState() => _MemberRoiDashboardState();
}

class _MemberRoiDashboardState extends State<MemberRoiDashboard> {
  late final _service = widget.service ?? MemberRoiService();
  final _owner = BackendService.user?.id;
  MemberRoiSnapshot? _data;
  int _days = 365, _generation = 0;
  bool _loading = true;
  String? _error;
  StreamSubscription<dynamic>? _auth;
  final _money = NumberFormat.currency(
    locale: 'en_CA',
    symbol: '\$',
    decimalDigits: 0,
  );
  @override
  void initState() {
    super.initState();
    _load();
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _owner) {
        _generation++;
        setState(() {
          _data = null;
          _loading = false;
          _error = 'Sign in again to view your ROI.';
        });
      }
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service
          .load(_days)
          .timeout(const Duration(seconds: 12));
      if (!mounted ||
          generation != _generation ||
          BackendService.user?.id != _owner)
        return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() {
          _loading = false;
          _error = 'Your ROI data could not load. Please try again.';
        });
    }
  }

  Future<void> _cost() async {
    final text = TextEditingController(
      text: _data?.annualCost?.toStringAsFixed(2) ?? '',
    );
    final key = GlobalKey<FormState>();
    bool saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Membership cost'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the annual amount you actually pay. Shorter periods use a daily share of this cost.',
                    style: TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: text,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Annual subscription · CAD',
                    ),
                    validator: _amount,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      update(() => saving = true);
                      try {
                        await _service.saveCost(double.parse(text.text.trim()));
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) await _load();
                      } catch (_) {
                        if (context.mounted)
                          update(() {
                            error =
                                'Could not save your cost. Please try again.';
                            saving = false;
                          });
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save cost'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
  }

  String? _amount(String? value) {
    final n = double.tryParse(value?.trim() ?? '');
    return n == null ||
            !n.isFinite ||
            n < 0 ||
            n > 999999999999 ||
            !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value!.trim())
        ? 'Enter a valid amount with up to two decimals'
        : null;
  }

  Future<void> _record() async {
    final label = TextEditingController(), revenue = TextEditingController();
    final key = GlobalKey<FormState>();
    String kind = 'consultation', source = 'Pact introduction';
    String? leadId, error;
    DateTime date = DateUtils.dateOnly(DateTime.now());
    bool saving = false;
    final id = pactMessageId();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Record a Pact outcome'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'consultation',
                          label: Text('Consultation'),
                        ),
                        ButtonSegment(
                          value: 'transaction',
                          label: Text('Transaction'),
                        ),
                      ],
                      selected: {kind},
                      showSelectedIcon: false,
                      onSelectionChanged: saving
                          ? null
                          : (v) => update(() => kind = v.first),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: label,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Private label',
                      ),
                      validator: (v) => (v?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Add a short label',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'How Pact helped',
                      ),
                      items: [
                        for (final s in [
                          'Pact profile',
                          'Pact introduction',
                          'Pact message',
                          'Pact opportunity',
                        ])
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: saving
                          ? null
                          : (v) => update(() => source = v!),
                    ),
                    const SizedBox(height: 14),
                    if ((_data?.inquiries.length ?? 0) > 0) ...[
                      DropdownButtonFormField<String>(
                        initialValue: leadId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Link to inquiry (optional)',
                          helperText: 'Linked outcomes are counted once.',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No linked inquiry'),
                          ),
                          for (final inquiry in _data!.inquiries)
                            DropdownMenuItem(
                              value: inquiry['id'] as String,
                              child: Text(
                                inquiry['requester_name'] as String? ??
                                    'Pact inquiry',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: saving
                            ? null
                            : (v) => update(() => leadId = v),
                      ),
                      const SizedBox(height: 14),
                    ],
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMd().format(date)),
                      leading: const Icon(Icons.calendar_today_outlined),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && context.mounted)
                                update(() => date = picked);
                            },
                    ),
                    if (kind == 'transaction') ...[
                      TextFormField(
                        controller: revenue,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Your earned fee / commission · CAD',
                        ),
                        validator: _amount,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Record your Pact-attributed earnings, rather than the full transaction price.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      update(() => saving = true);
                      try {
                        await _service.record(
                          id: id,
                          kind: kind,
                          label: label.text,
                          source: source,
                          date: date,
                          revenue: kind == 'transaction'
                              ? double.parse(revenue.text.trim())
                              : 0,
                          leadId: leadId,
                        );
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) await _load();
                      } catch (_) {
                        if (context.mounted)
                          update(() {
                            error =
                                'Could not save this outcome. Your input is still here.';
                            saving = false;
                          });
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save outcome'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    revenue.dispose();
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 18,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEMBER INSIGHTS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: _purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Your return on Pact',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.8,
                    color: _ink,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final days in [30, 90, 365])
                  ChoiceChip(
                    label: Text(days == 365 ? '12 months' : '$days days'),
                    selected: _days == days,
                    showCheckmark: false,
                    onSelected: _loading
                        ? null
                        : (_) {
                            setState(() {
                              _days = days;
                              _data = null;
                            });
                            _load();
                          },
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        if (d != null) ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NET RETURN ON MEMBERSHIP',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: _purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  d.roiPercent == null
                      ? 'Set your membership cost'
                      : '${d.roiPercent!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: d.roiPercent == null ? 28 : 56,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  d.roiPercent == null
                      ? 'Add your actual annual subscription to calculate ROI.'
                      : '${_money.format(d.netReturn)} in reported revenue above your membership cost for this period.',
                  style: const TextStyle(color: _muted, height: 1.6),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 30,
                  runSpacing: 16,
                  children: [
                    _number('Attributed revenue', _money.format(d.revenue)),
                    _number(
                      d.days == 365
                          ? 'Annual membership cost'
                          : 'Prorated membership cost',
                      d.periodCost == null
                          ? 'Not set'
                          : _money.format(d.periodCost),
                    ),
                    _number('Currency', 'CAD'),
                  ],
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _cost,
                  child: Text(
                    d.annualCost == null
                        ? 'Add membership cost'
                        : 'Edit membership cost',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final n = c.maxWidth >= 850
                  ? 4
                  : c.maxWidth >= 480
                  ? 2
                  : 1;
              final width = (c.maxWidth - (n - 1) * 14) / n;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final metric in [
                    (
                      'Profile views',
                      d.views,
                      Icons.visibility_outlined,
                      'Signed-in visitors, once daily',
                    ),
                    (
                      'Qualified inquiries',
                      d.qualified,
                      Icons.forum_outlined,
                      'Qualified in your lead workflow',
                    ),
                    (
                      'Consultations',
                      d.consultations,
                      Icons.event_available_outlined,
                      'Workflow + recorded outcomes',
                    ),
                    (
                      'Transactions',
                      d.transactions,
                      Icons.handshake_outlined,
                      'Won inquiries + recorded outcomes',
                    ),
                  ])
                    SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE9E6EE)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(metric.$3, color: _purple, size: 23),
                            const SizedBox(height: 16),
                            Text(
                              '${metric.$2}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              metric.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              metric.$4,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    const Text(
                      'Pact-generated outcomes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _record,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record outcome'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (d.outcomes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Your consultations and earned fees will appear here. Record an outcome when Pact helps you make a connection.',
                      style: TextStyle(height: 1.7, color: _muted),
                    ),
                  )
                else
                  for (final row in d.outcomes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row['label'] as String),
                      subtitle: Text(
                        '${row['source']} · ${row['occurred_on']} · member-reported',
                      ),
                      leading: Icon(
                        row['kind'] == 'transaction'
                            ? Icons.handshake_outlined
                            : Icons.event_outlined,
                        color: _purple,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (row['kind'] == 'transaction')
                            Text(
                              _money.format(row['revenue']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          PopupMenuButton<String>(
                            tooltip: 'Outcome options',
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'void',
                                child: Text('Remove from ROI'),
                              ),
                            ],
                            onSelected: (_) async {
                              try {
                                await _service.voidOutcome(row['id'] as String);
                                if (mounted) await _load();
                              } catch (_) {
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not remove this outcome. Try again.',
                                      ),
                                    ),
                                  );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Revenue is member-reported and is private to your account. ROI compares that revenue with membership cost before service-delivery costs and taxes. Automatic activity tracking started ${d.startedAt == null ? 'with this dashboard' : DateFormat.yMMMd().format(DateTime.parse(d.startedAt!))}.',
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _number(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
    ],
  );
}
