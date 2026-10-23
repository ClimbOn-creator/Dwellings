import 'dart:convert';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:flutter/material.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
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
        targetCloseDate: DateTime(2030, 6, 15),
        profileSnapshot: {
          'source_url': 'https://example.com/business/123',
          'deal_details': 'Seller-provided listing details',
          'currency': 'CAD',
        },
        privateOnly: true,
      );
      expect(room.userId, id);
      expect(inserted!['target_close_date'], '2030-06-15');
      expect(room.targetCloseDate, DateTime(2030, 6, 15));
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
  test('closing date can be omitted without inventing a deadline', () async {
    if (!BackendService.configured) return;
    final room = await DealRoomService.createManualRoom(
      title: 'No date fixture',
      dealKind: 'business',
      location: '',
      purchasePrice: 0,
      goals: '',
      privateOnly: true,
    );
    expect(inserted!['target_close_date'], isNull);
    expect(room.targetCloseDate, isNull);
  });
  testWidgets(
    'online deal save returns to the current dashboard and opens its planner',
    (tester) async {
      if (!BackendService.configured) return;
      inserted = null;
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<List<DealRoomBundle>> bundles() async => inserted == null
          ? []
          : [
              DealRoomBundle(
                room: DealRoom.fromJson({
                  ...inserted!,
                  'id': 'private-room',
                  'updated_at': '2026-10-22T00:00:00Z',
                }),
                tasks: [],
                notes: [],
                members: [],
                documents: [],
                documentEvents: [],
              ),
            ];
      await tester.pumpWidget(
        MaterialApp(
          home: DealRoomsPage(
            initialView: BuyerDashboardView.pipeline,
            loadTransactionBundles: bundles,
            loadTeamProviders: () async =>
                (<MarketplaceProvider>[], <String>{}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('private-deal-title')),
        'Online fixture deal',
      );
      final close = find.byKey(
        const ValueKey('private-deal-target_close_date'),
      );
      await tester.ensureVisible(close);
      await tester.enterText(close, '2030-06-15');
      final save = find.text('Save private deal');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(inserted!['target_close_date'], '2030-06-15');
      expect(find.text('Buyer dash'), findsOneWidget);
      expect(find.text('Your pipeline'), findsOneWidget);
      expect(find.text('Online fixture deal'), findsWidgets);
      expect(find.byType(DealRoomPage), findsNothing);
      await tester.tap(find.text('Online fixture deal').first);
      await tester.pumpAndSettle();
      expect(find.text('Transaction plan 📅'), findsOneWidget);
      expect(find.text('Buyer dash'), findsOneWidget);
      expect(find.byType(DealRoomPage), findsNothing);
      final savedBundle = (await bundles()).single;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: DealRoomPage(
            room: savedBundle.room,
            loadBundle: () async => savedBundle,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buyer dash'), findsOneWidget);
      expect(find.text('Transaction plan 📅'), findsOneWidget);
      expect(find.text('DEAL COMMAND CENTRE'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
