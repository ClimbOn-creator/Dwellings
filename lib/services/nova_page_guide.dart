import 'nova_walkthrough.dart';

List<NovaStep> novaPageWalkthrough(String page) {
  final role = page.startsWith('seller/')
      ? 'seller'
      : page.startsWith('member/')
      ? 'member'
      : 'buyer';
  List<NovaStep> steps;
  if (page.startsWith('buyer/dealScreen')) {
    final mode = page.split('/').length > 2 ? page.split('/')[2] : 'business';
    final first = mode == 'assets'
        ? 'assetAsk'
        : mode == 'realEstate'
        ? 'creName'
        : 'businessName';
    steps = [
      NovaStep(
        'pebble-calculator-tabs',
        'Choose a calculator',
        'Business value, asset value and commercial real estate use different assumptions. Choose the kind of opportunity you are evaluating.',
        page,
        NovaMood.curious,
        target: 'buyer.calc.tabs',
      ),
      NovaStep(
        'pebble-calculator-inputs',
        'Get help one field at a time',
        'Click the blue info button beside any field to open its explanation in the right sidebar. It covers what the figure means, how to calculate it, an example and the supporting records.',
        page,
        NovaMood.studying,
        target: 'buyer.calc.$first',
      ),
      NovaStep(
        'pebble-calculator-results',
        'Read the results',
        'Results appear when the required figures are entered. Compare the values and financing assumptions with supporting evidence. You can return to any field’s info button as you work.',
        page,
        NovaMood.planning,
        target: 'buyer.calc.$mode.results',
      ),
    ];
  } else if (page == 'seller/value') {
    steps = [
      for (final (number, title, body) in const [
        (
          1,
          'Business value range',
          'Use earnings and supported comparable multiples to estimate a range. Each blue info button explains the input in the right sidebar.',
        ),
        (
          2,
          'Asset reference',
          'Review the assets and liabilities included in the transfer. This is a separate comparison and is not added to earnings value automatically. Use any input’s info button for its calculation.',
        ),
        (
          3,
          'Cash at closing',
          'Model the proposed price, deferred payments, selling costs and debt repayment. This shows cash at closing before tax; each field has an explanation in the right sidebar.',
        ),
      ])
        NovaStep(
          'pebble-seller-calculator-$number',
          title,
          body,
          page,
          NovaMood.studying,
          target: 'seller.calc.panel.$number',
        ),
    ];
  } else {
    steps = novaWalkthrough(role)
        .where(
          (s) =>
              s.id != 'welcome' &&
              s.id != 'finish' &&
              s.destination == page &&
              !s.id.contains('-input-'),
        )
        .toList();
  }
  if (steps.isEmpty) {
    final copy = const {
      'resources': (
        'Government programs',
        'Search or filter the government and community programs on this page. Review location, eligible uses and application timing, then open the program’s official information.',
      ),
      'landing': (
        'Choose your path',
        'Start with buying, succession or transfer, or professional membership. The actions on this page take you into the path you choose.',
      ),
      'page:TeamPage': (
        "Your team",
        "Review your saved professionals, add the expertise you need and open their profiles. Check each deal\u2019s access separately before sharing private records.",
      ),
      'page:LocalNetworkPage': (
        "Your local professional network",
        "Use the location and professional filters to find relevant people. Open a profile to review their background and the available contact or team actions.",
      ),
      'page:ResourceProviderPage': (
        "Program details",
        "Review the provider, program requirements and contact information. Follow the official program link to confirm eligibility and application timing.",
      ),
      'page:NotificationCenterPage': (
        "Your private updates",
        "Review the latest notifications and open the relevant conversation or deal. The updates on this page relate to your account.",
      ),
      'page:ConnectionBriefPage': (
        "Build a connection brief",
        "Summarize the opportunity and the help you need. Review the intended recipient and shared information before sending the brief.",
      ),
      'page:ProfessionalOnboardingPage': (
        "Build your professional profile",
        "Work through identity, expertise, service area and contact details. Save accurate information so clients can understand your work.",
      ),
      'page:BusinessListingDetailPage': (
        "Review this business",
        "Read the business details and available financial information. Use the listing\u2019s interest or deal actions after reviewing the opportunity.",
      ),
      'page:ConsultingBookingPage': (
        "Arrange a consultation",
        "Choose a date and available time, add the requested booking details and review the booking before confirming.",
      ),
      'page:PersonalizedCalendarPage': (
        "Your calendar",
        "Review your scheduled events and add relevant dates. The connection and sync actions can link events with your supported calendar account.",
      ),
      'page:AffinityReviewDeskPage': (
        "Review Desk",
        "Review the deal submissions and their supporting details. Use the decision actions to manage approval and publication.",
      ),
      'page:FooterInformationPage': (
        "About this page",
        "Read this Affinity information page and follow any relevant contact or app links. The footer provides access to the other Affinity information pages.",
      ),
      'page:AboutPage': (
        "About Affinity",
        "Read about Affinity\u2019s approach and use the page\u2019s actions to explore the relevant service or app path.",
      ),
      'page:CapabilitiesPage': (
        "Affinity capabilities",
        "Review the services and capabilities described here, then use the relevant page action to continue.",
      ),
      'page:PlatformHubPage': (
        "Choose a workspace",
        "Choose the workspace that matches what you are here to do. Review the available paths before opening one.",
      ),
      'page:BusinessAcquisitionPage': (
        "Your acquisition workspace",
        "Review the deal stages and actions available here. Keep the opportunity\u2019s information and your next steps current.",
      ),
      'room/profile': (
        "Deal profile",
        "Review the source details for this deal. Keep its name, price, location and goals current and save changes when ready.",
      ),
      'room/evaluation': (
        "Deal evaluation",
        "Review the evidence and risk factors shown here. Use the evaluation alongside the source records and your advisers\u2019 review.",
      ),
      'room/team': (
        "This deal\u2019s team",
        "Review participants and their responsibilities. Add people deliberately and check what information they can access.",
      ),
      'room/timeline': (
        "Deal timeline",
        "Review the stage and recorded activity for this deal. Keep the transaction plan\u2019s tasks and dates current as work progresses.",
      ),
      'member/saved': (
        "Saved opportunities",
        "Review opportunities you have saved. Open one to review its details or remove it from your saved list when it no longer fits.",
      ),
      'member/recommendations': (
        "Recommended opportunities",
        "Review the suggested opportunities and compare them with your expertise and service area before opening a brief.",
      ),
      'member/professionals': (
        "Professional network",
        "Browse professional profiles and review their roles and experience. Use the available team and contact actions when relevant.",
      ),
      'member/opportunityDetail': (
        "Opportunity details",
        "Review the anonymous opportunity brief and requested support. Use the introduction or response action when your expertise fits.",
      ),
      'profile': (
        'Your profile',
        'Update your account details and save your changes on this page. The training section shows your completion status and lets you request Pebble again.',
      ),
      'member-profile': (
        'A professional’s profile',
        'Review their background, personal experience, services and member reviews. Use the available contact, team and review actions when relevant.',
      ),
      'auth': (
        'Your account',
        'Use the sign-in form for an existing account, or the account-creation option to register. The password recovery option helps restore access.',
      ),
      'membership': (
        'Professional membership',
        'Compare the available plans, then follow the membership action when you have chosen the level of support you need.',
      ),
      'listings': (
        'Businesses for sale',
        'Use the search and filters to narrow the listings. Open a listing to review its details before expressing interest or adding it to your pipeline.',
      ),
      'comparison': (
        'Compare opportunities',
        'Work through the comparison on this page to clarify your preferences and compare how opportunities fit your goals.',
      ),
      'content': (
        'Edit your site content',
        'Select a text or image slot, make your change and publish it. Confirm the save before moving on; published edits remain across app updates.',
      ),
    }[page];
    final title =
        copy?.$1 ??
        page
            .replaceFirst('page:', '')
            .replaceAll(RegExp(r'(Page|Screen)$'), '')
            .replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (m) => '${m[1]} ${m[2]}',
            );
    steps = [
      NovaStep(
        'pebble-page-${page.replaceAll('/', '-')}',
        title.isEmpty ? 'This page' : title,
        copy?.$2 ??
            'Use the sections and actions on this page to review its information and complete the work here. The navigation menu lets you choose another part of the app when you are ready.',
        page,
        NovaMood.welcome,
      ),
    ];
  }
  return [
    ...steps,
    NovaStep(
      'pebble-page-finish',
      'That’s this page.',
      'You can continue here, or request Pebble from the header whenever you need this page’s guide again.',
      page,
      NovaMood.celebrating,
    ),
  ];
}
