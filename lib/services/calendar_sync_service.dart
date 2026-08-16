import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'backend_service.dart';

class CalendarSyncService {
  static Future<String> _token() async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in before connecting a calendar.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null)
      throw StateError('Your session expired. Sign in again.');
    return session.accessToken;
  }

  static Future<Set<String>> connections() async {
    final response = await http.get(
      Uri.base.resolve('/api/calendar/status'),
      headers: {'authorization': 'Bearer ${await _token()}'},
    );
    final data = _data(response);
    return ((data['connections'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item['provider']?.toString() ?? '')
        .where((provider) => provider.isNotEmpty)
        .toSet();
  }

  static Future<void> connect(String provider) async {
    final response = await http.post(
      Uri.base.resolve('/api/calendar/connect'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode({'provider': provider}),
    );
    final data = _data(response);
    final uri = Uri.tryParse(data['authorization_url']?.toString() ?? '');
    if (uri == null || !await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw StateError('Could not open calendar authorization.');
    }
  }

  static Future<Map<String, String>> syncEvent({
    required String provider,
    required String title,
    required DateTime start,
    String? externalId,
  }) async {
    final response = await http.post(
      Uri.base.resolve('/api/calendar/events'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${await _token()}',
      },
      body: jsonEncode({
        'provider': provider,
        'title': title,
        'start': start.toUtc().toIso8601String(),
        'end': start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
        if (externalId?.isNotEmpty == true) 'external_id': externalId,
      }),
    );
    final data = _data(response);
    return {
      'external_id': data['external_id']?.toString() ?? '',
      'web_link': data['web_link']?.toString() ?? '',
    };
  }

  static Map<String, dynamic> _data(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(data['error']?.toString() ?? 'Calendar request failed.');
    }
    return data;
  }
}
