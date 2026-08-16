import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class ConsultingService {
  static Future<void> request({
    required String format,
    required String phone,
    required String outcome,
    required String challenge,
  }) async {
    if (!BackendService.configured || BackendService.user == null) {
      throw StateError('Sign in before requesting consulting support.');
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null)
      throw StateError('Your session expired. Sign in again.');
    final response = await http.post(
      Uri.base.resolve('/api/consulting-request'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'format': format,
        'phone': phone.trim(),
        'outcome': outcome.trim(),
        'challenge': challenge.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      throw StateError(
        data?['error']?.toString() ?? 'Could not send the consulting request.',
      );
    }
  }
}
