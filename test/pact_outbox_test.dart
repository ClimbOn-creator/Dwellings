import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dwelling_iq/services/pact_messaging_service.dart';

class FakeMessaging extends PactMessagingService {
  bool fail = true;
  final List<MessageRow> sends = [];
  @override
  Future<dynamic> call(String action, [MessageRow payload = const {}]) async {
    sends.add(Map.of(payload));
    if (fail) throw StateError('Network failed after commit');
    return payload;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'retry after process restart preserves the exact message id and body',
    () async {
      final api = FakeMessaging();
      final first = PactOutbox('user-a', api, isCurrentUser: () => true);
      await first.enqueue('thread-a', 'Hello');
      await first.flush();
      expect(first.pending.single['failed'], true);
      final id = first.pending.single['id'];
      first.dispose();
      final second = PactOutbox('user-a', api, isCurrentUser: () => true);
      await second.restore();
      expect(second.pending.single['id'], id);
      api.fail = false;
      await second.flush();
      expect(api.sends.length, 2);
      expect(api.sends.first, api.sends.last);
      expect(second.pending, isEmpty);
      second.dispose();
    },
  );
  test('another account cannot restore or send this account outbox', () async {
    final api = FakeMessaging();
    var current = true;
    final a = PactOutbox('a', api, isCurrentUser: () => current);
    await a.enqueue('room', 'Private draft');
    final b = PactOutbox('b', api, isCurrentUser: () => true);
    await b.restore();
    expect(b.pending, isEmpty);
    current = false;
    await a.flush();
    expect(api.sends, isEmpty);
    a.dispose();
    b.dispose();
  });
  test(
    'restart before first send exposes retry and committed history clears the pending copy',
    () async {
      final api = FakeMessaging();
      final first = PactOutbox('user-a', api, isCurrentUser: () => true);
      await first.enqueue('thread-a', 'Saved before crash');
      final id = first.pending.single['id'] as String;
      first.dispose();
      final resumed = PactOutbox('user-a', api, isCurrentUser: () => true);
      await resumed.restore();
      expect(resumed.pending.single['failed'], true);
      await resumed.reconcile([id]);
      expect(resumed.pending, isEmpty);
      expect(api.sends, isEmpty);
      resumed.dispose();
    },
  );
}
