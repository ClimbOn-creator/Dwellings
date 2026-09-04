import 'package:dwelling_iq/services/member_network_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation summaries parse unread and deal context', () {
    final conversation = MemberConversationSummary.fromJson({
      'conversation_id': 'conversation-1',
      'other_provider_id': 'provider-2',
      'other_name': 'Avery Singh',
      'other_company': 'North Coast Legal',
      'other_job_title': 'M&A Lawyer',
      'other_provider_type': 'ma_lawyer',
      'last_message': 'I can review the proposed structure.',
      'last_message_at': '2026-09-01T17:30:00Z',
      'unread_count': 3,
      'opportunity_id': 'deal-1',
      'opportunity_headline': 'Anonymous services acquisition',
    });

    expect(conversation.unreadCount, 3);
    expect(conversation.name, 'Avery Singh');
    expect(conversation.opportunityId, 'deal-1');
    expect(conversation.lastMessage, contains('proposed structure'));
  });

  test('signed-out inbox does not expose example conversations', () async {
    final conversations = await MemberNetworkService.loadConversations();

    expect(conversations, isEmpty);
  });

  test('chat messages preserve sender ownership', () {
    final message = MemberChatMessage.fromJson({
      'id': 'message-1',
      'sender_provider_id': 'provider-1',
      'sender_name': 'You',
      'body': 'Thanks for the referral.',
      'created_at': '2026-09-01T17:35:00Z',
      'is_mine': true,
      'read_at': '2026-09-01T17:40:00Z',
    });

    expect(message.isMine, isTrue);
    expect(message.body, 'Thanks for the referral.');
    expect(message.readAt, DateTime.parse('2026-09-01T17:40:00Z'));
  });
}
