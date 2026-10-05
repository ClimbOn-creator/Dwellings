import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_service.dart';

class NovaTrainingProgress {
  const NovaTrainingProgress({
    this.role = 'buyer',
    this.step = 0,
    this.completedAt,
    this.pendingSync = false,
  });
  final String role;
  final int step;
  final String? completedAt;
  final bool pendingSync;
  bool get completed => completedAt != null;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'role': role,
    'step': step,
    'completed_at': completedAt,
    'pending_sync': pendingSync,
  };
  factory NovaTrainingProgress.fromJson(Map<String, dynamic> row) =>
      NovaTrainingProgress(
        role: {'buyer', 'seller', 'member'}.contains(row['role'])
            ? row['role'] as String
            : 'buyer',
        step: row['step'] is num
            ? (row['step'] as num).toInt().clamp(0, 99)
            : 0,
        completedAt:
            row['completed_at'] is String &&
                DateTime.tryParse(row['completed_at']) != null
            ? row['completed_at'] as String
            : null,
        pendingSync: row['pending_sync'] == true,
      );
}

/// The only cloud payload is training progress, saved to the user's own private
/// account profile metadata. No deal records, notes, answers or financials are sent.
class NovaTrainingService extends ChangeNotifier {
  NovaTrainingService({
    String? Function()? accountId,
    Future<Map<String, dynamic>?> Function(String)? readProfile,
    Future<void> Function(String, Map<String, dynamic>)? writeProfile,
  }) : _accountId = accountId ?? (() => BackendService.user?.id),
       _readProfile = readProfile ?? _readAccount,
       _writeProfile = writeProfile ?? _writeAccount;
  final String? Function() _accountId;
  final Future<Map<String, dynamic>?> Function(String) _readProfile;
  final Future<void> Function(String, Map<String, dynamic>) _writeProfile;
  NovaTrainingProgress progress = const NovaTrainingProgress();
  bool loaded = false, profileSaved = false;
  String? scope;
  int _generation = 0;
  Future<void> _writes = Future.value();
  String get _key => 'nova.training.v1.${scope ?? "guest"}';
  bool get signedIn => scope != null;

  Future<void> load() async {
    final generation = ++_generation;
    final account = _accountId();
    scope = account;
    loaded = false;
    profileSaved = false;
    progress = const NovaTrainingProgress();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = 'nova.training.v1.${account ?? "guest"}';
    NovaTrainingProgress local = const NovaTrainingProgress();
    try {
      final raw = prefs.getString(key);
      if (raw != null) local = NovaTrainingProgress.fromJson(jsonDecode(raw));
    } catch (_) {}
    if (generation != _generation || account != _accountId()) return;
    progress = local;
    loaded = true;
    notifyListeners();
    if (account == null) return;
    try {
      final remote = await _readProfile(account);
      if (generation != _generation || account != _accountId()) return;
      final cloud = remote == null
          ? null
          : NovaTrainingProgress.fromJson(remote);
      if (cloud?.completed == true ||
          (!local.pendingSync && cloud != null && !local.completed)) {
        progress = cloud!;
        profileSaved = true;
        await prefs.setString(key, jsonEncode(progress.toJson()));
        notifyListeners();
      } else if (local.pendingSync ||
          (local.completed && cloud?.completed != true)) {
        await save(role: local.role, step: local.step, finish: local.completed);
      } else {
        profileSaved = cloud != null;
      }
    } catch (_) {
      /* Local progress is retained for the next sync attempt. */
    }
  }

  Future<bool> save({
    required String role,
    required int step,
    bool finish = false,
  }) async {
    final account = scope, generation = _generation, key = _key;
    if (account != _accountId()) return false;
    final next = NovaTrainingProgress(
      role: role,
      step: step,
      completedAt: finish
          ? progress.completedAt ?? DateTime.now().toUtc().toIso8601String()
          : progress.completedAt,
      pendingSync: account != null,
    );
    progress = next;
    profileSaved = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(next.toJson()));
    if (account == null) return false;
    bool saved = false;
    final write = _writes.catchError((_) {}).then((_) async {
      if (account != _accountId() ||
          generation != _generation ||
          !identical(progress, next))
        return;
      // Skip superseded queued steps. Finishing an offline tour must not wait
      // for a separate network timeout for every screen visited.
      try {
        await _writeProfile(
          account,
          {...next.toJson()}..remove('pending_sync'),
        );
        saved = true;
        // Do not overwrite a newer step or another account's state after an await.
        if (generation != _generation ||
            account != _accountId() ||
            !identical(progress, next))
          return;
        progress = NovaTrainingProgress(
          role: next.role,
          step: next.step,
          completedAt: next.completedAt,
        );
        profileSaved = true;
        await prefs.setString(key, jsonEncode(progress.toJson()));
        notifyListeners();
      } catch (_) {
        /* pending_sync stays in the account's local record */
      }
    });
    _writes = write;
    await write;
    return saved;
  }

  static String _token(String id) {
    final session = BackendService.configured
        ? Supabase.instance.client.auth.currentSession
        : null;
    if (session == null || session.user.id != id)
      throw StateError('Account changed.');
    return session.accessToken;
  }

  static Future<Map<String, dynamic>?> _readAccount(String id) async {
    final response = await http
        .get(
          Uri.parse('${BackendService.supabaseUrl}/auth/v1/user'),
          headers: {
            'authorization': 'Bearer ${_token(id)}',
            'apikey': BackendService.supabaseKey,
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw StateError('Profile unavailable.');
    final row = jsonDecode(response.body) as Map;
    if (row['id'] != id) throw StateError('Account changed.');
    final value = (row['user_metadata'] as Map?)?['nova_training'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<void> _writeAccount(
    String id,
    Map<String, dynamic> progress,
  ) async {
    final token = _token(
      id,
    ); // Capture this account's token before asynchronous work.
    final response = await http
        .put(
          Uri.parse('${BackendService.supabaseUrl}/auth/v1/user'),
          headers: {
            'authorization': 'Bearer $token',
            'apikey': BackendService.supabaseKey,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'data': {'nova_training': progress},
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 ||
        (jsonDecode(response.body) as Map)['id'] != id)
      throw StateError('Training could not sync.');
  }
}
