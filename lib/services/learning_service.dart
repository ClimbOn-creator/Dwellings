import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';
import 'learning_area_service.dart';

class LearningPermissions {
  const LearningPermissions({this.canPublish = false, this.isOwner = false});
  final bool canPublish, isOwner;
  factory LearningPermissions.fromJson(Map<String, dynamic> j) =>
      LearningPermissions(
        canPublish: j['can_publish'] == true,
        isOwner: j['is_owner'] == true,
      );
}

class LearningAttachment {
  const LearningAttachment({
    required this.name,
    required this.mime,
    required this.path,
    required this.url,
  });
  final String name, mime, path, url;
  bool get image => mime.startsWith('image/');
  bool get video => mime.startsWith('video/');
  bool get audio => mime.startsWith('audio/');
}

class LearningPost {
  const LearningPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.title,
    required this.body,
    required this.topic,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.areaName,
    this.distanceKm,
    this.liked = false,
    this.saved = false,
    this.media = const [],
  });
  final String id, authorId, author, title, body, topic;
  final DateTime createdAt;
  final int likes, comments;
  final String? areaName;
  final double? distanceKm;
  final bool liked, saved;
  final List<LearningAttachment> media;
}

class LearningUpload {
  const LearningUpload(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
  static const types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'mov': 'video/quicktime',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'pdf': 'application/pdf',
  };
  String get extension => name.split('.').last.toLowerCase();
  String get mime => types[extension] ?? '';
  void validate() {
    if (mime.isEmpty)
      throw StateError(
        'Use JPG, PNG, WebP, GIF, MP4, WebM, MOV, MP3, WAV, M4A or PDF.',
      );
    if (bytes.isEmpty || bytes.length > 90 * 1024 * 1024)
      throw StateError('Choose a file under 90 MB.');
  }
}

class LearningSeminar {
  const LearningSeminar({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.duration,
    required this.joinUrl,
    this.replayUrl = '',
    this.status = 'scheduled',
    this.registered = false,
  });
  final String id, hostId, title, description, joinUrl, replayUrl, status;
  final DateTime startsAt;
  final int duration;
  final bool registered;
  DateTime get endsAt => startsAt.add(Duration(minutes: duration));
  bool canJoin(DateTime now) =>
      status != 'cancelled' &&
      status != 'ended' &&
      (status == 'live' || (!now.isBefore(startsAt) && now.isBefore(endsAt)));
  static bool validUrl(String url) {
    final u = Uri.tryParse(url);
    return u != null &&
        u.scheme == 'https' &&
        u.host.isNotEmpty &&
        !url.contains(RegExp(r'\s'));
  }

  factory LearningSeminar.fromJson(
    Map<String, dynamic> j, {
    bool registered = false,
  }) => LearningSeminar(
    id: j['id'],
    hostId: j['host_id'],
    title: j['title'],
    description: j['description'] ?? '',
    startsAt: DateTime.parse(j['starts_at']).toLocal(),
    duration: j['duration_minutes'] as int,
    joinUrl: j['meeting_url'],
    replayUrl: j['replay_url'] ?? '',
    status: j['status'],
    registered: registered,
  );
}

class LearningService {
  static SupabaseClient get client => Supabase.instance.client;
  static Future<LearningPermissions> permissions() async {
    if (!BackendService.configured) return const LearningPermissions();
    return LearningPermissions.fromJson(
      Map<String, dynamic>.from(
        await client.rpc('learning_permissions') as Map,
      ),
    );
  }

  static Future<void> _requirePublisher() async {
    if (BackendService.user == null || !(await permissions()).canPublish)
      throw StateError('Only creator-approved contributors can publish.');
  }

