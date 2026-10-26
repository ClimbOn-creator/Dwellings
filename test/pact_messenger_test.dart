import 'dart:convert';
import 'package:dwelling_iq/widgets/site_inline_editor.dart';
import 'package:dwelling_iq/services/pact_web_demo_service.dart';
import 'package:dwelling_iq/screens/pact_messenger_page.dart';
import 'package:dwelling_iq/screens/pact_web_messages.dart';
import 'package:dwelling_iq/widgets/dashboard_ui.dart';
import 'package:flutter/services.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/widgets/pact_profile_panel.dart';
import 'package:dwelling_iq/services/account_service.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/services/pact_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const user = '00000000-0000-0000-0000-000000000001';
bool rejectSave = false;
Map<String, dynamic>? lastProfileSave;

const other = '00000000-0000-0000-0000-000000000002';

class FixtureChannel extends Fake implements RealtimeChannel {}

class DemoDelegate extends PactMessagingService {
  final calls = <String>[];
  @override
  RealtimeChannel listen(String userId, void Function() onChanged) =>
      FixtureChannel();
  @override
  Future<void> stopListening(RealtimeChannel channel) async {}
  @override
  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    calls.add(action);
    return action == 'capabilities' ? {'is_member': false} : <MessageRow>[];
  }
}

class FixtureMessages extends PactMessagingService {
  bool fail = true;
  final List<MessageRow> sends = [];
  final List<int> reads = [];
  @override
  RealtimeChannel listen(String userId, void Function() onChanged) =>
      FixtureChannel();
  @override
  Future<void> stopListening(RealtimeChannel channel) async {}
  @override
  Future<List<MessageRow>> rows(
    String action, [
    MessageRow payload = const {},
  ]) async => switch (action) {
    'list' => [
      {
        'id': 'thread',
        'title': 'Business acquisition',
        'status': 'accepted',
        'preview': 'Ready to review the next step',
        'unread_count': 1,
      },
    ],
    'members' => [
      {
        'id': user,
        'name': 'Alex Morgan',
        'status': 'accepted',
        'read_sequence': 0,
      },
      {
        'id': other,
        'name': 'Taylor Chen',
        'status': 'accepted',
        'read_sequence': 1,
      },
    ],
    'messages' => [
      {
        'id': 'message',
        'thread_id': 'thread',
        'sender_id': other,
        'sequence': 1,
        'body': 'Ready to review the next step',
      },
    ],
    _ => [],
  };
  @override
  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    if (action == 'send') {
      sends.add(Map.of(payload));
      if (fail) throw StateError('Offline');
    }
    if (action == 'read') reads.add(payload['sequence'] as int);
    return {};
  }
}

// Use the dashboard's real colors without fetching its external font in tests.
ThemeData webDashboardTestTheme() {
  final base = ThemeData();
  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: DashboardUi.blue,
      surface: Colors.white,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: DashboardUi.ink,
      displayColor: DashboardUi.ink,
    ),
  );
}

class FixtureWebMessages extends PactMessagingService {
  bool failSend = false, accepted = false;
  final sends = <MessageRow>[];
  final stored = <MessageRow>[];
  final reads = <int>[];
  @override
  RealtimeChannel listen(String userId, void Function() onChanged) =>
      FixtureChannel();
  @override
  Future<void> stopListening(RealtimeChannel channel) async {}
  @override
  Future<List<MessageRow>> rows(
    String action, [
    MessageRow payload = const {},
  ]) async {
    final request = payload['thread_id'] == 'request';
    return switch (action) {
      'list' => [
        {
          'id': 'thread',
          'title': 'Taylor Chen',
          'status': 'accepted',
          'can_send': true,
          'preview': 'Please review the next step',
          'last_sequence': 1,
          'unread_count': 1,
          'updated_at': '2000-01-01T12:00:00',
        },
        {
          'id': 'request',
          'title': 'Buyer inquiry',
          'status': accepted ? 'accepted' : 'pending',
          'can_send': accepted,
          'preview': 'Can you help with my purchase?',
          'last_sequence': 1,
          'unread_count': 1,
        },
      ],
      'members' => [
        {
          'id': user,
          'name': 'Alex Morgan',
          'status': request && !accepted ? 'pending' : 'accepted',
          'read_sequence': 0,
        },
        {
          'id': other,
          'name': 'Taylor Chen',
          'status': 'accepted',
          'read_sequence': 100,
        },
      ],
      'messages' => [
        {
          'id': request ? 'incoming-request' : 'incoming',
          'thread_id': request ? 'request' : 'thread',
          'sender_id': other,
          'sequence': 1,
          'body': request
              ? 'Can you help with my purchase?'
              : 'Please review the next step',
          'created_at': '2000-01-01T12:00:00',
        },
        ...stored.where((m) => m['thread_id'] == payload['thread_id']),
      ],
      'directory' => [
        {
          'id': other,
          'provider_id': 'provider',
          'full_name': 'Taylor Chen',
          'job_title': 'Accountant',
          'company_name': 'Advisory',
        },
      ],
      _ => [],
    };
  }

