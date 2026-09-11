import 'package:dwelling_iq/widgets/site_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/site_content_service.dart';
import 'package:dwelling_iq/widgets/site_inline_editor.dart';
import 'package:dwelling_iq/widgets/site_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final published = <String, String>{};
  var rejectWrites = false;
  var uploads = 0;
  const userId = '00000000-0000-0000-0000-000000000001';
  final mock = MockClient((request) async {
    final path = request.url.path;
    Object? result;
    var status = 200;
    if (path.endsWith('/token')) {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'sub': userId,
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
          'id': userId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'rw0882308@gmail.com',
          'created_at': '2026-09-11T00:00:00Z',
          'app_metadata': {'provider': 'google'},
          'user_metadata': {},
        },
      };
    } else if (path.endsWith('/is_affinity_content_editor')) {
      result = true;
    } else if (path.endsWith('/save_site_content_v2')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final key = body['target_key'] as String;
      if (rejectWrites || body['expected_value'] != published[key]) {
        status = 409;
        result = {
          'code': 'P0001',
          'message': 'This content changed since you opened it',
        };
      } else if (body['target_value'] == null) {
        published.remove(key);
      } else {
        published[key] = body['target_value'] as String;
      }
    } else if (path.endsWith('/site_content')) {
      result = published.entries
          .map((e) => {'content_key': e.key, 'content_value': e.value})
          .toList();
    } else if (path.contains('/storage/v1/object/site-media/')) {
      uploads++;
      result = {'Key': path.split('/object/').last};
    } else if (path.endsWith('/logout')) {
      result = {};
    } else {
      status = 404;
      result = {'message': 'Unexpected test request: $path'};
    }
    return http.Response(
      jsonEncode(result),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  });
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
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'rw0882308@gmail.com',
      password: 'fixture',
    );
  });
  tearDown(() {
    SiteContentService.editing.value = false;
    rejectWrites = false;
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });

  testWidgets(
    'publishes multiline text, loads partner edits, restores defaults and revokes toolbar on sign-out',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => SiteEditorShell(child: child!),
          home: const Scaffold(
            body: SiteText(
              'Original heading',
              contentKey: 'copy.integration.title',
              literal: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit this page'), findsOneWidget);
      await tester.tap(find.text('Edit this page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original heading'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'New heading\nWith a second line',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        published['copy.integration.title'],
        'New heading\nWith a second line',
      );
      expect(find.text('New heading\nWith a second line'), findsOneWidget);
      published['copy.integration.title'] = 'Partner changed the heading';
      await tester.runAsync(SiteContentService.initialize);
      await tester.pump();
      expect(find.text('Partner changed the heading'), findsOneWidget);
      await tester.runAsync(
        () => SiteContentService.save('copy.integration.title', ''),
      );
      await tester.pump();
      expect(find.text('Empty text · click to edit'), findsOneWidget);
      await tester.tap(find.text('Empty text · click to edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore original'));
      await tester.pumpAndSettle();
      expect(published.containsKey('copy.integration.title'), false);
      expect(find.text('Original heading'), findsOneWidget);
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
      await tester.pumpAndSettle();
      expect(find.text('Edit this page'), findsNothing);
      expect(find.text('Done editing'), findsNothing);
      expect(SiteContentService.editing.value, false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: !BackendService.configured,
  );

  test(
    'a rejected write cannot change the published local cache',
    () async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'rw0882308@gmail.com',
        password: 'fixture',
      );
      await SiteContentService.save('copy.integration.failure', 'Published');
      rejectWrites = true;
      await expectLater(
        SiteContentService.save('copy.integration.failure', 'Uncommitted'),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        SiteContentService.text('copy.integration.failure', 'fallback'),
        'Published',
      );
      expect(uploads, 0);
    },
    skip: !BackendService.configured,
  );
  testWidgets(
    'existing custom Content Studio headings restore without reloading their parent',
    (tester) async {
      await tester.runAsync(
        () => SiteContentService.save(
          'blueprint.title',
          'Custom blueprint heading',
        ),
      );
      final captured = SiteContentService.text(
        'blueprint.title',
        'Acquisition Blueprint',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiteText(captured, contentKey: 'copy.test.legacy'),
          ),
        ),
      );
      expect(find.text('Custom blueprint heading'), findsOneWidget);
      await tester.runAsync(
        () => SiteContentService.reset(
          'blueprint.title',
          expected: 'Custom blueprint heading',
        ),
      );
      await tester.pump();
      expect(find.text('Acquisition Blueprint'), findsOneWidget);
    },
    skip: !BackendService.configured,
  );

  testWidgets(
    'published text and pictures survive changing bundled defaults and remounting the app',
    (tester) async {
      await tester.runAsync(() async {
        await SiteContentService.save('copy.test.permanent', 'Owner wording');
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5p8AAAAASUVORK5CYII=',
        );
        final url = await SiteContentService.uploadImage(bytes, 'png');
        await SiteContentService.save('image.test.permanent', url);
      });
      final savedUrl = SiteContentService.published('image.test.permanent')!;
      Widget page(String fallback, String image) => MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SiteText(
                fallback,
                contentKey: 'copy.test.permanent',
                literal: true,
              ),
              SiteImage(
                contentKey: 'image.test.permanent',
                original: Image.asset(image, width: 100, height: 80),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        page('Old default', 'assets/brand/affinity-logo.png'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Owner wording'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        page(
          'Completely redesigned default',
          'assets/brand/affinity-footer-logo.png',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Owner wording'), findsOneWidget);
      expect(find.text('Completely redesigned default'), findsNothing);
      final picture = tester.widget<Image>(
        find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      );
      expect((picture.image as NetworkImage).url, savedUrl);
      expect(uploads, 1);
      await tester.runAsync(SiteContentService.initialize);
      expect(SiteContentService.published('image.test.permanent'), savedUrl);
    },
    skip: !BackendService.configured,
  );
}
