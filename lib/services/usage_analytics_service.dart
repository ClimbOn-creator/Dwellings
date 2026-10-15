import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_tunnel.dart';
import 'backend_service.dart';

/// Only coarse, anonymous daily navigation counters leave the browser.
/// No tracking is attempted until this account opts in on this browser.
class UsageAnalyticsService {
  static final consent = ValueNotifier<bool?>(null);
  static String? _user;
  static bool _owner = true; // Fail closed until the owner check finishes.
  static int _generation = 0;
  static StreamSubscription<dynamic>? _auth;
  static final _last = <String, DateTime>{};
  static String _feature = 'landing';
  static String get _key =>
      'affinity.usage-consent.v1.${_user ?? 'signed-out'}';
  static Future<void> initialize() async {
    _auth ??= BackendService.authChanges?.listen((_) => _load());
    await _load();
  }

  static Future<void> _load() async {
    final generation = ++_generation;
    final user = BackendService.user?.id;
    _user = user;
    _owner = true;
    consent.value = null;
    _last.clear();
    if (user == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final owner = await Supabase.instance.client.rpc(
        'is_affinity_data_owner',
      );
      if (generation != _generation || user != BackendService.user?.id) return;
      _owner = owner == true;
      consent.value = preferences.getBool(_key);
      if (_owner) consent.value = false;
      unawaited(visit(_feature));
    } catch (_) {
      /* No telemetry if auth, preferences or authorization is unavailable. */
    }
  }

  static Future<void> choose(bool enabled) async {
    final generation = _generation;
    final key = _key;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, enabled);
    if (generation != _generation) return;
    consent.value = enabled;
    if (enabled) unawaited(visit(_feature));
  }

  static String featureFor(String? name) {
    final value = (name ?? '').toLowerCase();
    if (value.contains('consulting')) return 'consulting';
    if (value.contains('learning')) return 'learning';
    if (value.contains('member') || value.contains('professional')) {
      return 'member';
    }
    if (value.contains('seller')) return 'seller';
    if (value.contains('buyer') ||
        value.contains('deal') ||
        value.contains('resources') ||
        value.contains('transaction') ||
        value.contains('business-calculator')) {
      return 'buyer';
    }
    if (value == 'business' || value == 'landing') return 'landing';
    return AppTunnelController.current.value.name;
  }

  static Future<void> visit(String feature) async {
    _feature = feature;
    if (!{
      'landing',
      'buyer',
      'seller',
      'member',
      'learning',
      'consulting',
    }.contains(feature)) {
      return;
    }
    if (consent.value != true ||
        _owner ||
        _user == null ||
        _user != BackendService.user?.id) {
      return;
    }
    final now = DateTime.now();
    if (_last[feature] != null &&
        now.difference(_last[feature]!) < const Duration(seconds: 30)) {
      return;
    }
    _last[feature] = now;
    try {
      await Supabase.instance.client.rpc(
        'record_affinity_feature_visit',
        params: {'feature_name': feature},
      );
    } catch (_) {
      /* Analytics must never block app use. No offline personal event queue. */
    }
  }
}

class UsageNavigationObserver extends NavigatorObserver {
  void _visit(Route<dynamic>? route) {
    if (route is! PageRoute || route.settings.name == 'owner-data') return;
    scheduleMicrotask(
      () => UsageAnalyticsService.visit(
        UsageAnalyticsService.featureFor(
          route.settings.name == '/'
              ? Uri.base.queryParameters['module']
              : route.settings.name,
        ),
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _visit(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _visit(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _visit(newRoute);
}
