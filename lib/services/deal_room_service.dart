import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_service.dart';
import 'marketplace_service.dart';

class DealRoom {
  const DealRoom({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.city,
    required this.purchasePrice,
    required this.timeline,
    required this.goals,
    required this.status,
    required this.propertySnapshot,
    required this.riskSnapshot,
    required this.sharingPreferences,
    required this.updatedAt,
    required this.transactionType,
    this.completedTaskCount = 0,
    this.totalTaskCount = 0,
    this.currentStep = 'Open the workspace to begin',
  });

  final String id;
  final String userId;
  final String title;
  final String address;
  final String city;
  final double purchasePrice;
  final String timeline;
  final String goals;
  final String status;
  final Map<String, dynamic> propertySnapshot;
  final Map<String, dynamic> riskSnapshot;
  final Map<String, dynamic> sharingPreferences;
  final DateTime updatedAt;
  final String transactionType;
  final int completedTaskCount;
  final int totalTaskCount;
  final String currentStep;
  bool get isBusiness => transactionType == 'business';
  double get progress =>
      totalTaskCount == 0 ? 0 : completedTaskCount / totalTaskCount;

  bool get ownedByCurrentUser => userId == BackendService.user?.id;

  factory DealRoom.fromJson(Map<String, dynamic> row) {
    final tasks =
        (row['deal_room_tasks'] as List<dynamic>? ?? [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList()
          ..sort(
            (a, b) => ((a['position'] as num?)?.toInt() ?? 0).compareTo(
              (b['position'] as num?)?.toInt() ?? 0,
            ),
          );
    final completed = tasks.where((task) => task['completed'] == true).length;
    final next = tasks.cast<Map<String, dynamic>?>().firstWhere(
      (task) => task?['completed'] != true,
      orElse: () => null,
    );
    final currentStep = tasks.isEmpty
        ? 'Open the workspace to begin'
        : next == null
        ? 'All checklist steps complete'
        : next['title'] as String? ?? 'Continue the checklist';
    return DealRoom(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String? ?? 'Property Deal Room',
      address: row['property_address'] as String? ?? '',
      city: row['city'] as String? ?? '',
      purchasePrice: (row['purchase_price'] as num?)?.toDouble() ?? 0,
      timeline: row['timeline'] as String? ?? '',
      goals: row['goals'] as String? ?? '',
      status: row['status'] as String? ?? 'active',
      propertySnapshot: row['property_snapshot'] is Map
          ? Map<String, dynamic>.from(row['property_snapshot'] as Map)
          : {},
      riskSnapshot: row['risk_snapshot'] is Map
          ? Map<String, dynamic>.from(row['risk_snapshot'] as Map)
          : {},
      sharingPreferences: row['sharing_preferences'] is Map
          ? Map<String, dynamic>.from(row['sharing_preferences'] as Map)
          : {},
      updatedAt: DateTime.parse(row['updated_at'] as String),
      transactionType: row['transaction_type'] as String? ?? 'property',
      completedTaskCount: completed,
      totalTaskCount: tasks.length,
      currentStep: currentStep,
    );
  }
}

class DealRoomTask {
  const DealRoomTask({
    required this.id,
    required this.title,
    required this.category,
    required this.completed,
    required this.position,
  });
  final String id;
  final String title;
  final String category;
  final bool completed;
  final int position;

  factory DealRoomTask.fromJson(Map<String, dynamic> row) => DealRoomTask(
    id: row['id'] as String,
    title: row['title'] as String,
    category: row['category'] as String? ?? 'general',
    completed: row['completed'] as bool? ?? false,
    position: row['position'] as int? ?? 0,
  );
}

class DealRoomNote {
  const DealRoomNote({
    required this.id,
    required this.authorUserId,
    required this.text,
    required this.createdAt,
  });
  final String id;
  final String authorUserId;
  final String text;
  final DateTime createdAt;

  bool get mine => authorUserId == BackendService.user?.id;

  factory DealRoomNote.fromJson(Map<String, dynamic> row) => DealRoomNote(
    id: row['id'] as String,
    authorUserId: row['author_user_id'] as String,
    text: row['note_text'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

class DealRoomMember {
  const DealRoomMember({
    required this.id,
    required this.status,
    required this.accessLevel,
    required this.provider,
  });
  final String id;
  final String status;
  final String accessLevel;
  final MarketplaceProvider provider;
}

class DealRoomDocument {
  const DealRoomDocument({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    required this.createdAt,
  });
  final String id;
  final String fileName;
  final int fileSize;
  final String contentType;
  final DateTime createdAt;

  factory DealRoomDocument.fromJson(Map<String, dynamic> row) =>
      DealRoomDocument(
        id: row['id'] as String,
        fileName: row['file_name'] as String,
        fileSize: (row['file_size'] as num?)?.toInt() ?? 0,
        contentType:
            row['content_type'] as String? ?? 'application/octet-stream',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

class DealRoomBundle {
  const DealRoomBundle({
    required this.room,
    required this.tasks,
    required this.notes,
    required this.members,
    required this.documents,
  });
  final DealRoom room;
  final List<DealRoomTask> tasks;
  final List<DealRoomNote> notes;
  final List<DealRoomMember> members;
  final List<DealRoomDocument> documents;
}

class DealRoomService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _roomSelect =
      'id, user_id, title, property_address, city, purchase_price, timeline, goals, '
      'status, transaction_type, property_snapshot, risk_snapshot, sharing_preferences, updated_at, '
      'deal_room_tasks(title, completed, position)';

  static Future<List<DealRoom>> loadRooms() async {
    if (BackendService.user == null) return [];
    final rows = await _client
        .from('deal_rooms')
        .select(_roomSelect)
        .order('updated_at', ascending: false)
        .limit(50);
    return rows
        .map((row) => DealRoom.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<DealRoom> createFromLatestAnalysis() async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to create a Deal Room.');
    final analysis = await _client
        .from('property_analyses')
        .select(
          'id, address_label, decision_mode, location_profile, property_inputs, model_output',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (analysis == null) {
      throw StateError('Save a property analysis before creating a Deal Room.');
    }
    final inputs = analysis['property_inputs'] is Map
        ? Map<String, dynamic>.from(analysis['property_inputs'] as Map)
        : <String, dynamic>{};
    final location = analysis['location_profile'] is Map
        ? Map<String, dynamic>.from(analysis['location_profile'] as Map)
        : <String, dynamic>{};
    final output = analysis['model_output'] is Map
        ? Map<String, dynamic>.from(analysis['model_output'] as Map)
        : <String, dynamic>{};
    final address = analysis['address_label'] as String? ?? '';
    final inserted = await _client
        .from('deal_rooms')
        .insert({
          'user_id': user.id,
          'property_analysis_id': analysis['id'],
          'title': address.isEmpty ? 'New property opportunity' : address,
          'property_address': address,
          'city': location['city'] as String? ?? '',
          'purchase_price': (inputs['price'] as num?)?.toDouble() ?? 0,
          'timeline': '',
          'goals': analysis['decision_mode'] == 'invest'
              ? 'Evaluate and complete an investment property acquisition.'
              : 'Evaluate and complete a home purchase.',
          'property_snapshot': inputs,
          'risk_snapshot': output,
        })
        .select(_roomSelect)
        .single();
    final room = DealRoom.fromJson(Map<String, dynamic>.from(inserted));

    const taskTemplates = [
      ('Confirm purchase goals and timeline', 'planning'),
      ('Review financing and pre-approval', 'financing'),
      ('Complete property due diligence', 'property'),
      ('Review offer and conditions', 'legal'),
      ('Confirm insurance and closing costs', 'closing'),
      ('Prepare closing documents', 'closing'),
    ];
    await _client.from('deal_room_tasks').insert([
      for (var index = 0; index < taskTemplates.length; index++)
        {
          'deal_room_id': room.id,
          'title': taskTemplates[index].$1,
          'category': taskTemplates[index].$2,
          'position': index,
        },
    ]);

    final teamRows = await _client
        .from('user_team_members')
        .select('provider_id, provider_profiles!inner(provider_type)')
        .eq('user_id', user.id)
        .inFilter('provider_profiles.provider_type', [
          'realtor',
          'mortgage_broker',
          'lawyer',
          'accountant',
          'lender',
        ]);
    if (teamRows.isNotEmpty) {
      await _client.from('deal_room_members').insert([
        for (final row in teamRows)
          {
            'deal_room_id': room.id,
            'provider_id': row['provider_id'],
            'invited_by': user.id,
          },
      ]);
    }
    return room;
  }

  static Future<DealRoomBundle> loadBundle(DealRoom room) async {
    final values = await Future.wait([
      _client
          .from('deal_room_tasks')
          .select('id, title, category, completed, position')
          .eq('deal_room_id', room.id)
          .order('position'),
      _client
          .from('deal_room_notes')
          .select('id, author_user_id, note_text, created_at')
          .eq('deal_room_id', room.id)
          .order('created_at', ascending: false)
          .limit(100),
      _client
          .from('deal_room_members')
          .select(
            'id, status, access_level, provider_profiles(id, provider_type, display_name, company_name, description, phone, email, website_url, license_number, license_region, accepting_leads, verified, years_experience, review_score, review_count, job_title, is_example, photo_index, logo_object_key, membership_tier, provider_regions(service_regions(city, region, country_code)), sponsored_placements(disclosure_label, active, starts_at, ends_at), lender_rates(interest_rate, mortgage_type, verified_at, effective_at, expires_at))',
          )
          .eq('deal_room_id', room.id)
          .order('created_at'),
      _client
          .from('deal_room_documents')
          .select('id, file_name, file_size, content_type, created_at')
          .eq('deal_room_id', room.id)
          .order('created_at', ascending: false),
    ]);
    final tasks = (values[0] as List)
        .map(
          (row) => DealRoomTask.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    final notes = (values[1] as List)
        .map(
          (row) => DealRoomNote.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    final members = <DealRoomMember>[];
    for (final raw in values[2] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final providerRow = row['provider_profiles'];
      if (providerRow is! Map) continue;
      final providers = MarketplaceService.providersFromRows([providerRow]);
      if (providers.isEmpty) continue;
      members.add(
        DealRoomMember(
          id: row['id'] as String,
          status: row['status'] as String? ?? 'invited',
          accessLevel: row['access_level'] as String? ?? 'standard',
          provider: providers.first,
        ),
      );
    }
    final documents = (values[3] as List)
        .map(
          (row) =>
              DealRoomDocument.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    return DealRoomBundle(
      room: room,
      tasks: tasks,
      notes: notes,
      members: members,
      documents: documents,
    );
  }

  static Future<void> toggleTask(DealRoomTask task, bool completed) async {
    await _client
        .from('deal_room_tasks')
        .update({
          'completed': completed,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', task.id);
  }

  static Future<void> addNote(String roomId, String text) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to add a note.');
    await _client.from('deal_room_notes').insert({
      'deal_room_id': roomId,
      'author_user_id': user.id,
      'note_text': text.trim(),
    });
  }

  static Future<void> uploadDocument(String roomId, PlatformFile file) async {
    final user = BackendService.user;
    final token = _client.auth.currentSession?.accessToken;
    if (user == null || token == null) {
      throw StateError('Sign in to upload a document.');
    }
    if (file.bytes == null) throw StateError('Could not read this file.');
    final request = http.MultipartRequest(
      'POST',
      Uri.base.resolve('/api/property-files'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['analysisId'] = roomId;
    request.files.add(
      http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
    );
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 201) {
      throw StateError('Upload failed: ${response.body}');
    }
    final uploaded = jsonDecode(response.body) as Map<String, dynamic>;
    await _client.from('deal_room_documents').insert({
      'deal_room_id': roomId,
      'uploaded_by': user.id,
      'object_key': uploaded['key'],
      'file_name': uploaded['name'] ?? file.name,
      'file_size': uploaded['size'] ?? file.size,
      'content_type': _contentTypeFor(file.extension),
    });
  }

  static String _contentTypeFor(String? extension) => switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => 'application/octet-stream',
  };

  static Future<void> updateRoom({
    required String roomId,
    required String status,
    required String timeline,
    required String goals,
  }) async {
    await _client
        .from('deal_rooms')
        .update({
          'status': status,
          'timeline': timeline.trim(),
          'goals': goals.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }

  static Future<void> updateSharing(
    String roomId,
    Map<String, dynamic> preferences,
  ) async {
    await _client
        .from('deal_rooms')
        .update({
          'sharing_preferences': preferences,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }

  static Future<void> updateMemberAccess(
    String membershipId,
    String accessLevel,
  ) async {
    await _client
        .from('deal_room_members')
        .update({'access_level': accessLevel})
        .eq('id', membershipId);
  }

  static Future<void> respondToInvite(String membershipId, bool accept) async {
    await _client.rpc(
      'respond_to_deal_room_invite',
      params: {
        'membership_id': membershipId,
        'invite_status': accept ? 'accepted' : 'declined',
      },
    );
  }
}
