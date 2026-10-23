import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_service.dart';
import 'pact_messaging_service.dart';

class PactPushService {
  static final openThread = StreamController<String>.broadcast();
  static StreamSubscription<String>? _registered;
  static StreamSubscription<RemoteMessage>? _opened;
  static String? _token;
  static void _open(RemoteMessage message) {
    final id = message.data['thread_id'];
    if (id != null && RegExp(r'^[0-9a-f-]{36}$').hasMatch(id)) {
      openThread.add(id);
    }
  }

  static Future<void> restore(PactMessagingService service) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('pact.push.enabled') == true) {
      try {
        await enable(service, requestPermission: false);
      } catch (_) {
        /* no config or offline: inbox still works */
      }
    }
  }

  static Future<void> enable(
    PactMessagingService service, {
    bool requestPermission = true,
  }) async {
    if (kIsWeb) throw StateError('Enable notifications in the mobile app.');
    final userId = BackendService.user?.id;
    if (userId == null) throw StateError('Sign in first.');
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    final permission = requestPermission
        ? await FirebaseMessaging.instance.requestPermission()
        : await FirebaseMessaging.instance.getNotificationSettings();
    if (permission.authorizationStatus == AuthorizationStatus.denied ||
        permission.authorizationStatus == AuthorizationStatus.notDetermined) {
      throw StateError('Notification permission unavailable.');
    }
    await _registered?.cancel();
    final ready = Completer<void>();
    _registered = FirebaseMessaging.instance.onRegistered.listen((token) async {
      if (BackendService.user?.id != userId) return;
      try {
        await service.call('register_device', {
          'token': token,
          'expected_user_id': userId,
        });
        _token = token;
        if (!ready.isCompleted) ready.complete();
      } catch (e) {
        if (!ready.isCompleted) ready.completeError(e);
      }
    });
    _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(_open);
    // Start listening before registration so fast callbacks cannot be missed.
    await Future.wait<void>([
      ready.future.timeout(const Duration(seconds: 20)),
      FirebaseMessaging.instance.register(),
    ]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pact.push.enabled', true);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _open(initial);
  }

  static Future<void> unregister(PactMessagingService service) async {
    await _registered?.cancel();
    _registered = null;
    if (_token != null) {
      await service.call('unregister_device', {'token': _token});
      _token = null;
    }
  }
}
