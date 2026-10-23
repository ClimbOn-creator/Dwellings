import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

typedef MessageRow = Map<String, dynamic>;

String pactMessageId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final s = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

class PactMessagingService {
  RealtimeChannel listen(String userId, void Function() onChanged) => Supabase
      .instance
      .client
      .channel(
        'pact:user:$userId',
        opts: const RealtimeChannelConfig(private: true),
      )
      .onBroadcast(event: 'changed', callback: (_) => onChanged())
      .subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) onChanged();
      });
  Future<void> stopListening(RealtimeChannel channel) =>
      Supabase.instance.client.removeChannel(channel).then((_) {});

  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    if (BackendService.user == null) {
      throw StateError('Sign in to use Messages.');
    }
    return Supabase.instance.client.rpc(
      'pact_messaging',
      params: {'action': action, 'payload': payload},
    );
  }

  Future<List<MessageRow>> rows(
    String action, [
    MessageRow payload = const {},
  ]) async => (await call(action, payload) as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

/// Account-scoped outbox. Native storage uses the OS secure store. Web drafts
/// stay in memory so shared browsers do not retain financial conversations.
/// A failed send keeps its original UUID; retry can never create a second row.
class PactOutbox extends ChangeNotifier {
  PactOutbox(this.userId, this.service, {bool Function()? isCurrentUser})
    : _isCurrentUser =
          isCurrentUser ?? (() => BackendService.user?.id == userId);
  final bool Function() _isCurrentUser;
  final String userId;
  final PactMessagingService service;
  static const _storage = FlutterSecureStorage();
  final List<MessageRow> pending = [];
  bool _sending = false;
  bool _closed = false;
  String get _key => 'pact.outbox.v1.$userId';
  Future<void> restore() async {
    if (kIsWeb) return;
    final value = await _storage.read(key: _key);
    if (value != null && !_closed) {
      pending.addAll(
        (jsonDecode(value) as List).map(
          (e) => Map<String, dynamic>.from(e as Map)..['failed'] = true,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> reconcile(Iterable<String> committedIds) async {
    if (_closed || _sending || !_isCurrentUser()) return;
    final ids = committedIds.toSet();
    final previousCount = pending.length;
    pending.removeWhere((row) => ids.contains(row['id']));
    if (pending.length != previousCount) {
      await _persist();
      if (!_closed) notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (!kIsWeb) await _storage.write(key: _key, value: jsonEncode(pending));
  }

  Future<void> enqueue(String threadId, String body) async {
    if (_closed || !_isCurrentUser()) throw StateError('Sign in again.');
    if (pending.length >= 100) {
      throw StateError('Retry or remove pending messages first.');
    }
    final row = <String, dynamic>{
      'id': pactMessageId(),
      'thread_id': threadId,
      'body': body.trim(),
    };
    pending.add(row);
    try {
      await _persist();
    } catch (_) {
      pending.remove(row);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> flush() async {
    if (_sending || _closed || !_isCurrentUser()) return;
    _sending = true;
    try {
      for (final row in List<MessageRow>.from(pending)) {
        if (_closed || !_isCurrentUser()) break;
        try {
          await service.call('send', {
            'id': row['id'],
            'thread_id': row['thread_id'],
            'body': row['body'],
            'expected_user_id': userId,
          });
          pending.remove(row);
          await _persist();
        } catch (_) {
          row['failed'] = true;
          await _persist();
          break;
        }
      }
    } finally {
      _sending = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> discard(String id) async {
    if (_sending) return;
    pending.removeWhere((r) => r['id'] == id);
    await _persist();
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
