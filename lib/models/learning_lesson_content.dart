// Permanent copy IDs for the Learning lessons. Keep IDs when revising defaults.
const learningLessonCopy = <String, String>{
  'learning.lesson.shared.goals': 'By the end of this, you’ll be able to…',
  'learning.lesson.shared.core': 'The core idea',
  'learning.lesson.shared.example': 'A worked example',
  'learning.lesson.shared.mistakes': 'Common mistakes',
  'learning.lesson.shared.check': 'Check yourself',
  'learning.lesson.shared.takeaways': 'Key takeaways',
  'learning.lesson.shared.video': 'Video lesson',
  'learning.lesson.shared.recording': 'Recording coming soon',
  'learning.lesson.shared.videoNote':
      'Explore the chapters and read the story below while the video is being prepared.',
  'learning.lesson.shared.chapters': 'Chapters',
  'learning.lesson.shared.transcript': 'Read the story',
  'learning.lesson.shared.terms': 'Key terms',
  'learning.lesson.shared.reveal': 'Explore the explanation',
  'learning.lesson.shared.fictional': 'Fictional learning example',
  'learning.lesson.shared.studyTime':
      'Approximate reading times. Move between lessons at your own pace.',
  'learning.lesson.roadmap.eyebrow': 'Lesson 1 of 9 · Roadmap',
  'learning.lesson.roadmap.subtitle': 'See the path to business ownership.',
  'learning.lesson.roadmap.readTime': 'About 6 minutes',
  'learning.lesson.roadmap.goal.0':
      'Recognize the stages between your first idea and taking over a business.',
  'learning.lesson.roadmap.goal.1':
      'Understand which questions belong at each stage.',
  'learning.lesson.roadmap.goal.2':
      'Choose a useful next lesson and set a realistic pace.',
  'learning.lesson.roadmap.core':
      'Think of buying a business as a route with checkpoints. Each checkpoint gives you more information before you commit more time or money. You may revisit an earlier step when new information changes the picture.',
  'learning.lesson.roadmap.exampleTitle':
      'Follow Maple Street from an idea to a handover',
  'learning.lesson.roadmap.exampleIntro':
      'Alex is considering Maple Street Laundromat. First, Alex decides whether ownership fits their life. Then they learn what to ask, what evidence to request, and how a handover could work. Use this syllabus to follow the same questions.',
  'learning.lesson.roadmap.timingTitle': 'Allow time for the real purchase',
  'learning.lesson.roadmap.timing':
      'BDC says an acquisition can take at least six months from deciding to pursue it through closing. Finding a suitable business can extend the process. Reviewing records, arranging financing and agreeing on terms can overlap. A pause, a revised offer or walking away can be a sensible result of learning more.',
  'learning.lesson.roadmap.stages': 'The checkpoints in a real purchase',
  'learning.lesson.roadmap.mistake.0':
      'Treating an asking price as the only decision. Fit, evidence, funding and the handover each deserve their own attention.',
  'learning.lesson.roadmap.mistake.1':
      'Expecting every deal to follow the same schedule. Missing records and approvals can change the pace.',
  'learning.lesson.roadmap.mistake.2':
      'Treating progress as a promise to buy. Each stage should help you decide whether to continue.',
  'learning.lesson.roadmap.question.0':
      'Alex likes the asking price. What else should they learn before making a commitment?',
  'learning.lesson.roadmap.answer.0':
      'Alex can first consider personal fit, the owner’s role and the evidence behind the listing. A price only becomes meaningful when you understand the business and the obligations that come with it.',
  'learning.lesson.roadmap.question.1':
      'The seller cannot provide an important record yet. What might Alex do next?',
  'learning.lesson.roadmap.answer.1':
      'Ask what is missing and when it can be supplied. Revisit the timetable and assumptions with the appropriate advisers. A checkpoint can lead to more questions, a pause or a decision to stop.',
  'learning.lesson.roadmap.takeaway.0':
      'Build understanding in stages and revisit earlier assumptions as evidence improves.',
  'learning.lesson.roadmap.takeaway.1':
      'Use the lessons in order or jump to the question you need to answer now.',
  'learning.lesson.roadmap.next': 'Next lesson · Discover',
  'learning.lesson.roadmap.chapter.0': 'Why the journey has checkpoints',
  'learning.lesson.roadmap.chapter.1': 'Maple Street’s path to ownership',
  'learning.lesson.roadmap.chapter.2': 'Give yourself room to pause',
  'learning.lesson.roadmap.story':
      'Alex sees a laundromat for sale and imagines getting the keys. The useful first move is to slow down and understand the journey. Alex explores whether the work fits, compares opportunities and asks for evidence. Specialists help investigate the records and the terms. A funding plan and a handover plan develop alongside that work. Some questions send Alex back to an earlier step. By closing, the goal is to understand what is being bought, how it will be paid for and what happens on the first day of ownership.',
  'learning.lesson.roadmap.term.0': 'Acquisition',
  'learning.lesson.roadmap.definition.0':
      'Buying an existing business or its assets.',
  'learning.lesson.roadmap.term.1': 'Due diligence',
  'learning.lesson.roadmap.definition.1':
      'Investigating the business and checking the claims behind a proposed purchase.',
  'learning.lesson.roadmap.term.2': 'Transition',
  'learning.lesson.roadmap.definition.2':
      'The practical handover of knowledge, responsibilities and relationships.',
  'learning.lesson.syllabus.discover.title': 'Discover',
  'learning.lesson.syllabus.discover.body':
      'Decide whether buying a business fits your goals and the role you want.',
  'learning.lesson.syllabus.discover.time': '6 min',
  'learning.lesson.syllabus.search.title': 'Search',
  'learning.lesson.syllabus.search.body':
      'Define your fit, find opportunities and read a listing with questions in mind.',
  'learning.lesson.syllabus.search.time': '8 min',
  'learning.lesson.syllabus.evaluate.title': 'Evaluate',
  'learning.lesson.syllabus.evaluate.body':
      'Examine trends, customer dependence and the work the owner performs.',
  'learning.lesson.syllabus.evaluate.time': '8 min',
  'learning.lesson.syllabus.financial.title': 'Financial',
  'learning.lesson.syllabus.financial.body':
      'Learn how reported earnings, cash flow and financial evidence fit together.',
  'learning.lesson.syllabus.financial.time': '10 min',
  'learning.lesson.syllabus.documents.title': 'Documents',
  'learning.lesson.syllabus.documents.body':
      'Understand the purpose of the records and agreements you encounter.',
  'learning.lesson.syllabus.documents.time': '8 min',
  'learning.lesson.syllabus.dealStructure.title': 'Deal Structure',
  'learning.lesson.syllabus.dealStructure.body':
      'Explore how payment terms distribute money, obligations and risk.',
  'learning.lesson.syllabus.dealStructure.time': '8 min',
  'learning.lesson.syllabus.transition.title': 'Transition',
  'learning.lesson.syllabus.transition.body':
      'Plan the first conversations and priorities after the handover.',
  'learning.lesson.syllabus.transition.time': '6 min',
  'learning.lesson.syllabus.faq.title': 'FAQ',
  'learning.lesson.syllabus.faq.body':
      'Return to definitions and questions as you work through the journey.',
  'learning.lesson.syllabus.faq.time': '5 min',
  'learning.lesson.discover.title': 'Discover',
  'learning.lesson.discover.eyebrow': 'Lesson 2 of 9 · Discover',
  'learning.lesson.discover.subtitle': 'Is business ownership for you?',
  'learning.lesson.discover.readTime': 'About 6 minutes',
  'learning.lesson.discover.goal.0':
      'Compare buying an existing business with starting a new one.',
  'learning.lesson.discover.goal.1':
      'Describe the role you would like to play as an owner.',
  'learning.lesson.discover.goal.2':
      'Identify personal limits that should shape your search.',
  'learning.lesson.discover.core':
      'Buying a business is like taking over a running relay. There are people, routines and a history to understand as you take responsibility. Starting a business gives you the task of designing those routines and finding your first customers. Both paths take work, and your preferred role matters.',
  'learning.lesson.discover.exampleTitle': 'Same laundromat, different owners',
  'learning.lesson.discover.exampleIntro':
      'Maple Street has regular customers, equipment and a lease. Alex likes the idea of owning it. Whether it fits depends on the work Alex wants to do and what the business actually needs.',
  'learning.lesson.discover.buy.title': 'Buying Maple Street',
  'learning.lesson.discover.buy.body':
      'You can investigate an existing trading history, customer base and operating routine. You also inherit a business that may need repairs, changes or careful relationship building. The records and agreements need checking.',
  'learning.lesson.discover.start.title': 'Starting a laundromat',
  'learning.lesson.discover.start.body':
      'You choose the concept, location and systems. You need to secure premises and equipment, attract customers and discover how the operation performs. Allow for the time and resources needed to establish demand.',
  'learning.lesson.discover.rolesTitle': 'Which role sounds closer to you?',
  'learning.lesson.discover.operator.title': 'Owner-operator',
  'learning.lesson.discover.operator.body':
      'Alex wants to run the shop and work with customers. They need to understand opening hours, repairs, staffing and the tasks the current owner handles.',
  'learning.lesson.discover.investor.title': 'Investor',
  'learning.lesson.discover.investor.body':
      'Alex wants to oversee a manager. They need evidence that management exists or can be hired, and that the business can support its cost.',
  'learning.lesson.discover.firstTimer.title': 'First-time buyer',
  'learning.lesson.discover.firstTimer.body':
      'Alex is learning ownership for the first time. This can overlap with either role. Relevant experience, training, advisers and a realistic handover can help identify gaps to work on.',
  'learning.lesson.discover.mistake.0':
      'Assuming an established business runs itself. Ask what the owner does each week and who could take over those tasks.',
  'learning.lesson.discover.mistake.1':
      'Choosing a business for its image alone. Look at the daily work, location, hours and responsibilities.',
  'learning.lesson.discover.mistake.2':
      'Letting enthusiasm replace limits. Decide how much time and money you can commit before a listing captures your attention.',
  'learning.lesson.discover.question.0':
      'How hands-on do you want to be, and what does that mean for Maple Street?',
  'learning.lesson.discover.answer.0':
      'Picture an ordinary Tuesday. If you want to work elsewhere during the day, ask who opens the shop, handles problems and manages staff. Your preferred role should guide which operating arrangements you investigate.',
  'learning.lesson.discover.question.1':
      'What would make you step away from an otherwise attractive business?',
  'learning.lesson.discover.answer.1':
      'Consider limits such as evening work, travel, uncertainty or the amount you can commit. Naming those limits early gives you a more consistent way to compare opportunities.',
  'learning.lesson.discover.takeaway.0':
      'The day-to-day role matters as much as the idea of ownership.',
  'learning.lesson.discover.takeaway.1':
      'Use your goals, experience and limits to decide which opportunities deserve a closer look.',
  'learning.lesson.discover.next': 'Next lesson · Search',
  'learning.lesson.discover.chapter.0': 'Buying or starting',
  'learning.lesson.discover.chapter.1': 'Meet three kinds of buyer',
  'learning.lesson.discover.chapter.2': 'Picture an ordinary Tuesday',
  'learning.lesson.discover.story':
      'Alex walks past Maple Street and sees familiar customers coming and going. An existing business has a history Alex can investigate. It also comes with responsibilities. Would Alex enjoy running the shop, or want someone else to manage it? A first-time buyer can take either path, but the questions change with the role. Before searching for the perfect listing, Alex pictures an ordinary working day and names the limits they want to respect. That picture becomes the beginning of a search brief.',
  'learning.lesson.discover.term.0': 'Owner-operator',
  'learning.lesson.discover.definition.0':
      'An owner who actively works in the day-to-day business.',
  'learning.lesson.discover.term.1': 'Investor',
  'learning.lesson.discover.definition.1':
      'An owner focused on oversight and returns, with operations handled by a suitable team.',
  'learning.lesson.discover.term.2': 'Owner dependence',
  'learning.lesson.discover.definition.2':
      'How much the business relies on the current owner’s work, knowledge or relationships.',
  'learning.lesson.search.title': 'Search',
  'learning.lesson.search.eyebrow': 'Lesson 3 of 9 · Search',
  'learning.lesson.search.subtitle': 'Find a business that fits your life.',
  'learning.lesson.search.readTime': 'About 8 minutes',
  'learning.lesson.search.goal.0':
      'Build a search brief using skills, money, lifestyle and industry.',
  'learning.lesson.search.goal.1':
      'Understand where opportunities appear and how to compare sources.',
  'learning.lesson.search.goal.2':
      'Turn listing claims into useful questions for the seller.',
  'learning.lesson.search.core':
      'A search brief works like a sieve. Your criteria help you decide which opportunities deserve time and which ones do not fit your situation. Keep the criteria specific enough to be useful, and revisit them when you learn something new.',
  'learning.lesson.search.exampleTitle':
      'Read Maple Street’s listing with four lenses',
  'learning.lesson.search.exampleIntro':
      'Alex has customer-service experience, wants to stay in their community and can work in the business. They still need to understand equipment maintenance and how much money must remain available after the purchase.',
  'learning.lesson.search.skills.title': 'Your skills',
  'learning.lesson.search.skills.body':
      'What can you do well, and where will you need help? Alex can serve customers, but needs to learn who repairs the machines and what that support costs.',
  'learning.lesson.search.money.title': 'Your money',
  'learning.lesson.search.money.body':
      'Consider the purchase, transaction costs, ongoing cash needs and a reserve. Alex needs to explore funding and equipment costs before deciding what is affordable.',
  'learning.lesson.search.lifestyle.title': 'Your lifestyle',
  'learning.lesson.search.lifestyle.body':
      'Think about hours, location and your desired role. Alex wants a local business, but must check evening calls and weekend cover.',
  'learning.lesson.search.industry.title': 'The industry',
  'learning.lesson.search.industry.body':
      'Learn what drives demand and costs. For Maple Street, Alex would investigate local competition, the lease, utilities and equipment condition.',
  'learning.lesson.search.listingTitle': 'Maple Street Laundromat',
  'learning.lesson.search.listingBody':
      'Established neighbourhood business. Loyal customers. Turnkey operation. Owner retiring. Strong cash flow. Growth potential.',
  'learning.lesson.search.annotation.0.title': '“Turnkey operation”',
  'learning.lesson.search.annotation.0.body':
      'Which tasks does the owner handle? Ask about training, staffing, maintenance and systems that will transfer.',
  'learning.lesson.search.annotation.1.title': '“Strong cash flow”',
  'learning.lesson.search.annotation.1.body':
      'What period does this cover, how is it calculated, and which records support it? Check ongoing costs and the work performed by the owner.',
  'learning.lesson.search.annotation.2.title': '“Growth potential”',
  'learning.lesson.search.annotation.2.body':
      'What would need to change, what would it cost, and what evidence supports the idea? Treat an untested opportunity as a question to investigate.',
  'learning.lesson.search.sourcesTitle': 'Where to look',
  'learning.lesson.search.brokers.title': 'Business brokers',
  'learning.lesson.search.brokers.body':
      'Brokers can introduce marketed opportunities and coordinate information. Ask whom they represent, how their fees work and what confidentiality steps apply.',
  'learning.lesson.search.marketplaces.title': 'Marketplaces',
  'learning.lesson.search.marketplaces.body':
      'Online listings let you compare opportunities. Check dates, definitions and whether the information comes from the seller or has been independently verified.',
  'learning.lesson.search.outreach.title': 'Direct outreach',
  'learning.lesson.search.outreach.body':
      'Owners and professional networks may know of future opportunities. Be clear about your interests and respect confidentiality and the owner’s willingness to talk.',
  'learning.lesson.search.mistake.0':
      'Searching only by price. A lower price can still come with work, costs or obligations that exceed your limits.',
  'learning.lesson.search.mistake.1':
      'Treating listing language as verified evidence. Ask for the records and definitions behind each material claim.',
  'learning.lesson.search.mistake.2':
      'Falling in love with the first match. Compare it with your brief and other opportunities before committing.',
  'learning.lesson.search.question.0':
      'Which of the four lenses would you investigate first for Alex, and why?',
  'learning.lesson.search.answer.0':
      'Several answers can be reasonable. If Alex needs predictable hours, start with staffing and owner duties. If funds are limited, investigate total cash needs. Explain which personal limit makes that lens important.',
  'learning.lesson.search.question.1':
      'A listing says “owner retiring” and “easy to run.” What would you ask next?',
  'learning.lesson.search.answer.1':
      'Ask for a typical working week, the responsibilities that must transfer and the support available during handover. The reason for selling and the ease of operation each need their own evidence.',
  'learning.lesson.search.takeaway.0':
      'Use skills, money, lifestyle and industry together to define a useful search brief.',
  'learning.lesson.search.takeaway.1':
      'A promising listing earns further investigation. Translate its claims into questions and evidence requests.',
  'learning.lesson.search.next': 'Next lesson · Evaluate',
  'learning.lesson.search.chapter.0': 'Build your search brief',
  'learning.lesson.search.chapter.1': 'Read the Maple Street listing',
  'learning.lesson.search.chapter.2': 'Turn claims into questions',
  'learning.lesson.search.story':
      'Alex finds Maple Street on a marketplace. The words “turnkey” and “strong cash flow” sound promising. Alex returns to a search brief organized around skills, money, lifestyle and industry. The location fits, but who handles breakdowns? What does cash flow include? What happens when the owner leaves? Alex compares the listing with broker introductions and conversations in their network. A stronger search produces better questions. Those questions help Alex decide which business deserves a closer evaluation.',
  'learning.lesson.search.term.0': 'Search brief',
  'learning.lesson.search.definition.0':
      'A short description of the business, role and limits that fit your situation.',
  'learning.lesson.search.term.1': 'Listing',
  'learning.lesson.search.definition.1':
      'A seller’s or intermediary’s introduction to an opportunity, with claims to investigate.',
  'learning.lesson.search.term.2': 'Working capital',
  'learning.lesson.search.definition.2':
      'Resources used to support day-to-day operations, including amounts tied up in receivables and inventory.',
  'learning.lesson.search.findLesson': 'Find a lesson or document in Pact',
};

