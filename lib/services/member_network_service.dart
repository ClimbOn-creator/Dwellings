import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class MemberConversationSummary {
  const MemberConversationSummary({
    required this.id,
    required this.otherProviderId,
    required this.name,
    required this.company,
    required this.jobTitle,
    required this.providerType,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.photoIndex,
    this.photoUrl = '',
    this.opportunityId,
    this.opportunityHeadline = '',
    this.isPreview = false,
  });

  final String id;
  final String otherProviderId;
  final String name;
  final String company;
  final String jobTitle;
  final String providerType;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final int? photoIndex;
  final String photoUrl;
  final String? opportunityId;
  final String opportunityHeadline;
  final bool isPreview;

  factory MemberConversationSummary.fromJson(Map<String, dynamic> row) =>
      MemberConversationSummary(
        id: row['conversation_id'] as String,
        otherProviderId: row['other_provider_id'] as String,
        name: row['other_name'] as String? ?? 'Affinity member',
        company: row['other_company'] as String? ?? '',
        jobTitle: row['other_job_title'] as String? ?? 'Professional member',
        providerType: row['other_provider_type'] as String? ?? 'professional',
        lastMessage: row['last_message'] as String? ?? '',
        lastMessageAt:
            DateTime.tryParse(row['last_message_at'] as String? ?? '') ??
            DateTime.now(),
        unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
        photoIndex: (row['other_photo_index'] as num?)?.toInt(),
        photoUrl: row['other_photo_url'] as String? ?? '',
        opportunityId: row['opportunity_id'] as String?,
        opportunityHeadline: row['opportunity_headline'] as String? ?? '',
      );
}

class MemberChatMessage {
  const MemberChatMessage({
    required this.id,
    required this.senderProviderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    required this.isMine,
    this.readAt,
  });

  final String id;
  final String senderProviderId;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final bool isMine;
  final DateTime? readAt;

