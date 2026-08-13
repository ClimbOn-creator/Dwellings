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
    this.dealKind = 'residential',
    this.currentStage = 'discovery',
    this.targetCloseDate,
    this.archivedAt,
    this.completedTaskCount = 0,
    this.totalTaskCount = 0,
    this.currentStep = 'Open the workspace to begin',
    this.blockedTaskCount = 0,
    this.nextDueAt,
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
  final String dealKind;
  final String currentStage;
  final DateTime? targetCloseDate;
  final DateTime? archivedAt;
  final int completedTaskCount;
  final int totalTaskCount;
  final String currentStep;
  final int blockedTaskCount;
  final DateTime? nextDueAt;
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
    final blocked = tasks
        .where((task) => task['task_status'] == 'blocked')
        .length;
    final dueDates =
        tasks
            .where(
              (task) => task['completed'] != true && task['due_at'] is String,
            )
            .map((task) => DateTime.tryParse(task['due_at'] as String))
            .whereType<DateTime>()
            .toList()
          ..sort();
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
      dealKind:
          row['deal_kind'] as String? ??
          ((row['transaction_type'] as String? ?? 'property') == 'business'
              ? 'business'
              : 'residential'),
      currentStage: row['current_stage'] as String? ?? 'discovery',
      targetCloseDate: row['target_close_date'] == null
          ? null
          : DateTime.tryParse(row['target_close_date'] as String),
      archivedAt: row['archived_at'] == null
          ? null
          : DateTime.tryParse(row['archived_at'] as String),
      completedTaskCount: completed,
      totalTaskCount: tasks.length,
      currentStep: currentStep,
      blockedTaskCount: blocked,
      nextDueAt: dueDates.isEmpty ? null : dueDates.first,
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
    this.details = '',
    this.stage = 'discovery',
    this.status = 'not_started',
    this.blockerNote = '',
    this.dueAt,
    this.assignedProviderId,
  });
  final String id;
  final String title;
  final String category;
  final bool completed;
  final int position;
  final String details;
  final String stage;
  final String status;
  final String blockerNote;
  final DateTime? dueAt;
  final String? assignedProviderId;
  bool get blocked => status == 'blocked';

  factory DealRoomTask.fromJson(Map<String, dynamic> row) => DealRoomTask(
    id: row['id'] as String,
    title: row['title'] as String,
    category: row['category'] as String? ?? 'general',
    completed: row['completed'] as bool? ?? false,
    position: row['position'] as int? ?? 0,
    details: row['details'] as String? ?? '',
    stage: row['stage'] as String? ?? 'discovery',
    status:
        row['task_status'] as String? ??
        ((row['completed'] as bool? ?? false) ? 'completed' : 'not_started'),
    blockerNote: row['blocker_note'] as String? ?? '',
    dueAt: row['due_at'] == null
        ? null
        : DateTime.tryParse(row['due_at'] as String),
    assignedProviderId: row['assigned_provider_id'] as String?,
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
    required this.sha256,
    required this.securityStatus,
    required this.category,
    required this.uploadedBy,
  });
  final String id;
  final String fileName;
  final int fileSize;
  final String contentType;
  final DateTime createdAt;
  final String sha256;
  final String securityStatus;
  final String category;
  final String uploadedBy;

  factory DealRoomDocument.fromJson(Map<String, dynamic> row) =>
      DealRoomDocument(
        id: row['id'] as String,
        fileName: row['file_name'] as String,
        fileSize: (row['file_size'] as num?)?.toInt() ?? 0,
        contentType:
            row['content_type'] as String? ?? 'application/octet-stream',
        createdAt: DateTime.parse(row['created_at'] as String),
        sha256: row['sha256'] as String? ?? '',
        securityStatus: row['security_status'] as String? ?? 'validated',
        category: row['category'] as String? ?? 'general',
        uploadedBy: row['uploaded_by'] as String? ?? '',
      );
}

