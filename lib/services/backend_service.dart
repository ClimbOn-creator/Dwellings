import 'package:flutter/foundation.dart';
import 'pact_session_storage.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/housing_model.dart';

class BackendService {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const googleAuthEnabled = bool.fromEnvironment('GOOGLE_AUTH_ENABLED');
  static bool get configured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!configured) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: kIsWeb
            ? null
            : PactSessionStorage(
                'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token',
              ),
      ),
    );
  }

  static User? get user =>
      configured ? Supabase.instance.client.auth.currentUser : null;

  static Stream<AuthState>? get authChanges =>
      configured ? Supabase.instance.client.auth.onAuthStateChange : null;

  static const mobileAuthRedirect =
      'com.dwellingiq.dwellingiq://login-callback/';

  static String get authRedirect =>
      kIsWeb ? Uri.base.origin : mobileAuthRedirect;

  static Future<void> signInWithGoogle() async {
    if (!configured) throw StateError('Supabase is not configured.');
    final launched = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!launched) throw StateError('Could not open Google sign-in.');
  }

  static Future<void> sendMagicLink(String email) async {
    if (!configured) throw StateError('Supabase is not configured.');
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: authRedirect,
    );
  }

  static Future<void> signOut() async {
    if (configured) await Supabase.instance.client.auth.signOut();
  }

  static Future<bool> saveAnalysis(
    PropertyInputs inputs,
    AnalysisResult result,
    DecisionMode mode,
  ) async {
    if (configured && user != null) {
      await Supabase.instance.client.from('property_analyses').insert({
        'user_id': user!.id,
        'address_label': inputs.address,
        'decision_mode': mode.name,
        'location_profile': inputs.profile.toJson(),
        'property_inputs': inputs.toJson(),
        'model_output': result.toJson(),
        'model_version': 'dwellings-iq-underwriting-0.3',
      });
      return true;
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList('dwellingiq_saved') ?? <String>[];
    saved.insert(
      0,
      jsonEncode({
        'created_at': DateTime.now().toIso8601String(),
        'mode': mode.name,
        'inputs': inputs.toJson(),
        'result': result.toJson(),
      }),
    );
    await preferences.setStringList(
      'dwellingiq_saved',
      saved.take(20).toList(),
    );
    return false;
  }
}
