// Permanent track IDs and published copy slots. Never repurpose these IDs.
enum LearningTrack {
  buying('Buying a Business'),
  succession('Succession'),
  transfer('Transfer');

  const LearningTrack(this.label);
  final String label;
}

const learningTrackCopy = <String, String>{
  'learning.track.buying.label': 'Buying a Business',
  'learning.track.buying.roadmap.title': 'Your path to buying a business',
  'learning.track.buying.roadmap.body':
      'Explore your goals, discover opportunities, compare businesses, review the evidence and plan the handover. Use the sections in this workspace to follow the buying journey at your own pace.',
  'learning.track.buying.discover.title': 'Discover your fit as a buyer',
  'learning.track.buying.discover.body':
      'What kind of business would you like to run? Explore your interests, experience and the day-to-day role you want before building your search criteria.',
  'learning.track.buying.search.title': 'Search for a business',
  'learning.track.buying.search.body':
      'Describe the industry, location and owner role you are looking for. Compare how each opportunity fits those criteria and keep a list of questions to explore.',
  'learning.track.buying.evaluate.title': 'Understand the opportunity',
  'learning.track.buying.evaluate.body':
      'Explore how the business works: its customers, team, operations and reliance on the current owner. Separate what you have learned from the questions that remain open.',
  'learning.track.buying.financial.title': 'Explore the financial picture',
  'learning.track.buying.financial.body':
      'Learn the vocabulary of revenue, expenses, profit and cash flow. Use this section to organize the financial questions you want to understand about a potential purchase.',
  'learning.track.buying.room.title': 'Know the purchase documents',
  'learning.track.buying.room.body':
      'Explore the purpose of a deal brief, confidentiality agreement, information request and purchase agreement. Keep track of which documents you understand and which need further explanation.',
  'learning.track.buying.dealStructure.title': 'Explore a buying deal',
  'learning.track.buying.dealStructure.body':
      'Learn how a proposed purchase brings together the price, payment timing, responsibilities and conditions. Compare the questions raised by different arrangements.',
  'learning.track.buying.transition.title': 'Plan the ownership handover',
  'learning.track.buying.transition.body':
      'Explore what you would need to learn from the current owner. Think about the team, customer relationships, routines and knowledge that support the first days of ownership.',
  'learning.track.buying.faq.title': 'Buying a business: questions',
  'learning.track.buying.faq.body':
      'Where should I begin? Start with Discover to explore your fit. How do I compare opportunities? Use Search and Evaluate. Where do the numbers and paperwork fit? Explore Financial and Documents before returning to Deal Structure and Transition.',
  'learning.track.succession.label': 'Succession',
  'learning.track.succession.roadmap.title': 'Your path to business succession',
  'learning.track.succession.roadmap.body':
      'Explore the future of the business, the people who may lead it and the knowledge they need. Follow the sections to develop your understanding of a gradual leadership and ownership transition.',
  'learning.track.succession.discover.title': 'Discover your succession goals',
  'learning.track.succession.discover.body':
      'What should the next chapter preserve, and what could change? Explore the current owner’s goals, the business’s values and the role a future leader would take on.',
  'learning.track.succession.search.title': 'Explore potential successors',
  'learning.track.succession.search.body':
      'Consider the experience, interests and readiness of possible successors. Explore what family members, employees or an outside leader might need to learn about the business.',
  'learning.track.succession.evaluate.title': 'Explore succession readiness',
  'learning.track.succession.evaluate.body':
      'Look at responsibilities, decision making and the knowledge held by the current owner. Which roles are understood by others, and which depend on one person?',
  'learning.track.succession.financial.title': 'Explore succession finances',
  'learning.track.succession.financial.body':
      'Learn how the business’s financial picture connects with an ownership transition. List the questions the current owner and successor would like to understand about ongoing operations and the change in ownership.',
  'learning.track.succession.room.title': 'Know the succession documents',
  'learning.track.succession.room.body':
      'Explore the role of a succession plan, role descriptions, training records and ownership records. Use this section to understand how written information can support continuity.',
  'learning.track.succession.dealStructure.title':
      'Explore a succession arrangement',
  'learning.track.succession.dealStructure.body':
      'Consider how leadership responsibilities and ownership might change over time. Explore the expectations, milestones and conversations that would help each person understand the plan.',
  'learning.track.succession.transition.title': 'Plan a gradual handover',
  'learning.track.succession.transition.body':
      'Explore mentoring, shared responsibilities and opportunities for a successor to lead. Think about how the team will know who is responsible as the current owner’s role changes.',
  'learning.track.succession.faq.title': 'Succession: questions',
  'learning.track.succession.faq.body':
      'Is succession only a change in ownership? Explore the difference between leadership and ownership in Deal Structure. Where can I think about successor readiness? Start with Search and Evaluate. How can knowledge carry forward? Explore Documents and Transition.',
  'learning.track.transfer.label': 'Transfer',
  'learning.track.transfer.roadmap.title': 'Your path to a business transfer',
  'learning.track.transfer.roadmap.body':
      'Explore the scope of a business transfer, the people involved and what needs to move between them. Follow the sections to understand the preparation, agreement and practical handover.',
  'learning.track.transfer.discover.title': 'Discover the transfer goals',
  'learning.track.transfer.discover.body':
      'What is being transferred, and what should the next chapter look like? Explore the intended owner’s role, the current owner’s goals and the parts of the business that need continuity.',
  'learning.track.transfer.search.title': 'Explore the receiving owner’s fit',
  'learning.track.transfer.search.body':
      'Consider who will take responsibility for the business and what they need to understand. Explore their experience, expectations and relationship with the team and customers.',
  'learning.track.transfer.evaluate.title': 'Explore transfer readiness',
  'learning.track.transfer.evaluate.body':
      'Build your understanding of the operations, relationships and knowledge involved in the transfer. Which questions about the receiving owner and the business still need answers?',
  'learning.track.transfer.financial.title':
      'Explore the transfer’s financial picture',
  'learning.track.transfer.financial.body':
      'Learn the financial vocabulary that appears in a business transfer. Explore how the parties describe the business’s finances, ongoing operating needs and the proposed exchange.',
  'learning.track.transfer.room.title': 'Know the transfer documents',
  'learning.track.transfer.room.body':
      'Explore the purpose of an ownership record, asset inventory, agreement and handover checklist. Identify the information each document is intended to capture.',
  'learning.track.transfer.dealStructure.title':
      'Explore a transfer arrangement',
  'learning.track.transfer.dealStructure.body':
      'Explore how the parties describe what changes hands, the timing and their responsibilities. Compare the questions that arise when the scope or timetable changes.',
  'learning.track.transfer.transition.title': 'Plan the practical transfer',
  'learning.track.transfer.transition.body':
      'Explore the handover of routines, records, relationships and responsibilities. Think about how the receiving owner will learn the business and how the team will experience the change.',
  'learning.track.transfer.faq.title': 'Transfer: questions',
  'learning.track.transfer.faq.body':
      'What should I define first? Start with Discover to explore the scope and goals. Where can I organize the information involved? Explore Evaluate and Documents. How do I think about the handover? Move between Deal Structure and Transition.',
  'learning.track.video.pending': 'Video lesson coming soon',
};
