import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/housing_model.dart';

class BackendService {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get configured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!configured) return;
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }

  static User? get user =>
      configured ? Supabase.instance.client.auth.currentUser : null;

  static Future<void> sendMagicLink(String email) async {
    if (!configured) throw StateError('Supabase is not configured.');
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: Uri.base.origin,
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
        'model_version': 'housing-moneyball-0.2-flutter',
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
