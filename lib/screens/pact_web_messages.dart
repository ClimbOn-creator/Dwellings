import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/backend_service.dart';
import '../services/pact_messaging_service.dart';
import '../services/pact_web_demo_service.dart';
import 'auth_page.dart';
import '../widgets/site_inline_editor.dart';

/// The same account inbox inside Pact's existing web dashboards.
/// Contact direction and membership are authorized by the server, never this UI.
class PactWebMessages extends StatefulWidget {
  const PactWebMessages({
    super.key,
    this.workspace = 'general',
    this.initialProviderId,
    this.initialThreadId,
    this.service,
    this.onExit,
  });
  final VoidCallback? onExit;
  final String workspace;
  final String? initialProviderId, initialThreadId;
  final PactMessagingService? service;
  @override
  State<PactWebMessages> createState() => _PactWebMessagesState();
}

class PactWebMessagesPage extends StatelessWidget {
  const PactWebMessagesPage({
    super.key,
    this.providerId,
    this.threadId,
    this.workspace = 'general',
  });
  final String? providerId, threadId;
  final String workspace;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    body: PactWebMessages(
      initialProviderId: providerId,
      initialThreadId: threadId,
      workspace: workspace,
    ),
  );
}

class _PactWebMessagesState extends State<PactWebMessages>
    with WidgetsBindingObserver {
  late final _api =
      widget.service ??
      PactWebDemoService(enabled: widget.workspace == 'buyer');
  final _search = TextEditingController(), _composer = TextEditingController();
  final _scroll = ScrollController();
  List<MessageRow> _threads = [], _messages = [], _members = [];
  MessageRow? _selected;
  final List<MessageRow> _optimistic = [];
  bool _refreshAgain = false;
  PactOutbox? _outbox;
  RealtimeChannel? _channel;
  StreamSubscription<dynamic>? _auth;
  Timer? _timer;
  String? _actor, _error, _connectionError, _nextThread;
  bool _loading = true,
      _refreshing = false,
      _sending = false,
      _foreground = true,
      _requests = false,
      _isMember = false;
  int _generation = 0;
  static const _dark = false;
  Color get _canvas => _dark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _sidebar =>
      _dark ? const Color(0xFF111113) : const Color(0xFFF6F6F8);
  Color get _text => _dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
  Color get _muted => _dark ? const Color(0xFFAAAAB0) : const Color(0xFF73737A);
  Color get _line => _dark ? const Color(0xFF3A3A3C) : const Color(0xFFDADAE0);
  static const _pink = Color(0xFFB52B70);
  static const _selectionPink = Color(0xFFFCE1EC);
  static const _selectionText = Color(0xFF682044);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SiteEditorOverlayGate.hide(this);
    });
    WidgetsBinding.instance.addObserver(this);
    _nextThread = widget.initialThreadId;
    _auth = BackendService.authChanges?.listen((_) => _accountChanged());
    _search.addListener(_changed);
    _accountChanged();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_foreground) _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant PactWebMessages old) {
    super.didUpdateWidget(old);
    if (old.initialProviderId != widget.initialProviderId &&
        widget.initialProviderId != null) {
      _openMember(widget.initialProviderId!);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _accountChanged() {
    final id = BackendService.user?.id;
    if (id == _actor) {
      if (_loading && id == null) setState(() => _loading = false);
      return;
    }
    _generation++;
    final channel = _channel;
    if (channel != null) unawaited(_api.stopListening(channel));
    _channel = null;
    _outbox?.removeListener(_changed);
    _outbox?.dispose();
    _outbox = null;
    _actor = id;
    _threads = [];
    _messages = [];
    _optimistic.clear();
    _members = [];
    _selected = null;
    _composer.clear();
    _search.clear();
    _error = null;
    _connectionError = null;
    _loading = id != null;
    _isMember = false;
    _requests = false;
    if (mounted) setState(() {});
    if (id != null) {
      _outbox = PactOutbox(id, _api)..addListener(_changed);
      _channel = _api.listen(id, _refresh);
      _initialize(_generation);
    }
  }

  Future<void> _initialize(int generation) async {
    try {
      await _outbox?.restore();
      final caps = await _api.call('capabilities');
      if (!mounted || generation != _generation) return;
      setState(() => _isMember = caps['is_member'] == true);
      await _refresh();
      if (widget.initialProviderId != null &&
          mounted &&
          generation == _generation) {
        await _openMember(widget.initialProviderId!);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _connectionError = 'Could not load messages. Please retry.';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  Future<void> _refresh() async {
    if (_actor == null || !_foreground) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    final generation = _generation;
    try {
      final rows = await _api.rows('list');
      if (!mounted || generation != _generation) return;
      final currentId = _nextThread ?? _selected?['id'];
      setState(() {
        _threads = rows;
        _loading = false;
        _connectionError = null;
      });
      if (currentId != null) {
        final thread = rows.where((r) => r['id'] == currentId).firstOrNull;
        if (thread == null) {
          setState(() {
            _selected = null;
            _messages = [];
            _members = [];
          });
        } else {
          if (_selected?['id'] != currentId) {
            _messages = [];
            _members = [];
          }
          setState(() => _selected = thread);
          await _load(thread, generation);
        }
        _nextThread = null;
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _connectionError =
              'Connection interrupted. Your saved messages will return when you reconnect.';
        });
      }
    } finally {
      _refreshing = false;
      if (_refreshAgain && mounted) {
        _refreshAgain = false;
        unawaited(_refresh());
      }
    }
  }

  Future<void> _load(MessageRow thread, int generation) async {
    final id = thread['id'];
    final members = await _api.rows('members', {'thread_id': id});
    final messages = await _api.rows('messages', {'thread_id': id});
    if (!mounted || generation != _generation || _selected?['id'] != id) return;
    await _outbox?.reconcile(messages.map((m) => m['id'] as String));
    if (!mounted || generation != _generation || _selected?['id'] != id) return;
    setState(() {
      _members = members;
      final merged = {
        for (final m in _messages) m['id']: m,
        for (final m in messages) m['id']: m,
      };
      _optimistic.removeWhere((m) => merged.containsKey(m['id']));
      _messages = merged.values.toList()
        ..sort(
          (a, b) => (a['sequence'] as num).compareTo(b['sequence'] as num),
        );
    });
    _markRead();
  }

  void _markRead() {
    if (_selected?['status'] != 'accepted' ||
        _messages.isEmpty ||
        !_foreground ||
        (_scroll.hasClients && _scroll.offset > 35)) {
      return;
    }
    final generation = _generation,
        id = _selected!['id'],
        seq = _messages.last['sequence'];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          generation != _generation ||
          _selected?['id'] != id ||
          !_foreground ||
          !_scroll.hasClients ||
          _scroll.offset > 35) {
        return;
      }
      try {
        await _api.call('read', {'thread_id': id, 'sequence': seq});
      } catch (_) {
        /* The next visible refresh retries. */
      }
    });
  }

  Future<void> _select(MessageRow row) async {
    setState(() {
      _selected = row;
      _messages = [];
      _members = [];
      _error = null;
    });
    try {
      await _load(row, _generation);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open the conversation. Please retry.',
        );
      }
    }
  }

  Future<void> _openMember(String providerId) async {
    final generation = _generation;
    try {
      final result = await _api.call('open_member', {
        'id': pactMessageId(),
        'provider_id': providerId,
        'context': widget.workspace,
      });
      if (!mounted || generation != _generation) return;
      _nextThread = result['id'] as String;
      _requests = false;
      await _refresh();
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'This member is unavailable, or the conversation is closed. Please retry if your connection was interrupted.',
        );
      }
    }
  }

  bool get _canSend =>
      _selected?['status'] == 'accepted' && _selected?['can_send'] == true;
  Future<void> _send() async {
    final body = _composer.text.trim(), id = _selected?['id'];
    if (body.isEmpty || id == null || !_canSend || _sending) return;
    final generation = _generation;
    setState(() => _sending = true);
    try {
      await _outbox!.enqueue(id as String, body);
      if (!mounted || generation != _generation) return;
      _optimistic.add(_outbox!.pending.last);
      _composer.clear();
      await _outbox!.flush();
      await _refresh();
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'Could not finish sending. Check the pending message and retry.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _respond(String status) async {
    try {
      await _api.call('respond', {
        'thread_id': _selected!['id'],
        'status': status,
      });
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update this request. Please retry.');
      }
    }
  }

  Future<void> _compose() async {
    final query = TextEditingController();
    List<MessageRow> choices = [];
    String? error;
    bool loading = true;
    int lookup = 0;
    final actor = _actor;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          Future<void> search() async {
            final request = ++lookup;
            update(() => loading = true);
            try {
              final rows = await _api.rows('directory', {
                'query': query.text.trim(),
              });
              if (context.mounted && request == lookup) {
                update(() {
                  choices = rows;
                  loading = false;
                  error = null;
                });
              }
            } catch (_) {
              if (context.mounted && request == lookup) {
                update(() {
                  loading = false;
                  error = 'Could not load members. Try again.';
                });
              }
            }
          }

          if (loading && lookup == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) search();
            });
          }
          return AlertDialog(
            title: const Text('New message'),
            content: SizedBox(
              width: 430,
              height: 410,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a Pact member. Members can reply to buyers and sellers after receiving their message.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: query,
                    decoration: InputDecoration(
                      labelText: 'Find a member',
                      suffixIcon: IconButton(
                        tooltip: 'Search members',
                        onPressed: search,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    onSubmitted: (_) => search(),
                  ),
                  if (loading) const LinearProgressIndicator(),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  Expanded(
                    child: ListView(
                      children: [
                        if (!loading && choices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('No available members found.'),
                          ),
                        ...choices.map(
                          (p) => ListTile(
                            leading: _avatar(
                              p['full_name']?.toString() ?? 'Member',
                              p['profile_photo_url']?.toString(),
                            ),
                            title: Text(p['full_name']?.toString() ?? 'Member'),
                            subtitle: Text(
                              [p['job_title'], p['company_name']]
                                  .whereType<String>()
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                            ),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              if (_actor == actor) {
                                _openMember(p['provider_id'] as String);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
    // Keep the controller through the route's closing animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    query.dispose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SiteEditorOverlayGate.restore(this),
    );
    _timer?.cancel();
    _auth?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(_api.stopListening(channel));
    _outbox?.removeListener(_changed);
    _outbox?.dispose();
    _search.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_actor == null) {
      return Center(
        child: FilledButton(
          onPressed: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
            _accountChanged();
          },
          child: const Text('Sign in to Messages'),
        ),
      );
    }
    final colors = ColorScheme.fromSeed(
      seedColor: _pink,
      brightness: _dark ? Brightness.dark : Brightness.light,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: _dark ? Brightness.dark : Brightness.light,
        colorScheme: colors,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: _text, displayColor: _text),
        iconTheme: IconThemeData(color: _muted),
        chipTheme: ChipThemeData(
          backgroundColor: _dark
              ? const Color(0xFF29292C)
              : const Color(0xFFE9E9EC),
          selectedColor: _pink,
          labelStyle: TextStyle(color: _text),
          checkmarkColor: Colors.white,
          side: BorderSide(color: _line),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _pink,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colors.primary),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: _sidebar,
          textStyle: TextStyle(color: _text),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.onExit == null ? 16 : 0),
        child: Material(
          color: _canvas,
          child: Column(
            children: [
              if (_error != null || _connectionError != null)
                MaterialBanner(
                  backgroundColor: _sidebar,
                  content: Text(
                    _error ?? _connectionError!,
                    style: TextStyle(color: _text),
                  ),
                  actions: [
                    TextButton(onPressed: _refresh, child: const Text('Retry')),
                    TextButton(
                      onPressed: () => setState(() {
                        _error = null;
                        _connectionError = null;
                      }),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final split = box.maxWidth >= 720;
                    return Row(
                      children: [
                        if (split || _selected == null)
                          SizedBox(
                            width: split ? 300 : box.maxWidth,
                            child: _inbox(),
                          ),
                        if (split) VerticalDivider(width: 1, color: _line),
                        if (split || _selected != null)
                          Expanded(
                            child: _selected == null
                                ? Center(
                                    child: Text(
                                      'Select a conversation',
                                      style: TextStyle(color: _muted),
                                    ),
                                  )
                                : _conversation(split),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String name, String? url, {double radius = 22}) =>
      CircleAvatar(
        radius: radius,
        backgroundColor: _dark
            ? const Color(0xFF565566)
            : const Color(0xFFE1E5EB),
        backgroundImage: url?.isNotEmpty == true ? NetworkImage(url!) : null,
        onBackgroundImageError: url?.isNotEmpty == true ? (_, _) {} : null,
        child: url?.isNotEmpty == true
            ? null
            : Text(
                name.trim().isEmpty
                    ? '?'
                    : name.trim().substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _dark ? Colors.white : const Color(0xFF394452),
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
  String _time(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return DateFormat.jm().format(date);
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(date);
  }

  Widget _inbox() {
    final q = _search.text.trim().toLowerCase();
    final rows = _threads
        .where(
          (r) =>
              (_requests
                  ? r['status'] == 'pending'
                  : r['status'] == 'accepted') &&
              ('${r['title']} ${r['preview']}'.toLowerCase().contains(q)),
        )
        .toList();
    final requests = _threads.where((r) => r['status'] == 'pending').length;
    return Container(
      color: _sidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 8, 10),
            child: Row(
              children: [
                if (widget.onExit != null)
                  IconButton(
                    tooltip: 'Back to dashboard',
                    onPressed: widget.onExit,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'New message',
                  onPressed: _compose,
                  icon: const Icon(Icons.edit_square),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              style: TextStyle(color: _text),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                hintStyle: TextStyle(color: _muted),
                prefixIcon: Icon(Icons.search, color: _muted),
                isDense: true,
                filled: true,
                fillColor: _canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: _line),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Inbox'),
                  labelStyle: TextStyle(
                    color: !_requests ? Colors.white : _text,
                  ),
                  selected: !_requests,
                  onSelected: (_) => setState(() => _requests = false),
                ),
                ChoiceChip(
                  label: Text(
                    requests > 0 ? 'Requests ($requests)' : 'Requests',
                  ),
                  labelStyle: TextStyle(
                    color: _requests ? Colors.white : _text,
                  ),
                  selected: _requests,
                  onSelected: (_) => setState(() => _requests = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        _requests
                            ? 'No message requests.'
                            : q.isNotEmpty
                            ? 'No matching conversations.'
                            : _isMember
                            ? 'Buyer and seller inquiries arrive here. You can reply after they message you.'
                            : 'Start a conversation with a Pact member.',
                        style: TextStyle(color: _muted, height: 1.5),
                      ),
                    ),
                  ...rows.map((r) {
                    final active = _selected?['id'] == r['id'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Material(
                        color: active ? _selectionPink : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: _avatar(
                            r['title'] as String,
                            r['photo_url'] as String?,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active ? _selectionText : _text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _time(r['updated_at']),
                                style: TextStyle(
                                  color: active ? _selectionText : _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            (r['preview'] as String?)?.isNotEmpty == true
                                ? r['preview'] as String
                                : r['status'] == 'pending'
                                ? 'Message request'
                                : 'Write your first message',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? _selectionText : _muted,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          trailing: (r['unread_count'] as num? ?? 0) > 0
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _pink,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () => _select(r),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversation(bool split) {
    final t = _selected!;
    final closed =
        _members.isNotEmpty &&
        _members
                .where(
                  (m) => m['status'] == 'accepted' || m['status'] == 'pending',
                )
                .length <
            2;
    final pending = <String, MessageRow>{
      for (final m in _optimistic.where((m) => m['thread_id'] == t['id']))
        m['id'] as String: m,
      for (final m in (_outbox?.pending ?? <MessageRow>[]).where(
        (m) => m['thread_id'] == t['id'],
      ))
        m['id'] as String: m,
    }.values.toList();
    final items = [
      ..._messages,
      ...pending.map((m) => {...m, 'local': true, 'sender_id': _actor}),
    ].reversed.toList();
    final outgoingOrder = <String, int>{};
    for (final message in items.reversed.where(
      (m) => m['sender_id'] == _actor,
    )) {
      outgoingOrder[message['id'] as String] = outgoingOrder.length;
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: _canvas,
            border: Border(bottom: BorderSide(color: _line)),
          ),
          child: Row(
            children: [
              if (!split)
                IconButton(
                  tooltip: 'Back to inbox',
                  onPressed: () => setState(() => _selected = null),
                  icon: const Icon(Icons.chevron_left),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  children: [
                    _avatar(
                      t['title'] as String,
                      t['photo_url'] as String?,
                      radius: 21,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (t['demo'] == true)
                      Text(
                        'Demo · simulated replies · browser session only',
                        style: TextStyle(color: _muted, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    if (t['status'] == 'pending')
                      Text(
                        'Message request',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (t['demo'] != true)
                PopupMenuButton<String>(
                  tooltip: 'Conversation options',
                  onSelected: (action) async {
                    try {
                      final id = t['id'];
                      if (action == 'leave') {
                        await _api.call('leave', {'thread_id': id});
                      } else {
                        final other = _members
                            .where((m) => m['id'] != _actor)
                            .firstOrNull;
                        if (other != null) {
                          await _api.call('block', {
                            'thread_id': id,
                            'user_id': other['id'],
                          });
                        }
                      }
                      await _refresh();
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => _error = 'Could not update the conversation.',
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave conversation'),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Block account'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (t['status'] == 'pending')
          Container(
            padding: const EdgeInsets.all(14),
            color: _sidebar,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    closed
                        ? 'This conversation is closed.'
                        : 'Accept to reply, or decline this request.',
                    style: TextStyle(color: _text),
                  ),
                ),
                TextButton(
                  onPressed: () => _respond('declined'),
                  child: const Text('Decline'),
                ),
                if (!closed)
                  FilledButton(
                    onPressed: () => _respond('accepted'),
                    child: const Text('Accept'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _markRead();
              return false;
            },
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final message = items[index];
                final date = DateTime.tryParse(
                  message['created_at']?.toString() ?? '',
                )?.toLocal();
                final older = index + 1 < items.length
                    ? DateTime.tryParse(
                        items[index + 1]['created_at']?.toString() ?? '',
                      )?.toLocal()
                    : null;
                final divider =
                    date != null &&
                    (older == null || !DateUtils.isSameDay(date, older));
                final lastOwn =
                    message['sender_id'] == _actor &&
                    !items.take(index).any((m) => m['sender_id'] == _actor);
                return Column(
                  children: [
                    if (divider)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          DateUtils.isSameDay(date, DateTime.now())
                              ? 'Today'
                              : DateFormat('EEE, MMM d').format(date),
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _bubble(
                      message,
                      lastOwn,
                      outgoingOrder[message['id']] ?? 0,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (closed && t['status'] == 'accepted')
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'This conversation is closed.',
              style: TextStyle(color: _muted),
            ),
          ),
        if (t['status'] == 'accepted' && !closed)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  if (!_canSend)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text(
                        _isMember
                            ? 'Waiting for an accepted conversation and an incoming inquiry before replying.'
                            : 'Your request has been sent. You can continue when the member accepts.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Focus(
                          onKeyEvent: (_, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed &&
                                !(_composer.value.composing.isValid &&
                                    !_composer.value.composing.isCollapsed)) {
                              if (_canSend && !_sending) _send();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            key: const ValueKey('web-message-composer'),
                            controller: _composer,
                            enabled: _canSend,
                            minLines: 1,
                            maxLines: 6,
                            maxLength: 4000,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(color: _text, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(color: _muted),
                              counterText: '',
                              filled: true,
                              fillColor: _sidebar,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide(color: _line),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: _canSend && !_sending ? _send : null,
                        style: IconButton.styleFrom(backgroundColor: _pink),
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _bubble(MessageRow message, bool last, int outgoingIndex) {
    final mine = message['sender_id'] == _actor,
        local = message['local'] == true;
    final seen =
        !local &&
        _members
            .where((m) => m['id'] != _actor && m['status'] == 'accepted')
            .any(
              (m) =>
                  (m['read_sequence'] as num? ?? 0) >=
                  (message['sequence'] as num? ?? 1),
            );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, box) => Container(
          constraints: BoxConstraints(
            maxWidth: math.min(560, box.maxWidth * .8),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  // One continuous vertical ribbon through sent messages: no
                  // clock animation and no message-text-dependent color jumps.
                  Color shade(double hue) {
                    final base = HSVColor.fromAHSV(1, hue % 360, .78, .92);
                    var low = 0.0, high = .92;
                    for (var i = 0; i < 12; i++) {
                      final value = (low + high) / 2;
                      if (base.withValue(value).toColor().computeLuminance() >
                          .16) {
                        high = value;
                      } else {
                        low = value;
                      }
                    }
                    return base.withValue(low).toColor();
                  }

                  final hue = 330.0 + outgoingIndex * 4;
                  final gradient = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [shade(hue), shade(hue + 4)],
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: mine ? gradient : null,
                      color: mine
                          ? null
                          : (_dark
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFFE9E9EB)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(21),
                        topRight: const Radius.circular(21),
                        bottomLeft: Radius.circular(mine ? 21 : 5),
                        bottomRight: Radius.circular(mine ? 5 : 21),
                      ),
                    ),
                    child: SelectableText(
                      message['body'] as String,
                      style: TextStyle(
                        color: mine ? Colors.white : _text,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
              if (local)
                Text(
                  message['failed'] == true ? 'Not sent' : 'Sending…',
                  style: TextStyle(
                    color: message['failed'] == true
                        ? Colors.redAccent
                        : _muted,
                    fontSize: 11,
                  ),
                ),
              if (local && message['failed'] == true)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _outbox!.flush();
                        await _refresh();
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () {
                        _optimistic.removeWhere(
                          (m) => m['id'] == message['id'],
                        );
                        _outbox!.discard(message['id'] as String);
                      },
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              if (!local && last && mine)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    seen ? 'Read' : 'Sent',
                    style: TextStyle(
                      color: seen ? Colors.redAccent : _muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (!local)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    _time(message['created_at']),
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
