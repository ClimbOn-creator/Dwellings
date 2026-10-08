import 'package:dwelling_iq/screens/deal_comparison_page.dart';
import 'package:dwelling_iq/widgets/nova_training_host.dart';
import 'dart:convert';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final requests = <String>[];
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
        final path = request.url.path;
        requests.add(path);
        Object result = [];
        if (request.headers['accept']?.contains('vnd.pgrst.object') == true) {
          return http.Response(
            jsonEncode({
              'code': 'PGRST116',
              'details': '0 rows',
              'message': 'no profile',
            }),
            406,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/token')) {
          const id = '00000000-0000-0000-0000-000000000001';
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
          result = {
            'access_token': 'e30.$payload.signature',
            'refresh_token': 'fixture',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': id,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'rw0882308@gmail.com',
              'created_at': '2026-09-11T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (path.endsWith('/is_affinity_admin')) {
          result = true;
        } else if (path.endsWith('/is_affinity_content_editor')) {
          result = false;
        } else if (path.endsWith('/profiles') ||
            path.endsWith('/provider_directory')) {
          return http.Response(
            jsonEncode({
              'code': 'PGRST116',
              'details': '0 rows',
              'message': 'no profile',
            }),
            406,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-0/0',
          },
        );
      }),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'rw0882308@gmail.com',
      password: 'fixture',
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'creator sees sample inbox and bubbles without sending or loading live sample threads',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(
            home: MemberDealMarketplacePage(
              initialView: MemberDashboardView.dealResponses,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Amelia Foster · Example'), findsOneWidget);
        expect(find.text('Affinity review desk'), findsNothing);
        await tester.tap(find.text('Amelia Foster · Example'));
        await tester.pumpAndSettle();
        expect(
          find.text('Thanks, Amelia. What should I review first?'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Example conversation · Replies are disabled in this preview.',
          ),
          findsOneWidget,
        );
        expect(
          requests.any(
            (p) =>
                p.endsWith('/send_member_message') ||
                p.endsWith('/load_member_messages') ||
                p.endsWith('/mark_member_conversation_read'),
          ),
          isFalse,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
      skip: !BackendService.configured,
    );
  }
  testWidgets(
    'signed-in comparison uses its own page guide',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: navigator,
            autoStart: false,
            child: child!,
          ),
          home: const DealComparisonPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pebble_page_help')));
      await tester.pumpAndSettle();
      expect(find.text('A comparison round'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Read both businesses'), findsOneWidget);
      expect(find.text('Find relevant support'), findsNothing);
      await tester.tap(find.byKey(const Key('nova_pause')));
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: !BackendService.configured,
  );
}
