import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/buyer_resources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final metadata = <String, dynamic>{'full_name': 'Existing buyer'};
  var reject = false;
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
        } else if (request.url.path.endsWith('/user')) {
          if (request.method == 'PUT') {
            if (reject) {
              return http.Response(
                jsonEncode({'msg': 'Save rejected'}),
                500,
                headers: {'content-type': 'application/json'},
              );
            }
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
    'resource add/remove preserves other selections and account data; failures do not save',
    () async {
      if (!BackendService.configured) return;
      await BuyerResourceTeam.setSaved('community-futures', true);
      await BuyerResourceTeam.setSaved('bc-training', true);
      expect(await BuyerResourceTeam.load(), {
        'community-futures',
        'bc-training',
      });
      await BuyerResourceTeam.setSaved('community-futures', false);
      expect(await BuyerResourceTeam.load(), {'bc-training'});
      expect(metadata['full_name'], 'Existing buyer');
      reject = true;
      await expectLater(
        BuyerResourceTeam.setSaved('bdc-acquisition', true),
        throwsA(isA<AuthException>()),
      );
      expect(await BuyerResourceTeam.load(), {'bc-training'});
      await Supabase.instance.client.auth.signOut();
      expect(await BuyerResourceTeam.load(), isEmpty);
      await expectLater(
        BuyerResourceTeam.setSaved('bc-training', true),
        throwsStateError,
      );
    },
  );
}
