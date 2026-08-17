class MemberEmailDraft {
  const MemberEmailDraft({required this.subject, required this.body});

  final String subject;
  final String body;

  String get copyText => 'Subject: $subject\n\n$body';
}

class MemberNewsletterDraft {
  const MemberNewsletterDraft({
    required this.subject,
    required this.preview,
    required this.body,
  });

  final String subject;
  final String preview;
  final String body;

  String get copyText => 'Subject: $subject\nPreview: $preview\n\n$body';
}

class MemberContentService {
  const MemberContentService._();

  static MemberEmailDraft composeEmail({
    required String recipientName,
    required String senderName,
    required String purpose,
    required String context,
    required String tone,
  }) {
    final recipient = recipientName.trim().isEmpty
        ? 'there'
        : recipientName.trim();
    final sender = senderName.trim().isEmpty
        ? 'Your Affinity professional'
        : senderName.trim();
    final detail = context.trim().isEmpty
        ? 'I wanted to check in and make sure you have what you need for the next step.'
        : context.trim();
    final warm = tone == 'Warm';
    final concise = tone == 'Concise';
    final opening = warm
        ? 'I hope your week is going well.'
        : concise
        ? ''
        : 'Thank you for trusting me to help with your next step.';
    final purposeCopy = switch (purpose) {
      'Meeting follow-up' =>
        'I am following up on our conversation and the priorities we discussed.',
      'Document request' =>
        'To keep your file moving, I need the remaining documents when they are available.',
      'Professional introduction' =>
        'I would like to connect you with a trusted professional who can help move this decision forward.',
      'Re-engagement' =>
        'It has been a little while since we last spoke, so I wanted to see where things stand.',
      _ => 'I wanted to share a quick update and confirm the next step.',
    };
    final subject = switch (purpose) {
      'Meeting follow-up' => 'Next steps from our conversation',
      'Document request' => 'Documents needed for your next step',
      'Professional introduction' => 'A helpful introduction for your purchase',
      'Re-engagement' => 'Checking in on your plans',
      _ => 'A quick update on your next step',
    };
    final paragraphs = [
      'Hi $recipient,',
      if (opening.isNotEmpty) opening,
      purposeCopy,
      detail,
      'If it is helpful, reply with a time that works for you and I will make the next step easy.',
      'Best,\n$sender',
    ];
    return MemberEmailDraft(subject: subject, body: paragraphs.join('\n\n'));
  }

  static MemberNewsletterDraft composeNewsletter({
    required String memberName,
    required String city,
    required String audience,
    required String theme,
    required String insight,
    required String callToAction,
  }) {
    final market = city.trim().isEmpty ? 'your local market' : city.trim();
    final author = memberName.trim().isEmpty
        ? 'Your local adviser'
        : memberName.trim();
    final topic = theme.trim().isEmpty ? 'The month ahead' : theme.trim();
    final observation = insight.trim().isEmpty
        ? 'The strongest decisions are being made by buyers who understand their numbers, prepare documents early and build the right professional team before urgency sets in.'
        : insight.trim();
    final cta = callToAction.trim().isEmpty
        ? 'Reply to this email if you would like a clear next-step plan for your purchase.'
        : callToAction.trim();
    return MemberNewsletterDraft(
      subject: '$market briefing · $topic',
      preview: 'A practical monthly update for $audience in $market.',
      body:
          '''Hello,

Here is your monthly Affinity briefing for $market.

$topic

$observation

WHAT TO DO NEXT
• Confirm the decision criteria that matter most.
• Review financing, legal and tax questions before making a commitment.
• Keep your deal team aligned around one shared next step.

$cta

— $author''',
    );
  }
}