  static Future<List<LearningPost>> posts({
    LearningArea? area,
    String order = 'recommended',
  }) async {
    if (!BackendService.configured) return [];
    if (area == null) return [];
    final ranked = await client.rpc(
      'learning_local_feed',
      params: {
        'latitude': LearningArea.coarse(area.latitude),
        'longitude': LearningArea.coarse(area.longitude),
        'feed_order': order,
      },
    );
    final matches = List<Map<String, dynamic>>.from(ranked);
    if (matches.isEmpty) return [];
    final ranks = {
      for (var i = 0; i < matches.length; i++) matches[i]['post_id']: i,
    };
    final distances = {
      for (final m in matches)
        m['post_id']: (m['distance_km'] as num).toDouble(),
    };
    final rows = await client
        .from('learning_posts')
        .select('*,learning_media(*)')
        .eq('status', 'published')
        .inFilter('id', matches.map((m) => m['post_id']).toList());
    rows.sort((a, b) => ranks[a['id']]!.compareTo(ranks[b['id']]!));
    if (rows.isEmpty) return [];
    final names = await client
        .from('learning_publishers')
        .select('user_id,display_name')
        .inFilter('user_id', rows.map((j) => j['author_id']).toSet().toList());
    final byId = {for (final n in names) n['user_id']: n['display_name']};
    final reactions = BackendService.user == null
        ? <Map<String, dynamic>>[]
        : await client
              .from('learning_reactions')
              .select('post_id,kind')
              .eq('user_id', BackendService.user!.id);
    final result = <LearningPost>[];
    for (final row in rows) {
      final files = List<Map<String, dynamic>>.from(
        row['learning_media'] ?? [],
      )..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
      final attachments = <LearningAttachment>[];
      for (final f in files) {
        final url = f['storage_backend'] == 'supabase'
            ? await client.storage
                  .from('learning-media')
                  .createSignedUrl(f['object_path'], 3600)
            : Uri.base.resolve('/api/learning-media?id=${f['id']}').toString();
        attachments.add(
          LearningAttachment(
            name: f['filename'],
            mime: f['mime_type'],
            path: f['object_path'],
            url: url,
          ),
        );
      }
      result.add(
        LearningPost(
          id: row['id'],
          authorId: row['author_id'],
          author: byId[row['author_id']] ?? 'Approved contributor',
          title: row['title'],
          body: row['body'],
          topic: row['topic'],
          createdAt: DateTime.parse(row['created_at']).toLocal(),
          likes: row['likes_count'],
          comments: row['comments_count'] ?? 0,
          areaName: row['area_name'],
          distanceKm: distances[row['id']],
          liked: reactions.any(
            (r) => r['post_id'] == row['id'] && r['kind'] == 'like',
          ),
          saved: reactions.any(
            (r) => r['post_id'] == row['id'] && r['kind'] == 'save',
          ),
          media: attachments,
        ),
      );
    }
    return result;
  }

  static Future<void> publish(
    String title,
    String body,
    String topic,
    List<LearningUpload> files, {
    LearningArea? area,
  }) async {
    await _requirePublisher();
    if (area == null) throw StateError('Choose the community for this post.');
    if (title.trim().length < 3 ||
        title.trim().length > 160 ||
        body.length > 12000)
      throw StateError('Enter a title of 3–160 characters and a shorter post.');
    if (files.length > 10)
      throw StateError('Add up to 10 attachments per post.');
    for (final file in files) file.validate();
    final user = BackendService.user!.id;
    final row = await client
        .from('learning_posts')
        .insert({
          'author_id': user,
          'title': title.trim(),
          'body': body.trim(),
          'topic': topic,
          'status': 'draft',
          ...area.toJson(),
        })
        .select('id')
        .single();
    final id = row['id'] as String;
    final uploaded = <String>[];
    try {
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        final token = client.auth.currentSession?.accessToken;
        if (token == null)
          throw StateError('Sign in to upload learning media.');
        final request = http.MultipartRequest(
          'POST',
          Uri.base.resolve('/api/learning-media'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields.addAll({'postId': id, 'position': '$i'});
        request.files.add(
          http.MultipartFile.fromBytes('file', f.bytes, filename: f.name),
        );
        final response = await http.Response.fromStream(await request.send());
        if (response.statusCode != 201)
          throw StateError('Upload failed: ${response.body}');
        uploaded.add((jsonDecode(response.body) as Map)['id'] as String);
      }
      // Recheck at the server when publishing. A revoked contributor cannot make a draft public.
      final changed = await client
          .from('learning_posts')
          .update({'status': 'published'})
          .eq('id', id)
          .select('id');
      if (changed.isEmpty)
        throw StateError(
          'Publishing access changed. Your post was not published.',
        );
    } catch (_) {
      if (uploaded.isNotEmpty) {
        try {
          final token = client.auth.currentSession?.accessToken;
          if (token != null)
            for (final mediaId in uploaded) {
              await http.delete(
                Uri.base.resolve('/api/learning-media?id=$mediaId'),
                headers: {'Authorization': 'Bearer $token'},
              );
            }
        } catch (_) {}
      }
      rethrow;
    }
  }

  static Future<void> reaction(
    LearningPost post,
    String kind,
    bool enabled,
  ) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to save or like lessons.');
    if (enabled) {
      await client
          .from('learning_reactions')
          .upsert(
            {'post_id': post.id, 'user_id': user.id, 'kind': kind},
            onConflict: 'post_id,user_id,kind',
            ignoreDuplicates: true,
          );
    } else {
      await client
          .from('learning_reactions')
          .delete()
          .eq('post_id', post.id)
          .eq('user_id', user.id)
          .eq('kind', kind);
    }
  }

