import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dwelling_iq/models/buyer_command_state.dart';
import 'package:dwelling_iq/services/deal_room_service.dart';
import 'package:dwelling_iq/widgets/buyer_command_centre.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';

final now = DateTime(2026, 10, 4, 15);
DealRoom room(
  String id, {
  String stage = 'diligence',
  String status = 'active',
  DateTime? closing,
  DateTime? updated,
}) => DealRoom(
  id: id,
  userId: 'buyer',
  title: id,
  address: '',
  city: 'Victoria',
  purchasePrice: 1000000,
  timeline: '',
  goals: '',
  status: status,
  propertySnapshot: {},
  riskSnapshot: {},
  sharingPreferences: {},
  updatedAt: updated ?? now,
  transactionType: 'business',
  currentStage: stage,
  targetCloseDate: closing,
);
DealRoomTask task(
  String title, {
  bool done = false,
  String status = 'not_started',
  DateTime? due,
  int position = 0,
}) => DealRoomTask(
  id: title,
  title: title,
  category: 'general',
  completed: done,
  position: position,
  stage: 'diligence',
  status: status,
  dueAt: due,
);
DealRoomBundle bundle(DealRoom deal, List<DealRoomTask> tasks) =>
    DealRoomBundle(
      room: deal,
      tasks: tasks,
      notes: [],
      members: [],
      documents: [],
      documentEvents: [],
    );
final island = room('Island HVAC');
final abc = room('ABC Plumbing', stage: 'financing');
final dental = room('West Coast Dental', stage: 'evaluation');
final fixtures = [
  bundle(island, [task('Review financials', due: DateTime(2026, 10, 6))]),
  bundle(abc, [
    task('Upload lender package', status: 'blocked'),
    task('Overdue documents', due: DateTime(2026, 10, 2)),
    task('Done', done: true, due: DateTime(2026, 10, 1)),
  ]),
  bundle(dental, [task('Complete valuation')]),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'health and next actions use unresolved tasks, with blocked and overdue actions first',
    () {
      final state = BuyerCommandState(
        [island, abc, dental, room('Archived', status: 'archived')],
        fixtures,
        now,
        lastRoomId: abc.id,
      );
      expect(state.deals.length, 3);
      expect(state.attentionCount, 2);
      expect(state.deals.map((deal) => deal.health), [
        AcquisitionHealth.dueSoon,
        AcquisitionHealth.attention,
        AcquisitionHealth.onTrack,
      ]);
      expect(state.deals[1].nextAction, 'Upload lender package');
      expect(state.resume!.room.id, abc.id);
      expect(state.events.map((event) => event.title), [
        'Overdue documents',
        'Review financials',
      ]);
      expect(state.deals[1].progress!.$2, closeTo(1 / 3, .001));
      expect(
        AcquisitionCommand(dental, null, now).health,
        AcquisitionHealth.awaitingDetails,
      );
    },
  );
  test(
    'resume falls back from removed or archived deal and progress measures the current stage',
    () {
      final latest = room(
        'Latest',
        updated: now.add(const Duration(hours: 1)),
        closing: DateTime(2026, 10, 16),
      );
      final state = BuyerCommandState(
        [island, latest, room('old', status: 'completed')],
        [
          bundle(latest, [
            task('one', done: true),
            task('two', done: true),
            task('three'),
          ]),
        ],
        now,
        lastRoomId: 'old',
      );
      expect(state.resume!.room.id, 'Latest');
      expect(state.resume!.progress!.$1, 'Due diligence');
      expect(state.resume!.progress!.$2, closeTo(2 / 3, .001));
      expect(state.events.single.title, 'Target closing');
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'command centre shows real actions and opens the selected deal at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        DealRoom? opened, planned;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: BuyerCommandCentre(
                    rooms: [island, abc, dental],
                    bundles: fixtures,
                    now: now,
                    greeting: 'Good afternoon',
                    name: 'Will Russell',
                    lastRoomId: abc.id,
                    search: const SizedBox(),
                    onOpenDeal: (deal) => opened = deal,
                    onOpenPlan: (deal) => planned = deal,
                    onRetry: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Good afternoon, Will'), findsOneWidget);
        expect(
          find.text('3 active acquisitions · 2 actions need attention'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Upload lender package'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Upload lender package'));
        expect(planned!.id, abc.id);
        await tester.ensureVisible(
          find.byKey(const Key('continue-acquisition')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('continue-acquisition')));
        expect(opened!.id, abc.id);
        expect(find.text('Checklist 33% complete'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'dashboard action opens the correct transaction plan and empty states stay honest',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DealRoomsPage(loadTransactionBundles: () async => fixtures),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BuyerCommandCentre), findsOneWidget);
      await tester.ensureVisible(find.text('Upload lender package'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload lender package'));
      await tester.pumpAndSettle();
      expect(find.text('Complete acquisition checklist'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).first,
            )
            .initialValue,
        abc.id,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'affinity.command.last_room.guest',
        ),
        abc.id,
      );
      expect(find.byType(BuyerCommandCentre), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('empty dashboard has no fabricated deals or deadlines', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DealRoomsPage()));
    await tester.pumpAndSettle();
    expect(
      find.text('0 active acquisitions · 0 actions need attention'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No deadlines scheduled. Add dates in a deal’s Transaction Plan.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('continue-acquisition')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
