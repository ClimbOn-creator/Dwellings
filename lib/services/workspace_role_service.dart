import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

enum WorkspaceRole { buyer, seller, member }

extension WorkspaceRoleLabel on WorkspaceRole {
  String get label => switch (this) {
    WorkspaceRole.buyer => 'Buyer',
    WorkspaceRole.seller => 'Seller',
    WorkspaceRole.member => 'Member',
  };
}

/// Shared, insert-only account identity; never inferred from device preferences
/// or editable auth metadata. Member capabilities remain separately authorized.
class WorkspaceRoleService {
  /// Existing server-owned creator permission; never trust editable profile data.
  Future<bool> isCreator() async {
    final userId = BackendService.user?.id;
    if (!BackendService.configured || userId == null) return false;
    try {
      final permissions = await Supabase.instance.client
          .rpc('learning_permissions')
          .timeout(const Duration(seconds: 12));
      return BackendService.user?.id == userId &&
          permissions is Map &&
          permissions['is_owner'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<WorkspaceRole?> load() async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in required.');
    final row = await Supabase.instance.client
        .from('account_workspaces')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    return row == null
        ? null
        : WorkspaceRole.values.byName(row['role'] as String);
  }

  Future<WorkspaceRole> choose(WorkspaceRole role) async {
    final user = BackendService.user;
    if (user == null) throw StateError('Sign in required.');
    // A unique user_id plus no update/delete privileges makes the first choice
    // win, including simultaneous choices from two devices.
    try {
      await Supabase.instance.client.from('account_workspaces').insert({
        'user_id': user.id,
        'role': role.name,
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }
    if (BackendService.user?.id != user.id) {
      throw StateError('Account changed.');
    }
    final saved = await load();
    if (saved == null) throw StateError('Workspace could not be saved.');
    return saved;
  }
}
