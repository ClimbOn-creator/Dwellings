enum FooterTopic {
  blueprint,
  readiness,
  dealScreen,
  pipeline,
  memberStudio,
  directory,
  buyerLeads,
  consulting,
  approach,
  privacy,
  terms,
  contact;

  bool get isInformationPage =>
      this == approach || this == privacy || this == terms || this == contact;

  FooterPageContent get content => footerPages[this]!;
  String get slug => switch (this) {
    dealScreen => 'deal-screen',
    memberStudio => 'member-studio',
    buyerLeads => 'buyer-leads',
    _ => name,
  };
  static FooterTopic? fromModule(String? module) {
    for (final topic in values) {
      if (module == 'footer-${topic.slug}') return topic;
    }
    return null;
  }
}

class FooterSection {
  const FooterSection(this.title, this.body, this.points);
  final String title, body;
  final List<String> points;
}

class FooterPageContent {
  const FooterPageContent({
    required this.label,
    required this.group,
    required this.headline,
    required this.intro,
    required this.action,
    required this.sections,
    required this.faqs,
  });
  final String label, group, headline, intro, action;
  final List<FooterSection> sections;
  final List<(String, String)> faqs;
}

const footerPages = <FooterTopic, FooterPageContent>{
  FooterTopic.blueprint: FooterPageContent(
    label: "Blueprint",
    group: "ACQUISITION PATH",
    headline: "Give your search a clear direction.",
    intro:
        "Turn your goals, available capital and operating preferences into a practical acquisition brief. Start with the business you want to own, then decide what a good opportunity needs to look like.",
    action: "Build my Blueprint",
    sections: [
      FooterSection(
        "Define your ideal business",
        "Choose the industries, locations and size of business you want to explore. Think about the work you want to do each week, the skills you bring and the responsibilities you want to take on.",
        [
          "Industry and geography",
          "Owner involvement",
          "Must-haves and deal breakers",
        ],
      ),
      FooterSection(
        "Set a realistic search range",
        "Record the capital you can contribute and the purchase range you want to investigate. Separate what is available today from financing that still needs a lender’s approval.",
        [
          "Available personal capital",
          "Target purchase range",
          "Financing questions",
        ],
      ),
      FooterSection(
        "Use the brief to compare opportunities",
        "Bring your criteria into the Deal screen, shortlist businesses that fit, and refine your Blueprint as you learn. A saved brief gives future conversations with advisers a useful starting point.",
        [
          "Screen an opportunity",
          "Discuss your criteria",
          "Refine as you learn",
        ],
      ),
    ],
    faqs: [
      (
        "Do I need a business in mind?",
        "No. Your Blueprint is useful before you start searching and can be updated when you find a specific opportunity.",
      ),
      (
        "Where is it saved?",
        "A draft stays on this device. Sign in to save it to your account and use it across your acquisition workspace.",
      ),
    ],
  ),
  FooterTopic.readiness: FooterPageContent(
    label: "Buyer readiness",
    group: "ACQUISITION PATH",
    headline: "Know what you can take on.",
    intro:
        "Assess your capital, experience and ability to operate a business before you commit to an acquisition. Use the questionnaire to identify the questions you still need to answer.",
    action: "Assess my readiness",
    sections: [
      FooterSection(
        "Start with your position today",
        "Consider your available capital, income needs, time commitments and relevant experience. Be candid about where you are starting; the answers are a planning tool.",
        ["Capital available", "Time and income needs", "Relevant experience"],
      ),
      FooterSection(
        "Make the gaps visible",
        "Identify what needs more work before moving ahead: lender conversations, operating knowledge, adviser support or clarity about your acquisition criteria.",
        ["Financing preparation", "Operational confidence", "Adviser support"],
      ),
      FooterSection(
        "Choose a practical next step",
        "Use your answers to shape your Blueprint, explore learning resources or discuss your circumstances with a professional. Revisit readiness when your situation changes.",
        [
          "Update your Blueprint",
          "Build your team",
          "Review your next milestone",
        ],
      ),
    ],
    faqs: [
      (
        "Is this a financing approval?",
        "No. A questionnaire cannot approve a loan or confirm affordability. A lender will need its own information and assessment.",
      ),
      (
        "Can I change my answers?",
        "Yes. Revisit the questionnaire as your capital, goals or experience change.",
      ),
    ],
  ),
  FooterTopic.dealScreen: FooterPageContent(
    label: "Deal screen",
    group: "ACQUISITION PATH",
    headline: "Put the opportunity through its paces.",
    intro:
        "Explore business value, assets and commercial real estate in one workspace. Enter your own figures, test assumptions and see which questions deserve a closer look.",
    action: "Open the Deal screen",
    sections: [
      FooterSection(
        "Estimate business value",
        "Work through asking price, earnings and valuation assumptions. Compare scenarios and use the results to prepare a more useful conversation with your accountant or business broker.",
        ["Business price", "Earnings assumptions", "Valuation scenarios"],
      ),
      FooterSection(
        "Understand the assets",
        "Review equipment, inventory and other assets separately from the value of the operating business. Check condition, ownership and the evidence behind each figure.",
        [
          "Equipment and inventory",
          "Replacement and resale value",
          "Ownership and condition",
        ],
      ),
      FooterSection(
        "Evaluate commercial property",
        "Model property income, expenses, vacancy and financing assumptions. Keep the real estate decision visible alongside the acquisition of the business.",
        [
          "Income and operating costs",
          "Vacancy and financing",
          "Property value assumptions",
        ],
      ),
    ],
    faqs: [
      (
        "Are the results a formal valuation?",
        "No. Results are estimates based on the figures and assumptions you enter. Validate them with qualified professionals and source documents.",
      ),
      (
        "What if some numbers are missing?",
        "Use the calculator to identify what you need to request. Keep estimates distinct from confirmed figures when discussing an opportunity.",
      ),
    ],
  ),
  FooterTopic.pipeline: FooterPageContent(
    label: "Pipeline",
    group: "ACQUISITION PATH",
    headline: "Keep every opportunity moving.",
    intro:
        "Use your buyer dashboard to organize potential acquisitions, see the current stage of each deal and keep the next action in view.",
    action: "Open my pipeline",
    sections: [
      FooterSection(
        "Bring your opportunities together",
        "Review businesses for sale or enter a private opportunity you already know about. A consistent deal record makes it easier to return to the facts later.",
        ["Marketplace opportunities", "Private deals", "Central deal records"],
      ),
      FooterSection(
        "Follow the stage of each deal",
        "Track progress from sourcing and review through diligence and closing. Keep tasks, upcoming deadlines and blockers visible in the buyer workspace.",
        [
          "Sourcing and review",
          "Diligence and closing",
          "Deadlines and blockers",
        ],
      ),
      FooterSection(
        "Move into the transaction workspace",
        "When a deal advances, bring your team into the process, work through the Transaction Plan and use the Transaction Room to coordinate the details.",
        ["Your personal team", "Transaction Plan", "Transaction Room"],
      ),
    ],
    faqs: [
      (
        "Can I add a deal found outside Affinity?",
        "Yes. The buyer dashboard includes a private-deal entry so you can organize an opportunity you sourced yourself.",
      ),
      (
        "Does adding a deal contact the seller?",
        "Entering a private deal does not send an offer. Use the relevant communication tools when you are ready to begin a conversation.",
      ),
    ],
  ),
  FooterTopic.memberStudio: FooterPageContent(
    label: "Member Studio",
    group: "PROFESSIONALS",
    headline: "Your professional home in Affinity.",
    intro:
        "Present your experience, explore buyer opportunities and manage the conversations that matter to your work. Member Studio brings your profile and deal activity together.",
    action: "Open Member Studio",
    sections: [
      FooterSection(
        "Build a profile with substance",
        "Share your role, company, service area and experience. Add a personal write-up of up to 200 words so buyers and sellers can understand how you approach a deal.",
        ["Professional details", "Service area", "Personal experience"],
      ),
      FooterSection(
        "Find work that fits your expertise",
        "Explore available opportunities and review the needs of the buyer before responding. Make your message specific to the deal and the help you can provide.",
        ["Opportunity details", "Relevant expertise", "Thoughtful responses"],
      ),
      FooterSection(
        "Stay on top of your conversations",
        "Follow responses, messages and ongoing work from the member dashboard. Keep your profile accurate as your services or availability change.",
        ["Buyer responses", "Member messages", "Profile updates"],
      ),
    ],
    faqs: [
      (
        "How do I become a member?",
        "Start the membership setup from Member Studio. The application gathers your professional details and the services you want to offer.",
      ),
      (
        "Will my write-up be public?",
        "Yes. The personal experience section is part of your public professional profile. Keep private client and deal information out of it.",
      ),
    ],
  ),
  FooterTopic.directory: FooterPageContent(
    label: "Expert directory",
    group: "PROFESSIONALS",
    headline: "Find the right expertise for the next step.",
    intro:
        "Explore professionals by role and service area. Read their profiles, compare experience and assemble a team around the needs of your acquisition or business transfer.",
    action: "Browse experts",
    sections: [
      FooterSection(
        "Search by the work you need done",
        "Look for business brokers, accountants, lawyers, lenders and other advisers relevant to the deal. The right role depends on the question you are trying to answer.",
        [
          "Business search and valuation",
          "Legal and tax advice",
          "Financing and specialist support",
        ],
      ),
      FooterSection(
        "Look beyond a job title",
        "Review a member’s company, experience write-up, service area and published reviews. Ask about relevant work and availability before making a commitment.",
        ["Relevant experience", "Service area", "Member reviews"],
      ),
      FooterSection(
        "Build your own deal team",
        "Add professionals to your team so you can find them again from your deal workspace. Confirm scope, fees and engagement terms directly with the professional.",
        ["Save to your team", "Discuss scope and fees", "Agree the engagement"],
      ),
    ],
    faqs: [
      (
        "Are example profiles real members?",
        "No. Profiles marked Example are fictional previews. They demonstrate team building and review features without representing an available professional.",
      ),
      (
        "Does adding someone to my team hire them?",
        "No. Saving a professional to your team does not create an engagement. Agree the work and terms directly with them.",
      ),
    ],
  ),
  FooterTopic.buyerLeads: FooterPageContent(
    label: "Buyer leads",
    group: "PROFESSIONALS",
    headline: "Start with a buyer’s actual needs.",
    intro:
        "Explore buyer opportunities through Member Studio and respond where your expertise can help. A useful introduction starts with understanding the deal and the support being requested.",
    action: "Explore buyer opportunities",
    sections: [
      FooterSection(
        "Understand the opportunity",
        "Review the information the buyer has chosen to share. Consider the business, location, transaction stage and service needs before deciding whether it is a fit.",
        ["Deal context", "Location and stage", "Requested support"],
      ),
      FooterSection(
        "Respond with a relevant approach",
        "Explain the work you can help with, your relevant experience and a sensible next step. Keep initial responses focused on the buyer’s circumstances.",
        [
          "Relevant background",
          "Proposed support",
          "A clear next conversation",
        ],
      ),
      FooterSection(
        "Follow the buyer’s response",
        "Use the dashboard to keep track of responses and conversations. Respect access limits and wait for the buyer to share any private details you need.",
        [
          "Response tracking",
          "Buyer-controlled contact",
          "Continued conversations",
        ],
      ),
    ],
    faqs: [
      (
        "Does responding guarantee an engagement?",
        "No. The buyer chooses who to work with. Scope, fees and professional engagements are agreed between the parties.",
      ),
      (
        "Why are some details unavailable?",
        "Buyers control what they share. Some information or contact actions become available only at the appropriate stage of the conversation.",
      ),
    ],
  ),
  FooterTopic.consulting: FooterPageContent(
    label: "Consulting",
    group: "PROFESSIONALS",
    headline: "Get perspective on your next decision.",
    intro:
        "Bring your goals, assumptions and open questions into a focused consulting conversation. Use it to sharpen your search or organize the next step in a live opportunity.",
    action: "Explore personal consulting",
    sections: [
      FooterSection(
        "Before you start searching",
        "Discuss what you want to own, what you can contribute and how a business would fit your life. Turn a broad intention into criteria you can use.",
        ["Acquisition goals", "Search criteria", "Readiness questions"],
      ),
      FooterSection(
        "When an opportunity gets serious",
        "Work through the assumptions behind a deal, identify missing information and organize the questions to bring to your professional advisers.",
        ["Deal assumptions", "Information gaps", "Diligence priorities"],
      ),
      FooterSection(
        "Prepare for a useful conversation",
        "Bring your Blueprint, available figures and the decisions you are trying to make. Use the consulting page’s calendar to choose an available booking time.",
        ["Your current context", "Questions and documents", "Calendar booking"],
      ),
    ],
    faqs: [
      (
        "Can I book from the app?",
        "Yes. Open personal consulting to use the existing booking calendar.",
      ),
      (
        "Can consulting replace my deal professionals?",
        "Legal, tax, lending and formal valuation work needs the appropriate professional engagement. Consulting helps you organize your decisions and next steps.",
      ),
    ],
  ),
  FooterTopic.approach: FooterPageContent(
    label: "Our approach",
    group: "AFFINITY",
    headline: "Better judgment. More deliberate decisions.",
    intro:
        "Affinity helps buyers, owners and professionals move through a business acquisition with clearer information, useful tools and the right people around the table.",
    action: "Explore the buyer workspace",
    sections: [
      FooterSection(
        "Give the decision a structure",
        "Start with a Blueprint and readiness assessment. Make your criteria explicit so that an attractive listing does not become your only reason to pursue a deal.",
        [
          "Clear acquisition criteria",
          "A realistic starting point",
          "Questions worth asking",
        ],
      ),
      FooterSection(
        "Put the information to work",
        "Use the Deal screen to explore assumptions, the pipeline to organize opportunities and the Transaction Plan to keep the work moving toward a decision.",
        [
          "Transparent assumptions",
          "Organized opportunities",
          "Practical transaction steps",
        ],
      ),
      FooterSection(
        "Connect people with the help they need",
        "The directory helps you discover professionals, while Resources points you toward government programs and community support. Choose the relationships that fit your circumstances.",
        ["Professional expertise", "Government programs", "Community support"],
      ),
    ],
    faqs: [
      (
        "Who is Affinity for?",
        "Buyers exploring an acquisition, owners planning a sale or succession, and professionals who support business transactions.",
      ),
      (
        "Who makes the final decision?",
        "You do, with the advisers you choose. Tools help you organize the information; they do not guarantee the outcome of a transaction.",
      ),
    ],
  ),
  FooterTopic.privacy: FooterPageContent(
    label: "Privacy",
    group: "AFFINITY",
    headline: "Understand what you share.",
    intro:
        "A practical guide to account information, public profiles and deal activity in Affinity. Review the visibility of information before publishing it or sharing it with other people.",
    action: "",
    sections: [
      FooterSection(
        "Account information",
        "Signing in uses your email and authentication details. Your account can also hold profile information, saved team members, saved resources and acquisition questionnaire answers.",
        [
          "Account and profile details",
          "Saved workspace activity",
          "Questionnaire answers",
        ],
      ),
      FooterSection(
        "Public member profiles and reviews",
        "Professional profile details, service areas and personal experience write-ups appear on public member profiles. Published member reviews include a public reviewer name, star rating and review text.",
        [
          "Public professional profiles",
          "Public experience write-ups",
          "Public member reviews",
        ],
      ),
      FooterSection(
        "Deal activity and sharing",
        "Deal records, conversations and documents are associated with the relevant workspace and its access rules. Share only the information needed for the transaction and check who has access before adding sensitive material.",
        [
          "Workspace participation",
          "Messages and documents",
          "Sharing decisions",
        ],
      ),
      FooterSection(
        "Information on this device",
        "The app uses browser storage for preferences and some drafts. Example-member review previews stay on this device. Clearing browser data can remove local drafts and previews; it does not by itself delete an account record.",
        ["Local drafts", "Motion preferences", "Example review previews"],
      ),
      FooterSection(
        "Questions and requests",
        "Use the Contact page for the company’s published contact details when available. Describe the account information or privacy question involved, and avoid sending passwords or sensitive deal documents in an initial message.",
        ["Account questions", "Profile corrections", "Privacy requests"],
      ),
    ],
    faqs: [
      (
        "Will saving an example review publish a real rating?",
        "No. Example-profile reviews are labeled previews and stored on this device.",
      ),
      (
        "Can I change my public profile?",
        "Members can update their professional details and personal experience in Member Studio. Check the public profile after saving to see what visitors can read.",
      ),
    ],
  ),
  FooterTopic.terms: FooterPageContent(
    label: "Terms",
    group: "AFFINITY",
    headline: "A shared understanding of the platform.",
    intro:
        "Read how Affinity’s tools, professional directory and transaction workspaces are intended to be used. Agree deal-specific obligations and professional services separately with the people involved.",
    action: "",
    sections: [
      FooterSection(
        "The role of Affinity",
        "Affinity provides tools for organizing acquisition decisions and discovering professional support. Buyers, sellers and professionals remain responsible for their own decisions, information and agreements.",
        [
          "Decision tools",
          "Professional discovery",
          "Participant responsibility",
        ],
      ),
      FooterSection(
        "Accounts and published information",
        "Use accurate account and professional information, keep your sign-in details private and only publish material you have permission to share. Do not present an example profile as a real professional.",
        ["Accurate information", "Account access", "Permission to publish"],
      ),
      FooterSection(
        "Calculators and estimates",
        "Calculator outputs depend on the inputs and assumptions provided. They are planning estimates, not an approved loan, guaranteed business price or formal valuation. Validate important figures with source documents and the appropriate advisers.",
        [
          "User-entered assumptions",
          "Planning estimates",
          "Independent validation",
        ],
      ),
      FooterSection(
        "Professional services and transactions",
        "Saving a professional to a team or discussing a deal does not create a service contract or purchase agreement. Confirm scope, fees, confidentiality and transaction terms directly with the parties before committing.",
        [
          "Professional engagements",
          "Confidentiality agreements",
          "Transaction contracts",
        ],
      ),
      FooterSection(
        "Reviews and respectful use",
        "Share honest experiences and keep reviews relevant to the professional’s work. Avoid private client details, confidential deal information, impersonation and abusive content. Example reviews are previews and do not rate a real member.",
        [
          "Relevant reviews",
          "Respectful communication",
          "Confidential information",
        ],
      ),
    ],
    faqs: [
      (
        "Does Affinity promise that a deal will close?",
        "No. Closing depends on the parties, financing, diligence and the agreements they make.",
      ),
      (
        "Where should I ask about platform terms?",
        "Use the company contact details on the Contact page when they are available. For obligations in a specific deal, speak to the parties and your adviser.",
      ),
    ],
  ),
  FooterTopic.contact: FooterPageContent(
    label: "Contact",
    group: "AFFINITY",
    headline: "Let’s get you to the right place.",
    intro:
        "Whether you have an account question, want to discuss an acquisition or need specialist expertise, start with the route that fits your question.",
    action: "Explore consulting",
    sections: [
      FooterSection(
        "A conversation about your acquisition",
        "For help organizing your goals or thinking through an opportunity, explore personal consulting and use the booking calendar to arrange a conversation.",
        [
          "Your current stage",
          "The decision you are facing",
          "Questions you want to discuss",
        ],
      ),
      FooterSection(
        "Specialist help with a deal",
        "For legal, tax, accounting, financing or business brokerage services, explore the expert directory. Confirm the professional’s services and availability directly.",
        ["The expertise you need", "Business location", "Scope and timing"],
      ),
      FooterSection(
        "Account and platform questions",
        "Use the company email shown here once it is published. Include the page you were using, what happened and the email associated with your account. Never send your password.",
        [
          "Page or feature involved",
          "A description of the issue",
          "Your account email",
        ],
      ),
    ],
    faqs: [
      (
        "What should I bring to a consulting call?",
        "Your acquisition goals, available business information and the questions you want to work through. You can prepare your Blueprint beforehand.",
      ),
      (
        "Should I email confidential deal documents?",
        "Start with a short description of your question. Arrange an appropriate way to share documents with the professional involved.",
      ),
    ],
  ),
};
