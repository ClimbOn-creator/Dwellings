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

  static Future<List<MemberChatMessage>> loadMessages(
    String conversationId,
  ) async {
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