class DealRoomDocumentEvent {
  const DealRoomDocumentEvent({
    required this.id,
    required this.eventType,
    required this.fileName,
    required this.createdAt,
    required this.mine,
  });
  final String id;
  final String eventType;
  final String fileName;
  final DateTime createdAt;
  final bool mine;

  factory DealRoomDocumentEvent.fromJson(Map<String, dynamic> row) =>
      DealRoomDocumentEvent(
        id: row['id'] as String,
        eventType: row['event_type'] as String? ?? 'viewed',
        fileName: row['file_name'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
        mine: row['actor_user_id'] == BackendService.user?.id,
      );
}

class DealRoomBundle {
  const DealRoomBundle({
    required this.room,
    required this.tasks,
    required this.notes,
    required this.members,
    required this.documents,
    required this.documentEvents,
  });
  final DealRoom room;
  final List<DealRoomTask> tasks;
  final List<DealRoomNote> notes;
  final List<DealRoomMember> members;
  final List<DealRoomDocument> documents;
  final List<DealRoomDocumentEvent> documentEvents;
}

class DealTaskTemplate {
  const DealTaskTemplate(this.title, this.details, this.stage, this.category);
  final String title;
  final String details;
  final String stage;
  final String category;
}

class DealRoomService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _roomSelect =
      'id, user_id, title, property_address, city, purchase_price, timeline, goals, '
      'status, transaction_type, property_snapshot, risk_snapshot, sharing_preferences, updated_at, '
      'deal_kind, current_stage, target_close_date, archived_at, '
      'deal_room_tasks(title, completed, task_status, due_at, position)';

  static const stageOrder = <String>[
    'discovery',
    'financing',
    'offer',
    'diligence',
    'legal',
    'closing',
    'transition',
    'complete',
  ];

  static const residentialStages = <String>[
    'discovery',
    'financing',
    'search',
    'offer',
    'diligence',
    'closing',
    'complete',
  ];

  static const commercialStages = <String>[
    'discovery',
    'underwriting',
    'financing',
    'offer',
    'diligence',
    'legal',
    'closing',
    'complete',
  ];

  static const businessStages = <String>[
    'discovery',
    'screening',
    'offer',
    'diligence',
    'financing',
    'legal',
    'closing',
    'transition',
    'complete',
  ];

  static List<String> stagesFor(String kind) => switch (kind) {
    'business' => businessStages,
    'commercial' => commercialStages,
    _ => residentialStages,
  };

  static List<DealTaskTemplate> templatesFor(String kind) => switch (kind) {
    'business' => _businessTemplates,
    'commercial' => _commercialTemplates,
    _ => _residentialTemplates,
  };

