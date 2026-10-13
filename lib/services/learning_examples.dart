import 'learning_service.dart';

// Illustrative cards only: never inserted into the live database.
class LearningExamples {
  static const titles = [
    'Buying your first business',
    'Financing an acquisition',
    'Planning a family succession',
    'Preparing an ownership transfer',
  ];
  static const bodies = [
    'Start with the kind of business you want to run. This example walks through a buyer’s criteria, a first conversation with an owner, and the questions to collect before reviewing an opportunity.',
    'See how a sample acquisition brings together a buyer’s contribution, lender financing and a working-capital reserve. The session explores the questions to ask about cash flow and repayment.',
    'A sample family business is preparing for its next chapter. Explore how the owner and successor can agree on responsibilities, timing and the support needed during a handover.',
    'Follow a sample transfer from the first discussion to the handover checklist. The example covers documents, team introductions and the practical steps to keep the business running.',
  ];
  static const areas = [
    'Victoria, BC',
    'Calgary, AB',
    'Toronto, ON',
    'Montréal, QC',
  ];
  static const topics = ['buyer', 'finance', 'seller', 'legal'];
  static const kinds = ['seminar', 'workshop', 'meeting', 'information'];
  static const modes = ['online', 'hybrid', 'in_person', 'online'];
  static const positions = [
    (48.4, -123.4),
    (51.0, -114.1),
    (43.7, -79.4),
    (45.5, -73.6),
  ];
  static List<LearningPost> get posts => [
    for (var i = 0; i < 4; i++)
      LearningPost(
        id: 'learning-example-$i',
        authorId: 'example',
        author: 'Affinity examples',
        title: titles[i],
        body: bodies[i],
        topic: topics[i],
        areaName: areas[i],
        createdAt: DateTime.now().subtract(Duration(days: i)),
        exampleIndex: i,
      ),
  ];
  static List<LearningSeminar> get events {
    final today = DateTime.now().toUtc();
    return [
      for (var i = 0; i < 4; i++)
        LearningSeminar(
          id: 'learning-example-event-$i',
          hostId: 'example',
          title: titles[i],
          description: bodies[i],
          organization: 'Affinity examples',
          startsAt: DateTime.utc(
            today.year,
            today.month,
            today.day + 7 + i * 2,
            18 + i,
          ).toLocal(),
          duration: 60,
          joinUrl: '',
          websiteUrl: 'https://example.com/#affinity-example-${i + 1}',
          kind: kinds[i],
          mode: modes[i],
          areaName: areas[i],
          latitude: positions[i].$1,
          longitude: positions[i].$2,
          venue: modes[i] == 'online' ? '' : 'Example community venue',
          exampleIndex: i,
        ),
    ];
  }
}
