import 'package:dwelling_iq/services/nova_page_guide.dart';
import 'package:dwelling_iq/widgets/calculator_help_sidebar.dart';
import 'package:dwelling_iq/models/platform_side.dart';
import 'package:dwelling_iq/services/nova_calculator_fields.dart';
import 'package:dwelling_iq/widgets/nova_target.dart';
import 'package:dwelling_iq/widgets/buyer_deal_screen.dart';
import 'package:dwelling_iq/screens/seller_dashboard_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:dwelling_iq/services/nova_training_service.dart';
import 'package:dwelling_iq/services/nova_training_controller.dart';
import 'package:dwelling_iq/services/nova_walkthrough.dart';
import 'package:dwelling_iq/widgets/nova_training_host.dart';
import 'package:dwelling_iq/widgets/nova_character.dart';
import 'package:dwelling_iq/screens/deal_rooms_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'completion survives another device and replay preserves completion',
    () async {
      Map<String, dynamic>? cloud;
      final service = NovaTrainingService(
        accountId: () => 'account-a',
        readProfile: (_) async => cloud,
        writeProfile: (_, value) async => cloud = value,
      );
      await service.load();
      expect(service.progress.completed, isFalse);
      await service.save(role: 'seller', step: 15, finish: true);
      expect(cloud!['completed_at'], isNotNull);
      expect(service.profileSaved, isTrue);
      SharedPreferences.setMockInitialValues({});
      final anotherDevice = NovaTrainingService(
        accountId: () => 'account-a',
        readProfile: (_) async => cloud,
        writeProfile: (_, value) async => cloud = value,
      );
      await anotherDevice.load();
      expect(anotherDevice.progress.completed, isTrue);
      final controller = NovaTrainingController(service: anotherDevice);
      controller.start(role: 'seller');
      expect(controller.index, 0);
      expect(controller.active, isTrue);
      await controller.next();
      expect(anotherDevice.progress.completed, isTrue);
    },
  );
  test(
    'failed profile save is cached and retried without claiming cloud success',
    () async {
      bool offline = true;
      Map<String, dynamic>? cloud;
      final service = NovaTrainingService(
        accountId: () => 'account-a',
        readProfile: (_) async => cloud,
        writeProfile: (_, value) async {
          if (offline) throw StateError('offline');
          cloud = value;
        },
      );
      await service.load();
      expect(
        await service.save(role: 'buyer', step: 15, finish: true),
        isFalse,
      );
      expect(service.progress.completed, isTrue);
      expect(service.progress.pendingSync, isTrue);
      expect(service.profileSaved, isFalse);
      offline = false;
      await service.load();
      expect(service.profileSaved, isTrue);
      expect(service.progress.pendingSync, isFalse);
      expect(cloud!['completed_at'], isNotNull);
    },
  );
  test(
    'account changes do not copy completion or late responses to another profile',
    () async {
      String account = 'account-a';
      final write = Completer<void>();
      final writes = <String>[];
      final service = NovaTrainingService(
        accountId: () => account,
        readProfile: (_) async => null,
        writeProfile: (id, _) async {
          writes.add(id);
          await write.future;
        },
      );
      await service.load();
      final saving = service.save(role: 'buyer', step: 15, finish: true);
      await Future<void>.delayed(Duration.zero);
      account = 'account-b';
      await service.load();
      write.complete();
      await saving;
      expect(service.scope, 'account-b');
      expect(service.progress.completed, isFalse);
      expect(writes, ['account-a']);
    },
  );
  test('pause is not completion and can resume the saved step', () async {
    final service = NovaTrainingService(accountId: () => null);
    await service.load();
    final controller = NovaTrainingController(service: service);
    controller.start(role: 'member');
    await controller.next();
    controller.pause();
    expect(service.progress.completed, isFalse);
    final reopened = NovaTrainingService(accountId: () => null);
    await reopened.load();
    final resumed = NovaTrainingController(service: reopened);
    resumed.start(role: reopened.progress.role, replay: false);
    expect(resumed.role, 'member');
    expect(resumed.index, 1);
  });
  test(
    'all app paths include room, documents, privacy and the six supplied moods',
    () {
      final moods = <NovaMood>{};
      for (final role in ['buyer', 'seller', 'member']) {
        final steps = novaWalkthrough(role);
        expect(steps.map((s) => s.id).toSet().length, steps.length);
        expect(steps.any((s) => s.destination == 'room/documents'), isTrue);
        expect(steps.any((s) => s.destination == 'room/privacy'), isTrue);
        expect(steps.last.id, 'finish');
        moods.addAll(steps.map((s) => s.mood));
      }
      expect(moods, NovaMood.values.toSet());
    },
  );
  test(
    'expanded courses explain every actual input, each result and every pipeline stage',
    () {
      for (final role in ['buyer', 'seller']) {
        final steps = novaWalkthrough(role);
        final fields = role == 'buyer'
            ? novaBuyerCalculatorFields
            : novaSellerCalculatorFields;
        expect(
          steps.where((s) => s.id.startsWith('$role-input-')).length,
          fields.length,
        );
        for (final field in fields) {
          final step = steps.singleWhere(
            (s) => s.target == '$role.calc.${field.key}',
          );
          expect(step.body, contains(field.help));
          expect(step.body, contains(field.example));
        }
        expect(steps.where((s) => s.id.startsWith('$role-result-')).length, 3);
        for (var i = 0; i < 4; i++) {
          expect(steps.any((s) => s.target == '$role.home.stage.$i'), isTrue);
          expect(steps.any((s) => s.target == '$role.home.metric.$i'), isTrue);
        }
      }
    },
  );
  test(
    'floating guide stays in view and avoids a highlighted field on both sizes',
    () {
      for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
        final guide = Size(size.width < 650 ? size.width - 24 : 470, 310);
        final target = Rect.fromLTWH(20, 180, size.width - 40, 80);
        final position = novaGuidePosition(
          size,
          guide,
          target,
          EdgeInsets.zero,
        );
        final rect = position & guide;
        expect(rect.left, greaterThanOrEqualTo(12));
        expect(rect.right, lessThanOrEqualTo(size.width - 12));
        expect(rect.top, greaterThanOrEqualTo(12));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 12));
        expect(rect.overlaps(target), isFalse);
      }
    },
  );
  testWidgets(
    'all buyer tabs expose every field to Pebble without filling examples',
    (tester) async {
      for (final mode in BuyerScreenMode.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BuyerDealScreen(
                key: ValueKey(mode),
                initialMode: mode,
                onBack: () {},
                onCreateBusinessRoom: (_, _) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fields = novaBuyerCalculatorFields
            .where((f) => f.mode == mode.name)
            .toList();
        final rendered = tester.widgetList<TextField>(find.byType(TextField));
        expect(
          rendered.map((f) => (f.key as ValueKey).value).toSet(),
          fields.map((f) => 'field_${f.key}').toSet(),
        );
        for (final field in fields) {
          expect(NovaTarget.contextFor('buyer.calc.${field.key}'), isNotNull);
        }
        expect(rendered.every((f) => f.controller!.text.isEmpty), isTrue);
        expect(
          NovaTarget.contextFor('buyer.calc.${mode.name}.results'),
          isNotNull,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'all seller input and result targets match the actual calculator page',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SellerDashboardPage(initialView: SellerDashboardView.value),
        ),
      );
      await tester.pumpAndSettle();
      final rendered = tester.widgetList<TextField>(find.byType(TextField));
      expect(
        rendered.map((f) => (f.key as ValueKey).value).toSet(),
        novaSellerCalculatorFields.map((f) => 'seller_${f.key}').toSet(),
      );
      for (final field in novaSellerCalculatorFields) {
        expect(NovaTarget.contextFor('seller.calc.${field.key}'), isNotNull);
      }
      for (var i = 1; i <= 3; i++) {
        expect(NovaTarget.contextFor('seller.calc.result.$i'), isNotNull);
      }
      expect(rendered.every((f) => f.controller!.text.isEmpty), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  for (final role in ['buyer', 'seller']) {
    testWidgets(
      '$role home exposes each metric, pipeline column and start control',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: role == 'buyer'
                ? const DealRoomsPage(initialSide: PlatformSide.business)
                : const SellerDashboardPage(),
          ),
        );
        await tester.pumpAndSettle();
        for (final step in novaDashboardSteps(role)) {
          expect(
            NovaTarget.contextFor(step.target!),
            isNotNull,
            reason: step.id,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Pebble scrolls to a deep field and keeps its character outside the bubble',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<NavigatorState>();
      final controller = NovaTrainingController(
        service: NovaTrainingService(accountId: () => null),
      );
      await controller.service.load();
      final index = novaWalkthrough(
        'buyer',
      ).indexWhere((s) => s.target == 'buyer.calc.businessYears');
      await controller.service.save(role: 'buyer', step: index);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: key,
            controller: controller,
            autoStart: false,
            pageBuilder: (_) => Scaffold(
              body: BuyerDealScreen(
                onBack: () {},
                onCreateBusinessRoom: (_, _) async {},
              ),
            ),
            child: child!,
          ),
          home: const Scaffold(),
        ),
      );
      await tester.pumpAndSettle();
      controller.start(role: 'buyer', replay: false);
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(const Key('field_businessYears')));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThan(844));
      final character = find.descendant(
        of: find.byType(NovaTourCard),
        matching: find.byType(NovaCharacter),
      );
      expect(
        find.ancestor(of: character, matching: find.byType(Material)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'calculator methods cover every buyer and seller input with field-specific guidance',
    () {
      for (final field in novaBuyerCalculatorFields) {
        final info = calculatorHelpFor(field.key);
        expect(info.how, isNotEmpty);
        expect(info.field, same(field));
      }
      for (final field in novaSellerCalculatorFields) {
        expect(calculatorHelpFor(field.key, seller: true).how, isNotEmpty);
      }
      expect(calculatorHelpFor('creCap').how, contains('NOI'));
      expect(calculatorHelpFor('businessDown').how, contains('× 100'));
      expect(
        calculatorHelpFor('businessEbitda').how,
        isNot(calculatorHelpFor('assetInventory').how),
      );
    },
  );
  test('page guides contain only their page and keep calculators short', () {
    for (final page in [
      'buyer/home',
      'seller/home',
      'buyer/dealScreen/assets',
      'seller/value',
      'consulting',
      'resources',
      'room/documents',
    ]) {
      final steps = novaPageWalkthrough(page);
      expect(steps.every((s) => s.destination == page), isTrue, reason: page);
      expect(steps.any((s) => s.id.contains('-input-')), isFalse);
    }
    expect(novaPageWalkthrough('buyer/dealScreen/business').length, 4);
    expect(novaPageWalkthrough('seller/value').length, 4);
  });
  test(
    'page replay preserves existing completion and profile progress',
    () async {
      final service = NovaTrainingService(accountId: () => null);
      await service.load();
      await service.save(role: 'seller', step: 18, finish: true);
      final original = service.progress.toJson();
      final controller = NovaTrainingController(service: service);
      controller.startPage('consulting');
      while (controller.active) {
        await controller.next();
      }
      expect(service.progress.toJson(), original);
      expect(controller.pageOnly, isTrue);
    },
  );
  testWidgets(
    'page guide stays on its original route and records first completion',
    (tester) async {
      final controller = NovaTrainingController(
        service: NovaTrainingService(accountId: () => null),
      );
      await controller.service.load();
      final key = GlobalKey<NavigatorState>();
      int pageChanges = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: key,
            controller: controller,
            autoStart: false,
            pageBuilder: (_) {
              pageChanges++;
              return const Scaffold(body: Text('Wrong page'));
            },
            child: child!,
          ),
          home: const Scaffold(body: Text('Stay on consulting')),
        ),
      );
      await tester.pumpAndSettle();
      controller.startPage('consulting');
      await tester.pumpAndSettle();
      expect(find.text('Stay on consulting'), findsOneWidget);
      while (controller.index < controller.steps.length - 1) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(pageChanges, 0);
      expect(find.text('Stay on consulting'), findsOneWidget);
      expect(controller.service.progress.completed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'info clicks open and switch sidebar content without changing typed figures',
    (tester) async {
      addTearDown(CalculatorHelpController.instance.close);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => CalculatorHelpHost(child: child!),
          home: Scaffold(
            body: BuyerDealScreen(
              onBack: () {},
              onCreateBusinessRoom: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('field_businessAsk')),
        '1,234,567',
      );
      await tester.tap(find.byKey(const Key('info_businessAsk')));
      await tester.pumpAndSettle();
      expect(find.text('What is it?'), findsOneWidget);
      expect(find.text('How to calculate it'), findsOneWidget);
      expect(CalculatorHelpController.instance.info!.field.key, 'businessAsk');
      await tester.tap(find.byKey(const Key('calculator_help_close')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('info_businessRevenue')));
      await tester.tap(find.byKey(const Key('info_businessRevenue')));
      await tester.pumpAndSettle();
      expect(
        CalculatorHelpController.instance.info!.field.key,
        'businessRevenue',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('field_businessAsk')))
            .controller!
            .text,
        '1,234,567',
      );
      expect(find.byType(NovaTourCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets('click-through tour, completion and replay fit $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<NavigatorState>();
      final controller = NovaTrainingController(
        service: NovaTrainingService(accountId: () => null),
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: key,
            controller: controller,
            autoStart: false,
            pageBuilder: (step) =>
                Scaffold(body: Text('Real route: ${step.destination}')),
            child: child!,
          ),
          home: const Scaffold(body: Text('Original page')),
        ),
      );
      await tester.pumpAndSettle();
      controller.start(role: 'buyer');
      await tester.pumpAndSettle();
      expect(find.byType(NovaCharacter), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NovaTourCard),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Real route: buyer/home'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(controller.index, 0);
      for (var i = 0; i < controller.steps.length - 1; i++) {
        await tester.ensureVisible(find.text('Next'));
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Finish training'));
      await tester.tap(find.text('Finish training'));
      await tester.pumpAndSettle();
      expect(controller.service.progress.completed, isTrue);
      expect(find.byType(NovaTourCard), findsNothing);
      controller.start(role: 'seller');
      await tester.pumpAndSettle();
      expect(find.byType(NovaTourCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'a completed profile prevents automatic welcome on a fresh device',
    (tester) async {
      final cloud = Completer<Map<String, dynamic>?>();
      final controller = NovaTrainingController(
        service: NovaTrainingService(
          accountId: () => 'account-a',
          readProfile: (_) => cloud.future,
          writeProfile: (_, _) async {},
        ),
      );
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          builder: (_, child) => NovaTrainingHost(
            navigatorKey: key,
            controller: controller,
            child: child!,
          ),
          home: const Scaffold(body: Text('Home')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NovaTourCard), findsNothing);
      cloud.complete({
        'role': 'buyer',
        'step': 15,
        'completed_at': '2026-10-05T10:00:00Z',
      });
      await tester.pumpAndSettle();
      expect(controller.active, isFalse);
      expect(find.byType(NovaTourCard), findsNothing);
    },
  );
  testWidgets('first load automatically introduces Pebble', (tester) async {
    final controller = NovaTrainingController(
      service: NovaTrainingService(accountId: () => null),
    );
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        builder: (_, child) => NovaTrainingHost(
          navigatorKey: key,
          controller: controller,
          child: child!,
        ),
        home: const Scaffold(body: Text('Landing')),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.active, isTrue);
    expect(find.text('Hi, I’m Pebble.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nova_pause')));
    await tester.pumpAndSettle();
    expect(controller.service.progress.completed, isFalse);
  });
  for (final view in [
    'overview',
    'financials',
    'plan',
    'documents',
    'privacy',
  ]) {
    testWidgets(
      'fictional room safely renders $view without changing recent deal',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'affinity.command.last_room.guest': 'actual-deal',
        });
        await tester.pumpWidget(
          MaterialApp(
            home: DealRoomPage(
              room: novaExampleBundle.room,
              trainingPreview: true,
              initialWorkspace: view,
              loadBundle: () async => novaExampleBundle,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          (await SharedPreferences.getInstance()).getString(
            'affinity.command.last_room.guest',
          ),
          'actual-deal',
        );
        expect(find.textContaining('Evergreen Services'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
