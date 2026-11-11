// These slot IDs remain stable when the activity wording changes.
const learningCreativeCopy = <String, String>{
  'learning.creative.roadmap.intro':
      'Follow Alex from a first idea to the keys to Maple Street. Scroll to walk the trail, clear the mist and discover each stop.',
  'learning.creative.roadmap.activity': 'The Trail',
  'learning.creative.roadmap.reading': 'The route in words',
  'learning.creative.roadmap.progress': '{{value0}} of 8 landmarks reached',
  'learning.creative.roadmap.finish':
      'You can see the route now. Next, find out which kind of Saturday you want.',
  'learning.creative.roadmap.alex': 'Alex',
  'learning.creative.discover.activity': 'Two Saturdays',
  'learning.creative.discover.intro':
      'Same Alex. Same Maple Street Laundromat. Two very different weekends. Pick a role, make a few decisions and see how the day unfolds.',
  'learning.creative.discover.operator.caption': 'At the shop',
  'learning.creative.discover.shopSign': 'MAPLE STREET',
  'learning.creative.discover.investor.caption': 'Overseeing a team',
  'learning.creative.discover.operator.pick': 'Try the owner-operator Saturday',
  'learning.creative.discover.investor.pick': 'Try the investor Saturday',
  'learning.creative.discover.operator.day': 'Alex’s owner-operator Saturday',
  'learning.creative.discover.investor.day': 'Alex’s investor Saturday',
  'learning.creative.discover.operator.scene.0':
      'The doors open. One machine is out of service, and an attendant asks Alex what to do.',
  'learning.creative.discover.operator.scene.1':
      'It is lunchtime. The morning has been busy, and the next shift needs a handover.',
  'learning.creative.discover.operator.scene.2':
      'The shop is closing. A supplier needs a decision about a repair booking for next week.',
  'learning.creative.discover.investor.scene.0':
      'Alex is at home. The manager reports a machine fault and asks who can approve the repair.',
  'learning.creative.discover.investor.scene.1':
      'The manager sends a midday update. One employee has called in sick.',
  'learning.creative.discover.investor.scene.2':
      'Alex gets the weekly report. Revenue looks steady, but repair costs are rising.',
  'learning.creative.discover.choice.0.0': 'Handle the problem in person',
  'learning.creative.discover.choice.0.1': 'Use the team’s agreed process',
  'learning.creative.discover.choice.1.0': 'Cover the shift yourself',
  'learning.creative.discover.choice.1.1': 'Ask the manager to arrange cover',
  'learning.creative.discover.choice.2.0': 'Work through the details yourself',
  'learning.creative.discover.choice.2.1': 'Review a plan with the manager',
  'learning.creative.discover.outcome.0.0':
      'Alex gets close to the problem and learns how the shop works. That also means the business needs Alex’s time and availability. Ask how often these calls happen.',
  'learning.creative.discover.outcome.0.1':
      'The team can act when responsibilities, authority and repair contacts are clear. Ask whether those systems already exist and what they cost to maintain.',
  'learning.creative.discover.outcome.1.0':
      'Alex keeps the shift covered by doing the work. Consider whether that kind of interruption fits the life you want and how often it would be sustainable.',
  'learning.creative.discover.outcome.1.1':
      'Delegating needs a capable manager, a backup plan and enough staffing. Ask whether the business can support those costs when you assess its earnings.',
  'learning.creative.discover.outcome.2.0':
      'Alex builds detailed operating knowledge and spends more time on the business. That can suit someone who enjoys the daily work and has room for it.',
  'learning.creative.discover.outcome.2.1':
      'Alex stays responsible for the decision while asking the manager to prepare options. Oversight still takes attention, information and a capable team.',
  'learning.creative.discover.nextMoment': 'See the next moment',
  'learning.creative.discover.resultButton': 'See your owner type',
  'learning.creative.discover.result.operator':
      'Your choices lean owner-operator',
  'learning.creative.discover.result.investor': 'Your choices lean investor',
  'learning.creative.discover.result.operatorBody':
      'You often chose to get involved yourself. Explore the daily work, opening hours and the knowledge you would need to take over. Your preferred role gives your search a useful starting point.',
  'learning.creative.discover.result.investorBody':
      'You often chose to work through a team. Explore management capability, reporting and the full cost of delegation. An investor still needs to understand and oversee the business.',
  'learning.creative.discover.result.note':
      'This reflects three fictional decisions. First-time buyers can take either role. Use it to start a conversation about the work you want to do.',
  'learning.creative.discover.restart': 'Try the other Saturday',
  'learning.creative.discover.reading': 'Before you choose ownership',
  'learning.creative.search.activity': 'Swipe the listings',
  'learning.creative.search.intro':
      'Five fictional businesses. Make a first call, then turn the card over. A green flag earns another look. A red flag earns a question.',
  'learning.creative.search.instructions':
      'Swipe right for a green flag or left for a red flag. You can also use the buttons or your arrow keys.',
  'learning.creative.search.red': 'Red flag',
  'learning.creative.search.green': 'Green flag',
  'learning.creative.search.counter': 'Listing {{value0}} of 5',
  'learning.creative.search.feedback.match': 'You spotted the teaching clue',
  'learning.creative.search.feedback.missed': 'Here is the clue to revisit',
  'learning.creative.search.feedback.question': 'Turn it into a question',
  'learning.creative.search.next': 'Next listing',
  'learning.creative.search.finish': 'See your field notes',
  'learning.creative.search.score':
      'You spotted {{value0}} of 5 teaching clues',
  'learning.creative.search.complete':
      'Your instincts have something to work with.',
  'learning.creative.search.summary':
      'These were first impressions of invented listings. The next step is to check fit and ask for evidence. Revisit any card to compare your first call with the explanation.',
  'learning.creative.search.restart': 'Try the five listings again',
  'learning.creative.search.reading': 'Field Notes',
  'learning.creative.search.fictional': 'Fictional listing',
  'learning.creative.search.maple.title': 'Maple Street Laundromat',
  'learning.creative.search.maple.category': 'Neighbourhood services',
  'learning.creative.search.maple.pitch':
      'Turnkey operation. Strong cash flow. Loyal customers. Owner retiring. A simple business with room to grow.',
  'learning.creative.search.maple.clue':
      '“Turnkey” does not explain who does the work. The listing gives no owner hours, staffing plan or evidence behind cash flow. The gap is worth investigating.',
  'learning.creative.search.maple.question':
      'What does the owner do in a typical week, who takes over those tasks, and which records support the cash-flow claim?',
  'learning.creative.search.cedar.title': 'Cedar Cycle Repair',
  'learning.creative.search.cedar.category': 'Repair and retail',
  'learning.creative.search.cedar.pitch':
      'A trained lead mechanic and documented service routines. Three years of trading records are available. Lease terms and the proposed handover can be reviewed.',
  'learning.creative.search.cedar.clue':
      'The listing offers specific information you can investigate. The team, records and handover are promising starting points. You still need to check the details and your own fit.',
  'learning.creative.search.cedar.question':
      'Will the lead mechanic stay, what do the records show, and which lease or transfer conditions need approval?',
  'learning.creative.search.riverside.title': 'Riverside Café',
  'learning.creative.search.riverside.category': 'Food and hospitality',
  'learning.creative.search.riverside.pitch':
      'A busy café with a large catering account. One nearby office supplies 60% of revenue. The catering agreement is renewed each year.',
  'learning.creative.search.riverside.clue':
      'One customer supplies most of the revenue. A change in that relationship could affect the business substantially. The size and renewal of that account deserve close attention.',
  'learning.creative.search.riverside.question':
      'How secure is the catering relationship, can it transfer, and what would the business look like without that account?',
  'learning.creative.search.harbour.title': 'Harbour Cleaning',
  'learning.creative.search.harbour.category': 'Commercial services',
  'learning.creative.search.harbour.pitch':
      'A working supervisor, written team routines and a spread of small customer contracts. No customer accounts for more than 8% of sales. Supervisor pay is included in reported costs.',
  'learning.creative.search.harbour.clue':
      'The listing addresses both customer concentration and the cost of management. Those details give you useful evidence requests and something to compare with your desired role.',
  'learning.creative.search.harbour.question':
      'Do records confirm the customer mix and supervisor cost, and will the team and customer agreements continue after a sale?',
  'learning.creative.search.spruce.title': 'Spruce Garden Centre',
  'learning.creative.search.spruce.category': 'Seasonal retail',
  'learning.creative.search.spruce.pitch':
      'Excellent lifestyle business. The owner works 50 hours a week during the season without a salary in the reported costs. Several major pieces of equipment will soon need replacement.',
  'learning.creative.search.spruce.clue':
      'The lifestyle claim leaves out the owner’s time and upcoming equipment needs. Compare the real workload and total cash needs with your skills, money and lifestyle limits.',
  'learning.creative.search.spruce.question':
      'What would it cost to replace the owner’s work and the equipment, and how does cash move through the slower months?',
  'learning.creative.shared.more': 'More lesson notes',
  'learning.creative.shared.try': 'Try the activity',
  'learning.creative.shared.watch': 'Video and story',
  'learning.creative.shared.read': 'Read the notes',
  'learning.creative.shared.videoDuration': '60–90 sec',
  'learning.creative.shared.terms': 'Tap a term to unpack it',
};

const creativeListings = [
  (id: 'maple', green: false),
  (id: 'cedar', green: true),
  (id: 'riverside', green: false),
  (id: 'harbour', green: true),
  (id: 'spruce', green: false),
];
