import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PactSessionStorage extends LocalStorage {
  PactSessionStorage(this.key);
  final String key;
  static const _storage = FlutterSecureStorage();
  @override
  Future<void> initialize() async {
    // Preserve existing native sessions, then remove their plaintext copy.
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getString(key);
    if (previous != null) {
      if (await _storage.read(key: key) == null) {
        await _storage.write(key: key, value: previous);
      }
      await preferences.remove(key);
    }
  }

  @override
  Future<String?> accessToken() => _storage.read(key: key);
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: key);
}
