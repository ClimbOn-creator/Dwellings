import '../widgets/personal_motion.dart';
import '../widgets/site_text.dart';
import '../widgets/site_parallax_image.dart';
import '../widgets/affinity_cinematic.dart';
import '../widgets/site_image.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/account_service.dart';
import '../services/site_content_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/acquisition_editorial_header.dart';
import '../widgets/membership_footer.dart';
import '../widgets/fixed_editorial_background.dart';
import '../widgets/site_copy_text.dart';
import 'auth_page.dart';
import 'business_acquisition_page.dart';
import 'deal_rooms_page.dart';
import 'assistant_workspace_page.dart';

const _ink = Color(0xFF050510);
const _green = Color(0xFF252525);
const _lime = Color(0xFF9B9B98);
const _line = Color(0xFF292944);
const _muted = Color(0xFFA5A5B5);
const _surface = Color(0xFF121225);
const _lilac = Color(0xFF9B9B98);
const _cream = Color(0xFFF4F1EB);

class AcquisitionSupportPage extends StatefulWidget {
  const AcquisitionSupportPage({super.key});

  @override
  State<AcquisitionSupportPage> createState() => _AcquisitionSupportPageState();
}

class _AcquisitionSupportPageState extends State<AcquisitionSupportPage> {
  static const _forest = Color(0xFF151A19);
  static const _acid = Color(0xFFE5E1D7);
  final _pageScroll = ScrollController();
  bool? _motionEnabled;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (mounted && _motionEnabled == null) {
        setState(
          () => _motionEnabled = preferences.getBool('affinity.landing.motion'),
        );
      }
    });
  }

  Future<void> _setMotion(bool value) async {
    setState(() => _motionEnabled = value);
    // Scene lengths differ in reading mode: start at the opening after switching.
    if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('affinity.landing.motion', value);
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Widget _copy(
    String id,
    String fallback, {
    double size = 18,
    Color color = _ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
  }) => SiteCopyText(
    id,
    fallback,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: size >= 36 ? -size * .035 : 0,
    ),
  );

  Widget _label(String id, String fallback, {Color color = _forest}) =>
      SiteCopyText(
        id,
        fallback,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );

  Widget _section(
    Widget child, {
    Color color = Colors.white,
    double vertical = 96,
  }) => Container(
    color: color,
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width < 700 ? 24 : 56,
      vertical: vertical,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    ),
  );

  Widget _button(
    String id,
    String title,
    VoidCallback action, {
    bool light = false,
  }) => FilledButton.icon(
    onPressed: action,
    iconAlignment: IconAlignment.end,
    style: FilledButton.styleFrom(
      backgroundColor: light ? _acid : _forest,
      foregroundColor: light ? _forest : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
    icon: const Icon(Icons.arrow_outward, size: 20),
    label: SiteCopyText(
      id,
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final enabled = _motionEnabled ?? !MediaQuery.disableAnimationsOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: !enabled),
      child: Builder(builder: (context) => _buildPage(context, enabled)),
    );
  }

  Widget _buildPage(BuildContext context, bool motionEnabled) => Scaffold(
    backgroundColor: _cream,
    body: CustomScrollView(
      controller: _pageScroll,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 82,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: const Color(0xFFF7F8F4),
          surfaceTintColor: Colors.transparent,
          title: const HomeBrandButton(size: 66, dark: false),
          actions: [
            TextButton.icon(
              onPressed: () => _setMotion(!motionEnabled),
              icon: Icon(
                motionEnabled
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 20,
              ),
              label: Text(motionEnabled ? 'Motion on' : 'Enable motion'),
              style: TextButton.styleFrom(foregroundColor: _forest),
            ),
            if (MediaQuery.sizeOf(context).width >= 700)
              _button(
                'copy.acquisition_support_page.1',
                'START MY PATH',
                () => _open(const AcquisitionBlueprintPage()),
              ),
            const SizedBox(width: 8),
            const AppNavigationMenu(side: PlatformSide.business, dark: false),
            const SizedBox(width: 12),
          ],
        ),
        SliverToBoxAdapter(
          child: AffinityScrollScene(
            controller: _pageScroll,
            startOffset: 0,
            screens: 2.7,
            fallback: Column(
              children: [
                _hero(),
                _section(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(
                        'home.cinema.eyebrow',
                        'FROM POSSIBILITY TO PERSPECTIVE',
                      ),
                      const SizedBox(height: 24),
                      _copy(
                        'home.cinema.statement',
                        'A bigger future.\nA clearer view.',
                        size: 48,
                        height: 1.05,
                      ),
                      const SizedBox(height: 24),
                      _copy(
                        'home.cinema.body',
                        'Turn the ambition to own a business into a path you can act on. Define your target. Understand the opportunity. Bring the right people with you.',
                      ),
                      const SizedBox(height: 24),
                      _label('home.cinema.scroll', 'SCROLL TO EXPLORE'),
                    ],
                  ),
                ),
              ],
            ),
            builder: (context, progress, height) => AffinityCinemaHero(
              progress: progress,
              height: height,
              onBuyer: () => _open(const AcquisitionBlueprintPage()),
              onMember: () => _open(const MemberStudioPage()),
            ),
          ),
        ),
        _reveal(_goalStatement()),
        SliverLayoutBuilder(
          builder: (context, constraints) => SliverToBoxAdapter(
            child: AffinityScrollScene(
              controller: _pageScroll,
              startOffset: constraints.precedingScrollExtent - 82,
              screens: 4.8,
              fallback: _movingMarketing(),
              builder: (context, progress, height) =>
                  AffinityCinemaChapters(progress: progress),
            ),
          ),
        ),
        _reveal(_buyerBenefits()),
        _reveal(_audiences()),
        _reveal(_path()),
        _reveal(_questions()),
        _reveal(_closing()),
        const SliverToBoxAdapter(child: MembershipFooter()),
      ],
    ),
  );

  Widget _reveal(Widget child) => SliverLayoutBuilder(
    builder: (context, sliver) => SliverToBoxAdapter(
      child: ValueListenableBuilder<bool>(
        valueListenable: SiteContentService.editing,
        builder: (context, editing, _) => AnimatedBuilder(
          animation: _pageScroll,
          child: child,
          builder: (context, content) {
            final still = editing || MediaQuery.disableAnimationsOf(context);
            final height = MediaQuery.sizeOf(context).height;
            final top =
                sliver.precedingScrollExtent -
                (_pageScroll.hasClients ? _pageScroll.offset : 0);
            final visible = still
                ? 1.0
                : ((height - top) / (height * .42)).clamp(0.0, 1.0);
            return Opacity(
              opacity: .25 + visible * .75,
              child: Transform.translate(
                offset: Offset(0, (1 - visible) * 100),
                child: content,
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _hero() => _section(
    LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 850;
        final words = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(
              'home.eyebrow',
              'BUSINESS ACQUISITION, MADE NAVIGABLE',
              color: _acid,
            ),
            const SizedBox(height: 30),
            _copy(
              'home.title',
              'Don’t just find a business.\nKnow what you’re buying into.',
              size: narrow ? 46 : 70,
              color: Colors.white,
              weight: FontWeight.w600,
              height: 1.02,
            ),
            const SizedBox(height: 28),
            _copy(
              'home.intro',
              'Affinity helps aspiring buyers define the right target, prepare to transact, screen real opportunities, and build the professional team needed to close with confidence.',
              size: 18,
              color: const Color(0xFFD2DFD9),
            ),
            const SizedBox(height: 34),
            _button(
              'copy.acquisition_support_page.2',
              'I WANT TO BUY A BUSINESS',
              () => _open(const AcquisitionBlueprintPage()),
              light: true,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _open(const MemberStudioPage()),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 4,
                ),
              ),
              icon: const Icon(Icons.arrow_outward, size: 18),
              iconAlignment: IconAlignment.end,
              label: const SiteCopyText(
                'copy.acquisition_support_page.3',
                'I PROVIDE PROFESSIONAL SERVICES',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
        final visual = ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(narrow ? 100 : 200),
            topRight: const Radius.circular(24),
            bottomLeft: const Radius.circular(24),
            bottomRight: const Radius.circular(24),
          ),
          child: SiteParallaxImage(
            controller: _pageScroll,
            contentKey: 'image.acquisition_support_page.mbackground1',
            asset: 'assets/images/affinity-city-hero.jpg',
            child: Container(
              height: narrow ? 360 : 640,
              alignment: Alignment.bottomLeft,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xC0102723)],
                ),
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(
                    'home.visual.eyebrow',
                    'YOUR NEXT CHAPTER',
                    color: _acid,
                  ),
                  const SizedBox(height: 12),
                  _copy(
                    'home.visual.title',
                    'Build a future\nyou can stand behind.',
                    size: 32,
                    color: Colors.white,
                    weight: FontWeight.w500,
                    height: 1.1,
                  ),
                ],
              ),
            ),
          ),
        );
        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [words, const SizedBox(height: 38), visual],
              )
            : Row(
                children: [
                  Expanded(flex: 6, child: words),
                  const SizedBox(width: 60),
                  Expanded(flex: 5, child: visual),
                ],
              );
      },
    ),
    color: _forest,
    vertical: 56,
  );

  Widget _goalStatement() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.sizeOf(context).width < 760) ...[
          _copy(
            'home.intro',
            'Affinity helps aspiring buyers define the right target, prepare to transact, screen real opportunities, and build the professional team needed to close with confidence.',
          ),
          const SizedBox(height: 36),
        ],
        _label('home.perspective.eyebrow', 'AMBITION, WITH A PLAN'),
        const SizedBox(height: 26),
        _copy(
          'home.goal',
          'A clearer path from “I want to buy a business” to “this is the right business for me.”',
          size: MediaQuery.sizeOf(context).width < 700 ? 36 : 56,
          weight: FontWeight.w500,
          height: 1.12,
        ),
        const SizedBox(height: 30),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 660,
            child: _copy(
              'home.goal_body',
              'The goal is not more deal flow. It is better judgment: a personal acquisition Blueprint, an honest view of readiness, disciplined screening, and access to specialists when the stakes rise.',
              color: const Color(0xFF56625D),
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _benefit(String id, String title, String body, {bool dark = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _copy(
              '$id.title',
              title,
              size: 23,
              weight: FontWeight.w600,
              color: dark ? Colors.white : _ink,
              height: 1.2,
            ),
            const SizedBox(height: 10),
            _copy(
              '$id.body',
              body,
              size: 17,
              color: dark ? const Color(0xFFCCDAD5) : const Color(0xFF56625D),
            ),
          ],
        ),
      );

  Widget _buyerBenefits() => _section(
    LayoutBuilder(
      builder: (context, box) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(
              'home.benefits.buyer.eyebrow',
              'LESS GUESSWORK. MORE DIRECTION.',
            ),
            const SizedBox(height: 24),
            _copy(
              'home.benefits.buyer.title',
              'Make your next move\na considered one.',
              size: box.maxWidth < 700 ? 38 : 54,
              height: 1.08,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 24),
            _copy(
              'home.benefits.buyer.intro',
              'Buying a business brings a lot of moving parts. Affinity gives you a place to connect them—and a practical next step when you need one.',
              color: const Color(0xFF56625D),
            ),
            const SizedBox(height: 30),
            _button(
              'home.benefits.buyer.cta',
              'Explore the deal screen',
              () => _open(const BusinessAcquisitionPage()),
            ),
          ],
        );
        final benefits = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _benefit(
              'home.benefits.focus',
              'Spend time on businesses that fit.',
              'Put your budget, location, experience and goals into a Blueprint. Use it to give your search boundaries before an attractive listing pulls you off course.',
            ),
            const Divider(color: Color(0xFFC5CCC4)),
            _benefit(
              'home.benefits.numbers',
              'See what the headline price leaves out.',
              'Work through earnings, owner compensation, working capital and debt assumptions. Turn uncertainty into questions you can investigate with your advisers.',
            ),
            const Divider(color: Color(0xFFC5CCC4)),
            _benefit(
              'home.benefits.progress',
              'Keep the next step in sight.',
              'Move promising opportunities into your pipeline. Bring your preparation, screening and professional conversations into a more organized acquisition process.',
            ),
          ],
        );
        return box.maxWidth < 850
            ? Column(children: [title, const SizedBox(height: 30), benefits])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 100),
                  Expanded(child: benefits),
                ],
              );
      },
    ),
    color: const Color(0xFFE9E8E2),
  );

  Widget _audiences() => SiteParallaxImage(
    controller: _pageScroll,
    contentKey: 'image.acquisition_support_page.mbackground2',
    asset: 'assets/images/affinity-reflection-facade.jpg',
    child: Container(
      color: const Color(0x99102723),
      child: _section(
        LayoutBuilder(
          builder: (context, box) {
            final buyer = _audience(false);
            final member = _audience(true);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(
                  'home.audiences.eyebrow',
                  'DIFFERENT EXPERTISE. SHARED MOMENTUM.',
                  color: _acid,
                ),
                const SizedBox(height: 22),
                _copy(
                  'home.audiences.title',
                  'Good decisions\nbring people together.',
                  size: box.maxWidth < 700 ? 40 : 64,
                  height: 1.06,
                  color: Colors.white,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 52),
                if (box.maxWidth < 800) ...[
                  buyer,
                  const SizedBox(height: 24),
                  member,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: buyer),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 76),
                          child: member,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
        color: Colors.transparent,
        vertical: 96,
      ),
    ),
  );

  Widget _audience(bool member) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: member ? _forest : Colors.white,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          member
              ? 'FOR PROFESSIONAL MEMBERS'
              : 'FOR BUYERS & THE ACQUISITION-CURIOUS',
          contentKey: 'copy.acquisition_support_page.m3',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.1,
            color: member ? _acid : _forest,
          ),
        ),
        const SizedBox(height: 30),
        _copy(
          member ? 'home.member_title' : 'home.buyer_title',
          member
              ? 'Be visible when buyers need you.'
              : 'Turn interest into a mandate.',
          size: 36,
          weight: FontWeight.w500,
          height: 1.08,
          color: member ? Colors.white : _ink,
        ),
        const SizedBox(height: 18),
        _copy(
          member ? 'home.member_body' : 'home.buyer_body',
          member
              ? 'Build a credible professional presence and respond privately when an Affinity-reviewed opportunity fits your expertise.'
              : 'Learn the path, define what fits your life and capital, measure your readiness, and screen opportunities against your own rules.',
          color: member ? const Color(0xFFCCDAD5) : const Color(0xFF56625D),
        ),
        const SizedBox(height: 18),
        _benefit(
          member ? 'home.member.presence' : 'home.buyer.start',
          member ? 'Let your expertise speak.' : 'Start where you are.',
          member
              ? 'Use Member Studio to present your services and the work you can support, so buyers can understand where you fit.'
              : 'You do not need a business picked out to begin. Define your target and work through your readiness before evaluating a live deal.',
          dark: member,
        ),
        _benefit(
          member ? 'home.member.connections' : 'home.buyer.support',
          member
              ? 'Find a relevant conversation.'
              : 'Bring in specialist support.',
          member
              ? 'Review opportunities and buyer needs, then express interest where your experience is relevant. Keep the conversation focused on the work ahead.'
              : 'Explore professionals for financing, legal, diligence, tax and transition questions as your acquisition takes shape.',
          dark: member,
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => member
              ? _open(const MemberStudioPage())
              : _open(const AcquisitionBlueprintPage()),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_outward),
          style: TextButton.styleFrom(
            foregroundColor: member ? _acid : _forest,
          ),
          label: SiteText(
            member ? 'EXPLORE MEMBER STUDIO' : 'BUILD MY BLUEPRINT',
            contentKey: 'copy.acquisition_support_page.m6',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _questions() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('home.faq.eyebrow', 'A FEW THINGS TO KNOW'),
        const SizedBox(height: 22),
        _copy(
          'home.faq.title',
          'Your starting questions, answered.',
          size: 40,
          height: 1.1,
          weight: FontWeight.w500,
        ),
        const SizedBox(height: 32),
        for (final item in const [
          (
            'start',
            'Do I need to have a business in mind?',
            'No. Begin with your Blueprint: the type of business, location, budget and role that could fit your life. Readiness helps you identify what to prepare before you pursue a specific opportunity.',
          ),
          (
            'members',
            'Who is the professional membership for?',
            'Professionals who help buyers prepare for and complete acquisitions, including financing, accounting, legal, diligence, risk and transition specialists. Member Studio is the starting point for presenting your services.',
          ),
          (
            'decision',
            'Does Affinity make the acquisition decision for me?',
            'You remain the decision-maker. Affinity helps organize your criteria, assumptions and next steps. Use screening results as a starting point for verification and specialist advice.',
          ),
        ])
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(vertical: 12),
            childrenPadding: const EdgeInsets.only(bottom: 24),
            title: _copy(
              'home.faq.${item.$1}.question',
              item.$2,
              size: 20,
              weight: FontWeight.w500,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _copy(
                  'home.faq.${item.$1}.answer',
                  item.$3,
                  color: const Color(0xFF56625D),
                ),
              ),
            ],
          ),
      ],
    ),
    color: const Color(0xFFF1F3EE),
    vertical: 80,
  );

  Widget _closing() => _section(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('home.closing.eyebrow', 'MAKE ROOM FOR WHAT’S NEXT'),
        const SizedBox(height: 24),
        _copy(
          'home.closing.title',
          'Your ambition deserves\na clear next step.',
          size: MediaQuery.sizeOf(context).width < 700 ? 44 : 72,
          weight: FontWeight.w500,
          height: 1.02,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 18,
          runSpacing: 16,
          children: [
            _button(
              'home.closing.buyer',
              'Build my Blueprint',
              () => _open(const AcquisitionBlueprintPage()),
            ),
            _button(
              'home.closing.member',
              'Explore membership',
              () => _open(const MemberStudioPage()),
            ),
          ],
        ),
      ],
    ),
    color: _acid,
  );

  Widget _movingMarketing() {
    const stories = [
      (
        'DEFINE',
        'Build a buyer-first acquisition Blueprint.',
        'Set the industries, geography, price range, role, return expectations, and hard limits that define a viable target.',
        Icons.explore_outlined,
      ),
      (
        'PREPARE',
        'Know what must be true before you transact.',
        'Organize capital, reserves, documentation, operating credibility, and lender conversations into an honest readiness view.',
        Icons.verified_user_outlined,
      ),
      (
        'SCREEN',
        'Pressure-test the deal—not your hopes.',
        'Normalize earnings, account for owner pay and working capital, test debt, and expose missing evidence before an offer.',
        Icons.query_stats_outlined,
      ),
      (
        'CONNECT',
        'Bring in the right expertise at the right moment.',
        'Find member professionals whose services match the financing, legal, diligence, tax, risk, and transition work ahead.',
        Icons.hub_outlined,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SiteText(
              contentKey: 'copy.acquisition_support_page.m1',
              literal: true,
              'WHAT AFFINITY MOVES FORWARD',
              style: TextStyle(
                color: Color(0xFF66615B),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth < 700
                  ? 1
                  : box.maxWidth < 1100
                  ? 2
                  : 4;
              final width = (box.maxWidth - 48 - (columns - 1) * 18) / columns;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (var index = 0; index < stories.length; index++)
                      SizedBox(
                        width: width,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: columns == 4 && index.isOdd ? 44 : 0,
                          ),
                          child: _MovingMarketingCard(
                            eyebrow: stories[index].$1,
                            title: stories[index].$2,
                            copy: stories[index].$3,
                            icon: stories[index].$4,
                            chapter: index,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _path() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 82, 24, 88),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SiteText(
              contentKey: 'copy.acquisition_support_page.4',
              literal: true,
              'THE BUYER PATH',
              style: TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const SiteText(
              contentKey: 'copy.acquisition_support_page.5',
              literal: true,
              'Four steps. One clearer decision.',
              style: TextStyle(
                color: _ink,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HomePathStep('01', 'Blueprint', 'Define the target.', () {
                  _open(const AcquisitionBlueprintPage());
                }),
                _HomePathStep('02', 'Readiness', 'Prepare the buyer.', () {
                  _open(const BuyerReadinessPage());
                }),
                _HomePathStep('03', 'Deal screen', 'Test the opportunity.', () {
                  _open(const BusinessAcquisitionPage());
                }),
                _HomePathStep('04', 'Pipeline', 'Manage what advances.', () {
                  _open(
                    const DealRoomsPage(initialSide: PlatformSide.business),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MovingMarketingCard extends StatelessWidget {
  const _MovingMarketingCard({
    required this.eyebrow,
    required this.title,
    required this.copy,
    required this.icon,
    required this.chapter,
  });
  final String eyebrow, title, copy;
  final IconData icon;
  final int chapter;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SiteImage(
            contentKey: 'image.home.cinema.chapter.$chapter',
            original: Image.asset(
              'assets/images/${AffinityCinemaChapters.chapters[chapter].$4}',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(icon, color: _green, size: 30),
            const Spacer(),
            SiteText(
              contentKey: 'copy.acquisition_support_page.m7',
              literal: false,
              eyebrow,
              style: const TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        SiteText(
          contentKey: 'copy.acquisition_support_page.m8',
          literal: false,
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 26,
            height: 1.06,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        SiteText(
          contentKey: 'copy.acquisition_support_page.m9',
          literal: false,
          copy,
          style: const TextStyle(
            color: Color(0xFF555562),
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _HomePathStep extends StatelessWidget {
  const _HomePathStep(this.number, this.title, this.copy, this.onTap);
  final String number, title, copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 620 ? double.infinity : 260,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 21),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFCDCDD4))),
        ),
        child: Row(
          children: [
            SiteText(
              contentKey: 'copy.acquisition_support_page.m10',
              literal: false,
              number,
              style: const TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SiteText(
                    contentKey: 'copy.acquisition_support_page.m11',
                    literal: false,
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SiteText(
                    contentKey: 'copy.acquisition_support_page.m12',
                    literal: false,
                    copy,
                    style: const TextStyle(color: Color(0xFF777783)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: _ink, size: 18),
          ],
        ),
      ),
    ),
  );
}

class AcquisitionBlueprintPage extends StatefulWidget {
  const AcquisitionBlueprintPage({super.key});
  @override
  State<AcquisitionBlueprintPage> createState() =>
      _AcquisitionBlueprintPageState();
}

class _AcquisitionBlueprintPageState extends State<AcquisitionBlueprintPage> {
  AcquisitionFoundation? value;
  final controllers = <String, TextEditingController>{};
  int _chapter = 0;

  @override
  void initState() {
    super.initState();
    AcquisitionFoundation.load().then((loaded) {
      for (final entry in loaded.blueprint.entries) {
        controllers[entry.key] = TextEditingController(text: '${entry.value}');
      }
      if (mounted) setState(() => value = loaded);
    });
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateDraft() async {
    final current = value!;
    current.blueprint.addAll({
      for (final entry in controllers.entries) entry.key: entry.value.text,
    });
    await current.save();
  }

  Future<void> _save() async {
    await _updateDraft();
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    try {
      await value!.saveForAccount('blueprint');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SiteText(
            templateValues: {'value1': '${error}'},
            contentKey: 'copy.acquisition_support_page.m13',
            literal: false,
            "Draft kept on this device. Cloud save failed: {{value1}}",
          ),
        ),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SiteText(
            contentKey: 'copy.acquisition_support_page.m14',
            literal: true,
            'Step 1 saved to your profile.',
          ),
        ),
      );
    }
  }

  Future<void> _goStep(int step) async {
    if (step == 0) return;
    await _updateDraft();
    if (!mounted) return;
    final page = switch (step) {
      1 => const BuyerReadinessPage(),
      2 => const BusinessAcquisitionPage(),
      _ => const DealRoomsPage(initialSide: PlatformSide.business),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => PersonalMotion(
    chapter: _chapter,
    builder: (context, scroll, toggle) => _ModuleScaffold(
      motionScroll: scroll,
      motionToggle: toggle,
      chapter: _chapter,
      kicker: 'PAGE 1 OF 4 · BLUEPRINT',
      title: SiteContentService.text(
        'blueprint.title',
        'Acquisition Blueprint',
      ),
      subtitle: SiteContentService.text(
        'blueprint.subtitle',
        'Define the acquisition you want before a compelling deal changes the rules.',
      ),
      currentStep: 0,
      onStepSelected: _goStep,
      child: value == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SiteText(
                      templateValues: {'value1': '${_chapter + 1}'},
                      contentKey: 'copy.acquisition_support_page.m15',
                      literal: false,
                      "QUESTION {{value1}} OF 4",
                      style: const TextStyle(
                        color: _lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    SiteText(
                      contentKey: 'copy.acquisition_support_page.m16',
                      literal: false,
                      '${((_chapter + 1) / 4 * 100).round()}%',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_chapter + 1) / 4,
                  minHeight: 3,
                  color: _green,
                  backgroundColor: _line,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(.07, .02),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_chapter),
                    child: _chapterBody(),
                  ),
                ),
                const SizedBox(height: 22),
                _chapterActions(),
              ],
            ),
    ),
  );

  Widget _chapterBody() => switch (_chapter) {
    0 => _GuidedQuestion(
      title: SiteContentService.text(
        'blueprint.q1_title',
        'What kind of owner do you want to become?',
      ),
      copy: SiteContentService.text(
        'blueprint.q1_body',
        'Start with the role and structure—not a price. You can revise this as your search becomes clearer.',
      ),
      children: [
        _dropdown('type', 'Acquisition structure', const [
          'Business acquisition',
          'Asset purchase',
          'Share purchase',
          'I’m not sure yet',
        ]),
        _dropdown('involvement', 'Your preferred role', const [
          'Owner-operator',
          'Strategic owner',
          'Investor with manager',
          'I’m not sure yet',
        ]),
      ],
    ),
    1 => _GuidedQuestion(
      title: SiteContentService.text(
        'blueprint.q2_title',
        'What would feel like a natural fit?',
      ),
      copy: SiteContentService.text(
        'blueprint.q2_body',
        'Use plain language. A broad answer is useful; “local service businesses” is enough to begin.',
      ),
      children: [
        _input(
          'geography',
          'Where would you consider buying?',
          hint: 'A city, province, region, or remote',
        ),
        _input(
          'industries',
          'What businesses interest you?',
          hint: 'Industries, business models, or simply “open to ideas”',
        ),
      ],
    ),
    2 => _GuidedQuestion(
      title: SiteContentService.text(
        'blueprint.q3_title',
        'Do you know your financial range?',
      ),
      copy: SiteContentService.text(
        'blueprint.q3_body',
        'These figures are optional planning estimates—not a test or lending approval. Leave them blank if you are still learning.',
      ),
      children: [
        _input(
          'minPrice',
          'Lower purchase range',
          unit: r'$ CAD',
          hint: 'Optional',
        ),
        _input(
          'maxPrice',
          'Upper purchase range',
          unit: r'$ CAD',
          hint: 'Optional',
        ),
        _input(
          'minReturn',
          'Minimum return or earnings yield',
          unit: '%',
          hint: 'Optional',
        ),
      ],
    ),
    _ => _GuidedQuestion(
      title: SiteContentService.text(
        'blueprint.q4_title',
        'What should protect you from the wrong deal?',
      ),
      copy: SiteContentService.text(
        'blueprint.q4_body',
        'Name the risks you already know you do not want. If nothing comes to mind, uncertainty is a valid answer.',
      ),
      children: [
        _input(
          'limits',
          'Non-negotiables',
          hint: 'Examples: no turnaround, no heavy travel—or “not sure yet”',
          maxLines: 3,
        ),
        _input(
          'stretch',
          'Where could you be flexible?',
          hint: 'Optional',
          maxLines: 3,
        ),
      ],
    ),
  };

  Widget _chapterActions() => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 10,
    children: [
      if (_chapter > 0)
        TextButton.icon(
          onPressed: () => setState(() => _chapter--),
          icon: const Icon(Icons.arrow_back),
          label: const SiteText(
            contentKey: 'copy.acquisition_support_page.6',
            literal: true,
            'Back',
          ),
        ),
      if (_chapter == 2)
        TextButton(
          onPressed: () {
            controllers['minPrice']?.clear();
            controllers['maxPrice']?.clear();
            controllers['minReturn']?.clear();
            setState(() => _chapter++);
          },
          child: const SiteText(
            contentKey: 'copy.acquisition_support_page.7',
            literal: true,
            'I DON’T KNOW YET',
          ),
        ),
      FilledButton.icon(
        onPressed: _chapter < 3
            ? () async {
                await _updateDraft();
                if (mounted) setState(() => _chapter++);
              }
            : _save,
        icon: Icon(_chapter < 3 ? Icons.arrow_forward : Icons.check_rounded),
        label: SiteText(
          contentKey: 'copy.acquisition_support_page.m17',
          literal: false,
          _chapter < 3 ? 'CONTINUE' : 'SAVE BLUEPRINT',
        ),
      ),
    ],
  );

  Widget _input(
    String key,
    String label, {
    String? unit,
    String? hint,
    int maxLines = 1,
  }) => _LabeledField(
    label: label,
    unit: unit,
    labelColor: _ink,
    child: TextField(
      controller: controllers[key],
      keyboardType: ['minPrice', 'maxPrice', 'minReturn'].contains(key)
          ? TextInputType.number
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hint: siteInputCopy(
          hint,
          contentKey: 'copy.acquisition_support_page.field.dynamic1',
        ),
      ),
    ),
  );

  Widget _dropdown(String key, String label, List<String> options) {
    final current = controllers[key]?.text.trim() ?? '';
    return _LabeledField(
      label: label,
      labelColor: _ink,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: options.contains(current) ? current : null,
        hint: const SiteText(
          contentKey: 'copy.acquisition_support_page.8',
          literal: true,
          'Select an option',
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: SiteText(
                  contentKey: 'copy.acquisition_support_page.m18',
                  literal: false,
                  option,
                ),
              ),
            )
            .toList(),
        onChanged: (selected) => controllers[key]?.text = selected ?? '',
      ),
    );
  }
}

class BuyerReadinessPage extends StatefulWidget {
  const BuyerReadinessPage({super.key});
  @override
  State<BuyerReadinessPage> createState() => _BuyerReadinessPageState();
}

class _BuyerReadinessPageState extends State<BuyerReadinessPage> {
  AcquisitionFoundation? value;
  final controllers = <String, TextEditingController>{};
  int _stage = 0;

  @override
  void initState() {
    super.initState();
    AcquisitionFoundation.load().then((loaded) {
      for (final key in ['equity', 'reserves', 'income', 'credit']) {
        controllers[key] = TextEditingController(
          text: '${loaded.readiness[key]}',
        );
      }
      if (mounted) setState(() => value = loaded);
    });
  }

  Future<void> _updateDraft() async {
    final current = value!;
    for (final entry in controllers.entries) {
      current.readiness[entry.key] = entry.value.text;
    }
    await current.save();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await _updateDraft();
    if (!mounted) return;
    if (BackendService.user == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
      if (!mounted || BackendService.user == null) return;
    }
    try {
      await value!.saveForAccount('readiness');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SiteText(
              contentKey: 'copy.acquisition_support_page.m19',
              literal: true,
              'Step 2 saved to your profile.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${error}'},
              contentKey: 'copy.acquisition_support_page.m20',
              literal: false,
              "Draft kept on this device. Cloud save failed: {{value1}}",
            ),
          ),
        );
      }
    }
  }

  Future<void> _goStep(int step) async {
    await _updateDraft();
    if (!mounted || step == 1) return;
    final page = switch (step) {
      0 => const AcquisitionBlueprintPage(),
      2 => const BusinessAcquisitionPage(),
      _ => const DealRoomsPage(initialSide: PlatformSide.business),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    return _ModuleScaffold(
      kicker: 'PAGE 2 OF 4 · READINESS',
      title: SiteContentService.text('readiness.title', 'Buyer Readiness'),
      subtitle: SiteContentService.text(
        'readiness.subtitle',
        'Understand what you can execute now and your path to becoming transaction-ready.',
      ),
      currentStep: 1,
      onStepSelected: _goStep,
      child: current == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SiteText(
                      templateValues: {'value1': '${_stage + 1}'},
                      contentKey: 'copy.acquisition_support_page.m21',
                      literal: false,
                      "MOMENT {{value1}} OF 3",
                      style: const TextStyle(
                        color: _lime,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    SiteText(
                      contentKey: 'copy.acquisition_support_page.m22',
                      literal: false,
                      '${((_stage + 1) / 3 * 100).round()}%',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_stage + 1) / 3,
                  minHeight: 3,
                  color: _green,
                  backgroundColor: _line,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: KeyedSubtree(
                    key: ValueKey(_stage),
                    child: _readinessMoment(current),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (_stage > 0)
                      TextButton.icon(
                        onPressed: () => setState(() => _stage--),
                        icon: const Icon(Icons.arrow_back),
                        label: const SiteText(
                          contentKey: 'copy.acquisition_support_page.9',
                          literal: true,
                          'Back',
                        ),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _stage < 2
                          ? () async {
                              await _updateDraft();
                              if (mounted) setState(() => _stage++);
                            }
                          : _save,
                      icon: Icon(
                        _stage < 2 ? Icons.arrow_forward : Icons.check_rounded,
                      ),
                      label: SiteText(
                        contentKey: 'copy.acquisition_support_page.m23',
                        literal: false,
                        _stage < 2 ? 'CONTINUE' : 'SAVE READINESS',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _readinessMoment(AcquisitionFoundation current) => switch (_stage) {
    0 => _GuidedQuestion(
      title: SiteContentService.text(
        'readiness.q1_title',
        'What capital could be available?',
      ),
      copy: SiteContentService.text(
        'readiness.q1_body',
        'A rough range is enough. Leave every field blank if you have not had this conversation yet.',
      ),
      children: [
        _readinessInput('equity', 'Cash or equity you might use'),
        _readinessInput('reserves', 'Capital you want untouched after closing'),
      ],
    ),
    1 => _GuidedQuestion(
      title: SiteContentService.text(
        'readiness.q2_title',
        'What supports the acquisition?',
      ),
      copy: SiteContentService.text(
        'readiness.q2_body',
        'These answers help frame—not approve—your capacity. “I’m not sure yet” is included on purpose.',
      ),
      children: [
        _readinessInput('income', 'Annual supporting income'),
        _LabeledField(
          label: 'How would you describe your credit?',
          labelColor: _ink,
          child: DropdownButtonFormField<String>(
            initialValue:
                const [
                  'Excellent',
                  'Good',
                  'Fair',
                  'Needs work',
                  'I’m not sure yet',
                ].contains(controllers['credit']?.text)
                ? controllers['credit']!.text
                : null,
            hint: const SiteText(
              contentKey: 'copy.acquisition_support_page.10',
              literal: true,
              'Choose what feels closest',
            ),
            items:
                const [
                      'Excellent',
                      'Good',
                      'Fair',
                      'Needs work',
                      'I’m not sure yet',
                    ]
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: SiteText(
                          contentKey: 'copy.acquisition_support_page.m24',
                          literal: false,
                          option,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (selected) =>
                controllers['credit']?.text = selected ?? '',
          ),
        ),
      ],
    ),
    _ => _GuidedQuestion(
      title: SiteContentService.text(
        'readiness.q3_title',
        'What is already in motion?',
      ),
      copy: SiteContentService.text(
        'readiness.q3_body',
        'This is a planning checklist, not homework you must finish today. Select only what is genuinely underway.',
      ),
      children: [
        for (final item in const {
          'proof': 'Proof of funds',
          'tax': 'Tax returns or financial statements',
          'resume': 'Buyer résumé or operating story',
          'entity': 'Acquisition entity information',
          'lender': 'An introductory lender conversation',
        }.entries)
          CheckboxListTile(
            value: current.readiness[item.key] == true,
            title: SiteText(
              contentKey: 'copy.acquisition_support_page.m25',
              literal: false,
              item.value,
            ),
            activeColor: _green,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) =>
                setState(() => current.readiness[item.key] = checked == true),
          ),
      ],
    ),
  };

  Widget _readinessInput(String key, String label) => _LabeledField(
    label: label,
    labelColor: _ink,
    unit: r'$ CAD',
    child: TextField(
      controller: controllers[key],
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hint: SiteText(
          'Optional estimate',
          contentKey: 'copy.acquisition_support_page.field1',
          literal: true,
        ),
      ),
    ),
  );
}

// Retained temporarily for migration of earlier local Guide sessions.
// ignore: unused_element
class AcquisitionGuideSheet extends StatefulWidget {
  const AcquisitionGuideSheet({super.key, required this.foundation});
  final AcquisitionFoundation foundation;
  @override
  State<AcquisitionGuideSheet> createState() => _AcquisitionGuideSheetState();
}

class _AcquisitionGuideSheetState extends State<AcquisitionGuideSheet> {
  final input = TextEditingController();
  bool thinking = false;
  late final List<({bool user, String text})> messages;

  @override
  void initState() {
    super.initState();
    messages = [
      (
        user: false,
        text:
            'I want to understand you before I recommend anything. What outcome would make this acquisition successful three years after close?',
      ),
    ];
  }

  Future<void> _ask([String? prompt]) async {
    final question = (prompt ?? input.text).trim();
    if (question.isEmpty || thinking) return;
    final memory = List<String>.from(
      widget.foundation.readiness['guideMemory'] as List? ?? const [],
    )..add(question);
    widget.foundation.readiness['guideMemory'] = memory;
    await widget.foundation.save();
    setState(() {
      messages.add((user: true, text: question));
      input.clear();
      thinking = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    final lower = question.toLowerCase();
    String answer;
    if (memory.length == 1) {
      answer =
          'Got it. Now help me understand the constraint: how much capital must remain untouched after closing, and how involved do you want to be day to day?';
    } else if (memory.length == 2) {
      answer =
          'That changes the shape of a viable deal. One more thing before I form a view: which risk would you regret most—overpaying, operational complexity, unreliable earnings, or missing growth?';
    } else if (memory.length == 3) {
      answer =
          'I have enough context to start being useful. I’ll carry these priorities into your Blueprint, readiness actions, and future deal screens. Ask me about a target or opportunity and I’ll explain my reasoning—not just give a verdict.';
    } else if (lower.contains('next')) {
      answer = widget.foundation.readiness['proof'] != true
          ? 'Prepare proof of funds first, then validate debt capacity with a lender. Those two actions remove the biggest execution uncertainty.'
          : 'Your documentation is progressing. Screen a live opportunity and compare its price, economics, risk, and fit separately.';
    } else if (lower.contains('realistic') || lower.contains('afford')) {
      answer =
          'Your entered capital suggests an indicative acquisition capacity of ${_money(widget.foundation.capacity)}. Treat that as a planning range, not approval, until a lender validates leverage and debt service.';
    } else {
      answer =
          'A viable deal for you should fit ${_money(widget.foundation.minPrice)}–${_money(widget.foundation.maxPrice)}, meet at least ${widget.foundation.blueprint['minReturn']}% headline return, and respect this hard limit: ${widget.foundation.blueprint['limits']}.';
    }
    setState(() {
      messages.add((user: false, text: answer));
      thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .88,
    child: Material(
      color: _ink,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.auto_awesome_rounded),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SiteText(
                        contentKey: 'copy.acquisition_support_page.m26',
                        literal: true,
                        'Acquisition Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SiteText(
                        contentKey: 'copy.acquisition_support_page.m27',
                        literal: true,
                        'Personalized from your saved foundation',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SiteText(
                contentKey: 'copy.acquisition_support_page.m28',
                literal: false,
                widget.foundation.guideSummary,
                style: const TextStyle(color: _muted, height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  backgroundColor: _surface,
                  side: const BorderSide(color: _line),
                  label: const SiteText(
                    contentKey: 'copy.acquisition_support_page.11',
                    literal: true,
                    'Teach the Guide about me',
                    style: TextStyle(color: _lilac),
                  ),
                  onPressed: () => _ask(
                    'My main acquisition goal is long-term independence and durable cash flow.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  for (final message in messages)
                    Align(
                      alignment: message.user
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 620),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: message.user ? _green : _surface,
                          border: Border.all(color: _line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SiteText(
                          contentKey: 'copy.acquisition_support_page.m29',
                          literal: false,
                          message.text,
                          style: TextStyle(color: Colors.white, height: 1.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (thinking)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _lilac,
                      ),
                    ),
                    SizedBox(width: 9),
                    SiteText(
                      contentKey: 'copy.acquisition_support_page.m30',
                      literal: true,
                      'Connecting this to your acquisition profile…',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: _ask,
                    decoration: const InputDecoration(
                      hint: SiteText(
                        'Ask about your acquisition…',
                        contentKey: 'copy.acquisition_support_page.field2',
                        literal: true,
                      ),
                      hintStyle: TextStyle(color: _muted),
                      filled: true,
                      fillColor: _surface,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _green),
                  onPressed: thinking ? null : _ask,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class AcquisitionFoundation {
  AcquisitionFoundation({
    required this.blueprint,
    required this.readiness,
    required this.dealScreen,
  });
  final Map<String, dynamic> blueprint;
  final Map<String, dynamic> readiness;
  final Map<String, dynamic> dealScreen;

  static const _key = 'acquisition_foundation_v1';
  static const _pendingKey = 'acquisition_foundation_pending_sync';
  static const _completedKey = 'acquisition_completed_modules';
  static final _defaults = {
    'blueprint': {
      'type': '',
      'geography': '',
      'minPrice': '',
      'maxPrice': '',
      'minReturn': '',
      'involvement': '',
      'industries': '',
      'limits': '',
      'stretch': '',
    },
    'readiness': {
      'equity': '',
      'reserves': '',
      'income': '',
      'credit': '',
      'proof': false,
      'tax': true,
      'resume': false,
      'entity': false,
      'lender': false,
    },
    'dealScreen': <String, dynamic>{},
  };

  static Future<AcquisitionFoundation> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    var data = raw == null
        ? jsonDecode(jsonEncode(_defaults)) as Map<String, dynamic>
        : jsonDecode(raw) as Map<String, dynamic>;
    const legacyBlueprint = {
      'type': 'Business Acquisition',
      'geography': 'British Columbia',
      'minPrice': '500000',
      'maxPrice': '2000000',
      'minReturn': '18',
      'involvement': 'Owner-operator',
      'industries': 'Home services, recurring revenue',
      'limits': 'No turnarounds; no single customer over 25%',
      'stretch': 'Adjacent industries with an experienced GM',
    };
    final blueprint = Map<String, dynamic>.from(data['blueprint'] as Map);
    final isLegacySeed = legacyBlueprint.entries.every(
      (entry) => '${blueprint[entry.key]}' == entry.value,
    );
    if (isLegacySeed) {
      data = jsonDecode(jsonEncode(_defaults)) as Map<String, dynamic>;
      await prefs.setString(_key, jsonEncode(data));
    }
    if (BackendService.user != null && prefs.getBool(_pendingKey) != true) {
      try {
        final cloud = await AccountService.loadAcquisitionFoundation();
        if (cloud != null && cloud.isNotEmpty) {
          data = cloud;
          await prefs.setString(_key, jsonEncode(data));
        }
      } catch (_) {
        // The local draft remains available if the profile migration is pending.
      }
    }
    final blueprintData = data['blueprint'] is Map
        ? Map<String, dynamic>.from(data['blueprint'] as Map)
        : Map<String, dynamic>.from(_defaults['blueprint']! as Map);
    final readinessData = data['readiness'] is Map
        ? Map<String, dynamic>.from(data['readiness'] as Map)
        : Map<String, dynamic>.from(_defaults['readiness']! as Map);
    final dealData = data['dealScreen'] is Map
        ? Map<String, dynamic>.from(data['dealScreen'] as Map)
        : <String, dynamic>{};
    final foundation = AcquisitionFoundation(
      blueprint: blueprintData,
      readiness: readinessData,
      dealScreen: dealData,
    );
    if (BackendService.user != null && prefs.getBool(_pendingKey) == true) {
      try {
        await foundation.syncPendingToAccount();
      } catch (_) {}
    }
    return foundation;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
    await prefs.setBool(_pendingKey, true);
  }

  Map<String, dynamic> toJson() => {
    'blueprint': blueprint,
    'readiness': readiness,
    'dealScreen': dealScreen,
  };

  Future<void> saveForAccount(String module) async {
    await save();
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedKey) ?? <String>[];
    if (!completed.contains(module)) completed.add(module);
    await prefs.setStringList(_completedKey, completed);
    await syncPendingToAccount();
  }

  Future<void> syncPendingToAccount() async {
    if (BackendService.user == null) throw StateError('Sign in required.');
    final prefs = await SharedPreferences.getInstance();
    await AccountService.saveAcquisitionFoundation(
      toJson(),
      completedModules: prefs.getStringList(_completedKey) ?? const [],
    );
    await prefs.setBool(_pendingKey, false);
  }

  double get minPrice => double.tryParse('${blueprint['minPrice']}') ?? 0;
  double get maxPrice => double.tryParse('${blueprint['maxPrice']}') ?? 0;
  double get capacity =>
      ((double.tryParse('${readiness['equity']}') ?? 0) +
          (double.tryParse('${readiness['reserves']}') ?? 0) * .5) *
      4;
  int get blueprintScore =>
      ((blueprint.values.where((value) => '$value'.trim().isNotEmpty).length /
                  blueprint.length) *
              100)
          .round();
  int get readinessScore {
    var score = 30;
    for (final key in ['proof', 'tax', 'resume', 'entity', 'lender']) {
      if (readiness[key] == true) score += 10;
    }
    final credit = '${readiness['credit']}'.toLowerCase();
    score += credit.contains('excellent')
        ? 20
        : credit.contains('good')
        ? 14
        : 7;
    return score.clamp(0, 100);
  }

  String get guideSummary =>
      'You are targeting ${blueprint['type'].toString().toLowerCase()} opportunities in ${blueprint['geography']}, between ${_money(minPrice)} and ${_money(maxPrice)}. ${readiness['proof'] == true ? 'Your documentation is progressing well.' : 'Proof of funds is your clearest readiness gap.'}';
}

class _ModuleScaffold extends StatelessWidget {
  const _ModuleScaffold({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.currentStep,
    required this.onStepSelected,
    this.motionScroll,
    this.motionToggle,
    this.chapter = 0,
  });
  final int chapter;
  final ScrollController? motionScroll;
  final Widget? motionToggle;
  final String kicker, title, subtitle;
  final Widget child;
  final int currentStep;
  final ValueChanged<int> onStepSelected;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: motionScroll == null ? _cream : Colors.transparent,
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: [
        if (motionToggle != null) motionToggle!,
        const AppNavigationMenu(side: PlatformSide.business, dark: false),
        const SizedBox(width: 12),
      ],
    ),
    body: _backdrop(
      context, SingleChildScrollView(
        controller: motionScroll,
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AcquisitionEditorialHeader(
                          studio: motionScroll != null,
                          currentStep: currentStep,
                          onSelected: onStepSelected,
                          kicker: kicker,
                          title: title,
                          subtitle: subtitle,
                          accent: currentStep == 0
                              ? const Color(0xFF244E43)
                              : const Color(0xFF40556D),
                        ),
                      ),
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ),
            ),
            const MembershipFooter(),
          ],
        ),
      ),
    ),
  );
  Widget _backdrop(BuildContext context, Widget child) => motionScroll == null
      ? FixedEditorialBackground(
          contentKey: 'image.acquisition_module.$currentStep.background',
          imagePath: 'assets/images/commercial-atrium.jpg',
          wash: _cream,
          washOpacity: .34,
          child: child,
        )
      : SiteParallaxImage(
          controller: motionScroll!,
          contentKey: 'image.acquisition_module.$currentStep.background',
          asset: 'assets/images/affinity-reflection-facade.jpg',
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650),
            color: [
              const Color(0xDDE0EEE8),
              const Color(0xDDE0EAF4),
              const Color(0xDDEBE2F1),
              const Color(0xDDF0E9DC),
            ][chapter],
            child: child,
          ),
        );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.unit,
    this.labelColor = const Color(0xFFE2E2EA),
  });
  final String label;
  final String? unit;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: SiteText(
              contentKey: 'copy.acquisition_support_page.m31',
              literal: false,
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (unit != null)
            SiteText(
              contentKey: 'copy.acquisition_support_page.m32',
              literal: false,
              unit!,
              style: const TextStyle(
                color: _green,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _GuidedQuestion extends StatelessWidget {
  const _GuidedQuestion({
    required this.title,
    required this.copy,
    required this.children,
  });

  final String title;
  final String copy;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFD5E3DF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16234F48),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SiteText(
          contentKey: 'copy.acquisition_support_page.m33',
          literal: false,
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 12),
        SiteText(
          contentKey: 'copy.acquisition_support_page.m34',
          literal: false,
          copy,
          style: const TextStyle(color: Color(0xFF626270), height: 1.55),
        ),
        const SizedBox(height: 28),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFAF9F6),
              hintStyle: const TextStyle(color: Color(0xFF898995)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8DDE8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8DDE8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _green, width: 2),
              ),
            ),
            textTheme: Theme.of(
              context,
            ).textTheme.apply(bodyColor: _ink, displayColor: _ink),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _ink),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String _money(num value) =>
    '\$${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';
