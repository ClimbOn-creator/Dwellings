import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/deal_room_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  Map<String, dynamic>? inserted;
  const id = '00000000-0000-0000-0000-000000000001';
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
        requests.add(request);
        Object body = [];
        if (request.url.path.endsWith('/token')) {
          final payload = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': id,
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
            'user': {
              'id': id,
              'aud': 'authenticated',
              'email': 'buyer@example.com',
              'created_at': '2026-10-16T00:00:00Z',
              'user_metadata': {},
            },
          };
        } else if (request.url.path.endsWith('/deal_rooms') &&
            request.method == 'POST') {
          inserted = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
          body = {
            ...inserted!,
            'id': 'private-room',
            'updated_at': '2026-10-16T00:00:00Z',
          };
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
    'online entry saves to the signed-in owner without invitations or publication',
    () async {
      final room = await DealRoomService.createManualRoom(
        title: 'Island HVAC',
        dealKind: 'business',
        location: 'Victoria, BC',
        purchasePrice: 800000,
        goals: '',
        profileSnapshot: {
          'source_url': 'https://example.com/business/123',
          'deal_details': 'Seller-provided listing details',
          'currency': 'CAD',
        },
        privateOnly: true,
      );
      expect(room.userId, id);
      expect(
        room.propertySnapshot['source_url'],
        'https://example.com/business/123',
      );
      expect(inserted!['sharing_preferences'], {
        'financials': false,
        'risk': false,
        'documents': false,
      });
      expect(requests.where((r) => r.method == 'POST').map((r) => r.url.path), [
        '/auth/v1/token',
        '/rest/v1/deal_rooms',
        '/rest/v1/deal_room_tasks',
      ]);
      expect(
        requests.any(
          (r) =>
              r.url.path.contains('team_members') ||
              r.url.path.contains('deal_room_members') ||
              r.url.path.contains('opportunit') ||
              r.url.path.contains('publish'),
        ),
        isFalse,
      );
      final tasks = jsonDecode(requests.last.body) as List;
      expect(tasks, isNotEmpty);
      expect(tasks.every((t) => t['deal_room_id'] == room.id), isTrue);
    },
    skip: !BackendService.configured,
  );
}
