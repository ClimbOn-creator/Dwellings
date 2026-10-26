import '../services/app_tunnel.dart';
import 'learning_dashboard_page.dart';
import 'seller_dashboard_page.dart';
import '../widgets/nova_target.dart';
import '../widgets/nova_training_status.dart';
import 'buyer_resources_page.dart';
import '../widgets/site_copy_text.dart';
import '../widgets/flowing_color_banner.dart';
import '../widgets/personal_motion.dart';
import '../widgets/marketplace_motion.dart';
import '../widgets/site_text.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/pact_profile_service.dart';
import '../widgets/pact_profile_panel.dart';

import '../models/platform_side.dart';
import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../services/deal_room_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/profile_photo.dart';
import '../widgets/app_navigation_menu.dart';
import '../widgets/topo_background.dart';
import '../widgets/membership_footer.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'member_deal_marketplace_page.dart';
import 'member_profile_page.dart';
import 'acquisition_support_page.dart';

const _ink = Color(0xFF171717);
const _purple = Color(0xFF252525);
const _lilac = Color(0xFF9B9B98);

class _LegacyProfilePage extends StatefulWidget {
  const _LegacyProfilePage();

  @override
  State<_LegacyProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_LegacyProfilePage> {
  final _overviewAnchor = GlobalKey();
  final _teamAnchor = GlobalKey();
  final _detailsAnchor = GlobalKey();
  AccountProfile? _profile;
  DashboardStats? _stats;
  List<MarketplaceProvider> _team = [];
  List<DealRoom> _deals = [];
  Map<String, dynamic>? _acquisition;
  bool _loading = true;
  bool _saving = false;
  Timer? _refreshTimer;
  StreamSubscription<dynamic>? _accountChanges;
  String? _editRevision;
  final _name = TextEditingController();
  final _job = TextEditingController();
  final _company = TextEditingController();
  final _bio = TextEditingController();
  String _employment = 'company';

  @override
  void initState() {
    super.initState();
    _load();
    _loadAcquisition();
    _accountChanges = BackendService.authChanges?.listen((_) {
      if (mounted && BackendService.user?.id != _profile?.id) {
        setState(() {
          _profile = null;
          _stats = null;
          _team = [];
          _deals = [];
        });
        _load();
      }
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshActivity(),
    );
  }

  Future<void> _loadAcquisition() async {
    try {
      final value = await AccountService.loadAcquisitionFoundation();
      if (mounted) setState(() => _acquisition = value);
    } catch (_) {
      // The rest of the profile remains usable while the migration rolls out.
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _accountChanges?.cancel();
    _name.dispose();
    _job.dispose();
    _company.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _refreshActivity() async {
    final actor = BackendService.user?.id;
    if (actor == null) return;
    try {
      final values = await Future.wait([
        AccountService.loadStats(),
        AccountService.loadTeam(),
        DealRoomService.loadRooms(),
        AccountService.loadProfile(),
      ]);
      if (!mounted || BackendService.user?.id != actor) return;
      final latest = values[3] as AccountProfile?;
      final dirty =
          _name.text != (_profile?.fullName ?? '') ||
          _job.text != (_profile?.jobTitle ?? '') ||
          _company.text != (_profile?.companyName ?? '') ||
          _bio.text != (_profile?.bio ?? '');
      setState(() {
        _stats = values[0] as DashboardStats;
        _team = values[1] as List<MarketplaceProvider>;
        _deals = values[2] as List<DealRoom>;
        _profile = latest;
        if (!dirty && latest != null) {
          _name.text = latest.fullName;
          _job.text = latest.jobTitle;
          _company.text = latest.companyName;
          _bio.text = latest.bio;
          _editRevision = latest.updatedAt;
        }
      });
    } catch (_) {
      /* Keep the last confirmed dashboard through connection loss. */
    }
  }

  Future<void> _load() async {
    final actor = BackendService.user?.id;
    if (actor == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final values = await Future.wait([
        AccountService.loadProfile(),
        AccountService.loadStats(),
        AccountService.loadTeam(),
        DealRoomService.loadRooms(),
      ]);
      final profile = values[0] as AccountProfile?;
      if (!mounted || BackendService.user?.id != actor) return;
      setState(() {
        _profile = profile;
        _editRevision = profile?.updatedAt;
        _stats = values[1] as DashboardStats;
        _team = values[2] as List<MarketplaceProvider>;
        _deals = values[3] as List<DealRoom>;
        _loading = false;
        _name.text = profile?.fullName ?? '';
        _job.text = profile?.jobTitle ?? '';
        _company.text = profile?.companyName ?? '';
        _bio.text = profile?.bio ?? '';
        _employment = profile?.employmentType.isNotEmpty == true
            ? profile!.employmentType
            : 'company';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${error}'},
              contentKey: 'copy.profile_page.m1',
              literal: false,
              "Could not load profile: {{value1}}",
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountService.updateProfile(
        fullName: _name.text,
        jobTitle: _job.text,
        companyName: _company.text,
        employmentType: _employment,
        bio: _bio.text,
        expectedUpdatedAt: _editRevision,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: SiteText(
              contentKey: 'copy.profile_page.m2',
              literal: true,
              'Profile saved.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save. Your profile may have changed on another device. Reopen the full editor to load the latest version.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editProfile() async {
    final profile = await AccountService.loadProfile();
    final professional = await MarketplaceService.loadMyProfessionalProfile();
    if (!mounted || profile == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PactProfileEditorPage(profile: profile, professional: professional),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _photo({bool cover = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (await PactProfileService.pickImage(cover ? 'cover' : 'avatar'))
        await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this image. Your saved photo is safe; please retry.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await BackendService.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PersonalMotion(
    profile: true,
    builder: (context, scroll, toggle) =>
        _buildProfile(context, scroll, toggle),
  );

  Widget _buildProfile(
    BuildContext context,
    ScrollController scroll,
    Widget toggle,
  ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _ink,
        body: TopoBackground(
          child: Center(child: CircularProgressIndicator(color: _purple)),
        ),
      );
    }
    if (BackendService.user == null) {
      return AuthPage(onAuthenticated: _load);
    }
    final profile = _profile;
    final stats =
        _stats ??
        const DashboardStats(
          analysisCount: 0,
          teamCount: 0,
          introductionCount: 0,
          dealRoomCount: 0,
          lastAddress: '',
          lastRisk: null,
        );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        backgroundColor: const Color(0xFFF7F8F4),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        title: const HomeBrandButton(size: 66, dark: false),
        actions: [
          toggle,
          const AppNavigationMenu(guidePage: 'profile', dark: false),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverToBoxAdapter(
            child: NovaTarget(
              id: 'profile.identity',
              child: _header(profile, scroll),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NovaTrainingStatus(),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 980
                              ? (constraints.maxWidth - 48) / 5
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _StatCard(
                                width: width,
                                value: '${stats.analysisCount}',
                                label: 'Saved analyses',
                              ),
                              _StatCard(
                                width: width,
                                value: '${stats.teamCount}',
                                label: 'Team members',
                              ),
                              _StatCard(
                                width: width,
                                value: '${stats.dealRoomCount}',
                                label: 'Deal Rooms',
                              ),
                              _StatCard(
                                width: width,
                                value: stats.lastRisk == null
                                    ? '—'
                                    : '${stats.lastRisk!.round()}/100',
                                label: 'Latest risk score',
                              ),
                              _StatCard(
                                width: width,
                                value: stats.lastAddress.isEmpty
                                    ? 'No draft yet'
                                    : stats.lastAddress,
                                label: 'Latest property',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                        key: _overviewAnchor,
                        child: NovaTarget(
                          id: 'profile.path',
                          child:
                              AppTunnelController.current.value ==
                                      AppTunnel.buyer ||
                                  AppTunnelController.current.value ==
                                      AppTunnel.landing
                              ? _acquisitionPath()
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      NovaTarget(id: 'profile.deals', child: _currentDeals()),
                      const SizedBox(height: 42),
                      SiteText(
                        key: _teamAnchor,
                        contentKey: 'copy.profile_page.1',
                        literal: true,
                        'Your selected team',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SiteText(
                        contentKey: 'copy.profile_page.2',
                        literal: true,
                        'The professionals you select for your team stay attached to your account.',
                        style: TextStyle(color: Color(0xFF666674)),
                      ),
                      const SizedBox(height: 20),
                      if (_team.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const SiteText(
                            contentKey: 'copy.profile_page.3',
                            literal: true,
                            'Your team is empty. Add professionals from My team in your dashboard.',
                          ),
                        )
                      else
                        ..._team.map(_teamRow),
                      const SizedBox(height: 36),
                      const BuyerResourcesPanel(teamOnly: true),
                      const SizedBox(height: 32),
                      KeyedSubtree(
                        key: _detailsAnchor,
                        child: NovaTarget(
                          id: 'profile.editor',
                          child: _profileEditor(profile),
                        ),
                      ),
                      const SizedBox(height: 42),
                      const MembershipFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acquisitionPath() {
    final foundation = _acquisition ?? const <String, dynamic>{};
    final blueprint = foundation['blueprint'] is Map
        ? Map<String, dynamic>.from(foundation['blueprint'] as Map)
        : const <String, dynamic>{};
    final readiness = foundation['readiness'] is Map
        ? Map<String, dynamic>.from(foundation['readiness'] as Map)
        : const <String, dynamic>{};
    final deal = foundation['dealScreen'] is Map
        ? Map<String, dynamic>.from(foundation['dealScreen'] as Map)
        : const <String, dynamic>{};
    final steps = <(String, bool, Widget)>[
      (
        '1. Blueprint',
        blueprint.values.any((value) => '$value'.trim().isNotEmpty),
        const AcquisitionBlueprintPage(),
      ),
      (
        '2. Readiness',
        readiness.values.any(
          (value) => value is bool ? value : '$value'.trim().isNotEmpty,
        ),
        const BuyerReadinessPage(),
      ),
      (
        '3. Deal screen',
        deal.isNotEmpty,
        const DealRoomsPage(
          initialSide: PlatformSide.business,
          initialView: BuyerDashboardView.dealScreen,
        ),
      ),
      (
        '4. Pipeline',
        _deals.any((room) => room.isBusiness),
        const DealRoomsPage(initialSide: PlatformSide.business),
      ),
    ];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F3FB),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SiteText(
            contentKey: 'copy.profile_page.4',
            literal: true,
            'YOUR ACQUISITION PATH',
            style: TextStyle(
              color: _lilac,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const SiteText(
            contentKey: 'copy.profile_page.5',
            literal: true,
            'Saved to your account',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: steps
                .map(
                  (step) => ActionChip(
                    avatar: Icon(
                      step.$2 ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: step.$2 ? const Color(0xFF7DE2C1) : _lilac,
                    ),
                    label: SiteText(
                      contentKey: 'copy.profile_page.m4',
                      literal: false,
                      step.$1,
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => step.$3)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _jumpTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null)
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
  }

  Widget _header(AccountProfile? profile, ScrollController scroll) => Column(
    children: [
      SizedBox(
        height: 205,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (profile?.coverUrl.isNotEmpty == true)
              Image.network(
                profile!.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const FlowingColorBanner(),
              )
            else
              EditableColorCover(
                contentKey: 'image.profile_page.mbackground1',
                original: const FlowingColorBanner(),
              ),
            Positioned(
              right: 20,
              bottom: 16,
              child: IconButton.filledTonal(
                onPressed: _saving ? null : () => _photo(cover: true),
                tooltip: 'Change cover photo',
                icon: const Icon(Icons.camera_alt_outlined),
              ),
            ),
          ],
        ),
      ),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxWidth < 650;
                final portrait = Transform.translate(
                  offset: const Offset(0, -48),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(52),
                    ),
                    child: Stack(
                      children: [
                        ProfilePhoto(
                          size: compact ? 148 : 210,
                          photoUrl: profile?.photoUrl ?? '',
                          borderRadius: BorderRadius.circular(44),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: IconButton.filled(
                            onPressed: _saving ? null : _photo,
                            tooltip: 'Upload profile photo',
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SiteText(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : 'Complete your profile',
                      contentKey: 'copy.profile_page.m5',
                      literal: false,
                      style: TextStyle(
                        fontSize: compact ? 30 : 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SiteText(
                      _publicIdentity(profile),
                      contentKey: 'copy.profile_page.m6',
                      literal: false,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF504956),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _editProfile,
                      child: const SiteCopyText(
                        'profile.portfolio.edit',
                        'Edit profile',
                      ),
                    ),
                  ],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 128, child: portrait),
                              identity,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 184, child: portrait),
                              const SizedBox(width: 32),
                              Expanded(child: identity),
                            ],
                          ),
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 20,
                      children: [
                        TextButton(
                          onPressed: () => _jumpTo(_overviewAnchor),
                          child: const SiteCopyText(
                            'profile.portfolio.overview',
                            'Overview',
                          ),
                        ),
                        TextButton(
                          onPressed: () => _jumpTo(_teamAnchor),
                          child: const SiteCopyText(
                            'profile.portfolio.team',
                            'My team',
                          ),
                        ),
                        TextButton(
                          onPressed: _editProfile,
                          child: const SiteCopyText(
                            'profile.portfolio.about',
                            'About & details',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ],
  );

  Widget _currentDeals() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E2E9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SiteText(
                contentKey: 'copy.profile_page.m7',
                literal: true,
                'Current deals',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => switch (AppTunnelController.current.value) {
                    AppTunnel.seller => const SellerDashboardPage(),
                    AppTunnel.learning => const LearningDashboardPage(),
                    AppTunnel.member => const MemberDashboardPage(),
                    _ => const DealRoomsPage(
                      initialSide: PlatformSide.business,
                    ),
                  },
                ),
              ),
              child: const SiteText(
                contentKey: 'copy.profile_page.6',
                literal: true,
                'VIEW ALL',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_deals.isEmpty)
          const SiteText(
            contentKey: 'copy.profile_page.7',
            literal: true,
            'No active deals yet. Your next property or business acquisition will appear here.',
            style: TextStyle(color: Color(0xFF666674), height: 1.45),
          )
        else
          ..._deals
              .take(3)
              .map(
                (deal) => InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DealRoomPage(room: deal),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SiteText(
                                contentKey: 'copy.profile_page.m8',
                                literal: false,
                                deal.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            SiteText(
                              contentKey: 'copy.profile_page.m9',
                              literal: false,
                              '${deal.completedTaskCount}/${deal.totalTaskCount}',
                              style: const TextStyle(
                                color: _purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: deal.progress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: const Color(0xFFE8E8EF),
                          color: _purple,
                        ),
                        const SizedBox(height: 7),
                        SiteText(
                          templateValues: {
                            'value1': '${deal.currentStep.toUpperCase()}',
                          },
                          contentKey: 'copy.profile_page.m10',
                          literal: false,
                          "CURRENT STEP · {{value1}}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF666674),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    ),
  );

  String _publicIdentity(AccountProfile? profile) {
    if (profile == null) return 'Pact member';
    final parts = [
      profile.jobTitle,
      profile.companyName,
    ].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? _roleLabel(profile.role) : parts.join(' · ');
  }

  Widget _profileEditor(AccountProfile? profile) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      title: const SiteText(
        contentKey: 'copy.profile_page.15',
        literal: true,
        'Profile details',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      subtitle: SiteText(
        templateValues: {'value1': '${_roleLabel(profile?.role ?? 'user')}'},
        contentKey: 'copy.profile_page.m19',
        literal: false,
        "{{value1}} account · Tap to edit",
        style: const TextStyle(
          color: _purple,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        const Text(
          'For professional accounts, identity details also appear on your public professional profile.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : _editProfile,
          icon: const Icon(Icons.tune),
          label: const Text('Edit full profile and specialties'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            label: SiteText(
              'Full name',
              contentKey: 'copy.profile_page.field5',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _job,
          decoration: const InputDecoration(
            label: SiteText(
              'Job title or specialty',
              contentKey: 'copy.profile_page.field6',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _company,
          decoration: const InputDecoration(
            label: SiteText(
              'Company, firm or practice',
              contentKey: 'copy.profile_page.field7',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _employment,
          decoration: const InputDecoration(
            label: SiteText(
              'Work arrangement',
              contentKey: 'copy.profile_page.field8',
              literal: true,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'company',
              child: SiteText(
                contentKey: 'copy.profile_page.m20',
                literal: true,
                'Part of a company or firm',
              ),
            ),
            DropdownMenuItem(
              value: 'self_employed',
              child: SiteText(
                contentKey: 'copy.profile_page.m21',
                literal: true,
                'Self-employed',
              ),
            ),
            DropdownMenuItem(
              value: 'own_practice',
              child: SiteText(
                contentKey: 'copy.profile_page.m22',
                literal: true,
                'Own practice or company',
              ),
            ),
          ],
          onChanged: (value) =>
              setState(() => _employment = value ?? _employment),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLines: 3,
          decoration: const InputDecoration(
            label: SiteText(
              'Professional bio or property goals',
              contentKey: 'copy.profile_page.field9',
              literal: true,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          child: SiteText(
            contentKey: 'copy.profile_page.m23',
            literal: false,
            _saving ? 'Saving…' : 'Save profile',
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 17),
          label: const SiteText(
            contentKey: 'copy.profile_page.16',
            literal: true,
            'Sign out',
          ),
        ),
      ],
    ),
  );

  Widget _teamRow(MarketplaceProvider provider) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      leading: ProfilePhoto(
        size: 58,
        photoUrl: provider.photoUrl,
        exampleIndex: provider.photoIndex,
        borderRadius: BorderRadius.circular(16),
      ),
      title: SiteText(
        contentKey: 'copy.profile_page.m24',
        literal: false,
        provider.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: SiteText(
        contentKey: 'copy.profile_page.m25',
        literal: false,
        '${provider.jobTitle} · ${provider.company}',
        style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SiteText(
            contentKey: 'copy.profile_page.m26',
            literal: false,
            provider.specialty,
            style: const TextStyle(
              color: Color(0xFF666674),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        if (provider.email.isNotEmpty ||
            provider.phone.isNotEmpty ||
            provider.websiteUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              [
                if (provider.email.isNotEmpty) provider.email,
                if (provider.phone.isNotEmpty) provider.phone,
                if (provider.websiteUrl.isNotEmpty) provider.websiteUrl,
              ].join('  ·  '),
              style: const TextStyle(
                color: Color(0xFF3F3F4C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: SiteText(
            templateValues: {
              'value1': '${provider.reviewScore.toStringAsFixed(1)}',
              'value2': '${provider.reviewCount}',
              'value3': '${provider.experience}',
              'value4': '${provider.isExample ? ' · Example profile' : ''}',
            },
            contentKey: 'copy.profile_page.m27',
            literal: false,
            "{{value1}} ★ · {{value2}} ratings · {{value3}} years experience{{value4}}",
            style: const TextStyle(
              color: _purple,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MemberProfilePage(
                  provider: provider,
                  messageDestinationBuilder: (_) =>
                      MemberDashboardPage(initialChatProvider: provider),
                ),
              ),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const SiteText(
              contentKey: 'copy.profile_page.17',
              literal: true,
              'OPEN FULL PROFILE',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await AccountService.removeTeamMember(provider.id);
                await _refreshActivity();
              },
              icon: const Icon(Icons.person_remove_outlined, size: 17),
              label: const SiteText(
                contentKey: 'copy.profile_page.18',
                literal: true,
                'REMOVE',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  String _roleLabel(String value) => switch (value) {
    'realtor' => 'Realtor',
    'mortgage_broker' => 'Mortgage broker',
    'lawyer' => 'Property lawyer',
    'accountant' => 'Accountant',
    'lender' => 'Bank or lender',
    _ => 'Buyer or investor',
  };
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.value,
    required this.label,
  });
  final double width;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => MarketplaceHover(
    child: Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE6E2EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SiteText(
            contentKey: 'copy.profile_page.m29',
            literal: false,
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 6),
          SiteText(
            contentKey: 'copy.profile_page.m30',
            literal: false,
            label,
            style: const TextStyle(color: Color(0xFF777785), fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<dynamic>(
    stream: BackendService.authChanges,
    builder: (context, _) {
      if (BackendService.user == null) return const AuthPage();
      return Scaffold(
        backgroundColor: const Color(0xFFF7F6FA),
        appBar: AppBar(
          title: const Text('Your profile'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: const [
            AppNavigationMenu(guidePage: 'profile', dark: false),
            SizedBox(width: 12),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: PactProfilePanel(
              desktopLayout: true,
              key: ValueKey(BackendService.user!.id),
              actions: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Account details & tools'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _LegacyProfilePage(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: BackendService.signOut,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
