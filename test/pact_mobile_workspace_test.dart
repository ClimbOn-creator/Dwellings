import 'package:dwelling_iq/widgets/workspace_role_gate.dart';
import 'package:dwelling_iq/services/workspace_role_service.dart';
import 'dart:convert';
import 'package:dwelling_iq/screens/pact_professional_editor.dart';
import 'package:dwelling_iq/screens/pact_professional_matches.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/services/pact_professional_service.dart';
import 'package:dwelling_iq/widgets/pact_professional_profile.dart';
import 'package:dwelling_iq/widgets/pact_mobile_surface.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dwelling_iq/screens/pact_mobile_workspace.dart';
import 'package:dwelling_iq/services/account_service.dart';
import 'package:dwelling_iq/services/backend_service.dart';
import 'package:dwelling_iq/services/business_sale_bulletin_service.dart';
import 'package:dwelling_iq/services/deal_room_service.dart';
import 'package:dwelling_iq/services/pact_messaging_service.dart';
import 'package:dwelling_iq/services/pact_mobile_workspace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String? serverWorkspaceRole;
bool rejectExperience = false;
Map<String, dynamic>? experienceSave;
const accountId = '00000000-0000-0000-0000-000000000001';

class WorkspaceFixture extends PactMobileWorkspaceService {
  bool member = false, failRecognition = false, failInsights = false;
  bool failSave = false;
  PactMobileRole? savedRole = PactMobileRole.buyer;
  @override
  Future<PactMobileRole?> loadRole() async {
    if (failRecognition) throw StateError("offline");
    return savedRole;
  }

  @override
  Future<PactMobileRole> chooseRole(PactMobileRole role) async {
    if (failSave) throw StateError("offline");
    return savedRole ??= role;
  }

  final reads = <int>[];
  @override
  Future<bool> isMember(PactMessagingService messaging) async {
    if (failRecognition) throw StateError('offline');
    return member;
  }

  @override
  Future<List<DealRoom>> deals() async => [];
  @override
  Future<List<IntroductionRequest>> leads() async => [];
  @override
  Future<List<BusinessSaleBulletin>> businesses() async => [];
  @override
  Future<List<SellerPostStats>> listings() async => [
    SellerPostStats.fromJson({
      'id': 'owned-listing',
      'title': 'Harbour Studio',
      'industry': 'Services',
      'region': 'Victoria, BC',
      'save_count': 8,
      'status': 'active',
      'summary': 'An owner-managed business.',
    }),
  ];
  @override
  Future<Map<String, List<Map<String, dynamic>>>> insights(int days) async {
    reads.add(days);
    if (failInsights) throw StateError('offline');
    return {'owned-listing': []};
  }
}

