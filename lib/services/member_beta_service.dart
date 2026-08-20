import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';

class AffinityNotification {
  const AffinityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.actionModule,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final String actionModule;
  final DateTime createdAt;
  final bool read;

  factory AffinityNotification.fromJson(Map<String, dynamic> row) =>
      AffinityNotification(
        id: row['id'] as String,
        title: row['title'] as String? ?? 'Affinity update',
        message: row['message'] as String? ?? '',
        actionModule: row['action_module'] as String? ?? 'member-studio',
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        read: row['read_at'] != null,
      );
}

class AffinityMatchPreferences {
  const AffinityMatchPreferences({
    this.specialties = const [],
    this.regions = const [],
    this.minimumScore = 0,
    this.emailNotifications = true,
  });

  final List<String> specialties;
  final List<String> regions;
  final int minimumScore;
  final bool emailNotifications;

  factory AffinityMatchPreferences.fromJson(Map<String, dynamic> row) =>
      AffinityMatchPreferences(
        specialties: List<String>.from(row['specialties'] as List? ?? const []),
        regions: List<String>.from(row['regions'] as List? ?? const []),
        minimumScore: (row['minimum_affinity_score'] as num?)?.toInt() ?? 0,
        emailNotifications: row['email_notifications'] as bool? ?? true,
      );
}

class MemberBetaService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<AffinityNotification>> loadNotifications() async {
    if (!BackendService.configured || BackendService.user == null) return [];
    final rows = await _client
        .from('affinity_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(80);
    return rows.map(AffinityNotification.fromJson).toList();
  }

  static Future<int> unreadCount() async {
    if (!BackendService.configured || BackendService.user == null) return 0;
    final rows = await _client
        .from('affinity_notifications')
        .select('id')
        .isFilter('read_at', null);
    return rows.length;
  }

  static Future<void> markRead(String id) async {
    if (BackendService.user == null) return;
    await _client
        .from('affinity_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  static Future<AffinityMatchPreferences> loadPreferences() async {
    final rows = await _client.rpc('load_affinity_match_preferences');
    final list = rows as List<dynamic>;
    if (list.isEmpty) return const AffinityMatchPreferences();
    return AffinityMatchPreferences.fromJson(
      Map<String, dynamic>.from(list.first as Map),
    );
  }

  static Future<void> savePreferences(AffinityMatchPreferences value) async {
    await _client.rpc(
      'save_affinity_match_preferences',
      params: {
        'target_specialties': value.specialties,
        'target_regions': value.regions,
        'target_minimum_score': value.minimumScore,
        'target_email_notifications': value.emailNotifications,
      },
    );
  }

  static Future<void> flushEmailOutbox() async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    try {
      await http.post(
        Uri.base.resolve('/api/member-notification-emails'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(const {'source': 'affinity-app'}),
      );
    } catch (_) {
      // The in-app notification is authoritative; email delivery is best effort.
    }
  }
}
