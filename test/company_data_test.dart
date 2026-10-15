import 'package:dwelling_iq/widgets/calculator_help_sidebar.dart';
import 'package:dwelling_iq/widgets/site_inline_editor.dart';
import 'package:dwelling_iq/screens/company_data_page.dart';
import 'package:dwelling_iq/services/company_data_service.dart';
import 'package:dwelling_iq/services/usage_analytics_service.dart';
import 'package:dwelling_iq/widgets/company_data_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CompanyDataReport sample() => CompanyDataReport({
  'generated_at': '2026-10-15T12:00:00Z',
  'days': 30,
  'totals': {
    'Registered accounts': 1234,
    'Professional profiles': 12,
    'Team selections': 22,
    'Event registrations': 9,
    'Profiles with a saved location': 20,
  },
  'inventory': [
    {'label': 'profiles', 'count': 1200, 'bytes': 1048576},
  ],
  'roles': [
    {'label': 'buyer', 'count': 12},
  ],
  'teams': [
    {'label': '=HYPERLINK("unsafe")', 'count': 2},
  ],
  'new_accounts': [
    {'day': '2026-10-15', 'count': 2},
  ],
  'uploaded_file_bytes': 2097152,
});
Widget _accessPreview(BuildContext context, bool allowed) =>
    allowed ? const Text('Private data entry') : const SizedBox.shrink();
void main() {
  testWidgets(
    'privacy shell keeps app content at full viewport when no prompt is shown',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => CalculatorHelpHost(
            child: UsagePrivacyHost(child: SiteEditorShell(child: child!)),
          ),
          home: const Scaffold(
            body: Center(child: Text('App content visible')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Scaffold)), const Size(800, 600));
      expect(
        tester.getCenter(find.text('App content visible')),
        const Offset(400, 300),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('export protects spreadsheet formulas and retains report context', () {
    final csv = sample().toCsv();
    expect(csv, contains("'="));
    expect(csv, contains('Selected period (days)'));
    expect(csv, contains('2026-10-15T12:00:00Z'));
    expect(csv, contains('Uploaded file bytes'));
    expect(CompanyDataReport.csvCell('  @SUM(1)'), contains("'  @SUM"));
    expect(
      CompanyDataReport.csvCell('Plain "quoted" name'),
      '"Plain ""quoted"" name"',
    );
  });
  test('usage categories contain no query or private form text', () {
    expect(
      UsageAnalyticsService.featureFor('personal-consulting'),
      'consulting',
    );
    expect(UsageAnalyticsService.featureFor('learningDashboard'), 'learning');
    expect(UsageAnalyticsService.featureFor('memberStudio'), 'member');
    expect(UsageAnalyticsService.featureFor('buyerDashboard'), 'buyer');
  });
  testWidgets('signed-out direct owner URL stays locked and entry is hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CompanyDataAccess(builder: _accessPreview),
              Expanded(child: CompanyDataPage()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private owner access'), findsOneWidget);
    expect(find.byType(CompanyDataReportView), findsNothing);
    expect(find.text('Private data entry'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'readable report, real counts, periods and missing-data labels at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int? changed;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompanyDataReportView(
                report: sample(),
                days: 30,
                onDaysChanged: (d) => changed = d,
                onRefresh: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Your company, in numbers'), findsOneWidget);
        expect(find.text('1,234'), findsNWidgets(2));
        expect(find.textContaining('1.0 MB in database'), findsOneWidget);
        await tester.tap(find.byType(DropdownButton<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Last 90 days').last);
        await tester.pumpAndSettle();
        expect(changed, 90);
        await tester.scrollUntilVisible(
          find.text('What is kept, and what is still missing'),
          700,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.textContaining('Historical clicks cannot be reconstructed'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
