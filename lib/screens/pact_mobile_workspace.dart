import 'dart:async';
import '../widgets/pact_mobile_surface.dart';
import 'pact_professional_matches.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/workspace_role_gate.dart';
import '../services/workspace_role_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/business_sale_bulletin_service.dart';
import '../services/deal_room_service.dart';
import '../services/pact_messaging_service.dart';
import '../services/pact_mobile_workspace_service.dart';

const pactMobileAccent = Color(0xFF6255DC);
const _ink = Color(0xFF222332);
const _muted = Color(0xFF737582);

/// The shared messaging screen owns authentication, realtime and the outbox.
/// This shell only chooses a workspace and renders authorized account data.
class PactMobileWorkspace extends StatefulWidget {
  const PactMobileWorkspace({
    super.key,
    required this.userId,
    required this.messaging,
    required this.messages,
    required this.profile,
    required this.tab,
    required this.onOpenThread,
    required this.threads,
    this.account,
    this.service,
    this.onContact,
  });
  final String userId;
  final PactMessagingService messaging;
  final Widget messages, profile;
  final ValueNotifier<int> tab;
  final void Function(MessageRow) onOpenThread;
  final List<MessageRow> threads;
  final AccountProfile? account;
  final PactMobileWorkspaceService? service;
  final Future<void> Function(String)? onContact;
  @override
  State<PactMobileWorkspace> createState() => _PactMobileWorkspaceState();
}

