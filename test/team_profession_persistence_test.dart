import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/account_service.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/services/discover_activity.dart';
import 'package:dwelling_iq/widgets/learning_discover_pinboard.dart';
import 'package:dwelling_iq/widgets/learning_discover_team_board.dart';
import 'package:dwelling_iq/widgets/profile_photo.dart';
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
            expect(
              request.url.queryParameters['user_id'],
              'eq.${user()['id']}',
            );
            body = team;
          } else {
            final row = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            final id = row['provider_id'];
            team.add({
              ...row,
              'provider_profiles': {
                'id': id,
                'provider_type': id == 'accountant'
                    ? 'accountant'
                    : id == 'first'
                    ? 'ma_lawyer'
                    : 'lawyer',
                'display_name': id,
                if (id == 'accountant') 'photo_index': 3,
              },
            });
            body = [];
          }
        } else if (request.url.path.endsWith('/provider_profiles')) {
          body = [
            {
              'id': 'accountant',
              'provider_type': 'accountant',
              'display_name': 'accountant',
              'photo_index': 3,
            },
          ];
        } else if (request.url.path.endsWith('/learning_progress')) {
          expect(request.url.queryParameters['user_id'], 'eq.${user()['id']}');
          body = [
            {'concept_id': 'search'},
          ];
        } else if (request.url.path.contains('/rest/v1/')) {
          body = [];
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
      final savedTeam = await AccountService.loadTeam();
      expect(savedTeam.map((member) => member.name), ['first', 'accountant']);
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

  testWidgets('Pinboard shows account data and updates activity in place', (
    tester,
  ) async {
    if (!BackendService.configured) return;
    team.clear();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Scaffold()),
    );
    unawaited(
      navigator.currentState!.push(
        DiscoverPinboardRoute(const Rect.fromLTWH(200, 60, 160, 100)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final account = BackendService.user!.id;
      await DiscoverActivity.recordForAccount(
        account,
        DiscoverActivityKind.files,
        'a',
      );
      await DiscoverActivity.recordForAccount(
        account,
        DiscoverActivityKind.files,
        'b',
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.text('Concepts completed'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.runAsync(() async {
      await DiscoverActivity.recordForAccount(
        BackendService.user!.id,
        DiscoverActivityKind.files,
        'c',
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Discover team board saves a professional and shows their portrait',
    (tester) async {
      if (!BackendService.configured) return;
      team.clear();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: DiscoverTeamBoard(interactive: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('?'), findsNWidgets(4));
      await tester.tap(find.text('Add professional').first);
      await tester.pumpAndSettle();
      final add = find.byTooltip('Add accountant to My Team');
      await tester.ensureVisible(add);
      await tester.runAsync(() async {
        await tester.tap(add);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(team.single['provider_id'], 'accountant');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('?'), findsNWidgets(3));
      final portrait = tester.widget<ProfilePhoto>(
        find.byKey(const ValueKey('team-photo-accountant')),
      );
      expect(portrait.exampleIndex, 3);
    },
  );
}
