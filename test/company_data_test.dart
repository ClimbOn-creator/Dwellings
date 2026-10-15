import 'package:dwelling_iq/models/company_dataset.dart';
import 'package:dwelling_iq/widgets/company_data_chart.dart';
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
  'totals': {'Registered accounts': 1234, 'Professional profiles': 12},
  'inventory': [
    {'label': 'profiles', 'count': 1200, 'bytes': 1048576},
  ],
  'roles': [
    {'label': 'buyer', 'count': 12},
  ],
  'locations': [
    {'label': 'Victoria, BC', 'count': 3},
  ],
  'teams': [
    {'label': '=HYPERLINK("unsafe")', 'count': 2},
  ],
  'uploaded_file_bytes': 2097152,
  'histories': {
    for (final id in [
      'accounts',
      'profiles',
      'provider_profiles',
      'learning_posts',
    ])
      id: {
        'current_total': id == 'accounts' ? 1234 : 12,
        'period_total': 3,
        'previous_total': 1,
        'series': [
          for (var i = 0; i < 30; i++)
            {
              'day': DateTime.utc(
                2026,
                9,
                16,
              ).add(Duration(days: i)).toIso8601String().substring(0, 10),
              'count': i == 29 ? 3 : 0,
            },
        ],
      },
  },
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

  test('chart buckets preserve totals; absent timestamps stay snapshots', () {
    final report = sample();
    final ninety = [
      for (var i = 0; i < 90; i++)
        {
          'day': DateTime.utc(
            2026,
            1,
            1,
          ).add(Duration(days: i)).toIso8601String().substring(0, 10),
          'count': 1,
        },
    ];
    (report.data['histories'] as Map)['accounts'] = {
      'current_total': 90,
      'period_total': 90,
      'previous_total': 0,
      'series': ninety,
    };
    final value = DatasetValues(companyDatasets.first, report);
    expect(value.chartPoints.length, 13);
    expect(value.chartPoints.fold<double>(0, (a, b) => a + b.value), 90);
    expect(value.changePercent, isNull);
    final snapshot = DatasetValues(
      companyDatasets.firstWhere((d) => d.id == 'learning_media'),
      report,
    );
    expect(snapshot.hasHistory, isFalse);
    expect(snapshot.daily, isEmpty);
    expect(report.toCsv(), contains('Daily UTC counts'));
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'dataset selection, compare, chart modes and details fit $width',
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
        expect(tester.takeException(), isNull, reason: 'Initial layout');
        expect(find.text('Data monitor'), findsOneWidget);
        if (width < 1000) {
          await tester.tap(find.byKey(const Key('dataset-drawer')));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('dataset-profiles')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CompanyDataChart>(find.byType(CompanyDataChart))
              .series
              .first
              .name,
          'Saved profiles',
        );
        final scroll = find
            .descendant(
              of: find.byKey(const Key('data-explorer-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(const Key('chart-lines')),
          250,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('chart-lines')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<CompanyDataChart>(find.byType(CompanyDataChart)).bars,
          isFalse,
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('breakdown-locations')),
          250,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('breakdown-locations')));
        await tester.pumpAndSettle();
        expect(find.text('Victoria, BC'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('data-detail-2')),
          -300,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('data-detail-2')));
        await tester.pumpAndSettle();
        expect(find.text('Source: profiles'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('compare-mode')),
          -500,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('compare-mode')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Comparison layout');
        final chart = tester.widget<CompanyDataChart>(
          find.byType(CompanyDataChart),
        );
        expect(chart.series.length, 2);
        expect(chart.series[0].name, 'Saved profiles');
        expect(chart.series[1].name, 'Professional members');
        expect(
          chart.series[0].points.map((p) => p.day),
          chart.series[1].points.map((p) => p.day),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('data-detail-1')),
          400,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('data-detail-1')));
        await tester.pumpAndSettle();
        expect(find.text('Daily counts · UTC'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('data-period')),
          -500,
          scrollable: scroll,
        );
        await tester.tap(find.byKey(const Key('data-period')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Last 90 days').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Period selector');
        expect(changed, 90);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('mixed units use labelled axes and snapshot comparison', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: CompanyDataChart(
              snapshot: true,
              series: [
                ChartSeries('Accounts', [DataPoint('2026-10-15', 2)], dataCyan),
                ChartSeries(
                  'Bytes',
                  [DataPoint('2026-10-15', 1048576)],
                  dataMint,
                  bytes: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Two scales: cyan uses the left axis; green uses the right axis.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