class DesktopRoleFixture extends WorkspaceRoleService {
  WorkspaceRole? role;
  @override
  Future<WorkspaceRole?> load() async => role;
  @override
  Future<WorkspaceRole> choose(WorkspaceRole value) async => role ??= value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final font in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          File('$fonts/${font.value}').readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
    }

    if (!BackendService.configured) return;
    await Supabase.initialize(
      url: BackendService.supabaseUrl,
      publishableKey: 'fixture',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((r) async {
        Object result = [];
        if (r.url.path.endsWith('/token')) {
          final claims = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': accountId,
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
              'id': accountId,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'fixture@example.test',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        }
        if (r.url.path.endsWith('/account_workspaces')) {
          if (r.method == 'POST') {
            if (serverWorkspaceRole != null) {
              return http.Response(
                '{"code":"23505","message":"duplicate workspace"}',
                409,
                request: r,
                headers: {'content-type': 'application/json'},
              );
            }
            serverWorkspaceRole = (jsonDecode(r.body) as Map)['role'] as String;
            return http.Response('', 201, request: r);
          }
          result = serverWorkspaceRole == null
              ? []
              : [
                  {'role': serverWorkspaceRole},
                ];
        }
        if (r.url.path.endsWith('/rpc/pact_save_profile')) {
          experienceSave = jsonDecode(r.body) as Map<String, dynamic>;
          if (rejectExperience) {
            return http.Response(
              '{"message":"Profile changed","code":"P0001"}',
              400,
              request: r,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response(
          jsonEncode(result),
          200,
          request: r,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'fixture@example.test',
      password: 'fixture',
    );
  });
  tearDownAll(() async {
    if (BackendService.configured) await Supabase.instance.dispose();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ValueNotifier<int>> mount(
    WidgetTester tester,
    WorkspaceFixture fixture, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tab = ValueNotifier<int>(0);
    addTearDown(tab.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: PactMobileWorkspace(
          userId: accountId,
          messaging: PactMessagingService(),
          service: fixture,
          tab: tab,
          threads: const [],
          messages: const Center(child: Text('Shared inbox fixture')),
          profile: const Center(child: Text('Shared profile fixture')),
          onOpenThread: (_) {},
          // Deliberately spoof a professional label: server capability must win.
          account: AccountProfile(
            id: accountId,
            username: 'alex',
            fullName: 'Alex',
            role: 'business_broker',
            jobTitle: '',
            companyName: '',
            employmentType: '',
            photoUrl: '',
            bio: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tab;
  }

  test(
    'shared service reads saved role and concurrent choices keep the first role',
    () async {
      if (!BackendService.configured) return;
      serverWorkspaceRole = null;
      final service = WorkspaceRoleService();
      expect(await service.load(), isNull);
      expect(await service.choose(WorkspaceRole.seller), WorkspaceRole.seller);
      expect(await WorkspaceRoleService().load(), WorkspaceRole.seller);
      expect(await service.choose(WorkspaceRole.buyer), WorkspaceRole.seller);
    },
  );
  testWidgets(
    'new accounts choose once; saved desktop role ignores phone preferences',
    (tester) async {
      if (!BackendService.configured) return;
      final fixture = WorkspaceFixture()..savedRole = null;
      final tab = await mount(tester, fixture);
      expect(find.text('Choose your workspace'), findsOneWidget);
      for (final label in ['Buyer', 'Seller', 'Member']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Businesses'), findsNothing);
      await tester.tap(find.text('Seller'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm workspace'));
      await tester.pumpAndSettle();
      expect(fixture.savedRole, PactMobileRole.seller);
      expect(find.byTooltip('Switch workspace'), findsNothing);
      expect(find.text('My Listing'), findsWidgets);
      tab.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('Shared inbox fixture'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      SharedPreferences.setMockInitialValues({
        'pact.mobile.workspace.$accountId': 'buyer',
      });
      await mount(tester, fixture);
      expect(find.text('My Listing'), findsWidgets);
      expect(find.text('Choose your workspace'), findsNothing);
    },
  );
  testWidgets('failed role save stays on selection and can retry', (
    tester,
  ) async {
    if (!BackendService.configured) return;
    final fixture = WorkspaceFixture()
      ..savedRole = null
      ..failSave = true;
    await mount(tester, fixture);
    await tester.tap(find.text('Member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm workspace'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save your workspace. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Clients'), findsNothing);
    fixture.failSave = false;
    await tester.tap(find.text('Confirm workspace'));
    await tester.pumpAndSettle();
    expect(fixture.savedRole, PactMobileRole.member);
    expect(find.text('Clients'), findsWidgets);
  });
  testWidgets(
    'server recognized members see clients and incoming leads on phone and tablet',
    (tester) async {
      if (!BackendService.configured) return;
      final fixture = WorkspaceFixture()
        ..member = true
        ..savedRole = PactMobileRole.member;
      final tab = await mount(tester, fixture, width: 834);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('Clients'), findsWidgets);
      expect(find.text('Leads'), findsWidgets);
      tab.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Build connections, thoughtfully'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(PactMobileWorkspace),
        matchesGoldenFile('goldens/pact_mobile_member.png'),
      );
    },
  );
  testWidgets(
    'seller charts use current bookmarks and do not substitute views or failed data',
    (tester) async {
      if (!BackendService.configured) return;
      final fixture = WorkspaceFixture()..savedRole = PactMobileRole.seller;
      final tab = await mount(tester, fixture);
      tab.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('8'), findsOneWidget);
      expect(find.byType(PactListingSaveChart), findsOneWidget);
      await expectLater(
        find.byType(PactMobileWorkspace),
        matchesGoldenFile('goldens/pact_mobile_listing_insights.png'),
      );
      await tester.tap(find.text('30 days'));
      await tester.pumpAndSettle();
      expect(fixture.reads.last, 30);
      fixture.failInsights = true;
      await tester.tap(find.text('90 days'));
      await tester.pumpAndSettle();
      expect(find.byType(PactListingSaveChart), findsNothing);
      expect(
        find.textContaining('Could not refresh: Listing insights'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed recognition never reveals member workspace', (
    tester,
  ) async {
    if (!BackendService.configured) return;
    await mount(tester, WorkspaceFixture()..failRecognition = true);
    expect(find.text('Could not recognize your account.'), findsOneWidget);
    expect(find.text('Clients'), findsNothing);
    expect(find.byTooltip('Switch workspace'), findsNothing);
  });
  testWidgets('buyer home has stable phone layout', (tester) async {
    if (!BackendService.configured) return;
    await mount(tester, WorkspaceFixture());
    await expectLater(
      find.byType(PactMobileWorkspace),
      matchesGoldenFile('goldens/pact_mobile_home.png'),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'desktop sign-in gates content until a permanent choice is saved',
    (tester) async {
      if (!BackendService.configured) return;
      final service = DesktopRoleFixture();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceRoleGate(
            service: service,
            child: Builder(
              builder: (context) =>
                  Text('Assigned: ${WorkspaceRoleScope.of(context)?.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choose your workspace'), findsOneWidget);
      expect(find.textContaining('Assigned:'), findsNothing);
      await tester.tap(find.text('Buyer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm workspace'));
      await tester.pumpAndSettle();
      expect(find.text('Assigned: buyer'), findsOneWidget);
      expect(service.role, WorkspaceRole.buyer);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceRoleGate(
            service: service,
            child: Builder(
              builder: (context) =>
                  Text('Assigned: ${WorkspaceRoleScope.of(context)?.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assigned: buyer'), findsOneWidget);
      expect(find.text('Choose your workspace'), findsNothing);
    },
  );
  testWidgets(
    'chart groups real dated saves and has an accessible description',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: PactListingSaveChart(
                days: 7,
                now: DateTime.utc(2026, 10, 22),
                counts: const {
                  '2026-10-22': 3,
                  '2026-10-21': 2,
                  '2026-10-01': 99,
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('99'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'professional match labels never promise fit with unknown eligibility',
    () {
      Map<String, dynamic> row(bool eligible, int score, int deal) => {
        'provider': {
          'id': 'provider',
          'provider_type': 'accountant',
          'display_name': 'Alex',
        },
        'eligible': eligible,
        'score': score,
        'missing': eligible ? [] : ['Credential not confirmed'],
        'reasons': ['Relevant service'],
        'components': {
          'service': 35,
          'industry': 30,
          'deal': deal,
          'location': 10,
        },
      };
      expect(
        ProfessionalMatch(row(false, 100, 25)).label,
        'More information needed',
      );
      expect(ProfessionalMatch(row(true, 75, 0)).label, 'Relevant experience');
      expect(ProfessionalMatch(row(true, 100, 25)).label, 'Strong fit');
    },
  );

  testWidgets('mobile gradient paints behind phone status safe area', (
    tester,
  ) async {
    if (!BackendService.configured) return;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.resetPadding);
    await mount(tester, WorkspaceFixture());
    expect(find.byType(PactMobileSurface), findsOneWidget);
    final surface = tester.getRect(find.byType(PactMobileSurface));
    expect(surface.top, 0);
    expect(surface.height, 844);
    expect(tester.getTopLeft(find.text('PACT')).dy, greaterThan(59));
    await expectLater(
      find.byType(PactMobileSurface),
      matchesGoldenFile('goldens/pact_mobile_full_bleed.png'),
    );
  });

  testWidgets(
    'member profile has left overlapping portrait and honest experience sections',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = MarketplaceService.providersFromRows([
        {
          'id': 'example',
          'provider_type': 'accountant',
          'display_name': 'Alex Morgan',
          'company_name': 'Harbour Advisory',
          'job_title': 'Acquisition accountant',
          'verified': true,
          'is_example': true,
          'specialties': ['Financial due diligence'],
          'professional_background': {
            'services': ['financial_due_diligence'],
            'industries': ['hospitality'],
            'availability': 'accepting',
            'employment': [
              {
                'title': 'Partner',
                'organization': 'Harbour Advisory',
                'start_year': '2015',
                'end_year': '',
                'description': 'Supporting business acquisitions.',
              },
            ],
            'credentials': [
              {
                'title': 'CPA',
                'issuer': 'Professional regulator',
                'jurisdiction': 'CA-BC',
              },
            ],
          },
        },
      ]).single;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: PactMobileSurface(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PactProfessionalHeader(
                      name: provider.name,
                      headline: provider.jobTitle,
                      company: provider.company,
                      photoUrl: '',
                      coverUrl: '',
                      verified: true,
                      tags: provider.specialties,
                      actions: [
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Edit profile'),
                        ),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Edit experience'),
                        ),
                      ],
                    ),
                    PactProfessionalExperience(provider: provider),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pact profile verified'), findsOneWidget);
      await expectLater(
        find.byType(PactMobileSurface),
        matchesGoldenFile('goldens/pact_professional_profile_phone.png'),
      );
      await tester.scrollUntilVisible(
        find.text('CPA'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Self-reported · current verification not confirmed'),
        findsOneWidget,
      );
      expect(find.textContaining('Credential verified by Pact'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'experience editor keeps failed changes and sends shared bounded fields',
    (tester) async {
      if (!BackendService.configured) return;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = AccountProfile.fromJson({
        'id': accountId,
        'full_name': 'Alex',
        'bio': 'Existing biography',
        'updated_at': '2026-10-22T00:00:00Z',
      });
      final provider = MarketplaceService.providersFromRows([
        {
          'id': 'provider',
          'provider_type': 'accountant',
          'display_name': 'Alex',
          'professional_background': {
            'services': ['valuation'],
            'industries': ['hospitality'],
            'currency': 'CAD',
            'availability': 'accepting',
            'employment': [],
          },
        },
      ]).single;
      await tester.pumpWidget(
        MaterialApp(
          home: PactProfessionalEditor(
            profile: profile,
            professional: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Financial due diligence'));
      await tester.pumpAndSettle();
      rejectExperience = true;
      final save = find.text('Save experience');
      await tester.scrollUntilVisible(
        save,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(experienceSave!['expected_updated_at'], '2026-10-22T00:00:00Z');
      final payload = experienceSave!['payload'] as Map;
      expect(payload['bio'], 'Existing biography');
      expect(
        (payload['professional_background'] as Map)['services'],
        containsAll(['valuation', 'financial_due_diligence']),
      );
      await tester.scrollUntilVisible(
        find.textContaining('Could not save. Your changes are still here.'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Could not save. Your changes are still here.'),
        findsOneWidget,
      );
      rejectExperience = false;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'deal matching requires criteria and presents clear empty results',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PactProfessionalMatchesPage(
            loadDeals: () async => [],
            loadMatches: (_) async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.text('Find matches');
      await tester.scrollUntilVisible(
        button,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Choose Profession.'),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Choose Profession.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
