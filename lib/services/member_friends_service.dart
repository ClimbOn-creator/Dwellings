import 'package:supabase_flutter/supabase_flutter.dart';
import 'workspace_role_service.dart';

class MemberFriend {
  const MemberFriend({
    required this.userId,
    required this.name,
    this.jobTitle = '',
    this.company = '',
    this.photoUrl = '',
    this.coverUrl = '',
    this.bio = '',
    this.status = 'none',
    this.incoming = false,
  });
  final String userId, name, jobTitle, company, photoUrl, coverUrl, bio, status;
  final bool incoming;
  factory MemberFriend.fromJson(Map<String, dynamic> row) => MemberFriend(
    userId: row['user_id'] as String,
    name: row['name'] as String? ?? 'Pact member',
    jobTitle: row['job_title'] as String? ?? '',
    company: row['company_name'] as String? ?? '',
    photoUrl: row['photo_url'] as String? ?? '',
    coverUrl: row['cover_url'] as String? ?? '',
    bio: row['bio'] as String? ?? '',
    status: row['status'] as String? ?? 'none',
    incoming: row['incoming'] == true,
  );
}

class MemberFriendsPageData {
  const MemberFriendsPageData(this.people, this.total);
  final List<MemberFriend> people;
  final int total;
}

class MemberFriendsService {
  Future<bool> available() async =>
      await WorkspaceRoleService().load() == WorkspaceRole.member;
  Future<MemberFriendsPageData> people({
    String scope = 'friends',
    String query = '',
    String? target,
    int offset = 0,
  }) async {
    final data = Map<String, dynamic>.from(
      await Supabase.instance.client.rpc(
            'pact_friend_people',
            params: {
              'p_scope': scope,
              'p_query': query,
              'p_target': target,
              'p_offset': offset,
            },
          )
          as Map,
    );
    return MemberFriendsPageData(
      (data['people'] as List)
          .map(
            (r) => MemberFriend.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
      (data['total'] as num).toInt(),
    );
  }

  Future<MemberFriend?> forProvider(String providerId) async {
    final row = await Supabase.instance.client.rpc(
      'pact_friend_provider',
      params: {'p_provider': providerId},
    );
    return row == null
        ? null
        : MemberFriend.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> act(MemberFriend friend, String action) async {
    await Supabase.instance.client.rpc(
      'pact_friend_action',
      params: {'p_target': friend.userId, 'p_action': action},
    );
  }
}