class _PactMobileWorkspaceState extends State<PactMobileWorkspace>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? PactMobileWorkspaceService();
  PactMobileRole _role = PactMobileRole.buyer;
  bool _loading = true, _checkingRole = true, _needsRole = false;
  String? _choiceError;
  final Set<String> _failures = {};
  int _generation = 0, _days = 7;
  List<BusinessSaleBulletin> _businesses = [];
  List<SellerPostStats> _listings = [];
  List<DealRoom> _deals = [];
  List<IntroductionRequest> _leads = [];
  Map<String, List<Map<String, dynamic>>> _insights = {};
  String _query = '';
  String? _listingId;
  bool get _current => mounted && BackendService.user?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_recognize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recognize());
  }

  Future<void> _recognize() async {
    final generation = ++_generation;
    setState(() {
      _checkingRole = true;
      _leads = [];
    });
    try {
      final role = await _service.loadRole();
      if (!_current || generation != _generation) return;
      setState(() {
        _needsRole = role == null;
        if (role != null) _role = role;
        _checkingRole = false;
        _failures.remove('Account recognition');
      });
      if (role != null) await _reload();
    } catch (_) {
      if (!_current || generation != _generation) return;
      setState(() {
        _failures.add('Account recognition');
        _loading = false;
      });
    }
  }

  Future<void> _chooseRole(WorkspaceRole value) async {
    final generation = _generation;
    try {
      final role = await _service.chooseRole(value);
      if (!_current || generation != _generation) return;
      setState(() {
        _role = role;
        _needsRole = false;
        _choiceError = null;
      });
      widget.tab.value = 0;
      await _reload();
    } catch (_) {
      if (_current && generation == _generation) {
        setState(
          () =>
              _choiceError = 'Could not save your workspace. Please try again.',
        );
      }
    }
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final role = _role;
    setState(() {
      _loading = true;
      _failures.clear();
    });
    // Independent failures must not turn missing analytics into invented zeros.
    Future<void> load<T>(
      String name,
      Future<T> Function() read,
      void Function(T) save,
    ) async {
      try {
        final value = await read();
        if (_current && generation == _generation) setState(() => save(value));
      } catch (_) {
        if (_current && generation == _generation) {
          setState(() => _failures.add(name));
        }
      }
    }

    await Future.wait([
      load('Transactions', _service.deals, (v) => _deals = v),
      if (role == PactMobileRole.buyer)
        load('Businesses', _service.businesses, (v) => _businesses = v),
      if (role == PactMobileRole.seller) ...[
        load('Listings', _service.listings, (v) => _listings = v),
        load(
          'Listing insights',
          () => _service.insights(_days),
          (v) => _insights = v,
        ),
      ],
      if (role == PactMobileRole.member)
        load('Leads', _service.leads, (v) => _leads = v),
    ]);
    if (_current && generation == _generation) setState(() => _loading = false);
  }

  void _go(int tab) {
    widget.tab.value = tab;
  }

  Future<void> _web(String module) async {
    final uri = Uri.https('dwelling-iq-app.pages.dev', '/', {'module': module});
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Unavailable');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Pact. Please try again.'),
          ),
        );
      }
    }
  }

  Widget _card(Widget child, {Color color = Colors.white}) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(color: Colors.white.withValues(alpha: .8)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
  Widget _title(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(color: _muted, height: 1.5)),
        ],
      ],
    ),
  );
  Widget _section(
    String title, {
    VoidCallback? onTap,
    String action = 'View all',
  }) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
        ),
        if (onTap != null) TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
  Widget _icon(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .65), color],
      ),
      borderRadius: BorderRadius.circular(13),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .16),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 23),
  );
  Widget _empty(
    String title,
    String body, {
    String? action,
    VoidCallback? onTap,
  }) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_outlined, color: pactMobileAccent),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: _muted, height: 1.5)),
        if (action != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ],
    ),
  );
  Widget _stat(String label, String number, IconData icon) => Expanded(
    child: _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: pactMobileAccent, size: 22),
          const SizedBox(height: 15),
          Text(
            number,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    ),
  );
  Widget _action(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _icon(icon, color),
              const Icon(Icons.north_east, color: _muted, size: 19),
            ],
          ),
          const SizedBox(height: 18),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
  Widget _home() {
    final unread = widget.threads.fold<int>(
      0,
      (sum, row) => sum + ((row['unread_count'] as num?)?.toInt() ?? 0),
    );
    final active = _deals.where((r) => r.archivedAt == null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'Ready for your\nnext chapter?',
          subtitle:
              'Your ${_role.label.toLowerCase()} workspace, wherever you are.',
        ),
        _card(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your next move',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unread > 0
                          ? 'You have $unread unread messages.'
                          : active.isNotEmpty
                          ? active.first.currentStep
                          : 'Keep your conversations and next steps together.',
                      style: const TextStyle(color: _muted, height: 1.5),
                    ),
                    TextButton(
                      onPressed: () => _go(2),
                      child: const Text('Open messages →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _icon(Icons.bolt_rounded, const Color(0xFFF4A844)),
            ],
          ),
          color: const Color(0xFFF5F2FF),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _stat(
              'Conversations',
              '${widget.threads.where((t) => t['status'] == 'accepted').length}',
              Icons.forum_outlined,
            ),
            const SizedBox(width: 8),
            _stat(
              _role == PactMobileRole.seller
                  ? 'Listings'
                  : _role == PactMobileRole.member
                  ? 'Inquiries'
                  : 'Transactions',
              _role == PactMobileRole.seller
                  ? (_failures.contains('Listings')
                        ? '—'
                        : '${_listings.length}')
                  : _role == PactMobileRole.member
                  ? (_failures.contains('Leads') ? '—' : '${_leads.length}')
                  : (_failures.contains('Transactions')
                        ? '—'
                        : '${active.length}'),
              Icons.work_outline,
            ),
          ],
        ),
        _section('Quick actions'),
        Row(
          children: [
            Expanded(
              child: _action(
                _role.tabs[1],
                _role == PactMobileRole.member
                    ? Icons.people_outline
                    : Icons.storefront_outlined,
                pactMobileAccent,
                () => _go(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _action(
                'Send a message',
                Icons.mail_outline,
                const Color(0xFFDA569C),
                () => _go(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _action(
                _role.tabs[3],
                Icons.explore_outlined,
                const Color(0xFF36AD96),
                () => _go(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _action(
                'Edit profile',
                Icons.person_outline,
                const Color(0xFF9867D6),
                () => _go(4),
              ),
            ),
          ],
        ),
        _section(
          'Active transactions',
          onTap: () => _web('${_role.name}-dashboard'),
          action: 'Manage on web',
        ),
        if (!_failures.contains('Transactions')) ...[
          if (active.isEmpty)
            _empty(
              'Room for your next deal',
              'Transactions you create on Pact will appear here.',
            ),
          for (final room in active.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.currentStage.replaceAll('_', ' '),
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: room.progress.clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${room.completedTaskCount} of ${room.totalTaskCount} tasks complete',
                    ),
                    if (room.targetCloseDate != null)
                      Text(
                        'Target close · ${DateFormat.yMMMd().format(room.targetCloseDate!)}',
                      ),
                  ],
                ),
              ),
            ),
        ],
        _section('Recent conversations', onTap: () => _go(2)),
        ...widget.threads.take(3).map(_threadTile),
        if (widget.threads.isEmpty)
          _empty(
            'A quieter inbox',
            'Your shared Pact conversations will appear here.',
          ),
      ],
    );
  }

  Widget _threadTile(MessageRow row) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _card(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFECE8FF),
          child: Icon(Icons.person_outline, color: pactMobileAccent),
        ),
        title: Text(
          '${row['title'] ?? 'Conversation'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${row['preview'] ?? 'Open conversation'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.north_east, size: 20),
        onTap: () {
          _go(2);
          widget.onOpenThread(row);
        },
      ),
    ),
  );

  Widget _businessList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(
        'Find your next\nopportunity',
        subtitle:
            'Businesses listed on Pact. Save them to revisit on any device.',
      ),
      TextField(
        onChanged: (v) => setState(() => _query = v.toLowerCase()),
        decoration: const InputDecoration(
          hintText: 'Search businesses',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 20),
      if (_businesses.isEmpty && !_failures.contains('Businesses'))
        _empty(
          'New opportunities start here',
          'There are no published businesses to show right now.',
        ),
      ..._businesses
          .where(
            (b) => '${b.title} ${b.industry} ${b.region}'
                .toLowerCase()
                .contains(_query),
          )
          .map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _businessDetail(b),
                child: _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.photos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            b.photos.first,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox(height: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        b.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${b.industry} · ${b.region}',
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.askingPriceBand,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            b.isSaved ? Icons.favorite : Icons.north_east,
                            color: b.isSaved ? const Color(0xFFCB4589) : _muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ],
  );

  Future<void> _businessDetail(BusinessSaleBulletin listing) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MobileBusinessDetail(listing: listing),
      ),
    );
    if (_current) await _reload();
  }

  Widget _listingPage() {
    final posts = _listings
        .where((p) => _listingId == null || p.listing.id == _listingId)
        .toList();
    final counts = <String, int>{};
    for (final post in posts) {
      for (final row
          in _insights[post.listing.id] ?? <Map<String, dynamic>>[]) {
        final day = '${row['day']}';
        counts[day] = (counts[day] ?? 0) + (row['count'] as num).toInt();
      }
    }
    final total = posts.fold<int>(0, (s, p) => s + p.saves);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(
          'My Listing',
          subtitle: 'A clear picture of how buyers are saving your business.',
        ),
        if (_listings.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _listingId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Listing'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All my listings')),
              ..._listings.map(
                (p) => DropdownMenuItem(
                  value: p.listing.id,
                  child: Text(p.listing.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _listingId = v == '' ? null : v),
          ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: {_days},
          onSelectionChanged: _loading
              ? null
              : (v) {
                  setState(() => _days = v.first);
                  _reload();
                },
        ),
        const SizedBox(height: 18),
        if (!_failures.contains('Listings'))
          Row(
            children: [
              _stat('Current saves', '$total', Icons.bookmark_border),
              const SizedBox(width: 10),
              _stat(
                'Active listings',
                '${posts.where((p) => p.status == 'active').length}',
                Icons.storefront_outlined,
              ),
            ],
          ),
        _section('When buyers saved'),
        if (!_failures.contains('Listing insights') &&
            !_failures.contains('Listings'))
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current bookmarks by save date (UTC)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                PactListingSaveChart(counts: counts, days: _days),
                const SizedBox(height: 14),
                const Text(
                  'Only bookmarks still saved are counted. Removing a save also removes it from this chart.',
                  style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _card(
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _muted, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Views and listing-specific enquiries are not tracked yet. No estimates or market comparisons are shown.',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        _section(
          'Your posts',
          onTap: () => _web('seller-posts'),
          action: 'Manage on web',
        ),
        if (_listings.isEmpty && !_failures.contains('Listings'))
          _empty(
            'Your listing belongs here',
            'Publish your business on the Pact website and its listing and buyer saves will appear here.',
            action: 'Open seller workspace',
            onTap: () => _web('seller-dashboard'),
          ),
        for (final post in posts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _card(
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(post.listing.title),
                subtitle: Text(
                  '${post.status} · ${post.saves} saves\n${post.listing.askingPriceBand}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.north_east),
                onTap: () => _businessDetail(post.listing),
              ),
            ),
          ),
      ],
    );
  }

  Widget _clients() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(
        'Clients',
        subtitle: 'People already connected to you through Pact conversations.',
      ),
      ...widget.threads
          .where((t) => t['status'] == 'accepted')
          .map(_threadTile),
      if (!widget.threads.any((t) => t['status'] == 'accepted'))
        _empty(
          'Build connections, thoughtfully',
          'Accepted conversations appear here. Buyer and seller contacts begin with their inquiry.',
          action: 'Review message requests',
          onTap: () => _go(2),
        ),
    ],
  );
  Future<void> _editLead(IntroductionRequest lead) async {
    final note = TextEditingController(text: lead.providerNotes);
    var status = lead.status;
    const statuses = [
      'pending',
      'accepted',
      'qualified',
      'contacted',
      'consultation',
      'won',
      'lost',
      'declined',
      'closed',
    ];
    if (!statuses.contains(status)) status = 'pending';
    bool saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            lead.requesterName.isEmpty ? 'Client inquiry' : lead.requesterName,
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.propertySummary),
                  const SizedBox(height: 14),
                  if (lead.requesterEmail.isNotEmpty)
                    SelectableText(lead.requesterEmail),
                  if (lead.requesterPhone.isNotEmpty)
                    SelectableText(lead.requesterPhone),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      for (final value in statuses)
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => update(() => status = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: note,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Private notes',
                    ),
                    enabled: !saving,
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving || status == 'pending'
                  ? null
                  : () async {
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        if (!_current) {
                          throw StateError('Account changed');
                        }
                        await _service.updateLead(
                          lead,
                          status,
                          note.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (_current) await _reload();
                      } catch (_) {
                        if (dialogContext.mounted) {
                          update(() {
                            saving = false;
                            error =
                                'Could not save. Your notes are still here; please retry.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save inquiry'),
            ),
          ],
        ),
      ),
    );
    // Wait for route disposal before releasing the editor controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    note.dispose();
  }

  Widget _leadPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(
        'Leads',
        subtitle:
            'Contact requests sent to your professional profile on the Pact website.',
      ),
      if (_leads.isEmpty && !_failures.contains('Leads'))
        _empty(
          'You’re ready for the next inquiry',
          'New professional inquiries appear here after a customer contacts you.',
        ),
      ..._leads.map(
        (lead) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.requesterName.isEmpty
                      ? 'Client inquiry'
                      : lead.requesterName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${lead.status} · ${DateFormat.yMMMd().format(lead.createdAt)}',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                Text(lead.propertySummary),
                if (lead.nextFollowUpAt != null)
                  Text(
                    'Follow up · ${DateFormat.yMMMd().format(lead.nextFollowUpAt!)}',
                  ),
                TextButton(
                  onPressed: () => _editLead(lead),
                  child: const Text('Review inquiry →'),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Member accounts can reply to incoming buyer and seller conversations. They cannot start unsolicited conversations.',
        style: TextStyle(color: _muted, height: 1.5),
      ),
    ],
  );

  Widget _findBuyers() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(
        'Find Buyers',
        subtitle:
            'Make your listing easy to discover and keep incoming conversations moving.',
      ),
      _empty(
        'Let interested buyers come to you',
        'Pact keeps buyer identities private. There is no searchable directory of private buyer accounts.',
        action: 'Manage my listing',
        onTap: () => _go(1),
      ),
      _section('Your conversations', onTap: () => _go(2)),
      ...widget.threads.map(_threadTile),
      if (widget.threads.isEmpty)
        _empty(
          'No conversations yet',
          'You’ll see conversations here when people connect with you through Pact.',
        ),
    ],
  );
  Widget _help() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(
        'A little help\ngoes a long way',
        subtitle:
            'Connect with a Pact professional or pick up where you left off on the web.',
      ),
      _empty(
        'Find the right professional',
        'Compare relevant specialties and experience for your specific deal.',
        action: 'Match professionals to a deal',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PactProfessionalMatchesPage(onContact: widget.onContact),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _empty(
        'Your full workspace',
        'Research, calculations and detailed transaction tools are available on the Pact website.',
        action: 'Open buyer workspace',
        onTap: () => _web('buyer-dashboard'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: pactMobileAccent,
        brightness: Brightness.light,
      ),
      textTheme: Theme.of(
        context,
      ).textTheme.apply(bodyColor: _ink, displayColor: _ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xDFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    child: ValueListenableBuilder<int>(
      valueListenable: widget.tab,
      builder: (context, tab, _) {
        if (_needsRole && !_checkingRole) {
          return Scaffold(
            body: SafeArea(
              child: WorkspaceChoice(
                onChoose: _chooseRole,
                error: _choiceError,
              ),
            ),
          );
        }

        final labels = _role.tabs;
        final icons = [
          Icons.home_rounded,
          _role == PactMobileRole.member
              ? Icons.people_outline
              : Icons.storefront_outlined,
          Icons.chat_bubble_outline,
          _role == PactMobileRole.buyer
              ? Icons.help_outline
              : _role == PactMobileRole.seller
              ? Icons.person_search_outlined
              : Icons.trending_up,
          Icons.person_outline,
        ];
        final page = tab == 1
            ? switch (_role) {
                PactMobileRole.buyer => _businessList(),
                PactMobileRole.seller => _listingPage(),
                PactMobileRole.member => _clients(),
              }
            : tab == 3
            ? switch (_role) {
                PactMobileRole.buyer => _help(),
                PactMobileRole.seller => _findBuyers(),
                PactMobileRole.member => _leadPage(),
              }
            : _home();
        return PactMobileSurface(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              color: Colors.transparent,
              child: SafeArea(
                top: tab != 4,
                child: Column(
                  children: [
                    if (tab != 4)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 16, 6),
                        child: Row(
                          children: [
                            const Text(
                              'PACT',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.4,
                              ),
                            ),
                            const Spacer(),
                            if (!_checkingRole && !_needsRole)
                              Text(
                                _role.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Open profile',
                              onPressed: () => _go(4),
                              icon: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    widget.account?.photoUrl.isNotEmpty == true
                                    ? NetworkImage(widget.account!.photoUrl)
                                    : null,
                                child:
                                    widget.account?.photoUrl.isNotEmpty == true
                                    ? null
                                    : const Icon(
                                        Icons.person_outline,
                                        color: pactMobileAccent,
                                        size: 21,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _checkingRole
                          ? Center(
                              child: _failures.contains('Account recognition')
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Could not recognize your account.',
                                        ),
                                        TextButton(
                                          onPressed: _recognize,
                                          child: const Text('Retry'),
                                        ),
                                        TextButton(
                                          onPressed: BackendService.signOut,
                                          child: const Text('Sign out'),
                                        ),
                                      ],
                                    )
                                  : const CircularProgressIndicator(),
                            )
                          : tab == 2
                          ? widget.messages
                          : tab == 4
                          ? widget.profile
                          : RefreshIndicator(
                              onRefresh: _reload,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  0,
                                  22,
                                  28,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  if (_loading)
                                    const LinearProgressIndicator(minHeight: 2),
                                  if (_failures.isNotEmpty)
                                    _card(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Could not refresh: ${_failures.join(', ')}. Previously loaded information may be out of date.',
                                          ),
                                          TextButton(
                                            onPressed: _reload,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  page,
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _checkingRole
                ? null
                : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x09000000),
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Expanded(
                                child: Semantics(
                                  selected: i == tab,
                                  child: InkWell(
                                    onTap: () => _go(i),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icons[i],
                                            color: tab == i
                                                ? pactMobileAccent
                                                : _muted,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            labels[i],
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: tab == i
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: tab == i
                                                  ? pactMobileAccent
                                                  : _muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    ),
  );
}

class PactListingSaveChart extends StatelessWidget {
  const PactListingSaveChart({
    super.key,
    required this.counts,
    required this.days,
    this.now,
  });
  final Map<String, int> counts;
  final int days;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final today = (now ?? DateTime.now()).toUtc();
    final end = DateTime.utc(today.year, today.month, today.day);
    final buckets = <int>[];
    final bucketDays = days == 90
        ? 15
        : days == 30
        ? 5
        : 1;
    final starts = <DateTime>[];
    for (var offset = days - 1; offset >= 0; offset -= bucketDays) {
      final start = end.subtract(Duration(days: offset));
      starts.add(start);
      var n = 0;
      for (var j = 0; j < bucketDays; j++) {
        n +=
            counts[DateFormat(
              'yyyy-MM-dd',
            ).format(start.add(Duration(days: j)))] ??
            0;
      }
      buckets.add(n);
    }
    final max = buckets.fold<int>(1, (a, b) => a > b ? a : b);
    return Semantics(
      label:
          'Current saves by date: ${[for (var i = 0; i < buckets.length; i++) '${DateFormat.MMMd().format(starts[i])}: ${buckets[i]}'].join(', ')}',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${buckets[i]}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: buckets[i] == 0
                                ? 3
                                : 118 * buckets[i] / max,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFABA0FA), pactMobileAccent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.MMMd().format(starts.first),
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              Text(
                DateFormat.MMMd().format(end),
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileBusinessDetail extends StatefulWidget {
  const _MobileBusinessDetail({required this.listing});
  final BusinessSaleBulletin listing;
  @override
  State<_MobileBusinessDetail> createState() => _MobileBusinessDetailState();
}

class _MobileBusinessDetailState extends State<_MobileBusinessDetail> {
  late bool _saved = widget.listing.isSaved;
  bool _busy = false;
  Future<void> _save() async {
    final user = BackendService.user?.id;
    setState(() => _busy = true);
    try {
      await BusinessSaleBulletinService.setSaved(widget.listing.id, !_saved);
      if (mounted && user == BackendService.user?.id) {
        setState(() => _saved = !_saved);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this listing. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.listing;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Business details'),
        actions: [
          IconButton(
            tooltip: _saved ? 'Unsave listing' : 'Save listing',
            onPressed: _busy ? null : _save,
            icon: Icon(
              _saved ? Icons.favorite : Icons.favorite_border,
              color: pactMobileAccent,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          if (b.photos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                b.photos.first,
                height: 230,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 22),
          Text(
            b.title,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '${b.industry} · ${b.region}',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 22),
          Text(
            b.askingPriceBand,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Text(b.summary, style: const TextStyle(fontSize: 16, height: 1.6)),
          for (final key in [
            'highlights',
            'revenue',
            'cash_flow',
            'real_estate',
            'location_details',
            'reason_for_selling',
          ])
            if (b.detail(key).isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                key.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                b.detail(key),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
            label: Text(
              _saved
                  ? 'Saved to your Pact account'
                  : 'Save to your Pact account',
            ),
          ),
        ],
      ),
    );
  }
}