  static Future<void> hidePost(String id) async {
    await client
        .from('learning_posts')
        .update({'status': 'hidden'})
        .eq('id', id);
  }

  static Future<List<LearningSeminar>> seminars() async {
    if (!BackendService.configured) return [];
    final rows = await client
        .from('learning_seminars')
        .select()
        .order('starts_at')
        .limit(100);
    final rsvps = BackendService.user == null
        ? <Map<String, dynamic>>[]
        : await client
              .from('learning_rsvps')
              .select('seminar_id')
              .eq('user_id', BackendService.user!.id);
    return rows
        .map(
          (j) => LearningSeminar.fromJson(
            j,
            registered: rsvps.any((r) => r['seminar_id'] == j['id']),
          ),
        )
        .toList();
  }

  static Future<void> schedule(Map<String, dynamic> fields) async {
    await _requirePublisher();
    if (!LearningSeminar.validUrl(fields['meeting_url']))
      throw StateError('Use an HTTPS seminar link.');
    await client.from('learning_seminars').insert({
      ...fields,
      'host_id': BackendService.user!.id,
    });
  }

  static Future<void> seminarStatus(String id, String status) async {
    await client
        .from('learning_seminars')
        .update({'status': status})
        .eq('id', id);
  }

  static Future<void> rsvp(LearningSeminar s, bool enabled) async {
    final u = BackendService.user;
    if (u == null) throw StateError('Sign in to reserve your place.');
    if (enabled) {
      await client.from('learning_rsvps').upsert({
        'seminar_id': s.id,
        'user_id': u.id,
      }, ignoreDuplicates: true);
    } else {
      await client
          .from('learning_rsvps')
          .delete()
          .eq('seminar_id', s.id)
          .eq('user_id', u.id);
    }
  }

  static Future<List<Map<String, dynamic>>> publishers() async {
    return List<Map<String, dynamic>>.from(
      await client.rpc('learning_publisher_list') as List,
    );
  }

  static Future<void> approve(String email, String name, bool active) async {
    await client.rpc(
      'approve_learning_publisher',
      params: {
        'target_email': email.trim(),
        'target_name': name.trim(),
        'approved': active,
      },
    );
  }

  static Future<List<LearningComment>> comments(
    String postId, {
    int limit = 100,
  }) async {
    final rows = await client
        .from('learning_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at')
        .order('id')
        .limit(limit);
    return rows.map(LearningComment.fromJson).toList();
  }

  static Future<void> comment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in to comment.');
    if (body.trim().isEmpty || body.trim().length > 2000)
      throw StateError('Write a comment of 1–2,000 characters.');
    await client.from('learning_comments').insert({
      'post_id': postId,
      'author_id': user.id,
      'body': body.trim(),
      'parent_id': parentId,
    });
  }

  static Future<void> removeComment(String id) async {
    await client
        .from('learning_comments')
        .update({
          'body': '',
          'removed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<Set<String>> progress() async {
    if (BackendService.user == null) return {};
    final rows = await client
        .from('learning_progress')
        .select('concept_id')
        .eq('user_id', BackendService.user!.id);
    return rows.map((j) => j['concept_id'] as String).toSet();
  }

  static Future<void> markConcept(String id, bool complete) async {
    final u = BackendService.user;
    if (u == null) return;
    if (complete) {
      await client.from('learning_progress').upsert({
        'user_id': u.id,
        'concept_id': id,
      }, ignoreDuplicates: true);
    } else {
      await client
          .from('learning_progress')
          .delete()
          .eq('user_id', u.id)
          .eq('concept_id', id);
    }
  }
}

class LearningComment {
  const LearningComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.author,
    required this.body,
    required this.createdAt,
    this.parentId,
    this.depth = 0,
    this.removed = false,
  });
  final String id, postId, authorId, author, body;
  final String? parentId;
  final int depth;
  final bool removed;
  final DateTime createdAt;
  factory LearningComment.fromJson(Map<String, dynamic> j) => LearningComment(
    id: j['id'],
    postId: j['post_id'],
    authorId: j['author_id'],
    author: j['author_name'],
    body: j['body'],
    parentId: j['parent_id'],
    depth: j['depth'],
    removed: j['removed_at'] != null,
    createdAt: DateTime.parse(j['created_at']),
  );
}
