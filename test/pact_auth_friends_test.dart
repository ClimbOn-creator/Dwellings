import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/screens/auth_page.dart';
import 'package:dwelling_iq/screens/member_friends_page.dart';
import 'package:dwelling_iq/services/member_friends_service.dart';

class FriendsFixture extends MemberFriendsService {
  String status = 'none';
  bool incoming = false, fail = false;
  final actions = <String>[];
  @override
  Future<bool> available() async => true;
  @override
  Future<MemberFriendsPageData> people({
    String scope = 'friends',
    String query = '',
    String? target,
    int offset = 0,
  }) async {
    if (fail) throw StateError('offline');
    final shown =
        scope == 'profile' ||
        scope == 'discover' && status == 'none' ||
        scope == 'friends' && status == 'accepted' ||
        scope == 'requests' && status == 'pending';
    return MemberFriendsPageData(
      shown
          ? [
              MemberFriend(
                userId: 'peer',
                name: 'Alex Morgan',
                jobTitle: 'Business adviser',
                company: 'North Coast',
                status: status,
                incoming: incoming,
              ),
            ]
          : [],
      shown ? 1 : 0,
    );
  }

  @override
  Future<void> act(MemberFriend friend, String action) async {
    if (fail) throw StateError('offline');
    actions.add(action);
    if (action == 'request') {
      status = 'pending';
      incoming = false;
    }
    if (action == 'accept') status = 'accepted';
    if (['remove', 'decline', 'cancel'].contains(action)) status = 'none';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (BackendService.configured) {
      await Supabase.initialize(
        url: BackendService.supabaseUrl,
        publishableKey: 'fixture',
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
          localStorage: EmptyLocalStorage(),
        ),
      );
    }
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final font in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            File(
              '$fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  Future<void> size(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('shared sign-in stays compact and readable at $width', (
      tester,
    ) async {
      await size(tester, width);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const AuthPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/pact-river.jpg'),
          tester.element(find.byType(AuthPage)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(AuthPage),
        matchesGoldenFile('goldens/pact_auth_${width.toInt()}.png'),
      );
    });
  }
  testWidgets('account creation uses three short steps and preserves input', (
    tester,
  ) async {
    await size(tester, 390);
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Morgan');
    await tester.enterText(find.byType(TextFormField).at(1), 'alex_morgan');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3 · Your professional identity'), findsOneWidget);
    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('alex@example.test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'friend requests save across profile visits and recipients can accept',
    (tester) async {
      final service = FriendsFixture();
      await size(tester, 390);
      await tester.pumpWidget(
        MaterialApp(
          home: MemberFriendsPage(service: service, initialScope: 'discover'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add friend'));
      await tester.pumpAndSettle();
      expect(service.actions, ['request']);
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('Request sent'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      service.incoming = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MemberFriendsPage(service: service, initialScope: 'requests'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<String>),
          matching: find.text('Friends'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(service.status, 'accepted');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed Friends refresh shows retry and never invents an empty network',
    (tester) async {
      final service = FriendsFixture()..fail = true;
      await tester.pumpWidget(
        MaterialApp(home: MemberFriendsPage(service: service)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Friends could not load. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Your circle starts here'), findsNothing);
      service.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Your circle starts here'), findsOneWidget);
    },
  );
}
