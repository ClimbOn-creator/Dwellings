import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_service.dart';

enum DiscoverActivityKind { files, deals }

class DiscoverActivity {
  static final _revision = ValueNotifier<int>(0);
  static ValueListenable<int> get changes => _revision;

  static Future<void> _pending = Future.value();

  static String _key(String userId, DiscoverActivityKind kind) =>
      'pact.discover.${kind.name}.$userId';

  static Future<void> record(DiscoverActivityKind kind, String id) {
    final userId = BackendService.user?.id;
    if (userId == null) return Future.value();
    return recordForAccount(userId, kind, id);
  }

  static Future<void> recordForAccount(
    String userId,
    DiscoverActivityKind kind,
    String id,
  ) {
    _pending = _pending
        .then((_) async {
          final preferences = await SharedPreferences.getInstance();
          final key = _key(userId, kind);
          final ids = (preferences.getStringList(key) ?? []).toSet();
          if (ids.add(id) &&
              await preferences.setStringList(key, ids.toList())) {
            _revision.value++;
          }
        })
        .catchError((Object _) {
          // Local activity tracking is best-effort so opening an item still works.
        });
    return _pending;
  }

  static Future<int> count(String userId, DiscoverActivityKind kind) async {
    await _pending;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key(userId, kind))?.length ?? 0;
  }
}
