import 'package:dwelling_iq/services/nova_page_guide.dart';
import 'package:dwelling_iq/services/member_network_service.dart';
import 'package:dwelling_iq/services/nova_walkthrough.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'main pages have distinct multi-step guides and stay on the requested page',
    () {
      final firstBodies = <String>{};
      final ids = <String>{};
      for (final page in [
        'resources',
        'comparison',
        'consulting',
        'profile',
        'auth',
        'transaction-rooms',
      ]) {
        final steps = novaPageWalkthrough(page);
        expect(steps.length, greaterThanOrEqualTo(4));
        expect(steps.every((s) => s.destination == page), isTrue);
        expect(
          steps.take(steps.length - 1).every((s) => s.target != null),
          isTrue,
        );
        expect(firstBodies.add(steps.first.body), isTrue);
        for (final step in steps.take(steps.length - 1))
          expect(ids.add(step.id), isTrue);
      }
      expect(
        novaPageWalkthrough('resources').map((s) => s.body).join(' '),
        contains('government'),
      );
      expect(
        novaPageWalkthrough('consulting').map((s) => s.body).join(' '),
        contains('calendar'),
      );
      for (final role in ['buyer', 'seller']) {
        final step = novaWalkthrough(
          role,
        ).singleWhere((s) => s.id == '$role-team');
        expect(step.body, contains('one professional per role'));
        expect(step.body, contains('replacement'));
      }
    },
  );
  test(
    'creator example threads are account restricted and explicitly previews',
    () {
      expect(CreatorMessageExamples.conversationsFor(null), isEmpty);
      expect(
        CreatorMessageExamples.conversationsFor('visitor@example.com'),
        isEmpty,
      );
      final threads = CreatorMessageExamples.conversationsFor(
        'RW0882308@gmail.com',
      );
      expect(threads.length, 3);
      expect(
        threads.every((t) => t.isPreview && t.name.contains('Example')),
        isTrue,
      );
      final content = <String>{};
      for (final thread in threads) {
        final messages = CreatorMessageExamples.messagesFor(
          'rw0882308@gmail.com',
          thread.id,
        );
        expect(messages.length, 3);
        expect(messages.any((m) => m.isMine), isTrue);
        expect(messages.any((m) => !m.isMine), isTrue);
        expect(content.add(messages.first.body), isTrue);
        expect(
          CreatorMessageExamples.messagesFor('visitor@example.com', thread.id),
          isEmpty,
        );
      }
    },
  );
  test(
    'example identifiers never reach live message writes or read updates',
    () async {
      await MemberNetworkService.markRead('creator-example-broker');
      await expectLater(
        MemberNetworkService.sendMessage('creator-example-broker', 'hello'),
        throwsStateError,
      );
      expect(
        await MemberNetworkService.loadMessages('creator-example-broker'),
        isEmpty,
      );
    },
  );
}
