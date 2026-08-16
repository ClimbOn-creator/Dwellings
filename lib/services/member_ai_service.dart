import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';
import 'member_content_service.dart';

class MemberAiService {
  static Future<Map<String, dynamic>> _generate(
    String type,
    Map<String, String> fields,
  ) async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in to use secure AI generation.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null)
      throw StateError('Your session expired. Sign in again.');
    final response = await http.post(
      Uri.base.resolve('/api/member-content'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'type': type, 'fields': fields}),
    );
    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(data['error']?.toString() ?? 'AI generation failed.');
    }
    return data;
  }

  static Future<MemberEmailDraft> composeEmail({
    required String recipientName,
    required String senderName,
    required String purpose,
    required String context,
    required String tone,
  }) async {
    final data = await _generate('email', {
      'recipient_name': recipientName,
      'sender_name': senderName,
      'purpose': purpose,
      'context': context,
      'tone': tone,
    });
    return MemberEmailDraft(
      subject: data['subject']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
    );
  }

  static Future<MemberNewsletterDraft> composeNewsletter({
    required String memberName,
    required String city,
    required String audience,
    required String theme,
    required String insight,
    required String callToAction,
  }) async {
    final data = await _generate('newsletter', {
      'member_name': memberName,
      'city_or_market': city,
      'audience': audience,
      'theme': theme,
      'verified_insight': insight,
      'call_to_action': callToAction,
    });
    return MemberNewsletterDraft(
      subject: data['subject']?.toString() ?? '',
      preview: data['preview']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
    );
  }
}
