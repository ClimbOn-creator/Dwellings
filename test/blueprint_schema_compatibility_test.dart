import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/account_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const uid = '00000000-0000-0000-0000-000000000001';
  final metadata = <String, dynamic>{
    'full_name': 'Existing owner',
    'saved_resource_ids': ['preserve-me'],
  };
  http.Request? currentRequest;
  var mode = 'progress';
  var writes = <Map<String, dynamic>>[];
  Map<String, dynamic> stored = {};
  Map<String, dynamic> user() => {
    'id': uid,
    'aud': 'authenticated',
    'email': 'owner@example.com',
    'created_at': '2026-09-20T00:00:00Z',
    'user_metadata': metadata,
  };
  http.Response response(Object value, [int status = 200]) => http.Response(
    jsonEncode(value),
    status,
    headers: {'content-type': 'application/json'},
    request: currentRequest,
  );
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
        currentRequest = request;
        if (request.url.path.endsWith('/token')) {
          final token = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': uid,
                    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                  }),
                ),
              )
              .replaceAll('=', '');
          return response({
            'access_token': 'e30.$token.signature',
            'refresh_token': 'fixture',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': user(),
          });
        }
        if (request.url.path.endsWith('/user')) {
          if (request.method == 'PUT')
            metadata.addAll(
              Map<String, dynamic>.from(
                jsonDecode(request.body)['data'] as Map,
              ),
            );
          return response(user());
        }
        if (request.url.path.endsWith('/profiles')) {
          if (request.method == 'PATCH') {
            final body = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            writes.add(body);
            if (mode == 'rejected')
              return response({
                'code': '42501',
                'message': 'Permission denied',
              }, 403);
            if (body.containsKey('acquisition_completed_modules'))
              return response({
                'code': 'PGRST204',
                'message':
                    "Could not find the 'acquisition_completed_modules' column of 'profiles' in the schema cache",
              }, 400);
            if (mode == 'foundation')
              return response({
                'code': 'PGRST204',
                'message':
                    "Could not find the 'acquisition_foundation' column of 'profiles' in the schema cache",
              }, 400);
            stored = Map<String, dynamic>.from(
              body['acquisition_foundation'] as Map,
            );
            return http.Response('', 204, request: request);
          }
          if (mode == 'foundation')
            return response({
              'code': '42703',
              'message':
                  'column profiles.acquisition_foundation does not exist',
            }, 400);
          return response([
            {'acquisition_foundation': stored},
          ]);
        }
        return response({});
      }),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'owner@example.com',
      password: 'fixture',
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  test(
    'missing progress column retries with questionnaire and module progress in existing JSON',
    () async {
      mode = 'progress';
      writes = [];
      await AccountService.saveAcquisitionFoundation(
        {
          'blueprint': {'industry': 'Services'},
        },
        completedModules: ['blueprint'],
      );
      expect(writes.length, 2);
      expect(writes.last.containsKey('acquisition_completed_modules'), isFalse);
      expect(stored['completedModules'], ['blueprint']);
      expect((await AccountService.loadAcquisitionFoundation())!['blueprint'], {
        'industry': 'Services',
      });
    },
    skip: !BackendService.configured,
  );
  test(
    'older profile schema saves to the same private account without losing existing metadata',
    () async {
      mode = 'foundation';
      writes = [];
      await AccountService.saveAcquisitionFoundation(
        {
          'blueprint': {'industry': 'Manufacturing'},
        },
        completedModules: ['blueprint'],
      );
      expect(metadata['saved_resource_ids'], ['preserve-me']);
      expect((await AccountService.loadAcquisitionFoundation())!['blueprint'], {
        'industry': 'Manufacturing',
      });
    },
    skip: !BackendService.configured,
  );
  test(
    'permission failures propagate and do not get treated as missing columns',
    () async {
      mode = 'rejected';
      writes = [];
      await expectLater(
        AccountService.saveAcquisitionFoundation({
          'blueprint': {},
        }, completedModules: []),
        throwsA(isA<PostgrestException>()),
      );
      expect(writes.length, 1);
    },
    skip: !BackendService.configured,
  );
}
