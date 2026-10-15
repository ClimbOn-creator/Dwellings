import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';
import '../services/company_data_service.dart';
import '../widgets/home_brand_button.dart';
import 'auth_page.dart';

const _green = Color(0xFF064F42);
const _muted = Color(0xFF60716D);

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
  int _days = 30, _generation = 0;
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
      _loading = true;
      _error = false;
      _report = null;
      _allowed = false;
    });
    final allowed = await CompanyDataService.isOwner();
    if (!mounted ||
        generation != _generation ||
        user != BackendService.user?.id) {
      return;
    }
    if (!allowed) {
      setState(() => _loading = false);
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F6F4),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const HomeBrandButton(size: 45, dark: false),
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
                    style: Theme.of(context).textTheme.headlineSmall,
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
            days: _days,
            onDaysChanged: (days) {
              _days = days;
              _reload();
            },
            onRefresh: _reload,
          ),
  );
}

/// Aggregate-only view. Private payloads never enter the public site-copy store.
class CompanyDataReportView extends StatelessWidget {
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
  String _count(num n) => NumberFormat.decimalPattern().format(n);
  static String bytes(num n) {
    if (n < 1024) return '${n.toInt()} B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    if (n < 1024 * 1024 * 1024) {
      return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final inventory = report.rows('inventory');
    final records = inventory.fold<int>(
      0,
      (total, row) => total + (row['count'] as num).toInt(),
    );
    final size = inventory.fold<int>(
      0,
      (total, row) => total + (row['bytes'] as num).toInt(),
    );
    final generated = DateTime.tryParse(
      report.data['generated_at']?.toString() ?? '',
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OWNERS ONLY',
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your company, in numbers',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A live summary of the records Affinity keeps in the company database. Totals are all-time unless a selected period is mentioned.',
                  style: TextStyle(color: _muted, fontSize: 16),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: days,
                      items: [
                        for (final d in [7, 30, 90, 365])
                          DropdownMenuItem(
                            value: d,
                            child: Text('Last $d days'),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) onDaysChanged(v);
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await CompanyDataService.export(report);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Export failed. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export summary CSV'),
                    ),
                    if (generated != null)
                      Text(
                        'Updated ${DateFormat.yMMMd().add_jm().format(generated.toLocal())}',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final width = c.maxWidth > 850
                        ? (c.maxWidth - 36) / 4
                        : c.maxWidth > 500
                        ? (c.maxWidth - 12) / 2
                        : c.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final key in [
                          'Registered accounts',
                          'Professional profiles',
                          'Team selections',
                          'Event registrations',
                        ])
                          SizedBox(
                            width: width,
                            child: _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _count(report.totals[key] as num? ?? 0),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: _green,
                                    ),
                                  ),
                                  Text(
                                    key,
                                    style: const TextStyle(color: _muted),
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
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How much data do we have?',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_count(records)} saved rows across ${inventory.length} tracked tables · ${bytes(size)} in database tables and indexes · ${bytes(report.number('uploaded_file_bytes'))} of files recorded in upload metadata.',
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                      const Text(
                        'Rows include examples, links and system records; they are not unique people. File sizes cover deal documents and learning media, not all hosting/storage buckets or backups.',
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _panels(context, [
                  _bars(
                    'New accounts · last $days days',
                    report
                        .rows('new_accounts')
                        .map((r) => {'label': r['day'], 'count': r['count']})
                        .toList(),
                    empty: 'No registrations in this period.',
                    daily: true,
                  ),
                  _bars(
                    'Saved account roles',
                    report.rows('roles'),
                    empty: 'No saved profiles yet.',
                  ),
                  _bars(
                    'Where people are looking',
                    report.rows('locations'),
                    note:
                        'Top 20 saved profile locations. These are preferences, not verified home addresses. ${_count(report.totals['Profiles with a saved location'] as num? ?? 0)} profiles have a saved city or province.',
                    empty: 'No locations have been provided yet.',
                  ),
                  _bars(
                    'Member professions',
                    report.rows('professions'),
                    note:
                        'Top 20 professional titles/types. Example profiles are excluded.',
                    empty: 'No real professional profiles yet.',
                  ),
                  _bars(
                    'Professionals chosen for teams',
                    report.rows('teams'),
                    note:
                        'Current selections, not confirmed engagements. Removed selections are no longer counted. Examples are excluded.',
                    empty: 'No real professionals have been selected yet.',
                  ),
                  _bars(
                    'Pipeline stages',
                    report.rows('pipeline'),
                    note:
                        'Saved stages, not independently verified deal outcomes.',
                    empty: 'No deal rooms yet.',
                  ),
                  _bars(
                    'Feature visits · last $days days',
                    report.rows('feature_visits'),
                    note:
                        'Optional, signed-in navigation counts starting ${report.data['usage_started'] ?? 'when the first user opts in'}. Visits are not unique visitors; owners and previews are excluded. No IPs, personal form values or full URLs are collected.',
                    empty: 'No opted-in activity has been recorded yet.',
                  ),
                  _bars(
                    'Membership status',
                    report.rows('member_status'),
                    note:
                        'Profile status only. Billing is not connected; this is not a revenue report.',
                    empty: 'No real professional memberships yet.',
                  ),
                ]),
                const SizedBox(height: 22),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Learning and business activity',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final entry in report.totals.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              const SizedBox(width: 12),
                              Text(
                                _count(entry.value as num),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved-record inventory',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final row in inventory)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (row['label'] as String).replaceAll('_', ' '),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_count(row['count'] as num)} rows · ${bytes(row['bytes'] as num)}',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _card(
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is kept, and what is still missing',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Existing accounts, profiles, teams, requests, deals and learning records remain in their original company database tables. Anonymous daily feature totals are saved separately and survive app updates. This dashboard reads summaries; it does not copy private messages, documents or financial inputs into analytics.',
                        style: TextStyle(height: 1.6),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Not measured yet: signed-out browsing, quiz answers, searches, event attendance, external-site conversions, verified hires and payments. Device-only drafts are not company database records. Historical clicks cannot be reconstructed. Deleted operational records are not archived by this dashboard.',
                        style: TextStyle(height: 1.6, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE6E1)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
  Widget _panels(BuildContext context, List<Widget> children) => LayoutBuilder(
    builder: (context, c) => Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final child in children)
          SizedBox(
            width: c.maxWidth > 800 ? (c.maxWidth - 18) / 2 : c.maxWidth,
            child: child,
          ),
      ],
    ),
  );
  Widget _bars(
    String title,
    List<Map<String, dynamic>> rows, {
    String? note,
    required String empty,
    bool daily = false,
  }) {
    final total = rows.fold<num>(0, (s, r) => s + (r['count'] as num));
    // Weekly/monthly reports remain readable; longer ranges group into calendar months.
    if (daily && rows.length > 31) {
      final months = <String, num>{};
      for (final r in rows) {
        final k = (r['label'] as String).substring(0, 7);
        months[k] = (months[k] ?? 0) + (r['count'] as num);
      }
      rows = months.entries
          .map((e) => {'label': e.key, 'count': e.value})
          .toList();
    }
    final max = rows.fold<num>(1, (v, r) => math.max(v, r['count'] as num));
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                note,
                style: const TextStyle(color: _muted, height: 1.5),
              ),
            ),
          const SizedBox(height: 16),
          if (rows.isEmpty || total == 0)
            Text(empty, style: const TextStyle(color: _muted)),
          if (total > 0)
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${r['label']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _count(r['count'] as num),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Semantics(
                      label: '${r['label']}: ${r['count']}',
                      child: LinearProgressIndicator(
                        value: (r['count'] as num) / max,
                        minHeight: 7,
                        color: _green,
                        backgroundColor: const Color(0xFFEAF1ED),
                        borderRadius: BorderRadius.circular(5),
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
