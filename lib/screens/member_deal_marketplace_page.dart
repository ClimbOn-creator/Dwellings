import 'package:flutter/material.dart';

import '../models/platform_side.dart';
import '../services/backend_service.dart';
import '../services/affinity_admin_service.dart';
import '../services/deal_room_service.dart';
import '../services/marketplace_service.dart';
import '../services/member_deal_marketplace_service.dart';
import '../services/member_beta_service.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/membership_footer.dart';
import '../widgets/profile_photo.dart';
import '../widgets/site_copy_text.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'affinity_review_desk_page.dart';
import 'member_profile_page.dart';
import 'professional_onboarding_page.dart';

const _ink = Color(0xFF171717);
const _green = Color(0xFF053827);
const _surface = Color(0xFFFCFBF8);
const _line = Color(0xFFD6D1C9);
const _muted = Color(0xFF68635D);

enum _StudioView { opportunities, professionals, myPitches, dealResponses }

class MemberDealMarketplacePage extends StatefulWidget {
  const MemberDealMarketplacePage({super.key});

  @override
  State<MemberDealMarketplacePage> createState() =>
      _MemberDealMarketplacePageState();
}

class _MemberDealMarketplacePageState extends State<MemberDealMarketplacePage> {
  _StudioView _view = _StudioView.opportunities;
  late Future<List<MemberDealOpportunity>> _opportunities;
  late Future<List<MemberDealPitch>> _myPitches;
  late Future<List<MemberDealPitch>> _responses;
  late Future<List<MarketplaceProvider>> _professionals;
  String _professionalQuery = '';
  String _responseFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _opportunities = MemberDealMarketplaceService.browse();
    _myPitches = MemberDealMarketplaceService.loadMyPitches();
    _responses = MemberDealMarketplaceService.loadBuyerResponses();
    _professionals = MarketplaceService.loadAffinityMembers();
  }

  Future<bool> _ensureSignedIn() async {
    if (BackendService.user != null) return true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthPage()));
    if (!mounted || BackendService.user == null) return false;
    setState(_reload);
    return true;
  }

  Future<void> _pitch(MemberDealOpportunity deal) async {
    if (!await _ensureSignedIn() || !mounted) return;
    if (deal.isPreview) {
      _message(
        'This is a privacy-safe preview. Verified member deals become available after the Member Studio database update is applied.',
      );
      return;
    }
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _PitchDialog(deal: deal),
    );
    if (sent == true && mounted) {
      setState(_reload);
      _message('Pitch sent privately to the anonymous buyer.');
    }
  }

  Future<void> _submitDeal() async {
    if (!await _ensureSignedIn() || !mounted) return;
    try {
      final rooms = (await DealRoomService.loadRooms())
          .where((room) => room.isBusiness && room.status != 'archived')
          .toList();
      if (!mounted) return;
      if (rooms.isEmpty) {
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Complete a deal assessment first'),
            content: const Text(
              'Your Deal Screen and Pipeline create the private source record Affinity reviews. Nothing is published automatically.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('NOT NOW'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OPEN PIPELINE'),
              ),
            ],
          ),
        );
        if (open == true && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const DealRoomsPage(initialSide: PlatformSide.business),
            ),
          );
        }
        return;
      }
      final selected = await showModalBottomSheet<DealRoom>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a deal to Affinity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Affinity receives the private assessment. Members see nothing until we create and approve an anonymous summary.',
                  style: TextStyle(color: _muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                for (final room in rooms)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(room.title),
                    subtitle: Text(
                      '${room.city.isEmpty ? 'Location private' : room.city} · ${room.currentStage}',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.pop(context, room),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected == null) return;
      await MemberDealMarketplaceService.submitForReview(selected.id);
      if (mounted) {
        _message(
          'Submitted for Affinity review. It remains private until approved.',
        );
      }
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  Future<void> _openMatchSettings() async {
    if (!await _ensureSignedIn() || !mounted) return;
    try {
      final current = await MemberBetaService.loadPreferences();
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _MatchSettingsDialog(current: current),
      );
      if (saved == true && mounted) setState(_reload);
    } catch (error) {
      if (mounted) _message(_friendlyError(error));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F3EF),
    appBar: AppBar(
      toolbarHeight: 78,
      backgroundColor: const Color(0xFFF7F5F0),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      title: const HomeBrandButton(size: 58, dark: false),
      actions: const [
        AppNavigationMenu(side: PlatformSide.business, dark: false),
        SizedBox(width: 12),
      ],
    ),
    body: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [_hero(), _workspace(), const MembershipFooter()],
      ),
    ),
  );

  Widget _hero() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 350),
      padding: EdgeInsets.fromLTRB(24, compact ? 52 : 72, 24, 58),
      decoration: const BoxDecoration(
        color: Color(0xFF0B3A2C),
        image: DecorationImage(
          image: AssetImage('assets/images/affinity-member-studio.jpg'),
          fit: BoxFit.cover,
          opacity: .2,
          alignment: Alignment.center,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SiteCopyText(
                'studio.eyebrow',
                'AFFINITY PROFESSIONAL NETWORK',
                style: TextStyle(
                  color: Color(0xFFC8D8D1),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              SiteCopyText(
                'studio.title',
                'Opportunity meets expertise.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 42 : 62,
                  height: .96,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 720,
                child: SiteCopyText(
                  'studio.intro',
                  'A private professional network where verified specialists discover Affinity-reviewed acquisitions, understand the need, and make a concise confidential pitch.',
                  style: TextStyle(
                    color: Color(0xFFD9E2DE),
                    fontSize: 17,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _submitDeal,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('SUBMIT A DEAL'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfessionalOnboardingPage(),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8AA59A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('JOIN THE NETWORK'),
                  ),
                  FutureBuilder<bool>(
                    future: AffinityAdminService.isAdmin(),
                    builder: (context, snapshot) => snapshot.data == true
                        ? OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AffinityReviewDeskPage(),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF8AA59A)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 18,
                            ),
                            label: const Text('REVIEW DESK'),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workspace() => Container(
    width: double.infinity,
    color: const Color(0xFFF1F3EF),
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 84),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: LayoutBuilder(
          builder: (context, box) {
            final desktop = box.maxWidth >= 900;
            if (!desktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _viewSelector(),
                  const SizedBox(height: 20),
                  _currentView(),
                  const SizedBox(height: 20),
                  _privacyStrip(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 220, child: _desktopNavigation()),
                const SizedBox(width: 20),
                Expanded(child: _currentView()),
                const SizedBox(width: 20),
                SizedBox(width: 250, child: _privacyStrip()),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _desktopNavigation() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _navItem(
            _StudioView.opportunities,
            Icons.work_outline_rounded,
            'Opportunities',
          ),
          _navItem(
            _StudioView.professionals,
            Icons.people_outline_rounded,
            'Professionals',
          ),
          _navItem(_StudioView.myPitches, Icons.send_outlined, 'My pitches'),
          _navItem(
            _StudioView.dealResponses,
            Icons.inbox_outlined,
            'Deal responses',
          ),
        ],
      ),
    ),
  );

  Widget _navItem(_StudioView view, IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: _view == view,
      selectedTileColor: const Color(0xFFE7EEE9),
      leading: Icon(icon, size: 20, color: _view == view ? _green : _muted),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: _view == view ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () => setState(() => _view = view),
    ),
  );

  Widget _privacyStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFE7EEE9),
          child: Icon(Icons.shield_outlined, color: _green, size: 20),
        ),
        SizedBox(height: 16),
        Text(
          'Private by design',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 9),
        SiteCopyText(
          'studio.privacy',
          'Members see only an Affinity-written opportunity brief. Buyer names, exact addresses, documents, raw assessments, and contact details remain private until the buyer accepts a pitch.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
        ),
      ],
    ),
  );

  Widget _viewSelector() => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      _viewChip(_StudioView.opportunities, 'OPPORTUNITIES'),
      _viewChip(_StudioView.professionals, 'PROFESSIONALS'),
      _viewChip(_StudioView.myPitches, 'MY PITCHES'),
      _viewChip(_StudioView.dealResponses, 'MY DEAL RESPONSES'),
    ],
  );

  Widget _viewChip(_StudioView view, String label) => ChoiceChip(
    label: Text(label),
    selected: _view == view,
    selectedColor: _green,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: _view == view ? Colors.white : _ink,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: .7,
    ),
    side: const BorderSide(color: _line),
    onSelected: (_) => setState(() => _view = view),
  );

  Widget _currentView() => switch (_view) {
    _StudioView.opportunities => _opportunityFeed(),
    _StudioView.professionals => _professionalDirectory(),
    _StudioView.myPitches => _pitchList(_myPitches, buyerView: false),
    _StudioView.dealResponses => _pitchList(_responses, buyerView: true),
  };

  Widget _opportunityFeed() => FutureBuilder<List<MemberDealOpportunity>>(
    future: _opportunities,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      if (snapshot.hasError) {
        return _AccessState(
          title: 'Member access required',
          message:
              'Sign in with a verified professional profile to browse approved opportunities. Buyer identities remain private.',
          action: BackendService.user == null ? 'SIGN IN' : null,
          onTap: BackendService.user == null
              ? () async {
                  if (await _ensureSignedIn() && mounted) setState(_reload);
                }
              : null,
        );
      }
      final deals = snapshot.data ?? [];
      if (deals.isEmpty) {
        return const _AccessState(
          title: 'The review desk is active',
          message:
              'Approved opportunities will appear here after Affinity completes its evaluation and privacy review.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              const title = SiteCopyText(
                'studio.opportunities_title',
                'Reviewed opportunities',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              );
              final settings = OutlinedButton.icon(
                onPressed: _openMatchSettings,
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('MATCH SETTINGS'),
              );
              if (box.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), settings],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  settings,
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'Concise, anonymous briefs prepared by Affinity.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 20),
          for (final deal in deals) ...[
            _DealPost(deal: deal, onPitch: () => _pitch(deal)),
            const SizedBox(height: 18),
          ],
        ],
      );
    },
  );

  Widget _professionalDirectory() => FutureBuilder<List<MarketplaceProvider>>(
    future: _professionals,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      final query = _professionalQuery.trim().toLowerCase();
      final providers = (snapshot.data ?? const <MarketplaceProvider>[])
          .where(
            (provider) =>
                query.isEmpty ||
                '${provider.name} ${provider.company} ${provider.jobTitle} ${provider.specialty}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SiteCopyText(
            'studio.professionals_title',
            'Verified professionals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          const SiteCopyText(
            'studio.professionals_intro',
            'Find the people buyers may need across financing, diligence, legal, tax, insurance, operations, and transition.',
            style: TextStyle(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _professionalQuery = value),
            decoration: InputDecoration(
              hintText: 'Search expertise, company, or name',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (providers.isEmpty)
            const _AccessState(
              title: 'No matching professionals yet',
              message:
                  'Try a broader specialty or check back as the verified network grows.',
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth >= 680
                    ? (box.maxWidth - 14) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final provider in providers)
                      SizedBox(
                        width: width,
                        child: _ProfessionalCard(provider: provider),
                      ),
                  ],
                );
              },
            ),
        ],
      );
    },
  );

  Widget _pitchList(
    Future<List<MemberDealPitch>> future, {
    required bool buyerView,
  }) => FutureBuilder<List<MemberDealPitch>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingBlock();
      }
      if (BackendService.user == null) {
        return _AccessState(
          title: 'Sign in to see private activity',
          message: buyerView
              ? 'Buyer responses are visible only to the owner of the submitted deal.'
              : 'Your pitches and buyer decisions are visible only to your member account.',
          action: 'SIGN IN',
          onTap: () async {
            if (await _ensureSignedIn() && mounted) setState(_reload);
          },
        );
      }
      if (snapshot.hasError) {
        return _AccessState(
          title: 'Member Studio setup required',
          message: _friendlyError(snapshot.error!),
        );
      }
      final allPitches = snapshot.data ?? [];
      final pitches = buyerView && _responseFilter != 'all'
          ? allPitches
                .where((pitch) => pitch.status == _responseFilter)
                .toList()
          : allPitches;
      if (allPitches.isEmpty) {
        return _AccessState(
          title: buyerView ? 'No deal responses yet' : 'No pitches yet',
          message: buyerView
              ? 'When a verified member responds to your published deal, their short pitch and contact details appear here.'
              : 'Review an approved opportunity and send a concise, specific proposal. Your contact details go to the buyer—not the other way around.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buyerView) ...[
            const Text(
              'Compare private pitches',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Shortlist promising professionals before sharing your identity. Only acceptance releases your account email.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _responseChip('all', 'ALL ${allPitches.length}'),
                _responseChip(
                  'submitted',
                  'NEW ${allPitches.where((p) => p.status == 'submitted').length}',
                ),
                _responseChip(
                  'shortlisted',
                  'SHORTLIST ${allPitches.where((p) => p.status == 'shortlisted').length}',
                ),
                _responseChip(
                  'accepted',
                  'CONNECTED ${allPitches.where((p) => p.status == 'accepted').length}',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (pitches.isEmpty)
            const _AccessState(
              title: 'No pitches in this view',
              message:
                  'Choose another response filter to compare your private proposals.',
            ),
          for (final pitch in pitches) ...[
            _PitchCard(
              pitch: pitch,
              buyerView: buyerView,
              onRespond: buyerView
                  ? (status) async {
                      try {
                        await MemberDealMarketplaceService.respondToPitch(
                          pitch.id,
                          status,
                        );
                        if (mounted) setState(_reload);
                      } catch (error) {
                        if (mounted) _message(_friendlyError(error));
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    },
  );

  Widget _responseChip(String value, String label) => ChoiceChip(
    label: Text(label),
    selected: _responseFilter == value,
    selectedColor: _green,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: _responseFilter == value ? Colors.white : _ink,
      fontSize: 9,
      fontWeight: FontWeight.w900,
    ),
    onSelected: (_) => setState(() => _responseFilter = value),
  );
}

class _DealPost extends StatelessWidget {
  const _DealPost({required this.deal, required this.onPitch});
  final MemberDealOpportunity deal;
  final VoidCallback onPitch;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: const Color(0xFFE2E5DF)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: _green,
              child: Icon(Icons.lock_person_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANONYMOUS BUYER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Identity protected · Affinity reviewed',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _Score(score: deal.affinityScore),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          deal.headline,
          style: const TextStyle(
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '${deal.industry} · ${deal.region} · ${deal.stage}',
          style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
        ),
        if (deal.matchScore != null) ...[
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 16, color: _green),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${deal.matchScore}% professional match · ${deal.matchReason}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(deal.summary, style: const TextStyle(height: 1.6, fontSize: 15)),
        const SizedBox(height: 22),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: [
            _Fact(label: 'PRICE BAND', value: deal.purchasePriceBand),
            _Fact(label: 'CAPITAL SOUGHT', value: deal.capitalRequiredBand),
            _Fact(label: 'AFFINITY VIEW', value: deal.scoreLabel),
          ],
        ),
        if (deal.supportNeeded.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final need in deal.supportNeeded)
                Chip(
                  label: Text(need),
                  backgroundColor: const Color(0xFFE7ECE9),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 210,
              child: Text(
                deal.isPreview
                    ? 'PRIVACY-SAFE PREVIEW'
                    : 'ONLY YOUR PITCH IS SHARED',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onPitch,
              style: FilledButton.styleFrom(backgroundColor: _green),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('PITCH THIS DEAL'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PitchDialog extends StatefulWidget {
  const _PitchDialog({required this.deal});
  final MemberDealOpportunity deal;

  @override
  State<_PitchDialog> createState() => _PitchDialogState();
}

class _PitchDialogState extends State<_PitchDialog> {
  final _pitch = TextEditingController();
  final _offer = TextEditingController();
  late final TextEditingController _email;
  bool _confirmed = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: BackendService.user?.email ?? '');
  }

  @override
  void dispose() {
    _pitch.dispose();
    _offer.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_pitch.text.trim().length < 30 ||
        !_email.text.contains('@') ||
        !_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write a specific pitch, include a valid reply email, and confirm the privacy rule.',
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await MemberDealMarketplaceService.sendPitch(
        opportunityId: widget.deal.id,
        pitch: _pitch.text,
        offerSummary: _offer.text,
        contactEmail: _email.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pitch the anonymous buyer'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deal.headline, style: const TextStyle(color: _muted)),
            const SizedBox(height: 18),
            TextField(
              controller: _pitch,
              maxLength: 420,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your pitch',
                hintText:
                    'Explain what you can offer, why it fits this deal, and the next useful step.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _offer,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Offer summary',
                hintText: 'Example: Indicative loan from 8%, subject to review',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Your reply email'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text(
                'I will not ask Affinity to reveal the buyer. The buyer decides whether to share contact details.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _sending ? null : () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: Text(_sending ? 'SENDING…' : 'SEND PRIVATE PITCH'),
      ),
    ],
  );
}

class _PitchCard extends StatelessWidget {
  const _PitchCard({
    required this.pitch,
    required this.buyerView,
    this.onRespond,
  });
  final MemberDealPitch pitch;
  final bool buyerView;
  final ValueChanged<String>? onRespond;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: const Color(0xFFE2E5DF)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                buyerView
                    ? '${pitch.providerName}${pitch.companyName.isEmpty ? '' : ' · ${pitch.companyName}'}'
                    : pitch.opportunityHeadline,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _StatusPill(pitch.status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          buyerView ? pitch.providerType : 'Anonymous buyer',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Text(pitch.pitch, style: const TextStyle(height: 1.55)),
        if (pitch.offerSummary.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            pitch.offerSummary,
            style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
          ),
        ],
        if (buyerView && pitch.contactEmail.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText('Reply to ${pitch.contactEmail}'),
        ],
        if (!buyerView && pitch.buyerContactEmail.isNotEmpty) ...[
          const SizedBox(height: 14),
          SelectableText(
            'Buyer accepted · ${pitch.buyerContactEmail}',
            style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
          ),
        ],
        if (buyerView &&
            (pitch.status == 'submitted' || pitch.status == 'shortlisted')) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            children: [
              if (pitch.status == 'submitted')
                OutlinedButton.icon(
                  onPressed: () => onRespond?.call('shortlisted'),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                  label: const Text('SHORTLIST'),
                ),
              FilledButton(
                onPressed: () => onRespond?.call('accepted'),
                style: FilledButton.styleFrom(backgroundColor: _green),
                child: const Text('ACCEPT & SHARE MY EMAIL'),
              ),
              OutlinedButton(
                onPressed: () => onRespond?.call('declined'),
                child: const Text('DECLINE'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _MatchSettingsDialog extends StatefulWidget {
  const _MatchSettingsDialog({required this.current});
  final AffinityMatchPreferences current;

  @override
  State<_MatchSettingsDialog> createState() => _MatchSettingsDialogState();
}

class _MatchSettingsDialogState extends State<_MatchSettingsDialog> {
  late final TextEditingController specialties;
  late final TextEditingController regions;
  late double minimumScore;
  late bool emailNotifications;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    specialties = TextEditingController(
      text: widget.current.specialties.join(', '),
    );
    regions = TextEditingController(text: widget.current.regions.join(', '));
    minimumScore = widget.current.minimumScore.toDouble();
    emailNotifications = widget.current.emailNotifications;
  }

  @override
  void dispose() {
    specialties.dispose();
    regions.dispose();
    super.dispose();
  }

  List<String> _split(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await MemberBetaService.savePreferences(
        AffinityMatchPreferences(
          specialties: _split(specialties.text),
          regions: _split(regions.text),
          minimumScore: minimumScore.round(),
          emailNotifications: emailNotifications,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Opportunity match settings'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Affinity uses these preferences to rank and filter anonymous opportunities. They are never shown to buyers.',
              style: TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: specialties,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Expertise',
                hintText: 'Commercial lending, QOE, M&A legal',
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: regions,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Regions',
                hintText: 'British Columbia, Alberta',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Minimum Affinity score · ${minimumScore.round()}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: minimumScore,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _green,
              onChanged: (value) => setState(() => minimumScore = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: emailNotifications,
              activeThumbColor: _green,
              title: const Text('Email me about private activity'),
              subtitle: const Text('Deal matches and pitch decisions only.'),
              onChanged: (value) => setState(() => emailNotifications = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: _green),
        child: Text(saving ? 'SAVING…' : 'SAVE MATCH SETTINGS'),
      ),
    ],
  );
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.provider});
  final MarketplaceProvider provider;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberProfilePage(provider: provider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilePhoto(
                  size: 56,
                  photoUrl: provider.photoUrl,
                  exampleIndex: provider.photoIndex,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (provider.verified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: _green,
                              size: 17,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        provider.jobTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              provider.company.isEmpty
                  ? provider.category.label
                  : provider.company,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            if (provider.specialty.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                provider.specialty,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EEE9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    provider.category.label.toUpperCase(),
                    style: const TextStyle(
                      color: _green,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'VIEW PROFILE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    color: const Color(0xFFE7ECE9),
    child: Column(
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: _green,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'SCORE',
          style: TextStyle(color: _green, fontSize: 8, letterSpacing: .8),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: status == 'accepted'
          ? const Color(0xFFDCECE4)
          : const Color(0xFFEDEAE4),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      status.toUpperCase(),
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 280,
    child: Center(child: CircularProgressIndicator(color: _green)),
  );
}

class _AccessState extends StatelessWidget {
  const _AccessState({
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(38),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.lock_outline, color: _green, size: 32),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        if (action != null && onTap != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: _green),
            child: Text(action!),
          ),
        ],
      ],
    ),
  );
}

String _friendlyError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  if (text.contains('verified Affinity member')) {
    return 'A verified, active professional membership is required to browse and pitch opportunities.';
  }
  if (text.contains('Could not find the function') ||
      text.contains('does not exist')) {
    return 'The Member Studio backend migration still needs to be applied.';
  }
  return text;
}
