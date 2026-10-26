import 'dart:async';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/member_friends_service.dart';
import '../screens/member_friends_page.dart';
import 'profile_photo.dart';

class MemberFriendsPreview extends StatefulWidget {
  const MemberFriendsPreview({super.key, this.service});
  final MemberFriendsService? service;
  @override
  State<MemberFriendsPreview> createState() => _MemberFriendsPreviewState();
}

class _MemberFriendsPreviewState extends State<MemberFriendsPreview> {
  late final _service = widget.service ?? MemberFriendsService();
  final _owner = BackendService.user?.id;
  MemberFriendsPageData? _friends, _requests;
  bool _available = false, _loading = true, _refreshing = false;
  String? _error;
  Timer? _refresh;
  StreamSubscription<dynamic>? _auth;
  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 20), (_) => _load());
    _auth = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _owner)
        setState(() {
          _available = false;
          _friends = null;
          _requests = null;
          _error = null;
        });
    });
  }

  Future<void> _load() async {
    if (_refreshing || _owner == null || BackendService.user?.id != _owner)
      return;
    _refreshing = true;
    try {
      final available = await _service.available();
      final friends = available ? await _service.people() : null;
      final requests = available
          ? await _service.people(scope: 'requests')
          : null;
      if (!mounted || BackendService.user?.id != _owner) return;
      setState(() {
        _available = available;
        _friends = friends;
        _requests = requests;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && BackendService.user?.id == _owner)
        setState(() {
          _error = 'Friends could not refresh.';
          _loading = false;
        });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _open([String scope = 'friends']) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MemberFriendsPage(service: _service, initialScope: scope),
      ),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _auth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Padding(
        padding: EdgeInsets.all(24),
        child: LinearProgressIndicator(minHeight: 2),
      );
    if (!_available && _error == null) return const SizedBox.shrink();
    final incoming = _requests?.people.where((p) => p.incoming).length ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF6255DC),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your circle',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),
              ),
              if (_friends != null)
                Text(
                  '${_friends!.total} ${_friends!.total == 1 ? 'friend' : 'friends'}',
                  style: const TextStyle(
                    color: Color(0xFF817C8E),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ] else if (_friends!.people.isEmpty)
            const Text(
              'Your people, all in one place. Find a member and start a connection.',
              style: TextStyle(color: Color(0xFF817C8E), height: 1.6),
            )
          else
            Wrap(
              spacing: 20,
              runSpacing: 14,
              children: [
                for (final friend in _friends!.people.take(5))
                  SizedBox(
                    width: 64,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MemberFriendProfilePage(
                              friend: friend,
                              service: _service,
                            ),
                          ),
                        );
                        if (mounted) await _load();
                      },
                      child: Column(
                        children: [
                          ProfilePhoto(size: 54, photoUrl: friend.photoUrl),
                          const SizedBox(height: 7),
                          Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _open(),
                child: const Text('Open Friends'),
              ),
              TextButton(
                onPressed: () => _open('discover'),
                child: const Text('Find members'),
              ),
              if (incoming > 0)
                TextButton(
                  onPressed: () => _open('requests'),
                  child: const Text('New requests'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uses the same relationship on a directory profile and in the Friends hub.
class MemberFriendProviderButton extends StatefulWidget {
  const MemberFriendProviderButton({super.key, required this.providerId});
  final String providerId;
  @override
  State<MemberFriendProviderButton> createState() =>
      _MemberFriendProviderButtonState();
}

class _MemberFriendProviderButtonState
    extends State<MemberFriendProviderButton> {
  final _service = MemberFriendsService();
  final _owner = BackendService.user?.id;
  MemberFriend? _friend;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_owner == null || BackendService.user?.id != _owner) return;
    try {
      if (!await _service.available()) return;
      final friend = await _service.forProvider(widget.providerId);
      if (mounted && BackendService.user?.id == _owner)
        setState(() {
          _friend = friend;
          _failed = false;
        });
    } catch (_) {
      if (mounted && BackendService.user?.id == _owner)
        setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => _failed
      ? TextButton(onPressed: _load, child: const Text('Retry friend status'))
      : _friend == null
      ? const SizedBox.shrink()
      : FriendActions(friend: _friend!, service: _service, onChanged: _load);
}
