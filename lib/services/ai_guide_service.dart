import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class AiGuideResult {
  const AiGuideResult({
    required this.message,
    required this.blueprintPatch,
    required this.calendarEvents,
    required this.suggestedAction,
  });

  final String message;
  final Map<String, String> blueprintPatch;
  final List<Map<String, String>> calendarEvents;
  final String suggestedAction;
}

class AiGuideService {
  static Future<AiGuideResult> generate({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> workspace,
  }) async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in to use secure AI generation.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null)
      throw StateError('Your session expired. Sign in again.');
    final response = await http.post(
      Uri.base.resolve('/api/ai-guide'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'messages': messages, 'workspace': workspace}),
    );
    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(data['error']?.toString() ?? 'AI generation failed.');
    }
    return AiGuideResult(
      message: data['message']?.toString() ?? 'I could not form a response.',
      blueprintPatch: data['blueprint_patch'] is Map
          ? Map<String, String>.from(
              (data['blueprint_patch'] as Map).map(
                (key, value) => MapEntry('$key', '$value'),
              ),
            )
          : const {},
      calendarEvents: data['calendar_events'] is List
          ? (data['calendar_events'] as List)
                .whereType<Map>()
                .map(
                  (event) => Map<String, String>.from(
                    event.map((key, value) => MapEntry('$key', '$value')),
                  ),
                )
                .toList()
          : const [],
      suggestedAction: data['suggested_action']?.toString() ?? '',
    );
  }
}