  factory MemberChatMessage.fromJson(Map<String, dynamic> row) =>
      MemberChatMessage(
        id: row['id'] as String,
        senderProviderId: row['sender_provider_id'] as String? ?? '',
        senderName: row['sender_name'] as String? ?? 'Affinity member',
        body: row['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        isMine: row['is_mine'] as bool? ?? false,
        readAt: DateTime.tryParse(row['read_at'] as String? ?? ''),
      );
}

class MemberNetworkService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<MemberConversationSummary>> loadConversations() async {
    if (!BackendService.configured || BackendService.user == null) {
      return const [];
    }
    final rows = await _client.rpc('list_member_conversations');
    return (rows as List<dynamic>)
        .map(
          (row) => MemberConversationSummary.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static List<MemberConversationSummary> get creatorExampleConversations =>
      CreatorMessageExamples.conversationsFor(BackendService.user?.email);

  static Future<List<MemberChatMessage>> loadMessages(
    String conversationId,
  ) async {
    if (CreatorMessageExamples.ownsId(conversationId)) {
      return CreatorMessageExamples.messagesFor(
        BackendService.user?.email,
        conversationId,
      );
    }
    if (!BackendService.configured || BackendService.user == null) {
      return const [];
    }
    dynamic rows;
    try {
      rows = await _client.rpc(
        'load_member_messages_with_receipts',
        params: {'target_conversation_id': conversationId},
      );
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202' &&
          !error.message.contains('load_member_messages_with_receipts')) {
        rethrow;
      }
      rows = await _client.rpc(
        'load_member_messages',
        params: {'target_conversation_id': conversationId},
      );
    }
    await markRead(conversationId);
    return (rows as List<dynamic>)
        .map(
          (row) =>
              MemberChatMessage.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  static Future<String> startConversation({
    required String providerId,
    String? opportunityId,
  }) async {
    _requireMember();
    return await _client.rpc(
          'start_member_conversation',
          params: {
            'target_provider_id': providerId,
            'target_opportunity_id': opportunityId,
          },
        )
        as String;
  }

  static Future<void> sendMessage(String conversationId, String body) async {
    if (CreatorMessageExamples.ownsId(conversationId)) {
      throw StateError(
        'Example conversations are a preview. No message is sent.',
      );
    }
    _requireMember();
    await _client.rpc(
      'send_member_message',
      params: {
        'target_conversation_id': conversationId,
        'message_body': body.trim(),
      },
    );
  }

  static Future<void> markRead(String conversationId) async {
    if (CreatorMessageExamples.ownsId(conversationId)) return;
    if (!BackendService.configured || BackendService.user == null) return;
    await _client.rpc(
      'mark_member_conversation_read',
      params: {'target_conversation_id': conversationId},
    );
  }

  static Future<void> referToDeal({
    required String opportunityId,
    required String providerId,
    String note = '',
  }) async {
    _requireMember();
    await _client.rpc(
      'refer_member_to_deal',
      params: {
        'target_opportunity_id': opportunityId,
        'target_provider_id': providerId,
        'referral_note': note.trim(),
      },
    );
  }

  static void _requireMember() {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in with a verified member profile to continue.');
    }
  }
}

/// Local preview content for the two creator accounts. It is never inserted into
/// live conversations or sent through messaging RPCs.
class CreatorMessageExamples {
  static bool allowed(String? email) => const {
    'rw0882308@gmail.com',
    'dfisch5@gmail.com',
  }.contains(email?.trim().toLowerCase());
  static bool ownsId(String id) => id.startsWith('creator-example-');
  static const threads = [
    (
      'broker',
      'Amelia Foster',
      'Business broker',
      'Island HVAC · Example',
      'The seller can share the financial package once the confidentiality agreement is signed.',
      0,
    ),
    (
      'accountant',
      'Marcus Chen',
      'Accountant',
      'ABC Plumbing · Example',
      'I have noted two owner add-backs to reconcile before we confirm the earnings estimate.',
      1,
    ),
    (
      'lender',
      'Priya Patel',
      'Lender',
      'West Coast Dental · Example',
      'The financing checklist is ready. Let’s confirm your equity contribution and target closing date.',
      2,
    ),
  ];
  static List<MemberConversationSummary> conversationsFor(String? email) {
    if (!allowed(email)) return const [];
    final now = DateTime.now();
    return [
      for (final (id, name, role, deal, body, photo) in threads)
        MemberConversationSummary(
          id: 'creator-example-$id',
          otherProviderId: 'example-$id',
          name: '$name · Example',
          company: 'Fictional professional',
          jobTitle: role,
          providerType: 'professional',
          lastMessage: body,
          lastMessageAt: now.subtract(Duration(minutes: (photo + 1) * 25)),
          unreadCount: photo == 0 ? 1 : 0,
          photoIndex: photo,
          opportunityHeadline: deal,
          isPreview: true,
        ),
    ];
  }

  static List<MemberChatMessage> messagesFor(String? email, String id) {
    if (!allowed(email)) return const [];
    final thread = threads
        .where((t) => 'creator-example-${t.$1}' == id)
        .firstOrNull;
    if (thread == null) return const [];
    final now = DateTime.now();
    final replies = switch (thread.$1) {
      'broker' => [
        'Thanks, Amelia. What should I review first?',
        'Start with revenue trends, customer concentration and the owner’s responsibilities. We can organize the follow-up questions in the room.',
      ],
      'accountant' => [
        'Could you flag the items that need supporting records?',
        'Yes. Please request the payroll detail and invoices for those adjustments. I’ll keep the unresolved items together for our next review.',
      ],
      _ => [
        'What would you need from me before our financing meeting?',
        'An outline of your available capital, the proposed purchase terms and the latest financial statements would be a useful start.',
      ],
    };
    return [
      MemberChatMessage(
        id: '$id-1',
        senderProviderId: 'example-${thread.$1}',
        senderName: thread.$2,
        body: thread.$5,
        createdAt: now.subtract(const Duration(minutes: 40)),
        isMine: false,
      ),
      MemberChatMessage(
        id: '$id-2',
        senderProviderId: 'creator',
        senderName: 'You',
        body: replies[0],
        createdAt: now.subtract(const Duration(minutes: 30)),
        isMine: true,
        readAt: now.subtract(const Duration(minutes: 29)),
      ),
      MemberChatMessage(
        id: '$id-3',
        senderProviderId: 'example-${thread.$1}',
        senderName: thread.$2,
        body: replies[1],
        createdAt: now.subtract(const Duration(minutes: 25)),
        isMine: false,
      ),
    ];
  }
}
