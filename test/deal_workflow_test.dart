import 'package:flutter_test/flutter_test.dart';

import 'package:dwelling_iq/services/deal_room_service.dart';

void main() {
  group('guided deal workflows', () {
    for (final kind in ['residential', 'commercial', 'business']) {
      test('$kind has a complete staged checklist', () {
        final stages = DealRoomService.stagesFor(kind);
        final tasks = DealRoomService.templatesFor(kind);

        expect(stages.first, 'discovery');
        expect(stages.last, 'complete');
        expect(tasks.length, greaterThanOrEqualTo(15));
        expect(tasks.map((task) => task.title).toSet().length, tasks.length);
        expect(tasks.every((task) => stages.contains(task.stage)), isTrue);
        expect(tasks.every((task) => task.details.trim().isNotEmpty), isTrue);
        expect(
          stages.every(
            (stage) =>
                tasks.any((task) => task.stage == stage) || stage == 'complete',
          ),
          isTrue,
        );
      });
    }
  });
}
