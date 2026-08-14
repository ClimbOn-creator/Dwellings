import 'package:dwelling_iq/services/member_content_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberContentService', () {
    test('email draft includes client context and sender', () {
      final draft = MemberContentService.composeEmail(
        recipientName: 'Alex',
        senderName: 'Morgan Lee',
        purpose: 'Document request',
        context: 'Please send the last two years of statements.',
        tone: 'Professional',
      );

      expect(draft.subject, contains('Documents'));
      expect(draft.body, contains('Alex'));
      expect(draft.body, contains('last two years'));
      expect(draft.body, contains('Morgan Lee'));
    });

    test('newsletter draft uses market and verified member insight', () {
      final draft = MemberContentService.composeNewsletter(
        memberName: 'Jamie Chen',
        city: 'Victoria, BC',
        audience: 'Property buyers',
        theme: 'Financing readiness',
        insight: 'Pre-approval timing matters before an offer is written.',
        callToAction: 'Book a 15-minute planning call.',
      );

      expect(draft.subject, contains('Victoria, BC'));
      expect(draft.body, contains('Pre-approval timing'));
      expect(draft.body, contains('Jamie Chen'));
    });
  });
}
