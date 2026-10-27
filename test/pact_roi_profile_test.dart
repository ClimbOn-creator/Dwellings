import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/services/marketplace_service.dart';
import 'package:dwelling_iq/screens/member_profile_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/services/account_service.dart';
import 'package:dwelling_iq/services/profile_snapshot_service.dart';
import 'package:dwelling_iq/services/member_roi_service.dart';
import 'package:dwelling_iq/widgets/pact_profile_panel.dart';
import 'package:dwelling_iq/widgets/pact_desktop_profile_header.dart';
import 'package:dwelling_iq/widgets/pact_professional_profile.dart';
import 'package:dwelling_iq/widgets/member_roi_dashboard.dart';
import 'package:dwelling_iq/widgets/affinity_button_gradients.dart';

class RoiFixture extends MemberRoiService {
  bool fail = false;
  double? cost = 2988;
  @override
  Future<MemberRoiSnapshot> load(int days) async {
    if (fail) throw StateError('offline');
    return MemberRoiSnapshot(
      days: days,
      views: 42,
      qualified: 8,
      consultations: 3,
      transactions: 1,
      revenue: 15000,
      annualCost: cost,
      startedAt: '2026-10-26T00:00:00Z',
    );
  }

  @override
  Future<void> saveCost(double value) async {
    cost = value;
  }
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
      await (FontLoader(font.key)..addFont(
            File(
              '$fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  final account = AccountProfile.fromJson({
    'id': 'fixture',
    'full_name': 'Alex Morgan',
    'job_title': 'Business adviser',
    'company_name': 'North Coast',
    'bio': 'Connecting good people with their next chapter.',
  });
  Future<void> frame(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AffinityButtonGradients.apply(
          ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        ),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
    // Image decoding happens outside fake test time. Wait for the actual banner
    // so a busy full-suite run cannot capture its loading placeholder.
    await tester.runAsync(() => precacheImage(
      const AssetImage('assets/images/pact-river.jpg'),
      tester.element(find.byType(Scaffold).first),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'profile is stable, settings remain bounded and layout matches device at $width',
      (tester) async {
        var loads = 0;
        await frame(
          tester,
          width,
          PactProfilePanel(
            desktopLayout: true,
            load: () async {
              loads++;
              return PactProfileSnapshot(account: account);
            },
            actions: [ListTile(title: const Text('Sign out'), onTap: () {})],
          ),
        );
        expect(
          find.byType(
            width < 850 ? PactProfessionalHeader : PactDesktopProfileHeader,
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Account & preferences'));
        await tester.tap(find.text('Account & preferences'));
        await tester.pumpAndSettle();
        expect(find.text('Sign out'), findsOneWidget);
        await tester.pump(const Duration(seconds: 65));
        await tester.pumpAndSettle();
        expect(loads, 1);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'desktop dashboard profile keeps the desktop layout in a 760 pixel pane',
    (tester) async {
      await frame(
        tester,
        1440,
        Center(
          child: SizedBox(
            width: 760,
            child: PactProfilePanel(
              desktopLayout: true,
              load: () async => PactProfileSnapshot(account: account),
              actions: [
                ListTile(title: const Text('Account tools'), onTap: () {}),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(PactDesktopProfileHeader), findsOneWidget);
      expect(find.byType(PactProfessionalHeader), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/pact_desktop_profile_embedded.png'),
      );
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets('professional profile uses the correct header at $width', (
      tester,
    ) async {
      final provider = MarketplaceService.providersFromRows([
        {
          'id': 'example-profile',
          'provider_type': 'accountant',
          'display_name': 'Alex Morgan',
          'company_name': 'North Coast',
          'job_title': 'Business adviser',
          'is_example': true,
          'verified': false,
          'years_experience': 8,
          'membership_tier': 'free',
        },
      ]).first;
      await frame(tester, width, MemberProfilePage(provider: provider));
      expect(
        find.byType(
          width < 900 ? PactProfessionalHeader : PactDesktopProfileHeader,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'a hung profile request ends with retry while keeping confirmed identity',
    (tester) async {
      final pending = Completer<PactProfileSnapshot>();
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PactProfilePanel(
              initialProfile: account,
              load: () => pending.future,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(
        find.text('Could not refresh your profile. Pull down to retry.'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('ROI uses net return and cannot divide by missing or zero cost', () {
    const d = MemberRoiSnapshot(days: 365, revenue: 15000, annualCost: 2988);
    expect(d.netReturn, 12012);
    expect(d.roiPercent, closeTo(402.008, 0.01));
    expect(
      const MemberRoiSnapshot(days: 365, revenue: 15000).roiPercent,
      isNull,
    );
    expect(
      const MemberRoiSnapshot(
        days: 365,
        revenue: 15000,
        annualCost: 0,
      ).roiPercent,
      isNull,
    );
    expect(const MemberRoiSnapshot(days: 30, annualCost: 3650).periodCost, 300);
  });
  for (final width in [390.0, 1200.0]) {
    testWidgets('ROI dashboard shows reported return and scales at $width', (
      tester,
    ) async {
      await frame(
        tester,
        width,
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: MemberRoiDashboard(service: RoiFixture()),
        ),
      );
      expect(find.text('402.0%'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/pact_roi_${width.toInt()}.png'),
      );
    });
  }
  testWidgets(
    'failed ROI reads display an error rather than invented zero metrics',
    (tester) async {
      await frame(
        tester,
        390,
        SingleChildScrollView(
          child: MemberRoiDashboard(service: RoiFixture()..fail = true),
        ),
      );
      expect(
        find.text('Your ROI data could not load. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Profile views'), findsNothing);
    },
  );
  testWidgets(
    'desktop profile has a banner, side column and compact sections',
    (tester) async {
      await frame(
        tester,
        1200,
        PactProfilePanel(
          desktopLayout: true,
          load: () async => PactProfileSnapshot(account: account),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/pact-river.jpg'),
          tester.element(find.byType(PactProfilePanel)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/pact_desktop_profile.png'),
      );
    },
  );
}
