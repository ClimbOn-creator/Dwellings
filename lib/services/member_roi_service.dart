import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class MemberRoiSnapshot {
  const MemberRoiSnapshot({
    required this.days,
    this.views = 0,
    this.qualified = 0,
    this.consultations = 0,
    this.transactions = 0,
    this.revenue = 0,
    this.annualCost,
    this.startedAt,
    this.outcomes = const [],
    this.inquiries = const [],
  });
  final int days, views, qualified, consultations, transactions;
  final double revenue;
  final double? annualCost;
  final String? startedAt;
  final List<Map<String, dynamic>> outcomes, inquiries;
  double? get periodCost =>
      annualCost == null ? null : annualCost! * days / 365;
  double? get netReturn => periodCost == null ? null : revenue - periodCost!;
  double? get roiPercent => periodCost == null || periodCost! <= 0
      ? null
      : (revenue - periodCost!) / periodCost! * 100;
  factory MemberRoiSnapshot.fromJson(Map<String, dynamic> r) =>
      MemberRoiSnapshot(
        days: (r['days'] as num).toInt(),
        views: (r['views'] as num).toInt(),
        qualified: (r['qualified_inquiries'] as num).toInt(),
        consultations: (r['consultations'] as num).toInt(),
        transactions: (r['transactions'] as num).toInt(),
        revenue: (r['revenue'] as num).toDouble(),
        annualCost: (r['annual_cost'] as num?)?.toDouble(),
        startedAt: r['tracking_started_at'] as String?,
        outcomes: (r['outcomes'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        inquiries: (r['inquiries'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

class MemberRoiService {
  Future<MemberRoiSnapshot> load(int days) async => MemberRoiSnapshot.fromJson(
    Map<String, dynamic>.from(
      await Supabase.instance.client.rpc(
            'pact_member_roi_summary',
            params: {'p_days': days},
          )
          as Map,
    ),
  );
  Future<void> saveCost(double cost) async {
    final owner = BackendService.user?.id;
    if (owner == null) throw StateError('Sign in required');
    await Supabase.instance.client.from('member_roi_settings').upsert({
      'owner_id': owner,
      'annual_cost': cost,
    });
  }

  Future<void> record({
    required String id,
    required String kind,
    required String label,
    required String source,
    required DateTime date,
    required double revenue,
    String? leadId,
  }) async {
    final owner = BackendService.user?.id;
    if (owner == null) throw StateError('Sign in required');
    try {
      await Supabase.instance.client.from('member_roi_outcomes').insert({
        'id': id,
        'owner_id': owner,
        'kind': kind,
        'label': label.trim(),
        'source': source,
        'lead_id': leadId,
        'occurred_on': date.toIso8601String().split('T').first,
        'revenue': revenue,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> voidOutcome(String id) async {
    final owner = BackendService.user?.id;
    if (owner == null) throw StateError('Sign in required');
    await Supabase.instance.client
        .from('member_roi_outcomes')
        .update({'voided_at': DateTime.now().toUtc().toIso8601String()})
        .eq('owner_id', owner)
        .eq('id', id);
  }

  static Future<void> view({String? memberId, String? providerId}) async {
    if (BackendService.user == null) return;
    try {
      await Supabase.instance.client
          .rpc(
            'pact_record_member_profile_view',
            params: {'p_member': memberId, 'p_provider': providerId},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Analytics must never block a profile. */
    }
  }
}
