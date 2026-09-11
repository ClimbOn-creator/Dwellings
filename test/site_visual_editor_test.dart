import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dwelling_iq/services/site_content_service.dart';
import 'package:dwelling_iq/widgets/site_text.dart';
import 'package:dwelling_iq/widgets/site_inline_editor.dart';
import 'package:dwelling_iq/widgets/site_image.dart';

void main() {
  setUp(() => SiteContentService.editing.value = false);
  tearDown(() => SiteContentService.editing.value = false);

  testWidgets(
    'normal controls work; edit mode selects text without navigating',
    (tester) async {
      var navigations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () => navigations++,
              child: const SiteText(
                'Start here',
                contentKey: 'copy.test.start',
                literal: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start here'));
      expect(navigations, 1);
      SiteContentService.editing.value = true;
      await tester.pump();
      await tester.tap(find.text('Start here'));
      await tester.pumpAndSettle();
      expect(navigations, 1);
      expect(find.text('Selected text'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Completely rewritten text\nSecond line',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Start here'), findsOneWidget);
      expect(SiteContentService.published('copy.test.start'), isNull);
    },
  );

  testWidgets('failed save retains draft and never publishes local success', (
    tester,
  ) async {
    SiteContentService.editing.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SiteText(
            'Original',
            contentKey: 'copy.test.failure',
            literal: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep my draft');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep my draft',
    );
    expect(SiteContentService.published('copy.test.failure'), isNull);
  });

  testWidgets('private dynamic records are not website copy', (tester) async {
    SiteContentService.editing.value = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SiteText(
            'Private customer message 91372',
            contentKey: 'copy.test.private',
          ),
        ),
      ),
    );
    expect(find.byType(SiteEditTarget), findsNothing);
    expect(find.text('Private customer message 91372'), findsOneWidget);
  });

  testWidgets('pictures open replacement editor with upload and cancel', (
    tester,
  ) async {
    SiteContentService.editing.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SiteImage(
            contentKey: 'image.test.photo',
            original: Image.asset(
              'assets/brand/affinity-logo.png',
              width: 150,
              height: 80,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SiteImage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Upload a picture'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(SiteImage), findsOneWidget);
  });

  testWidgets('background control preserves foreground edit targets', (
    tester,
  ) async {
    SiteContentService.editing.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SiteBackground(
            contentKey: 'image.test.background',
            original: Container(
              padding: const EdgeInsets.all(60),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/brand/affinity-logo.png'),
                ),
              ),
              child: const SiteText(
                'Foreground',
                contentKey: 'copy.test.foreground',
                literal: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit background'), findsOneWidget);
    await tester.tap(find.text('Foreground'));
    await tester.pumpAndSettle();
    expect(find.text('Selected text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'template editing never puts account values in the public draft',
    (tester) async {
      SiteContentService.editing.value = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiteText(
              'Welcome, {{value1}}',
              contentKey: 'copy.test.template',
              templateValues: {'value1': 'Private account name'},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Welcome, Private account name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Welcome, {{value1}}',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  test('uploads reject disguised and oversized files', () {
    expect(
      () => SiteContentService.validateImage(
        Uint8List.fromList(List.filled(20, 65)),
        'png',
      ),
      throwsArgumentError,
    );
    expect(
      () => SiteContentService.validateImage(
        Uint8List(10 * 1024 * 1024 + 1),
        'jpg',
      ),
      throwsArgumentError,
    );
    final png = Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      0,
    ]);
    expect(() => SiteContentService.validateImage(png, 'png'), returnsNormally);
    expect(
      () => SiteContentService.validateImage(png, 'jpg'),
      throwsArgumentError,
    );
  });
}
