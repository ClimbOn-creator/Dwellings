import '../services/member_roi_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/member_friends_service.dart';
import '../widgets/pact_professional_profile.dart';
import '../widgets/profile_photo.dart';

const _purple = Color(0xFF6255DC);
const _ink = Color(0xFF252333);

class MemberFriendsPage extends StatefulWidget {
  const MemberFriendsPage({
    super.key,
    this.service,
    this.initialScope = 'friends',
  });
  final MemberFriendsService? service;
  final String initialScope;
  @override
  State<MemberFriendsPage> createState() => _MemberFriendsPageState();
}

class _MemberFriendsPageState extends State<MemberFriendsPage>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? MemberFriendsService();
  late String _scope = widget.initialScope;
  final _search = TextEditingController();
  final _owner = BackendService.user?.id;
  List<MemberFriend> _people = [];
  int _total = 0, _generation = 0;
  bool _loading = true, _foreground = true;
  String? _error;
  Timer? _debounce, _refresh;
  StreamSubscription<dynamic>? _auth;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _owner) {
        setState(() {
          _generation++;
          _people = [];
          _total = 0;
          _error = 'Sign in again to view Friends.';
        });
      }
    });
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_foreground && !_loading) _load(quiet: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _load(quiet: true);
  }

  Future<void> _load({bool more = false, bool quiet = false}) async {
    if (BackendService.user?.id != _owner) return;
    final generation = ++_generation;
    if (!quiet)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final data = await _service.people(
        scope: _scope,
        query: _search.text.trim(),
        offset: more ? _people.length : 0,
      );
      if (!mounted ||
          generation != _generation ||
          BackendService.user?.id != _owner)
        return;
      setState(() {
        _people = more ? [..._people, ...data.people] : data.people;
        _total = data.total;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted &&
          generation == _generation &&
          BackendService.user?.id == _owner) {
        setState(() {
          _loading = false;
          _error = 'Friends could not load. Please try again.';
        });
      }
    }
  }

  void _switch(String scope) {
    _debounce?.cancel();
    setState(() {
      _scope = scope;
      _people = [];
      _total = 0;
    });
    _load();
  }

  Future<void> _open(MemberFriend friend) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MemberFriendProfilePage(friend: friend, service: _service),
      ),
    );
    if (mounted) await _load(quiet: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _debounce?.cancel();
    _refresh?.cancel();
    _auth?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F6FA),
    appBar: AppBar(
      title: const Text('Friends'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, c) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: c.maxWidth > 1140 ? (c.maxWidth - 1080) / 2 : 22,
            vertical: 26,
          ),
          children: [
            const Text(
              'Good people.\nShared possibilities.',
              style: TextStyle(
                fontSize: 32,
                height: 1.1,
                letterSpacing: -1,
                color: _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Build your circle, one connection at a time.',
              style: TextStyle(color: Color(0xFF817C8E), height: 1.5),
            ),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'friends', label: Text('Friends')),
                ButtonSegment(value: 'requests', label: Text('Requests')),
                ButtonSegment(value: 'discover', label: Text('Discover')),
              ],
              selected: {_scope},
              onSelectionChanged: (v) => _switch(v.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: _scope == 'discover'
                    ? 'Find a member by name or company'
                    : 'Search your circle',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _debounce?.cancel();
                // Invalidate an in-flight search as soon as its text becomes stale.
                _generation++;
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _load(),
                );
              },
            ),
            const SizedBox(height: 22),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: () => _load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (!_loading && _error == null && _people.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 38,
                      color: _purple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _search.text.isNotEmpty
                          ? 'No members found'
                          : _scope == 'requests'
                          ? 'You’re all caught up'
                          : _scope == 'friends'
                          ? 'Your circle starts here'
                          : 'More people, soon',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scope == 'friends'
                          ? 'Find another Pact member and send a friend request.'
                          : 'Try a different name or check back later.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF817C8E),
                        height: 1.5,
                      ),
                    ),
                    if (_scope == 'friends')
                      TextButton(
                        onPressed: () => _switch('discover'),
                        child: const Text('Discover members'),
                      ),
                  ],
                ),
              ),
            if (_people.isNotEmpty)
              LayoutBuilder(
                builder: (context, card) {
                  final columns = card.maxWidth >= 850
                      ? 3
                      : card.maxWidth >= 580
                      ? 2
                      : 1;
                  final width = (card.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final friend in _people)
                        SizedBox(
                          width: width,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => _open(friend),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Row(
                                      children: [
                                        ProfilePhoto(
                                          size: 54,
                                          photoUrl: friend.photoUrl,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                friend.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  color: _ink,
                                                ),
                                              ),
                                              if (friend.jobTitle.isNotEmpty ||
                                                  friend
                                                      .company
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 5),
                                                Text(
                                                  [
                                                        friend.jobTitle,
                                                        friend.company,
                                                      ]
                                                      .where(
                                                        (s) => s.isNotEmpty,
                                                      )
                                                      .join(' · '),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    height: 1.4,
                                                    color: Color(0xFF817C8E),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  FriendActions(
                                    friend: friend,
                                    service: _service,
                                    onChanged: () => _load(quiet: true),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (_people.length < _total)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: _loading ? null : () => _load(more: true),
                  child: const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class FriendActions extends StatefulWidget {
  const FriendActions({
    super.key,
    required this.friend,
    required this.service,
    required this.onChanged,
  });
  final MemberFriend friend;
  final MemberFriendsService service;
  final Future<void> Function() onChanged;
  @override
  State<FriendActions> createState() => _FriendActionsState();
}

class _FriendActionsState extends State<FriendActions> {
  bool _busy = false;
  Future<void> _act(String action) async {
    final owner = BackendService.user?.id;
    if (action == 'remove') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove friend?'),
          content: Text(
            'You and ${widget.friend.name} will be removed from each other’s Friends.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep friend'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted || BackendService.user?.id != owner) return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.act(widget.friend, action);
      if (mounted && BackendService.user?.id == owner) await widget.onChanged();
    } catch (_) {
      if (mounted && BackendService.user?.id == owner)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this change. Please refresh and try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_busy)
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (f.status == 'accepted') ...[
          const Icon(Icons.people_alt_outlined, color: _purple, size: 18),
          const Text(
            'Friends',
            style: TextStyle(color: _purple, fontWeight: FontWeight.w600),
          ),
          PopupMenuButton<String>(
            tooltip: 'Friend options',
            onSelected: _act,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove friend'),
              ),
            ],
          ),
        ] else if (f.status == 'pending' && f.incoming) ...[
          FilledButton(
            onPressed: () => _act('accept'),
            child: const Text('Accept'),
          ),
          TextButton(
            onPressed: () => _act('decline'),
            child: const Text('Decline'),
          ),
        ] else if (f.status == 'pending') ...[
          const Text(
            'Request sent',
            style: TextStyle(color: Color(0xFF817C8E)),
          ),
          TextButton(
            onPressed: () => _act('cancel'),
            child: const Text('Cancel'),
          ),
        ] else
          FilledButton.icon(
            onPressed: () => _act('request'),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Add friend'),
          ),
      ],
    );
  }
}

class MemberFriendProfilePage extends StatefulWidget {
  const MemberFriendProfilePage({
    super.key,
    required this.friend,
    required this.service,
  });
  final MemberFriend friend;
  final MemberFriendsService service;
  @override
  State<MemberFriendProfilePage> createState() =>
      _MemberFriendProfilePageState();
}

class _MemberFriendProfilePageState extends State<MemberFriendProfilePage> {
  late MemberFriend _friend = widget.friend;
  final _owner = BackendService.user?.id;
  bool _expanded = false;
  @override
  void initState() {
    super.initState();
    unawaited(MemberRoiService.view(memberId: widget.friend.userId));
  }

  Future<void> _reload() async {
    final data = await widget.service.people(
      scope: 'profile',
      target: _friend.userId,
    );
    if (mounted && BackendService.user?.id == _owner && data.people.isNotEmpty)
      setState(() => _friend = data.people.first);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F6FA),
    appBar: AppBar(
      title: const Text('Member profile'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      children: [
        PactProfessionalHeader(
          name: _friend.name,
          photoUrl: _friend.photoUrl,
          coverUrl: _friend.coverUrl,
          headline: _friend.jobTitle,
          company: _friend.company,
          edgeToEdge: true,
          actions: [
            FriendActions(
              friend: _friend,
              service: widget.service,
              onChanged: _reload,
            ),
          ],
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            margin: const EdgeInsets.all(22),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Text(
                  _friend.bio.isEmpty
                      ? 'This member hasn’t added an introduction yet.'
                      : _friend.bio,
                  maxLines: _expanded ? null : 5,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.7, color: Color(0xFF817C8E)),
                ),
                if (_friend.bio.length > 240)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Show less' : 'Read more'),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