  @override
  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    if (action == 'capabilities') return {'is_member': true};
    if (action == 'open_member') return {'id': 'thread'};
    if (action == 'respond') accepted = payload['status'] == 'accepted';
    if (action == 'read') reads.add(payload['sequence'] as int);
    if (action == 'send') {
      sends.add(Map.of(payload));
      if (failSend) throw StateError('Offline');
      stored.add({
        ...payload,
        'sender_id': user,
        'sequence': stored.length + 2,
        'created_at': '2000-01-01T12:01:00',
      });
    }
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!BackendService.configured) return;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Supabase.initialize(
      url: BackendService.supabaseUrl,
      publishableKey: 'test',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        Object result = {};
        if (request.url.path.endsWith('/token')) {
          final claims = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': user,
                    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                  }),
                ),
              )
              .replaceAll('=', '');
          result = {
            'access_token': 'e30.$claims.signature',
            'refresh_token': 'fixture',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': user,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'alex@example.test',
              'created_at': '2026-10-21T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (request.url.path.endsWith('/rpc/pact_save_profile')) {
          lastProfileSave = jsonDecode(request.body) as Map<String, dynamic>;
          if (rejectSave)
            return http.Response(
              jsonEncode({
                'message': 'Profile changed on another device',
                'code': 'P0001',
              }),
              400,
              request: request,
              headers: {'content-type': 'application/json'},
            );
        } else if (request.url.path.endsWith('/account_workspaces')) {
          result = [
            {'role': 'buyer'},
          ];
        } else if (request.url.path.endsWith('/profiles')) {
          result = [
            {
              'id': user,
              'username': 'alexmorgan',
              'full_name': 'Alex Morgan',
              'account_role': 'business_broker',
              'job_title': 'Business broker',
              'company_name': 'North Shore Advisory',
              'bio':
                  'Helping owners and buyers move their next chapter forward.',
              'profile_photo_url': '',
            },
          ];
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  test('native Google OAuth uses the app callback and PKCE', () async {
    if (!BackendService.configured) return;
    expect(BackendService.authRedirect, BackendService.mobileAuthRedirect);
    final response = await Supabase.instance.client.auth.getOAuthSignInUrl(
      provider: OAuthProvider.google,
      redirectTo: BackendService.authRedirect,
    );
    final url = Uri.parse(response.url);
    expect(url.queryParameters['provider'], 'google');
    expect(
      url.queryParameters['redirect_to'],
      BackendService.mobileAuthRedirect,
    );
    expect(url.queryParameters['code_challenge'], isNotEmpty);
    expect(url.queryParameters['code_challenge_method']?.toLowerCase(), 's256');
  });
  testWidgets(
    'mobile dashboard reads only the visible conversation and clears on sign out',
    (tester) async {
      if (!BackendService.configured) return;
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'alex@example.test',
        password: 'fixture',
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FixtureMessages();
      await tester.pumpWidget(
        MaterialApp(
          home: PactMessengerPage(service: api, mobileWorkspace: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.reads, isEmpty);
      await tester.tap(find.text('Messages').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Business acquisition'));
      await tester.pumpAndSettle();
      expect(api.reads, contains(1));
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      api.reads.clear();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(api.reads, isEmpty);
      await tester.ensureVisible(find.text('Account & preferences'));
      await tester.drag(find.byType(PactProfilePanel), const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account & preferences'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Sign out'));
      });
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Business acquisition'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('mobile profile, retry and sign-out protect the conversation', (
    tester,
  ) async {
    if (!BackendService.configured) return;
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'alex@example.test',
      password: 'fixture',
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FixtureMessages();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: PactMessengerPage(service: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Business acquisition'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('North Shore Advisory'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(PactMessengerPage),
      matchesGoldenFile('goldens/pact_mobile_profile.png'),
    );
    await tester.tap(find.text('Messages').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business acquisition'));
    await tester.pumpAndSettle();
    expect(api.reads, contains(1));
    await tester.enterText(find.byType(TextField), 'Please review this draft');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Not sent'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.sends.length, 2);
    expect(api.sends.first, api.sends.last);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Account & preferences'));
    await tester.drag(find.byType(PactProfilePanel), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account & preferences'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Sign out'));
    });
    await tester.pumpAndSettle();
    expect(find.text('Ready to review the next step'), findsNothing);
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'professional editor preserves failed edits and saves shared specialty fields',
    (tester) async {
      if (!BackendService.configured) return;
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'alex@example.test',
        password: 'fixture',
      );
      final profile = AccountProfile.fromJson({
        'id': user,
        'full_name': 'Alex Morgan',
        'updated_at': '2026-10-21T00:00:00Z',
      });
      final provider = MarketplaceService.providersFromRows([
        {
          'id': 'professional',
          'provider_type': 'accountant',
          'display_name': 'Alex Morgan',
          'description': 'Original description',
          'specialties': ['Tax'],
          'service_markets': ['Vancouver'],
        },
      ]).single;
      await tester.pumpWidget(
        MaterialApp(
          home: PactProfileEditorPage(profile: profile, professional: provider),
        ),
      );
      await tester.pumpAndSettle();
      final specialties = find.byKey(
        const ValueKey('pact-profile-specialties'),
      );
      await tester.scrollUntilVisible(
        specialties,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(specialties, 'Tax, Business acquisitions');
      final save = find.text('Save changes');
      await tester.scrollUntilVisible(
        save,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      rejectSave = true;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your profile changed on another device'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        specialties,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tax, Business acquisitions'), findsOneWidget);
      expect(lastProfileSave!['expected_updated_at'], '2026-10-21T00:00:00Z');
      expect((lastProfileSave!['payload'] as Map)['specialties'], [
        'Tax',
        'Business acquisitions',
      ]);
      rejectSave = false;
      await tester.scrollUntilVisible(
        save,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
    },
  );
  testWidgets(
    'web demo contacts reply locally, deduplicate sends and show real read progress',
    (tester) async {
      if (!BackendService.configured) return;
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'alex@example.test',
        password: 'fixture',
      );
      final delegate = DemoDelegate();
      final api = PactWebDemoService(enabled: true, delegate: delegate);
      final channel = api.listen(user, () {});
      final threads = await api.rows('list');
      expect(threads.length, 2);
      expect(threads.every((r) => r['demo'] == true), isTrue);
      final payload = <String, dynamic>{
        'id': 'demo-test-send',
        'thread_id': 'demo-broker',
        'body': 'Hello',
        'expected_user_id': user,
      };
      await api.call('send', payload);
      await api.call('send', payload);
      expect(
        (await api.rows('messages', {'thread_id': 'demo-broker'})).length,
        2,
      );
      var members = await api.rows('members', {'thread_id': 'demo-broker'});
      expect(members.last['read_sequence'], 0);
      await tester.pump(const Duration(milliseconds: 950));
      members = await api.rows('members', {'thread_id': 'demo-broker'});
      expect(members.last['read_sequence'], 2);
      await tester.pump(const Duration(milliseconds: 1300));
      final history = await api.rows('messages', {'thread_id': 'demo-broker'});
      expect(history.length, 3);
      expect(history.last['sender_id'], 'demo-broker');
      expect(delegate.calls, ['list']); // Demo text never reaches Supabase.
      await expectLater(
        api.call('send', {
          ...payload,
          'id': 'wrong-owner',
          'expected_user_id': other,
        }),
        throwsStateError,
      );
      await api.stopListening(channel);
      final disabled = PactWebDemoService(enabled: false, delegate: delegate);
      expect(await disabled.rows('list'), isEmpty);
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
      await expectLater(
        api.call('send', {...payload, 'id': 'signed-out'}),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'web messages show a split inbox, send with Enter and retry the same id',
    (tester) async {
      if (!BackendService.configured) return;
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'alex@example.test',
        password: 'fixture',
      );
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FixtureWebMessages()..failSend = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: webDashboardTestTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: PactWebMessages(service: api, workspace: 'buyer'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Select a conversation'), findsOneWidget);
      expect(find.byTooltip('Use light appearance'), findsNothing);
      expect(find.byTooltip('Use dark appearance'), findsNothing);
      expect(
        Theme.of(tester.element(find.byType(PactWebMessages))).brightness,
        Brightness.light,
      );
      expect(SiteEditorOverlayGate.hidden.value, isTrue);
      final requestChip = find.widgetWithText(ChoiceChip, 'Requests (1)');
      final chip = tester.widget<ChoiceChip>(requestChip);
      final background = Theme.of(
        tester.element(requestChip),
      ).chipTheme.backgroundColor!;
      final foreground = chip.labelStyle!.color!;
      final light = foreground.computeLuminance(),
          dark = background.computeLuminance();
      expect(
        ((light > dark ? light : dark) + .05) /
            ((light < dark ? light : dark) + .05),
        greaterThanOrEqualTo(4.5),
      );

      await tester.tap(find.text('Taylor Chen').first);
      await tester.pumpAndSettle();
      expect(find.text('Please review the next step'), findsWidgets);
      final selectedTile = find.ancestor(
        of: find.text('Taylor Chen').first,
        matching: find.byType(Material),
      );
      expect(
        tester
            .widgetList<Material>(selectedTile)
            .any((m) => m.color == const Color(0xFFFCE1EC)),
        isTrue,
      );
      final input = find.byKey(const ValueKey('web-message-composer'));
      await tester.enterText(input, 'Please review this document');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Not sent'), findsOneWidget);
      expect(api.sends.length, 1);
      api.failSend = false;
      await tester.tap(find.text('Retry').last);
      await tester.pumpAndSettle();
      expect(api.sends.length, 2);
      expect(api.sends.first, api.sends.last);
      expect(find.text('Please review this document'), findsOneWidget);
      LinearGradient sentGradient(String body) => tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text(body),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.gradient)
          .whereType<LinearGradient>()
          .single;
      final firstGradient = sentGradient('Please review this document');
      expect(firstGradient.begin, Alignment.topCenter);
      expect(firstGradient.end, Alignment.bottomCenter);
      expect(
        firstGradient.colors.every((c) => c.computeLuminance() <= .161),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(
        sentGradient('Please review this document').colors,
        firstGradient.colors,
      );

      expect(api.reads, isNotEmpty);
      await expectLater(
        find.byType(PactWebMessages),
        matchesGoldenFile('goldens/pact_web_messages.png'),
      );
      api.failSend = true;
      await tester.enterText(input, 'Cancel this draft');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Not sent'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this draft'), findsNothing);
      api.failSend = false;
      await tester.enterText(input, 'A different message with no colour hash');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      final nextGradient = sentGradient(
        'A different message with no colour hash',
      );
      expect(nextGradient.colors.first, firstGradient.colors.last);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(SiteEditorOverlayGate.hidden.value, isFalse);
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
    },
  );
  testWidgets(
    'web member can read a request but only reply after accepting; sign-out clears it',
    (tester) async {
      if (!BackendService.configured) return;
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'alex@example.test',
        password: 'fixture',
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FixtureWebMessages();
      await tester.pumpWidget(
        MaterialApp(
          theme: webDashboardTestTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: PactWebMessages(service: api, workspace: 'member'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Requests (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buyer inquiry'));
      await tester.pumpAndSettle();
      expect(find.text('Can you help with my purchase?'), findsOneWidget);
      expect(find.byKey(const ValueKey('web-message-composer')), findsNothing);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('web-message-composer')),
      );
      expect(field.enabled, isTrue);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => Supabase.instance.client.auth.signOut());
      await tester.pumpAndSettle();
      expect(find.text('Can you help with my purchase?'), findsNothing);
      expect(find.text('Sign in to Messages'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