const learningRoadmapStageCopy = <String, String>{
  'learning.journey.find.body':
      'Alex starts with a search brief describing the role, location and responsibilities that fit their life. They compare Maple Street with other opportunities and ask what the owner does each week.\n\nA useful outcome is a shortlist of businesses worth investigating, with clear reasons for each choice. Finding that fit can take time. Revisit the brief when you learn more about an industry.',
  'learning.journey.value.body':
      'Alex asks for evidence behind Maple Street’s asking price, including trading history, costs and the owner’s work. They explore how the equipment, lease and ongoing cash needs affect the picture.\n\nA useful outcome is a set of assumptions to investigate with qualified advisers. A listing’s description and the seller’s asking price are starting points for questions.',
  'learning.journey.offer.body':
      'Alex and the seller explore the main terms and the conditions that would need to be met. Price, payment timing, what transfers and the proposed handover all matter.\n\nA useful outcome is clarity about what each party is proposing. Alex gets appropriate legal guidance on the wording and obligations before signing or making a commitment.',
  'learning.journey.diligence.body':
      'Alex works with advisers to investigate financial records, agreements, operations and material risks. For Maple Street, the questions include the lease, machine condition, utility costs and staff responsibilities.\n\nA useful outcome is an informed decision about proceeding, revising terms or stepping away. Missing information is a reason to ask further questions and revisit the schedule.',
  'learning.journey.close.body':
      'Alex coordinates the funding, final agreements and closing conditions with the appropriate advisers. They also plan how keys, systems, supplier relationships and practical knowledge will pass from the seller.\n\nA useful outcome is a purchase that can be completed and an operating plan for the first day. The handover continues after closing as Alex learns the business.',
};
