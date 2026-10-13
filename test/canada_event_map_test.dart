import 'dart:ui' show PointerDeviceKind;
import 'package:dwelling_iq/widgets/canada_event_map.dart';
import 'package:dwelling_iq/services/learning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CanadaMapGeometry geometry;
  setUpAll(() async => geometry = await CanadaMapGeometry.asset);
  LearningSeminar event(
    String id, {
    double lat = 49.3,
    double lon = -123.1,
    String status = 'scheduled',
    String organization = 'Local Chamber',
    String kind = 'meeting',
  }) => LearningSeminar(
    id: id,
    hostId: 'host',
    title: 'Community acquisition meeting $id',
    description: 'Meet the local team',
    startsAt: DateTime.now().add(const Duration(days: 2)),
    duration: 60,
    joinUrl: 'https://example.com/meet',
    websiteUrl: 'https://example.com/company-events',
    status: status,
    organization: organization,
    kind: kind,
    areaName: 'Vancouver, BC',
    latitude: lat,
    longitude: lon,
  );
  test(
    'Canada boundaries contain all provinces and places project consistently',
    () {
      expect((geometry.json['provinces'] as List).length, 13);
      final west = geometry.normalized(49.3, -123.1),
          east = geometry.normalized(45.5, -73.6),
          north = geometry.normalized(69, -105);
      expect(west.dx, lessThan(east.dx));
      expect(north.dy, lessThan(west.dy));
      for (final p in [west, east, north]) {
        expect(p.dx, inInclusiveRange(0, 1));
        expect(p.dy, inInclusiveRange(0, 1));
      }
      expect(
        event('past', status: 'cancelled').visibleOnMap(DateTime.now()),
        false,
      );
      expect(
        event('ended', status: 'ended').visibleOnMap(DateTime.now()),
        false,
      );
    },
  );
  test('cover URL accepts the one-to-one and legacy list relation formats', () {
    final record = {
      'id': 'one',
      'host_id': 'host',
      'title': 'Session',
      'starts_at': '2026-11-01T18:00:00Z',
      'duration_minutes': 60,
      'meeting_url': null,
      'website_url': 'https://example.com/company',
      'status': 'scheduled',
      'event_mode': 'in_person',
      'learning_event_images': {'id': 'cover'},
    };
    final parsed = LearningSeminar.fromJson(record);
    expect(parsed.imageUrl, contains('id=cover'));
    expect(parsed.informationUrl, 'https://example.com/company');
    expect(parsed.canJoin(DateTime.utc(2026, 11, 1, 18)), false);
    record['learning_event_images'] = [
      {'id': 'cover'},
    ];
    expect(LearningSeminar.fromJson(record).imageUrl, contains('id=cover'));
  });
  testWidgets('hovered pin opens the organizer website on click', (
    tester,
  ) async {
    LearningSeminar? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CanadaEventMap(
            events: [event('website')],
            onOpen: (e) => opened = e,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pin = find.byKey(const ValueKey('event-pin-website'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(pin));
    await tester.pumpAndSettle();
    expect(opened, isNull);
    await tester.tap(pin);
    await tester.pump();
    expect(opened?.informationUrl, 'https://example.com/company-events');
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'event points expose hover and tap previews with host/date/time at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final e = event('one');
        LearningSeminar? opened;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CanadaEventMap(events: [e], onOpen: (e) => opened = e),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final pin = find.byKey(const ValueKey('event-pin-one'));
        expect(pin, findsOneWidget);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(pin));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('event-map-preview')), findsOneWidget);
        expect(find.text('Local Chamber'), findsOneWidget);
        expect(find.textContaining('min'), findsOneWidget);
        expect(
          find.text('Times shown in your local time zone'),
          findsOneWidget,
        );
        await mouse.moveTo(
          tester.getCenter(find.byKey(const Key('event-map-preview'))),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const Key('event-map-preview')), findsOneWidget);
        await tester.tap(find.text('Visit website'));
        await tester.pump();
        expect(opened?.id, e.id);
        await tester.tap(pin);
        await tester.pump();
        expect(find.byKey(const Key('event-map-preview')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'overlapping local events form a group and cancelled pins are excluded',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanadaEventMap(
              events: [
                event('one'),
                event('two'),
                event('cancelled', lat: 45.5, lon: -73.6, status: 'cancelled'),
              ],
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-pin-cancelled')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('event-pin-one')));
      await tester.pump();
      expect(find.text('2 local events'), findsOneWidget);
      expect(find.text('Community acquisition meeting one'), findsOneWidget);
      expect(find.text('Community acquisition meeting two'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