  static Future<DealRoom> createManualRoom({
    required String title,
    required String dealKind,
    required String location,
    required double purchasePrice,
    required String goals,
    DateTime? targetCloseDate,
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to start a deal.');
    final transactionType = dealKind == 'business' ? 'business' : 'property';
    final inserted = await _client
        .from('deal_rooms')
        .insert({
          'user_id': user.id,
          'transaction_type': transactionType,
          'deal_kind': dealKind,
          'current_stage': 'discovery',
          'title': title.trim(),
          'property_address': location.trim(),
          'city': location.trim(),
          'purchase_price': purchasePrice,
          'goals': goals.trim(),
          'target_close_date': targetCloseDate == null
              ? null
              : _dateOnly(targetCloseDate),
          'sharing_preferences': {
            'financials': dealKind != 'business',
            'risk': true,
            'documents': false,
          },
        })
        .select(_roomSelect)
        .single();
    final room = DealRoom.fromJson(Map<String, dynamic>.from(inserted));
    await _insertTemplates(room.id, dealKind);
    await _attachSelectedTeam(room.id, dealKind, user.id);
    return room;
  }

  static Future<void> _insertTemplates(String roomId, String kind) async {
    final templates = templatesFor(kind);
    await _client.from('deal_room_tasks').insert([
      for (var index = 0; index < templates.length; index++)
        {
          'deal_room_id': roomId,
          'title': templates[index].title,
          'details': templates[index].details,
          'stage': templates[index].stage,
          'category': templates[index].category,
          'position': index,
        },
    ]);
  }

  static Future<void> addGuidedChecklist(String roomId, String kind) =>
      _insertTemplates(roomId, kind);

  static Future<void> _attachSelectedTeam(
    String roomId,
    String kind,
    String userId,
  ) async {
    final providerTypes = kind == 'business'
        ? const [
            'business_broker',
            'ma_lawyer',
            'quality_of_earnings',
            'commercial_lender',
            'tax_advisor',
            'insurance_advisor',
            'human_resources',
            'cybersecurity',
            'industry_advisor',
            'wealth_manager',
          ]
        : const [
            'realtor',
            'mortgage_broker',
            'lawyer',
            'accountant',
            'lender',
          ];
    final rows = await _client
        .from('user_team_members')
        .select('provider_id, provider_profiles!inner(provider_type)')
        .eq('user_id', userId)
        .inFilter('provider_profiles.provider_type', providerTypes);
    if (rows.isEmpty) return;
    await _client.from('deal_room_members').insert([
      for (final row in rows)
        {
          'deal_room_id': roomId,
          'provider_id': row['provider_id'],
          'invited_by': userId,
          'access_level': kind == 'business' ? 'summary' : 'standard',
        },
    ]);
  }

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
    const commercialTypes = {
      'office',
      'retail',
      'industrial',
      'multifamily',
      'mixedUse',
      'land',
      'hospitality',
    };
    final propertyType = inputs['propertyType'] as String? ?? '';
    final dealKind = commercialTypes.contains(propertyType)
        ? 'commercial'
        : 'residential';
    final inserted = await _client
        .from('deal_rooms')
        .insert({
          'user_id': user.id,
          'property_analysis_id': analysis['id'],
          'title': address.isEmpty ? 'New property opportunity' : address,
          'property_address': address,
          'city': location['city'] as String? ?? '',
          'purchase_price': (inputs['price'] as num?)?.toDouble() ?? 0,
          'deal_kind': dealKind,
          'current_stage': 'discovery',
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

    await _insertTemplates(room.id, dealKind);

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
    if (room.ownedByCurrentUser) {
      await _ensureGuidedChecklist(room);
    }
    final values = await Future.wait([
      _client
          .from('deal_room_tasks')
          .select(
            'id, title, details, category, stage, task_status, blocker_note, '
            'completed, due_at, assigned_provider_id, position',
          )
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
          .select(
            'id, file_name, file_size, content_type, created_at, uploaded_by, sha256, security_status, category',
          )
          .eq('deal_room_id', room.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false),
      _client
          .from('deal_room_document_events')
          .select('id, actor_user_id, event_type, file_name, created_at')
          .eq('deal_room_id', room.id)
          .order('created_at', ascending: false)
          .limit(50),
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
    final documentEvents = (values[4] as List)
        .map(
          (row) => DealRoomDocumentEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
    return DealRoomBundle(
      room: room,
      tasks: tasks,
      notes: notes,
      members: members,
      documents: documents,
      documentEvents: documentEvents,
    );
  }

  static Future<void> _ensureGuidedChecklist(DealRoom room) async {
    final existingRows = await _client
        .from('deal_room_tasks')
        .select('title, position')
        .eq('deal_room_id', room.id);
    final titles = existingRows
        .map((row) => row['title'] as String? ?? '')
        .toSet();
    final templates = templatesFor(room.dealKind);
    final missing = templates.where((task) => !titles.contains(task.title));
    if (missing.isEmpty) return;
    final highestPosition = existingRows.fold<int>(
      -1,
      (highest, row) => ((row['position'] as num?)?.toInt() ?? -1) > highest
          ? (row['position'] as num?)?.toInt() ?? highest
          : highest,
    );
    var offset = 0;
    await _client.from('deal_room_tasks').insert([
      for (final task in missing)
        {
          'deal_room_id': room.id,
          'title': task.title,
          'details': task.details,
          'stage': task.stage,
          'category': task.category,
          'position': highestPosition + (++offset),
        },
    ]);
  }

  static Future<void> toggleTask(DealRoomTask task, bool completed) async {
    await _client
        .from('deal_room_tasks')
        .update({
          'completed': completed,
          'task_status': completed ? 'completed' : 'not_started',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', task.id);
  }

  static Future<void> updateTask({
    required String taskId,
    required String status,
    required String blockerNote,
    DateTime? dueAt,
    String? assignedProviderId,
  }) async {
    await _client
        .from('deal_room_tasks')
        .update({
          'task_status': status,
          'completed': status == 'completed',
          'blocker_note': status == 'blocked' ? blockerNote.trim() : '',
          'due_at': dueAt?.toIso8601String(),
          'assigned_provider_id': assignedProviderId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);
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
  }

  static Future<void> downloadDocument(DealRoomDocument document) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Sign in to download this document.');
    final response = await http.get(
      Uri.base.resolve('/api/property-files?documentId=${document.id}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Download failed: ${response.body}');
    }
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save secure Deal Room document',
      fileName: document.fileName,
      bytes: response.bodyBytes,
    );
  }

  static Future<void> deleteDocument(DealRoomDocument document) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Sign in to delete this document.');
    final response = await http.delete(
      Uri.base.resolve('/api/property-files?documentId=${document.id}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Delete failed: ${response.body}');
    }
  }

  static Future<void> updateRoom({
    required String roomId,
    required String status,
    required String timeline,
    required String goals,
    String? currentStage,
    DateTime? targetCloseDate,
  }) async {
    await _client
        .from('deal_rooms')
        .update({
          'status': status,
          'timeline': timeline.trim(),
          'goals': goals.trim(),
          'current_stage': ?currentStage,
          'target_close_date': targetCloseDate == null
              ? null
              : _dateOnly(targetCloseDate),
          'archived_at': status == 'archived'
              ? DateTime.now().toIso8601String()
              : null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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

  static const _residentialTemplates = <DealTaskTemplate>[
    DealTaskTemplate(
      'Define needs and budget',
      'Record must-haves, preferred areas, maximum monthly carrying cost and decision-makers.',
      'discovery',
      'planning',
    ),
    DealTaskTemplate(
      'Confirm representation',
      'Review the buyer agency agreement, scope, compensation and conflicts with the selected realtor.',
      'discovery',
      'team',
    ),
    DealTaskTemplate(
      'Obtain mortgage pre-approval',
      'Confirm maximum loan, down payment, rate hold, stress-test assumptions and expiry date.',
      'financing',
      'financing',
    ),
    DealTaskTemplate(
      'Document available funds',
      'Confirm down payment, deposit and closing-cost funds and where each amount is held.',
      'financing',
      'financing',
    ),
    DealTaskTemplate(
      'Build the property shortlist',
      'Compare location, condition, strata, taxes, commute, schools and resale considerations.',
      'search',
      'property',
    ),
    DealTaskTemplate(
      'Review comparable sales',
      'Assess recent licensed comparables and document adjustments supporting the offer range.',
      'offer',
      'valuation',
    ),
    DealTaskTemplate(
      'Prepare offer and conditions',
      'Set price, deposit, completion, possession and conditions for financing, inspection and documents.',
      'offer',
      'legal',
    ),
    DealTaskTemplate(
      'Complete property inspection',
      'Review structure, systems, moisture, safety, maintenance and major future capital items.',
      'diligence',
      'property',
    ),
    DealTaskTemplate(
      'Review title and disclosures',
      'Check title, charges, easements, property disclosure statement and known defects with counsel.',
      'diligence',
      'legal',
    ),
    DealTaskTemplate(
      'Review strata or condo records',
      'Review bylaws, minutes, depreciation report, insurance, contingency reserve and special levies.',
      'diligence',
      'property',
    ),
    DealTaskTemplate(
      'Finalize financing',
      'Submit the accepted contract, satisfy lender conditions and confirm final mortgage instructions.',
      'diligence',
      'financing',
    ),
    DealTaskTemplate(
      'Bind property insurance',
      'Confirm coverage, exclusions, deductible, replacement cost and effective date.',
      'closing',
      'insurance',
    ),
    DealTaskTemplate(
      'Approve closing statement',
      'Review adjustments, property transfer tax, legal fees and cash required to close.',
      'closing',
      'legal',
    ),
    DealTaskTemplate(
      'Complete final walkthrough',
      'Verify agreed condition, inclusions, repairs and vacant possession before completion.',
      'closing',
      'property',
    ),
    DealTaskTemplate(
      'Complete purchase and possession',
      'Sign closing documents, transfer funds, receive keys and record warranties and service contacts.',
      'complete',
      'closing',
    ),
  ];

  static const _commercialTemplates = <DealTaskTemplate>[
    DealTaskTemplate(
      'Define investment mandate',
      'Set asset class, geography, target return, hold period, leverage and risk limits.',
      'discovery',
      'planning',
    ),
    DealTaskTemplate(
      'Assemble acquisition team',
      'Confirm broker, lender, commercial lawyer, accountant, inspector and environmental consultants.',
      'discovery',
      'team',
    ),
    DealTaskTemplate(
      'Build initial underwriting',
      'Model rent roll, recoveries, vacancy, operating costs, capital needs, NOI, cap rate and exit.',
      'underwriting',
      'financial',
    ),
    DealTaskTemplate(
      'Stress-test downside cases',
      'Test vacancy, renewal probability, interest rates, capex, rent decline and exit cap expansion.',
      'underwriting',
      'risk',
    ),
    DealTaskTemplate(
      'Confirm financing strategy',
      'Compare term, amortization, recourse, covenants, fees, reserves and lender underwriting.',
      'financing',
      'financing',
    ),
    DealTaskTemplate(
      'Submit letter of intent',
      'Set price, deposit, exclusivity, diligence access, financing condition and closing structure.',
      'offer',
      'legal',
    ),
    DealTaskTemplate(
      'Review title, survey and zoning',
      'Confirm permitted use, access, easements, encroachments, parking and development constraints.',
      'diligence',
      'legal',
    ),
    DealTaskTemplate(
      'Audit leases and rent roll',
      'Reconcile leases, amendments, arrears, inducements, options, deposits and tenant correspondence.',
      'diligence',
      'leasing',
    ),
    DealTaskTemplate(
      'Inspect building and systems',
      'Assess envelope, roof, structure, HVAC, electrical, plumbing, elevators and accessibility.',
      'diligence',
      'property',
    ),
    DealTaskTemplate(
      'Complete environmental review',
      'Complete appropriate Phase I/II work and evaluate remediation and reliance rights.',
      'diligence',
      'environmental',
    ),
    DealTaskTemplate(
      'Validate operating statements',
      'Reconcile taxes, utilities, repairs, management, recoveries and normalized NOI.',
      'diligence',
      'financial',
    ),
    DealTaskTemplate(
      'Review service contracts',
      'Check property management, maintenance, security, equipment leases and termination rights.',
      'diligence',
      'operations',
    ),
    DealTaskTemplate(
      'Negotiate purchase agreement',
      'Resolve representations, conditions, adjustments, holdbacks, indemnities and closing deliverables.',
      'legal',
      'legal',
    ),
    DealTaskTemplate(
      'Satisfy lender conditions',
      'Deliver valuation, environmental, leases, insurance, entity and legal documentation.',
      'closing',
      'financing',
    ),
    DealTaskTemplate(
      'Approve closing funds and adjustments',
      'Confirm tax, rent, deposit, utility and operating-cost adjustments and closing funds.',
      'closing',
      'closing',
    ),
    DealTaskTemplate(
      'Launch ownership transition',
      'Notify tenants and vendors, transfer accounts and execute the first 100-day asset plan.',
      'complete',
      'transition',
    ),
  ];

  static const _businessTemplates = <DealTaskTemplate>[
    DealTaskTemplate(
      'Define acquisition criteria',
      'Set industry, geography, purchase range, owner role, target earnings and risk limits.',
      'discovery',
      'planning',
    ),
    DealTaskTemplate(
      'Confirm adviser team',
      'Select business broker, M&A counsel, accountant/QoE, lender, tax and insurance advisers.',
      'discovery',
      'team',
    ),
    DealTaskTemplate(
      'Execute confidentiality agreement',
      'Review permitted use, disclosure restrictions, clean-team needs and return/destruction terms.',
      'screening',
      'confidentiality',
    ),
    DealTaskTemplate(
      'Complete initial viability screen',
      'Test normalized earnings, owner compensation, debt service, working capital and buyer cash flow.',
      'screening',
      'financial',
    ),
    DealTaskTemplate(
      'Review information memorandum',
      'Identify unsupported claims, missing evidence and questions for management.',
      'screening',
      'commercial',
    ),
    DealTaskTemplate(
      'Prepare and negotiate LOI',
      'Set price, structure, working capital, exclusivity, financing, diligence and transition expectations.',
      'offer',
      'legal',
    ),
    DealTaskTemplate(
      'Complete quality of earnings',
      'Reconcile financial statements, tax returns, bank activity, add-backs and normalized EBITDA/SDE.',
      'diligence',
      'financial',
    ),
    DealTaskTemplate(
      'Analyze customers and revenue',
      'Review concentration, churn, contracts, pipeline, pricing, recurring revenue and bad debts.',
      'diligence',
      'commercial',
    ),
    DealTaskTemplate(
      'Analyze suppliers and operations',
      'Review concentration, lead times, inventory, capacity, quality systems and key dependencies.',
      'diligence',
      'operations',
    ),
    DealTaskTemplate(
      'Review people and owner dependence',
      'Assess key employees, compensation, contractors, liabilities, retention and succession risk.',
      'diligence',
      'people',
    ),
    DealTaskTemplate(
      'Review legal and regulatory matters',
      'Check entity records, licences, disputes, IP, privacy, material contracts and compliance.',
      'diligence',
      'legal',
    ),
    DealTaskTemplate(
      'Assess technology and cybersecurity',
      'Review systems ownership, access, backups, incidents, vendors and transition requirements.',
      'diligence',
      'technology',
    ),
    DealTaskTemplate(
      'Finalize financing and working capital',
      'Confirm lender structure, covenants, equity, seller financing and opening liquidity.',
      'financing',
      'financing',
    ),
    DealTaskTemplate(
      'Finalize tax and acquisition structure',
      'Compare asset/share structure, allocations, rollover options and post-close tax obligations.',
      'legal',
      'tax',
    ),
    DealTaskTemplate(
      'Negotiate definitive agreements',
      'Resolve representations, indemnities, holdbacks, earn-outs, conditions and closing deliverables.',
      'legal',
      'legal',
    ),
    DealTaskTemplate(
      'Complete closing readiness review',
      'Confirm funds flow, consents, releases, insurance, accounts, payroll and Day One communications.',
      'closing',
      'closing',
    ),
    DealTaskTemplate(
      'Execute 100-day transition plan',
      'Transfer relationships and knowledge, retain key people and monitor cash, customers and milestones.',
      'transition',
      'transition',
    ),
    DealTaskTemplate(
      'Close transition and measure thesis',
      'Compare actual performance with the acquisition thesis and assign ongoing improvement actions.',
      'complete',
      'transition',
    ),
  ];
}
