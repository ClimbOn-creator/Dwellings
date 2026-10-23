import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';
import 'pact_messaging_service.dart';

/// Fictional conversations for trying the buyer inbox. Demo content stays in
/// browser memory; real account IDs and conversations always use the real API.
class PactWebDemoService extends PactMessagingService {
  PactWebDemoService({required this.enabled, this.delegate});
  final bool enabled;
  final PactMessagingService? delegate;
  static final _sessions = <String, Map<String, List<MessageRow>>>{};
  final _read = <String, int>{};
  final _timers = <Timer>[];
  void Function()? _changed;
  String? _owner;
  static const contacts = {
    'demo-broker': 'Alex Morgan · Demo broker',
    'demo-lender': 'Jamie Chen · Demo lender',
  };
  Map<String, List<MessageRow>> get _conversations {
    final actor = BackendService.user?.id;
    if (actor == null || !enabled) return {};
    return _sessions.putIfAbsent(
      actor,
      () => {
        for (final id in contacts.keys)
          id: [
            {
              'id': '$id-welcome',
              'thread_id': id,
              'sequence': 1,
              'sender_id': id,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'body': id == 'demo-broker'
                  ? 'Hi! I’m Alex, your demo broker. What kind of business are you looking to buy? This is a simulated conversation — no real professional receives these messages.'
                  : 'Hi! I’m Jamie, your demo lender. Want to try a financing conversation? Replies here are simulated; please use fictional details.',
            },
          ],
      },
    );
  }

  @override
  RealtimeChannel listen(String userId, void Function() onChanged) {
    _owner = userId;
    _changed = onChanged;
    return (delegate ?? superService).listen(userId, onChanged);
  }

  final superService = PactMessagingService();
  @override
  Future<void> stopListening(RealtimeChannel channel) async {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _changed = null;
    _owner = null;
    await (delegate ?? superService).stopListening(channel);
  }

  Future<dynamic> _real(String action, MessageRow payload) =>
      (delegate ?? superService).call(action, payload);
  @override
  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    final conversations = _conversations;
    if (action == 'list') {
      final real = await _real(action, payload) as List;
      return [
        ...real,
        for (final entry in conversations.entries)
          {
            'id': entry.key,
            'title': contacts[entry.key],
            'status': 'accepted',
            'can_send': true,
            'demo': true,
            'preview': entry.value.last['body'],
            'updated_at': entry.value.last['created_at'],
            'unread_count': 0,
          },
      ];
    }
    final id = payload['thread_id'];
    if (!contacts.containsKey(id) || !enabled) return _real(action, payload);
    final messages = conversations[id];
    final actor = BackendService.user?.id;
    if (actor == null ||
        messages == null ||
        (payload['expected_user_id'] != null &&
            payload['expected_user_id'] != actor)) {
      throw StateError('Sign in again.');
    }
    switch (action) {
      case 'members':
        return [
          {'id': actor, 'status': 'accepted', 'read_sequence': messages.length},
          {'id': id, 'status': 'accepted', 'read_sequence': _read[id] ?? 0},
        ];
      case 'messages':
        return messages.map((m) => Map<String, dynamic>.from(m)).toList();
      case 'read':
        return {};
      case 'send':
        final existing = messages.where((m) => m['id'] == payload['id']);
        if (existing.isNotEmpty) return existing.first;
        final message = <String, dynamic>{
          ...payload,
          'sender_id': actor,
          'sequence': messages.length + 1,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        messages.add(message);
        final text = payload['body'] as String;
        _timers.add(
          Timer(const Duration(milliseconds: 900), () {
            if (BackendService.user?.id != actor || _owner != actor) return;
            _read[id as String] = message['sequence'] as int;
            _changed?.call();
          }),
        );
        _timers.add(
          Timer(const Duration(milliseconds: 2200), () {
            if (BackendService.user?.id != actor || _owner != actor) return;
            messages.add({
              'id': '${payload['id']}-reply',
              'thread_id': id,
              'sender_id': id,
              'sequence': messages.length + 1,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'body': reply(
                id as String,
                text,
                messages.where((m) => m['sender_id'] == actor).length,
              ),
            });
            _changed?.call();
          }),
        );
        return message;
      default:
        throw StateError('Demo conversations support text messages only.');
    }
  }

  static String reply(String id, String body, int turn) {
    final text = body.toLowerCase();
    if (RegExp(r'\b(hi|hello|hey)\b').hasMatch(text)) {
      return id == 'demo-broker'
          ? 'Hello! Happy to help you try this out. Which industry and location would you choose for a sample acquisition?'
          : 'Hey! For our sample deal, are you exploring financing or just checking your options?';
    }
    if (text.contains('thank')) {
      return 'You’re welcome! What else would you like to explore in this demo?';
    }
    if (text.contains('call') || text.contains('meet')) {
      return 'We could discuss that on a call in a real conversation. For this demo, what would you put on the agenda?';
    }
    if (id == 'demo-lender') {
      if (text.contains('rate') ||
          text.contains('loan') ||
          text.contains('financ')) {
        return 'For a fictional financing discussion, I’d ask about the purchase price, your contribution and the business cash flow. What sample purchase price shall we use? This isn’t a lending offer.';
      }
      return turn.isOdd
          ? 'Got it. In a real inquiry I’d review the deal details before discussing options. What fictional budget are you working with?'
          : 'That helps. We could put the next steps into a checklist and review them together. What would you like to ask next?';
    }
    return turn.isOdd
        ? 'That’s a useful starting point. For our sample search, what budget and timeline would you have in mind?'
        : 'Understood. I’d narrow the shortlist and compare the opportunities with you. Would you like to discuss the business, due diligence or next steps?';
  }
}
