import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/platform_side.dart';
import '../services/affinity_admin_service.dart';
import '../services/backend_service.dart';
import '../services/member_beta_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import 'auth_page.dart';

const _ink = Color(0xFF171717);
const _green = Color(0xFF053827);
const _paper = Color(0xFFF4F1EB);
const _line = Color(0xFFD6D1C9);
const _muted = Color(0xFF68635D);

class AffinityReviewDeskPage extends StatefulWidget {
  const AffinityReviewDeskPage({super.key});

  @override
  State<AffinityReviewDeskPage> createState() => _AffinityReviewDeskPageState();
}

class _AffinityReviewDeskPageState extends State<AffinityReviewDeskPage> {
  late Future<bool> _access;
  late Future<List<AffinityReviewItem>> _queue;
  late Future<List<AffinityMemberAccount>> _members;
  late Future<AffinityBetaMetrics> _metrics;
  late Future<List<AffinityAuditEvent>> _events;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _queue = Future.value(const <AffinityReviewItem>[]);
    _members = Future.value(const <AffinityMemberAccount>[]);
    _metrics = Future.value(
      const AffinityBetaMetrics(
        submittedDeals: 0,
        publishedDeals: 0,
        totalPitches: 0,
        shortlistedPitches: 0,
        acceptedPitches: 0,
        activeProfessionals: 0,
        pendingEmails: 0,
        averageHoursToPublish: 0,
      ),
    );
    _events = Future.value(const <AffinityAuditEvent>[]);
    _access = AffinityAdminService.isAdmin();
    _access.then((allowed) {
      if (!mounted || !allowed) return;
      setState(() {
        _queue = AffinityAdminService.loadReviewQueue();
        _members = AffinityAdminService.loadMemberAccounts();
        _metrics = AffinityAdminService.loadBetaMetrics();
        _events = AffinityAdminService.loadAuditEvents();
      });
    });
  }

  void _refresh() => setState(_reload);

  Future<void> _signIn() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: FutureBuilder<bool>(
      future: _access,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        if (snapshot.data != true) return _locked();
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _header(),
              Container(
                width: double.infinity,
                color: _paper,
                padding: const EdgeInsets.fromLTRB(22, 34, 22, 84),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: [
                            _tabChip(0, 'DEAL REVIEW QUEUE'),
                            _tabChip(1, 'MEMBER ACCOUNTS'),
                            _tabChip(2, 'BETA OPERATIONS'),
                          ],
                        ),
                        const SizedBox(height: 26),
                        if (_tab == 0)
                          _reviewQueue()
                        else if (_tab == 1)
                          _memberAccounts()
                        else
                          _operations(),
                      ],
                    ),
                  ),
                ),
              ),
              const MembershipFooter(),
            ],
          ),
        );
      },
    ),
  );

  Widget _locked() => SingleChildScrollView(
    child: Column(
      children: [
        SizedBox(
          height: 620,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              margin: const EdgeInsets.all(22),
              padding: const EdgeInsets.all(38),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 42),
                  const SizedBox(height: 18),
                  const Text(
                    'Private Affinity Review Desk',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    BackendService.user == null
                        ? 'Sign in with the account that will own Affinity administration.'
                        : 'This signed-in account has not been added to the Affinity administrator allow-list.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _signIn,
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    child: Text(
                      BackendService.user == null
                          ? 'SIGN IN'
                          : 'USE ANOTHER ACCOUNT',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const MembershipFooter(),
      ],
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    color: _green,
    padding: const EdgeInsets.fromLTRB(24, 66, 24, 62),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRIVATE OPERATIONS',
              style: TextStyle(
                color: Color(0xFFB8CEC4),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Affinity Review Desk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Review private assessments, create safe anonymous listings, approve professional members, and control what enters the Member Studio.',
              style: TextStyle(color: Color(0xFFD8E4DE), height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tabChip(int tab, String label) => ChoiceChip(
    label: Text(label),
    selected: _tab == tab,
    selectedColor: _green,
    backgroundColor: Colors.white,
    side: const BorderSide(color: _line),
    labelStyle: TextStyle(
      color: _tab == tab ? Colors.white : _ink,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .7,
    ),
    onSelected: (_) => setState(() => _tab = tab),
  );

  Widget _reviewQueue() => FutureBuilder<List<AffinityReviewItem>>(
    future: _queue,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _Loading();
      }
      if (snapshot.hasError) return _error(snapshot.error!);
      final items = snapshot.data ?? [];
      if (items.isEmpty) {
        return const _Empty(
          'No deals are waiting. Buyer submissions will appear here.',
        );
      }
      return Column(
        children: [
          for (final item in items) ...[
            _ReviewCard(
              item: item,
              onOpen: () async {
                final changed = await showDialog<bool>(
                  context: context,
                  builder: (_) => _ReviewEditor(item: item),
                );
                if (changed == true && mounted) _refresh();
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    },
  );

  Widget _memberAccounts() => FutureBuilder<List<AffinityMemberAccount>>(
    future: _members,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _Loading();
      }
      if (snapshot.hasError) return _error(snapshot.error!);
      final members = snapshot.data ?? [];
      if (members.isEmpty) {
        return const _Empty('No professional profiles have been submitted.');
      }
      return Column(
        children: [
          for (final member in members) ...[
            _MemberAccessCard(member: member, onChanged: _refresh),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );

  Widget _operations() => FutureBuilder<AffinityBetaMetrics>(
    future: _metrics,
    builder: (context, metricSnapshot) {
      if (metricSnapshot.connectionState == ConnectionState.waiting) {
        return const _Loading();
      }
      if (metricSnapshot.hasError) return _error(metricSnapshot.error!);
      final metrics = metricSnapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OperationsMetric('DEALS SUBMITTED', '${metrics.submittedDeals}'),
              _OperationsMetric(
                'LIVE OPPORTUNITIES',
                '${metrics.publishedDeals}',
              ),
              _OperationsMetric('TOTAL PITCHES', '${metrics.totalPitches}'),
              _OperationsMetric('SHORTLISTED', '${metrics.shortlistedPitches}'),
              _OperationsMetric('CONNECTIONS', '${metrics.acceptedPitches}'),
              _OperationsMetric(
                'ACTIVE PROFESSIONALS',
                '${metrics.activeProfessionals}',
              ),
              _OperationsMetric(
                'AVG. HOURS TO PUBLISH',
                metrics.averageHoursToPublish.toStringAsFixed(1),
              ),
              _OperationsMetric('PENDING EMAILS', '${metrics.pendingEmails}'),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              await MemberBetaService.flushEmailOutbox();
              if (mounted) _refresh();
            },
            style: FilledButton.styleFrom(backgroundColor: _green),
            icon: const Icon(Icons.outgoing_mail, size: 18),
            label: const Text('PROCESS NOTIFICATION EMAILS'),
          ),
          const SizedBox(height: 34),
          const Text(
            'Private audit trail',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'A reviewer-only record of deal, pitch, and access decisions.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<AffinityAuditEvent>>(
            future: _events,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const _Loading();
              if (snapshot.hasError) return _error(snapshot.error!);
              final events = snapshot.data ?? [];
              if (events.isEmpty)
                return const _Empty(
                  'New Member Studio activity will be recorded here.',
                );
              return Column(
                children: [for (final event in events) _AuditRow(event)],
              );
            },
          ),
        ],
      );
    },
  );

  Widget _error(Object error) => _Empty(
    error.toString().contains('does not exist')
        ? 'Apply migration 202608190015_affinity_review_desk.sql, then reload this page.'
        : error.toString(),
  );
}

class _OperationsMetric extends StatelessWidget {
  const _OperationsMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 245,
    padding: const EdgeInsets.all(20),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow(this.event);
  final AffinityAuditEvent event;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    color: Colors.white,
    child: Row(
      children: [
        const CircleAvatar(
          radius: 17,
          backgroundColor: Color(0xFFE7ECE9),
          child: Icon(Icons.history_rounded, color: _green, size: 17),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.eventType.replaceAll('_', ' '),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${event.entityType} · ${event.actorEmail} · ${event.metadata}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          DateFormat.MMMd().add_jm().format(event.createdAt.toLocal()),
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.onOpen});
  final AffinityReviewItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    color: Colors.white,
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
                    item.businessName.isEmpty
                        ? item.dealTitle
                        : item.businessName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.industry.isEmpty ? 'Industry not supplied' : item.industry} · ${item.region.isEmpty ? 'Region private' : item.region}',
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
            _Status(item.status),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 28,
          runSpacing: 14,
          children: [
            _Metric(
              'ASKING PRICE',
              item.purchasePrice == 0
                  ? 'Not supplied'
                  : NumberFormat.compactCurrency(
                      symbol: r'$',
                      decimalDigits: 1,
                    ).format(item.purchasePrice),
            ),
            _Metric('MODEL SCORE', _value(item, 'viability_score')),
            _Metric('RISK SCORE', _value(item, 'risk_score')),
            _Metric('PITCHES', '${item.pitchCount}'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Submitted ${DateFormat.yMMMd().format(item.submittedAt)} · Buyer identity restricted to reviewers',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: const Text('OPEN REVIEW'),
            ),
          ],
        ),
      ],
    ),
  );

  static String _value(AffinityReviewItem item, String key) {
    final value = item.assessmentResults[key];
    if (value is num) return value.toStringAsFixed(0);
    return '—';
  }
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({required this.item});
  final AffinityReviewItem item;

  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late final TextEditingController headline;
  late final TextEditingController industry;
  late final TextEditingController region;
  late final TextEditingController summary;
  late final TextEditingController stage;
  late final TextEditingController priceBand;
  late final TextEditingController capitalBand;
  late final TextEditingController score;
  late final TextEditingController scoreLabel;
  late final TextEditingController support;
  late final TextEditingController notes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    headline = TextEditingController(text: item.headline);
    industry = TextEditingController(text: item.industry);
    region = TextEditingController(text: item.region);
    summary = TextEditingController(text: item.summary);
    stage = TextEditingController(text: item.currentStage);
    priceBand = TextEditingController(text: item.purchasePriceBand);
    capitalBand = TextEditingController(text: item.capitalRequiredBand);
    score = TextEditingController(text: item.affinityScore?.toString() ?? '');
    scoreLabel = TextEditingController(text: item.scoreLabel);
    support = TextEditingController(text: item.supportNeeded.join(', '));
    notes = TextEditingController(text: item.reviewNotes);
  }

  @override
  void dispose() {
    for (final controller in [
      headline,
      industry,
      region,
      summary,
      stage,
      priceBand,
      capitalBand,
      score,
      scoreLabel,
      support,
      notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String status) async {
    if (status == 'published') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publish anonymous opportunity?'),
          content: const Text(
            'Verified professional members will immediately see the public fields. Confirm that the summary contains no buyer name, exact address, email, or identifying details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: const Text('PUBLISH SAFELY'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => saving = true);
    try {
      await AffinityAdminService.saveReview(
        opportunityId: widget.item.id,
        status: status,
        headline: headline.text,
        industry: industry.text,
        region: region.text,
        summary: summary.text,
        stage: stage.text,
        purchasePriceBand: priceBand.text,
        capitalRequiredBand: capitalBand.text,
        affinityScore: int.tryParse(score.text),
        scoreLabel: scoreLabel.text,
        supportNeeded: support.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        reviewNotes: notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Review and anonymize deal'),
    content: SizedBox(
      width: 780,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _privateSource(),
            const SizedBox(height: 24),
            const Text(
              'MEMBER-FACING FIELDS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: headline,
              decoration: const InputDecoration(labelText: 'Safe headline'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: industry,
                    decoration: const InputDecoration(labelText: 'Industry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: region,
                    decoration: const InputDecoration(
                      labelText: 'General region',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: summary,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Anonymous opportunity summary',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceBand,
                    decoration: const InputDecoration(
                      labelText: 'Purchase price band',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: capitalBand,
                    decoration: const InputDecoration(
                      labelText: 'Capital required band',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: score,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Affinity score (0–100)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: scoreLabel,
                    decoration: const InputDecoration(labelText: 'Score label'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stage,
              decoration: const InputDecoration(labelText: 'Deal stage'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: support,
              decoration: const InputDecoration(
                labelText: 'Support needed, separated by commas',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Private reviewer notes—never shown to members',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      TextButton(
        onPressed: saving ? null : () => _save('needs_information'),
        child: const Text('NEEDS INFORMATION'),
      ),
      TextButton(
        onPressed: saving ? null : () => _save('declined'),
        child: const Text('DECLINE'),
      ),
      OutlinedButton(
        onPressed: saving ? null : () => _save('reviewing'),
        child: const Text('SAVE REVIEW'),
      ),
      FilledButton(
        onPressed: saving ? null : () => _save('published'),
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: Text(saving ? 'SAVING…' : 'PUBLISH'),
      ),
    ],
  );

  Widget _privateSource() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    color: const Color(0xFFE7ECE9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIVATE SOURCE · REVIEWERS ONLY',
          style: TextStyle(
            color: _green,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '${widget.item.businessName} · ${widget.item.buyerEmail}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _Metric('MODEL SCORE', _rawValue('viability_score')),
            _Metric('RISK', _rawValue('risk_score')),
            _Metric('DATA COMPLETENESS', _rawValue('data_completeness')),
            _Metric('DSCR', _rawValue('dscr')),
            _Metric('PAYBACK YEARS', _rawValue('payback_years')),
          ],
        ),
      ],
    ),
  );

  String _rawValue(String key) {
    final value = widget.item.assessmentResults[key];
    if (value is num) return value.toStringAsFixed(1);
    return '—';
  }
}

class _MemberAccessCard extends StatefulWidget {
  const _MemberAccessCard({required this.member, required this.onChanged});
  final AffinityMemberAccount member;
  final VoidCallback onChanged;

  @override
  State<_MemberAccessCard> createState() => _MemberAccessCardState();
}

class _MemberAccessCardState extends State<_MemberAccessCard> {
  bool saving = false;

  Future<void> _set(bool approve) async {
    setState(() => saving = true);
    try {
      await AffinityAdminService.setMemberAccess(
        providerId: widget.member.id,
        verified: approve,
        tier: approve ? 'professional' : 'free',
        membershipStatus: approve ? 'active' : 'cancelled',
        onboardingStatus: approve ? 'verified' : 'suspended',
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    color: Colors.white,
    child: Wrap(
      spacing: 18,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.member.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.member.companyName} · ${widget.member.email} · ${widget.member.providerType.replaceAll('_', ' ')}',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 7),
              Text(
                '${widget.member.onboardingStatus.toUpperCase()} · ${widget.member.membershipTier.toUpperCase()} · ${widget.member.membershipStatus.toUpperCase()}',
                style: const TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            if (!widget.member.verified)
              FilledButton(
                onPressed: saving ? null : () => _set(true),
                style: FilledButton.styleFrom(backgroundColor: _green),
                child: const Text('APPROVE MEMBER'),
              )
            else
              OutlinedButton(
                onPressed: saving ? null : () => _set(false),
                child: const Text('SUSPEND ACCESS'),
              ),
          ],
        ),
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    color: status == 'published'
        ? const Color(0xFFDCECE4)
        : const Color(0xFFEDEAE4),
    child: Text(
      status.replaceAll('_', ' ').toUpperCase(),
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 300,
    child: Center(child: CircularProgressIndicator(color: _green)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(42),
    color: Colors.white,
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: _muted, height: 1.5),
    ),
  );
}
