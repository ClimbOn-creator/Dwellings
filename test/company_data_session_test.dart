import 'package:dwelling_iq/services/app_tunnel.dart';
import 'dart:convert';
import 'package:dwelling_iq/screens/company_data_page.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/usage_analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var owner = true;
  final recorded = <Map<String, dynamic>>[];
  final mock = MockClient((request) async {
    final path = request.url.path;
    Object? result;
    if (path.endsWith('/token')) {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'sub': '00000000-0000-0000-0000-000000000001',
                'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
              }),
            ),
          )
          .replaceAll('=', '');
      result = {
        'access_token': 'e30.$payload.signature',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': '00000000-0000-0000-0000-000000000001',
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'owner@example.com',
          'created_at': '2026-10-01T00:00:00Z',
          'app_metadata': {},
          'user_metadata': {},
        },
      };
    } else if (path.endsWith('/is_affinity_data_owner')) {
      result = owner;
    } else if (path.endsWith('/load_affinity_data_explorer')) {
      result = {
        'totals': {'Registered accounts': 13},
        'inventory': [],
      };
    } else if (path.endsWith('/record_affinity_feature_visit')) {
      recorded.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
    } else if (path.endsWith('/logout')) {
      result = {};
    } else {
      return http.Response('{"message":"Unexpected request"}', 404);
    }
    return http.Response(
      jsonEncode(result),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  });
  Future<void> signIn() => Supabase.instance.client.auth.signInWithPassword(
    email: 'owner@example.com',
    password: 'fixture',
  );
  setUpAll(() async {
    if (!BackendService.configured) return;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: BackendService.supabaseUrl,
      publishableKey: 'test-public-key',
      httpClient: mock,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  testWidgets('owner report is removed on sign-out', (tester) async {
    owner = true;
    await tester.runAsync(signIn);
    expect(BackendService.user, isNotNull);
    await tester.pumpWidget(const MaterialApp(home: CompanyDataPage()));
    await tester.pumpAndSettle();
    expect(find.text('Data monitor'), findsOneWidget);
    await tester.runAsync(() => Supabase.instance.client.auth.signOut());
    await tester.pumpAndSettle();
    expect(find.byType(CompanyDataReportView), findsNothing);
    expect(find.text('Private owner access'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: !BackendService.configured);
  test(
    'usage is opt-in, stops after opt-out/sign-out and excludes owners',
    () async {
      owner = false;
      await signIn();
      await UsageAnalyticsService.initialize();
      await UsageAnalyticsService.visit('buyer');
      expect(recorded, isEmpty);
      await UsageAnalyticsService.choose(false);
      await UsageAnalyticsService.visit('seller');
      expect(recorded, isEmpty);
      await UsageAnalyticsService.choose(true);
      await UsageAnalyticsService.visit('learning');
      expect(recorded, isNotEmpty);
      for (final row in recorded) {
        expect(row.keys, ['feature_name']);
        expect({
          'landing',
          'buyer',
          'seller',
          'member',
          'learning',
          'consulting',
        }, contains(row['feature_name']));
      }
      final beforePreview = recorded.length;
      AppTunnelController.select(AppTunnel.member);
      UsageNavigationObserver().didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/nova-training-preview'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );
      await Future<void>.delayed(Duration.zero);
      expect(recorded.length, beforePreview);
      await UsageAnalyticsService.choose(false);
      final before = recorded.length;
      await UsageAnalyticsService.visit('consulting');
      expect(recorded.length, before);
      await Supabase.instance.client.auth.signOut();
      await UsageAnalyticsService.visit('member');
      expect(recorded.length, before);
      owner = true;
      await signIn();
      await UsageAnalyticsService.initialize();
      await UsageAnalyticsService.choose(true);
      await UsageAnalyticsService.visit('buyer');
      expect(recorded.length, before);
      await Supabase.instance.client.auth.signOut();
    },
    skip: !BackendService.configured,
  );
}
