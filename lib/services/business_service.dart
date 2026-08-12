import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_model.dart';
import 'backend_service.dart';
import 'deal_room_service.dart';

class BusinessService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> saveAssessment(
    BusinessInputs inputs,
    BusinessResult result,
  ) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to save this assessment.');
    final row = await _client
        .from('business_assessments')
        .insert({
          'user_id': user.id,
          'business_name': inputs.businessName.trim().isEmpty
              ? 'Confidential opportunity'
              : inputs.businessName.trim(),
          'industry': inputs.industry.trim(),
          'location': inputs.location.trim(),
          'inputs': inputs.toJson(),
          'results': result.toJson(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  static Future<DealRoom> createAcquisitionRoom({
    required String assessmentId,
    required BusinessInputs inputs,
    required BusinessResult result,
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to create a workspace.');
    final inserted = await _client
        .from('deal_rooms')
        .insert({
          'user_id': user.id,
          'business_assessment_id': assessmentId,
          'transaction_type': 'business',
          'title': inputs.businessName.trim().isEmpty
              ? 'Confidential business acquisition'
              : inputs.businessName.trim(),
          'property_address': inputs.location.trim(),
          'city': inputs.location.trim(),
          'purchase_price': inputs.n('askingPrice'),
          'goals':
              'Assess, diligence, finance and complete a business acquisition.',
          'property_snapshot': inputs.toJson(),
          'risk_snapshot': result.toJson(),
          'sharing_preferences': {
            'financials': false,
            'risk': true,
            'documents': false,
          },
        })
        .select(
          'id, user_id, title, property_address, city, purchase_price, timeline, goals, status, transaction_type, property_snapshot, risk_snapshot, sharing_preferences, updated_at',
        )
        .single();
    final room = DealRoom.fromJson(Map<String, dynamic>.from(inserted));
    const stages = [
      ('Define buyer criteria and acquisition goals', 'planning'),
      ('Execute confidentiality agreement', 'confidentiality'),
      ('Collect three years of financial statements', 'financial'),
      ('Reconcile tax returns and bank statements', 'financial'),
      ('Verify seller add-backs and normalized earnings', 'financial'),
      ('Review customers, suppliers and concentration', 'commercial'),
      ('Assess owner dependence and management transition', 'operations'),
      ('Review employees, contractors and obligations', 'people'),
      ('Review leases, licences and material contracts', 'legal'),
      ('Assess technology, privacy and cybersecurity', 'technology'),
      ('Confirm financing structure and working capital', 'financing'),
      ('Prepare and negotiate letter of intent', 'legal'),
      ('Complete quality-of-earnings review', 'financial'),
      ('Finalize tax and ownership structure', 'tax'),
      ('Negotiate purchase agreement and closing conditions', 'legal'),
      ('Prepare transition and first 100-day plan', 'transition'),
    ];
    await _client.from('deal_room_tasks').insert([
      for (var index = 0; index < stages.length; index++)
        {
          'deal_room_id': room.id,
          'title': stages[index].$1,
          'category': stages[index].$2,
          'position': index,
        },
    ]);
    final selectedAdvisers = await _client
        .from('user_team_members')
        .select('provider_id, provider_profiles!inner(provider_type)')
        .eq('user_id', user.id)
        .inFilter('provider_profiles.provider_type', [
          'lawyer',
          'accountant',
          'lender',
        ]);
    if (selectedAdvisers.isNotEmpty) {
      await _client.from('deal_room_members').insert([
        for (final row in selectedAdvisers)
          {
            'deal_room_id': room.id,
            'provider_id': row['provider_id'],
            'invited_by': user.id,
            'access_level': 'summary',
          },
      ]);
    }
    return room;
  }
}
