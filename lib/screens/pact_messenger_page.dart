import 'package:flutter/cupertino.dart';
import '../widgets/pact_profile_panel.dart';
import 'pact_mobile_workspace.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/pact_messaging_service.dart';
import '../services/pact_push_service.dart';

const _pactGreen = Color(0xFF007D70);

class PactMessengerPage extends StatefulWidget {
  const PactMessengerPage({
    super.key,
    this.initialThreadId,
    this.service,
    this.mobileWorkspace = false,
  });
  final PactMessagingService? service;
  final bool mobileWorkspace;
  final String? initialThreadId;
  @override
  State<PactMessengerPage> createState() => _PactMessengerPageState();
}

class _PactMessengerPageState extends State<PactMessengerPage>
    with WidgetsBindingObserver {
  late final _api = widget.service ?? PactMessagingService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  List<MessageRow> _threads = [], _messages = [], _members = [];
  MessageRow? _selected;
  AccountProfile? _profile;
  PactOutbox? _outbox;
  Timer? _timer;
  RealtimeChannel? _channel;
  StreamSubscription<dynamic>? _auth;
  StreamSubscription<String>? _push;
  String? _error, _userId, _deepLink;
  int _tab = 0;
  final _mobileTab = ValueNotifier<int>(0);
  bool get _readingMessages =>
      widget.mobileWorkspace ? _mobileTab.value == 2 : _tab == 0;
  int _generation = 0;
  bool _busy = false,
      _refreshing = false,
      _foreground = true,
      _requests = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLink = widget.initialThreadId;
    if (_deepLink != null) _mobileTab.value = 2;
    _mobileTab.addListener(_visibleTabChanged);
    _auth = BackendService.authChanges?.listen(
      (_) => _accountChanged(),
      onError: (Object error) =>
          _showError('Google sign-in could not finish. Please try again.'),
    );
    _push = PactPushService.openThread.stream.listen((id) {
      _deepLink = id;
      _mobileTab.value = 2;
      _refresh();
    });
    _accountChanged();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_foreground) _refresh();
    });
  }

  void _accountChanged() {
    final id = BackendService.user?.id;
    if (id == _userId) return;
    final previousUser = _userId;
    _generation++;
    if (widget.mobileWorkspace && previousUser != null && previousUser != id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    final channel = _channel;
    if (channel != null) {
      unawaited(_api.stopListening(channel));
      _channel = null;
    }
    _userId = id;
    _mobileTab.value = _deepLink == null ? 0 : 2;
    _outbox?.dispose();
    _outbox = id == null ? null : PactOutbox(id, _api);
    _outbox?.addListener(_changed);
    _threads = [];
    _messages = [];
    _members = [];
    _selected = null;
    _profile = null;
    _busy = false;
    _composer.clear();
    if (mounted) setState(() {});
    if (id != null) {
      _channel = _api.listen(id, _refresh);
      _initializeAccount();
    }
  }

  Future<void> _initializeAccount() async {
    final generation = _generation;
    try {
      await _outbox?.restore();
      final profile = await AccountService.loadProfile();
      if (!mounted || generation != _generation) return;
      setState(() => _profile = profile);
      await _refresh();
      await PactPushService.restore(_api);
    } catch (_) {
      if (mounted && generation == _generation) {
        _showError('Could not load your account. Please retry.');
      }
    }
  }

  void _visibleTabChanged() {
    if (_mobileTab.value == 2) unawaited(_refresh());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing || _userId == null || !_foreground) return;
    _refreshing = true;
    final generation = _generation;
    final selectedId = _selected?['id'];
    try {
      // Failed messages remain visible for an explicit retry. Reconnection still
      // reloads authoritative history even if a previous push was missed.
      final threads = await _api.rows('list');
      if (!mounted || generation != _generation) return;
      setState(() {
        _threads = threads;
        _error = null;
      });
      final id = _deepLink ?? selectedId;
      if (id != null) {
        final matches = threads.where((r) => r['id'] == id);
        if (matches.isEmpty) {
          if (_deepLink != null) {
            _showError('This conversation is no longer available.');
          }
          setState(() {
            _selected = null;
            _messages = [];
            _members = [];
          });
        } else if (_selected?['id'] == selectedId || _deepLink != null) {
          final row = matches.first;
          setState(() {
            _selected = row;
            if (_deepLink != null) {
              _tab = 0;
              _mobileTab.value = 2;
            }
          });
          await _loadThread(row, generation);
        }
        _deepLink = null;
      }
    } catch (_) {
      if (generation == _generation) {
        _showError(
          'Connection interrupted. Your messages are saved; pull to retry.',
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadThread(MessageRow thread, int generation) async {
    final id = thread['id'];
    final members = await _api.rows('members', {'thread_id': id});
    final messages = await _api.rows('messages', {'thread_id': id});
    if (!mounted || generation != _generation || _selected?['id'] != id) return;
    await _outbox?.reconcile(messages.map((row) => row['id'] as String));
    if (!mounted || generation != _generation || _selected?['id'] != id) return;
    setState(() {
      _members = members;
      final merged = {
        for (final r in _messages) r['id']: r,
        for (final r in messages) r['id']: r,
      };
      _messages = merged.values.toList()
        ..sort(
          (a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int),
        );
    });
    // Only advance after a frame containing these messages was rendered while
    // the conversation is foregrounded; never use server NOW as a read cursor.
    if (messages.isNotEmpty &&
        _foreground &&
        _readingMessages &&
        !(_outbox?.pending.any((r) => r['thread_id'] == id) ?? false) &&
        (!_scroll.hasClients || _scroll.offset < 20)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted ||
            generation != _generation ||
            _selected?['id'] != id ||
            !_foreground ||
            !_readingMessages ||
            !_scroll.hasClients ||
            _scroll.offset >= 20 ||
            (_outbox?.pending.any((r) => r['thread_id'] == id) ?? false)) {
          return;
        }
        try {
          await _api.call('read', {
            'thread_id': id,
            'sequence': messages.last['sequence'],
          });
        } catch (_) {
          /* next refresh retries */
        }
      });
    }
  }

  Future<void> _select(MessageRow row) async {
    setState(() {
      _selected = row;
      _messages = [];
      _members = [];
      _composer.clear();
    });
    try {
      await _loadThread(row, _generation);
    } catch (_) {
      _showError('Could not open this conversation. Retry when connected.');
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty ||
        _selected == null ||
        _busy ||
        _selected?['can_send'] == false) {
      return;
    }
    final generation = _generation;
    final outbox = _outbox!;
    setState(() => _busy = true);
    try {
      await outbox.enqueue(_selected!['id'] as String, body);
      if (!mounted || generation != _generation) return;
      _composer.clear();
      await outbox.flush();
      await _refresh();
    } catch (_) {
      if (mounted && generation == _generation) {
        _showError(
          'Could not finish sending. Check your connection and pending messages.',
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await BackendService.signInWithGoogle();
    } catch (_) {
      _showError(
        'Could not open Google sign-in. Please check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountService.signIn(_email.text, _password.text);
      _password.clear();
      _accountChanged();
    } catch (_) {
      _showError(
        'Could not sign in. Check your email, password and connection.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newConversation() async {
    if (widget.mobileWorkspace) {
      await _mobileNewConversation();
      return;
    }
    final username = TextEditingController(), title = TextEditingController();
    final people = <MessageRow>[];
    String? error;
    bool saving = false;
    final requestId = pactMessageId();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('New conversation'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Conversation name',
                  ),
                ),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'Exact Pact username',
                  ),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          try {
                            final found = await _api.rows('contacts', {
                              'username': username.text.trim(),
                            });
                            if (!context.mounted) return;
                            update(() {
                              if (found.isEmpty) {
                                error =
                                    'No available account with that username.';
                              } else if (people.length >= 9) {
                                error = 'Maximum 9 other participants.';
                              } else {
                                if (!people.any(
                                  (p) => p['id'] == found.first['id'],
                                )) {
                                  people.add(found.first);
                                }
                                error = null;
                                username.clear();
                              }
                            });
                          } catch (_) {
                            if (context.mounted) {
                              update(
                                () =>
                                    error = 'Could not look up that username.',
                              );
                            }
                          }
                        },
                  child: const Text('Add person'),
                ),
                ...people.map(
                  (p) => ListTile(
                    dense: true,
                    title: Text(
                      p['full_name'] as String? ?? p['username'].toString(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => update(() => people.remove(p)),
                    ),
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                const Text(
                  'Each person receives a request. Messages start after everyone accepts.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving || people.isEmpty
                  ? null
                  : () async {
                      update(() => saving = true);
                      try {
                        final result = await _api.call('create', {
                          'id': requestId,
                          'title': title.text.trim().isEmpty
                              ? people
                                    .map((p) => p['full_name'])
                                    .join(', ')
                                    .substring(
                                      0,
                                      people
                                          .map((p) => p['full_name'])
                                          .join(', ')
                                          .length
                                          .clamp(0, 120),
                                    )
                              : title.text.trim(),
                          'recipients': people.map((p) => p['id']).toList(),
                        });
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _deepLink = result['id'] as String;
                        await _refresh();
                      } catch (_) {
                        if (context.mounted) {
                          update(() {
                            saving = false;
                            error =
                                'Could not create the request. Check the connection and retry.';
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Creating…' : 'Send request'),
            ),
          ],
        ),
      ),
    );
    // Controllers are kept until the closing dialog animation has completed.
  }

  Future<void> _respond(String status) async {
    try {
      await _api.call('respond', {
        'thread_id': _selected!['id'],
        'status': status,
      });
      await _refresh();
    } catch (_) {
      _showError('Could not update the request. Please retry.');
    }
  }

  Widget _avatar(String name, {String? url, double radius = 25}) =>
      CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE0EFEB),
        foregroundColor: _pactGreen,
        child: url != null && url.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Text(
                    name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase(),
                  ),
                ),
              )
            : Text(name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase()),
      );
  Widget _inbox() {
    final rows = _threads
        .where(
          (r) =>
              _requests ? r['status'] == 'pending' : r['status'] == 'accepted',
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _requests ? 'Message requests' : 'Messages',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'New conversation',
                onPressed: _newConversation,
                icon: const Icon(Icons.edit_square, color: _pactGreen),
              ),
            ],
          ),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Inbox')),
            ButtonSegment(value: true, label: Text('Requests')),
          ],
          selected: {_requests},
          onSelectionChanged: (v) => setState(() => _requests = v.first),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _requests
                          ? 'No requests right now.'
                          : 'Your conversations start here. Tap the compose button to connect with someone on Pact.',
                    ),
                  ),
                ...rows.map(
                  (r) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: _avatar(r['title'] as String),
                    title: Text(
                      r['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      r['status'] == 'pending'
                          ? 'Would like to start a conversation'
                          : (r['preview'] as String? ?? 'Waiting for a reply'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: (r['unread_count'] as num? ?? 0) > 0
                        ? Badge(label: Text('${r['unread_count']}'))
                        : null,
                    onTap: () => _select(r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _conversation() {
    final t = _selected!;
    final pending =
        _outbox?.pending.where((r) => r['thread_id'] == t['id']).toList() ?? [];
    final waiting = t.containsKey('can_send')
        ? t['can_send'] != true
        : _members.any((m) => m['status'] == 'pending');
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            tooltip: 'Back to inbox',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() {
              _selected = null;
              _messages = [];
              _members = [];
            }),
          ),
          title: Text(
            t['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${_members.length} participants'),
          trailing: PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'leave') {
                try {
                  await _api.call('leave', {'thread_id': t['id']});
                  await _refresh();
                } catch (_) {
                  _showError('Could not leave conversation.');
                }
              } else {
                final target = _members.firstWhere((m) => m['id'] == action);
                try {
                  await _api.call('block', {
                    'thread_id': t['id'],
                    'user_id': target['id'],
                  });
                  await _refresh();
                } catch (_) {
                  _showError('Could not block account.');
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave conversation'),
              ),
              ..._members
                  .where((m) => m['id'] != _userId)
                  .map(
                    (m) => PopupMenuItem(
                      value: m['id'] as String,
                      child: Text('Block ${m['name']}'),
                    ),
                  ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (t['status'] == 'pending')
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Accept this request to join the conversation.'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _respond('declined'),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => _respond('accepted'),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (waiting && t['status'] == 'accepted')
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Waiting for everyone to accept the request.'),
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.all(20),
            children: [
              ...pending.reversed.map(
                (r) => Align(
                  alignment: Alignment.centerRight,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(r['body'] as String),
                          Text(
                            r['failed'] == true ? 'Not sent' : 'Sending…',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (r['failed'] == true)
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
                                  onPressed: () =>
                                      _outbox!.discard(r['id'] as String),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ..._messages.reversed.map((m) {
                final mine = m['sender_id'] == _userId;
                final seen = _members
                    .where(
                      (r) => r['id'] != _userId && r['status'] == 'accepted',
                    )
                    .any(
                      (r) =>
                          (r['read_sequence'] as num) >= (m['sequence'] as num),
                    );
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: mine ? null : const Color(0xFFF0F2F2),
                      gradient: mine
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                HSLColor.fromAHSL(
                                  1,
                                  (330 +
                                          _messages
                                                  .where(
                                                    (r) =>
                                                        r['sender_id'] ==
                                                        _userId,
                                                  )
                                                  .toList()
                                                  .indexOf(m) *
                                              4) %
                                      360,
                                  .62,
                                  .37,
                                ).toColor(),
                                HSLColor.fromAHSL(
                                  1,
                                  (334 +
                                          _messages
                                                  .where(
                                                    (r) =>
                                                        r['sender_id'] ==
                                                        _userId,
                                                  )
                                                  .toList()
                                                  .indexOf(m) *
                                              4) %
                                      360,
                                  .62,
                                  .37,
                                ).toColor(),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!mine)
                          Text(
                            _members
                                    .where((r) => r['id'] == m['sender_id'])
                                    .map((r) => r['name'])
                                    .firstOrNull
                                    ?.toString() ??
                                'Participant',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        SelectableText(
                          m['body'] as String,
                          style: TextStyle(
                            color: mine ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (mine)
                          Text(
                            seen ? 'Read' : 'Sent',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              if (_messages.length >= 50)
                TextButton(
                  onPressed: () async {
                    try {
                      final older = await _api.rows('messages', {
                        'thread_id': t['id'],
                        'before': _messages.first['sequence'],
                      });
                      if (mounted && _selected?['id'] == t['id']) {
                        setState(() => _messages = [...older, ..._messages]);
                      }
                    } catch (_) {
                      _showError('Could not load earlier messages.');
                    }
                  },
                  child: const Text('Load earlier messages'),
                ),
            ],
          ),
        ),
        if (t['status'] == 'accepted')
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      maxLength: 4000,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _busy || waiting ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _contactProvider(String providerId) async {
    final generation = _generation;
    try {
      final result = await _api.call('open_member', {
        'id': pactMessageId(),
        'provider_id': providerId,
        'context': 'general',
      });
      if (!mounted || generation != _generation) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _mobileTab.value = 2;
      _deepLink = result['id'] as String;
      await _refresh();
    } catch (_) {
      rethrow; // The visible profile reports the error and keeps the action available.
    }
  }

  Future<void> _mobileNewConversation() async {
    final generation = _generation;
    try {
      final selected = await showModalBottomSheet<MessageRow>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MobileMemberPicker(api: _api),
      );
      if (selected == null || !mounted || generation != _generation) return;
      final result = await _api.call('open_member', {
        'id': pactMessageId(),
        'provider_id': selected['provider_id'],
        'context': 'general',
      });
      if (!mounted || generation != _generation) return;
      _deepLink = result['id'] as String;
      await _refresh();
    } catch (_) {
      if (mounted && generation == _generation) {
        _showError('Could not open the member directory. Please retry.');
      }
    }
  }

  Widget _messagePane() => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= 800) {
        return Row(
          children: [
            SizedBox(width: 340, child: _inbox()),
            const VerticalDivider(width: 1),
            Expanded(
              child: _selected == null
                  ? const Center(child: Text('Select a conversation'))
                  : _conversation(),
            ),
          ],
        );
      }
      return _selected == null ? _inbox() : _conversation();
    },
  );

  Widget _profilePage() => PactProfilePanel(
    initialProfile: _profile,
    onChanged: _initializeAccount,
    actions: [
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Enable push notifications'),
        subtitle: const Text('Message previews stay private'),
        onTap: () async {
          try {
            await PactPushService.enable(_api);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification preferences updated.'),
                ),
              );
            }
          } catch (_) {
            _showError(
              'Push notifications need Firebase and Apple/Android setup before they can be enabled.',
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sign out'),
        onTap: () async {
          try {
            await PactPushService.unregister(
              _api,
            ).timeout(const Duration(seconds: 3));
          } catch (_) {
            /* A network outage must not prevent local sign-out. */
          }
          try {
            await BackendService.signOut();
          } catch (_) {
            _accountChanged(); // Supabase clears the local session before contacting the server.
          }
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final loggedIn = _userId != null;
    if (loggedIn && widget.mobileWorkspace) {
      return PactMobileWorkspace(
        key: ValueKey(_userId),
        userId: _userId!,
        messaging: _api,
        onContact: _contactProvider,
        account: _profile,
        tab: _mobileTab,
        threads: _threads,
        onOpenThread: (row) => unawaited(_select(row)),
        profile: _profilePage(),
        messages: Column(
          children: [
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(child: _messagePane()),
          ],
        ),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: widget.mobileWorkspace ? pactMobileAccent : _pactGreen,
          primary: widget.mobileWorkspace ? pactMobileAccent : _pactGreen,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: widget.mobileWorkspace
            ? Colors.transparent
            : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              if (_error != null)
                MaterialBanner(
                  content: Text(_error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _error = null),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Expanded(
                child: !loggedIn
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(28),
                            children: [
                              const Text(
                                'pact.',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your conversations. Everywhere.',
                                style: TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 28),
                              OutlinedButton(
                                onPressed: _busy ? null : _googleLogin,
                                child: const Text('Continue with Google'),
                              ),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text('or sign in with email'),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _password,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                onSubmitted: (_) => _busy ? null : _login(),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _busy ? null : _login,
                                child: Text(
                                  _busy ? 'Signing in…' : 'Sign in to Pact',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Use the same account as the Pact website.',
                              ),
                            ],
                          ),
                        ),
                      )
                    : _tab == 1
                    ? _profilePage()
                    : LayoutBuilder(
                        builder: (context, c) {
                          if (c.maxWidth >= 800) {
                            return Row(
                              children: [
                                SizedBox(width: 340, child: _inbox()),
                                const VerticalDivider(width: 1),
                                Expanded(
                                  child: _selected == null
                                      ? const Center(
                                          child: Text('Select a conversation'),
                                        )
                                      : _conversation(),
                                ),
                              ],
                            );
                          }
                          return _selected == null ? _inbox() : _conversation();
                        },
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: loggedIn
            ? CupertinoTabBar(
                currentIndex: _tab,
                onTap: (i) => setState(() => _tab = i),
                activeColor: const Color(0xFF007AFF),
                inactiveColor: const Color(0xFF8E8E93),
                backgroundColor: const Color(0xE6F7F8F8),
                height: 62,
                iconSize: 29,
                border: const Border(
                  top: BorderSide(color: Color(0x33909090), width: .5),
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chat_bubble_2),
                    activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                    label: 'Messages',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_crop_circle),
                    activeIcon: Icon(CupertinoIcons.person_crop_circle_fill),
                    label: 'Profile',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mobileTab.removeListener(_visibleTabChanged);
    _mobileTab.dispose();
    _timer?.cancel();
    final channel = _channel;
    if (channel != null) {
      unawaited(_api.stopListening(channel));
    }
    _auth?.cancel();
    _push?.cancel();
    _outbox?.dispose();
    _email.dispose();
    _password.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _MobileMemberPicker extends StatefulWidget {
  const _MobileMemberPicker({required this.api});
  final PactMessagingService api;
  @override
  State<_MobileMemberPicker> createState() => _MobileMemberPickerState();
}

class _MobileMemberPickerState extends State<_MobileMemberPicker> {
  final _query = TextEditingController();
  List<MessageRow> _choices = [];
  bool _loading = true;
  String? _error;
  int _request = 0;
  late final String? _owner = BackendService.user?.id;
  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final choices = await widget.api.rows('directory', {
        'query': _query.text.trim(),
      });
      if (!mounted ||
          request != _request ||
          BackendService.user?.id != _owner) {
        return;
      }
      setState(() {
        _choices = choices;
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load members. Please search again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _request++;
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * .75 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(220.0, 640.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Connect with a Pact member',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: 'Search members',
                  suffixIcon: IconButton(
                    tooltip: 'Search members',
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Members can reply to buyer and seller inquiries. Private customer accounts are not searchable.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
            Expanded(
              child: ListView(
                children: [
                  if (!_loading && _choices.isEmpty && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text('No available members found.'),
                    ),
                  for (final row in _choices)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text('${row['full_name'] ?? 'Pact member'}'),
                      subtitle: Text('${row['company_name'] ?? ''}'),
                      trailing: const Icon(Icons.north_east),
                      onTap: () {
                        if (BackendService.user?.id == _owner) {
                          Navigator.pop(context, row);
                        }
                      },
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
