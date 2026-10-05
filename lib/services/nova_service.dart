import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class NovaContext {
  const NovaContext({
    required this.area,
    required this.label,
    this.dealId,
    this.facts = const {},
    this.lesson,
  });
  final String area, label;
  final String? dealId, lesson;
  final Map<String, dynamic> facts;
  String get scope => '$area:${dealId ?? label}';
  Map<String, dynamic> toJson() => {
    'area': area,
    'label': label,
    if (dealId != null) 'dealId': dealId,
    if (lesson != null) 'lesson': lesson,
    'draft': facts,
  };
  List<String> get suggestions => switch (area) {
    'financials' || 'valuation' => [
      'Why did EBITDA decrease?',
      'Is this customer concentration dangerous?',
      'Explain this balance sheet.',
      'What should I ask the seller?',
      'How much debt could this business support?',
    ],
    'seller' => [
      'What should I prepare before speaking to a buyer?',
      'What could reduce my business value?',
      'Help me plan a gradual handover.',
    ],
    'member' => [
      'How should I introduce my expertise?',
      'What should my profile explain?',
      'How do I support a deal team?',
    ],
    'learning' => [
      'Explain this in plain language.',
      'Give me a worked example.',
      'Check my understanding with one question.',
    ],
    _ => [
      'What needs my attention first?',
      'What should I ask the seller?',
      'Which information is missing before I proceed?',
    ],
  };
}

class NovaAnswer {
  const NovaAnswer(this.text, this.sources);
  final String text;
  final List<String> sources;
}

class NovaUnavailable implements Exception {
  const NovaUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class NovaService {
  static Future<NovaAnswer> ask(
    NovaContext context,
    String question,
    List<Map<String, String>> history, {
    String evidence = '',
    bool consentToShare = false,
  }) async {
    if (!consentToShare)
      throw const NovaUnavailable(
        'Choose whether to share context with OpenAI before asking Nova.',
      );
    if (!BackendService.configured || BackendService.user == null) {
      throw const NovaUnavailable(
        'Sign in to ask Nova about your private workspace. You can still use the guided introduction and lessons.',
      );
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw const NovaUnavailable('Please sign in again.');
    try {
      final response = await http
          .post(
            Uri.base.resolve('/api/nova'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'context': context.toJson(),
              'question': question,
              'history': history.length > 12
                  ? history.sublist(history.length - 12)
                  : history,
              'evidence': evidence,
              'consentToShare': consentToShare,
            }),
          )
          .timeout(const Duration(seconds: 90));
      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const NovaUnavailable(
          'Nova’s live service is not available on this preview. Your guides and lessons still work.',
        );
      }
      if (response.statusCode != 200) {
        throw NovaUnavailable(
          body['error'] as String? ??
              'Nova could not answer. Please try again.',
        );
      }
      final answer = body['answer'] as String?;
      if (answer == null || answer.trim().isEmpty)
        throw const NovaUnavailable(
          'Nova did not return an answer. Please try again.',
        );
      return NovaAnswer(
        answer,
        List<String>.from(body['sources'] as List? ?? []),
      );
    } on NovaUnavailable {
      rethrow;
    } catch (_) {
      throw const NovaUnavailable(
        'Nova could not connect. Your question is still here; try again shortly.',
      );
    }
  }
}
