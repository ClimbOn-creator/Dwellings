import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'team_professions_test.dart' show member;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final metadata = <String, dynamic>{'full_name': 'Existing buyer'};
  final team = <Map<String, dynamic>>[];
  Map<String, dynamic> user() => {
    'id': '00000000-0000-0000-0000-000000000001',
    'aud': 'authenticated',
    'email': 'buyer@example.com',
    'created_at': '2026-09-20T00:00:00Z',
    'user_metadata': metadata,
  };
  setUpAll(() async {
    if (!BackendService.configured) return;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: BackendService.supabaseUrl,
      publishableKey: 'test-public-key',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        Object body = {};
        if (request.url.path.endsWith('/token')) {
          final payload = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': user()['id'],
                    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                  }),
                ),
              )
              .replaceAll('=', '');
          body = {
            'access_token': 'e30.$payload.signature',
            'refresh_token': 'fixture',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': user(),
          };
        } else if (request.url.path.endsWith('/user_team_members')) {
          if (request.method == 'GET') {
            body = team;
          } else {
            final row = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            final id = row['provider_id'];
            team.add({
              ...row,
              'provider_profiles': {
                'provider_type': id == 'accountant'
                    ? 'accountant'
                    : id == 'first'
                    ? 'ma_lawyer'
                    : 'lawyer',
                'display_name': id,
              },
            });
            body = [];
          }
        } else if (request.url.path.endsWith('/user')) {
          if (request.method == 'PUT') {
            metadata.addAll(
              Map<String, dynamic>.from(
                jsonDecode(request.body)['data'] as Map,
              ),
            );
          }
          body = user();
        }
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'buyer@example.com',
      password: 'fixture',
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  test(
    'shared save guard blocks a second profession and serializes competing adds',
    () async {
      if (!BackendService.configured) return;
      final first = member('first', 'First lawyer', ProviderCategory.maLawyer);
      final second = member('second', 'Second lawyer', ProviderCategory.lawyer);
      await MarketplaceService.addToTeam(first);
      await MarketplaceService.addToTeam(first);
      expect(team.length, 1);
      await expectLater(MarketplaceService.addToTeam(second), throwsStateError);
      expect(team.length, 1);
      await MarketplaceService.addToTeam(
        member('accountant', 'Accountant', ProviderCategory.accountant),
      );
      expect(team.length, 2);
      team.clear();
      final outcomes = await Future.wait([
        MarketplaceService.addToTeam(
          first,
        ).then((_) => true, onError: (_) => false),
        MarketplaceService.addToTeam(
          second,
        ).then((_) => true, onError: (_) => false),
      ]);
      expect(outcomes, [true, false]);
      expect(team.length, 1);
    },
  );
}
