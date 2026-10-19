import 'dart:convert';
import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/screens/member_deal_marketplace_page.dart';
import 'package:dwelling_iq/screens/tunnel_pages.dart';
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
        if (path.endsWith('/token')) {
          const id = '00000000-0000-0000-0000-000000000002';
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
              'email': 'member@example.test',
              'created_at': '2026-10-18T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (path.contains('/is_affinity_')) {
          result = false;
        } else if (request.headers['accept']?.contains('vnd.pgrst.object') ==
            true) {
          return http.Response(
            jsonEncode({
              'code': 'PGRST116',
              'details': '0 rows',
              'message': 'no profile',
            }),
            406,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(result),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'member signs in without a paid plan and sign-out removes workspace at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        requests.clear();
        await tester.pumpWidget(const MaterialApp(home: MemberDashboardPage()));
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        expect(find.byType(MemberPricingPage), findsNothing);
        expect(find.byType(MemberDealMarketplacePage), findsNothing);
        final email = find.ancestor(
          of: find.text('Email address'),
          matching: find.byType(TextFormField),
        );
        final password = find.ancestor(
          of: find.text('Password'),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(email, 'member@example.test');
        await tester.enterText(password, 'fixture-password');
        final submit = find.widgetWithText(FilledButton, 'Sign in');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
        expect(find.byType(MemberDealMarketplacePage), findsOneWidget);
        expect(find.byType(AuthPage), findsNothing);
        expect(find.byType(MemberPricingPage), findsNothing);
        expect(
          requests.any((path) => path.contains('membership_applications')),
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => BackendService.signOut());
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        expect(find.byType(MemberDealMarketplacePage), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      skip: !BackendService.configured,
    );
  }
}
