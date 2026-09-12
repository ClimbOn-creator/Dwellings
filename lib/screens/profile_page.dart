import '../widgets/personal_motion.dart';
import '../widgets/marketplace_motion.dart';
import '../widgets/site_parallax_image.dart';
import '../widgets/site_text.dart';
import '../widgets/site_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
import 'connection_brief_page.dart';
import 'deal_rooms_page.dart';
import 'member_deal_marketplace_page.dart';
import 'member_profile_page.dart';
import 'acquisition_support_page.dart';
import 'business_acquisition_page.dart';

const _ink = Color(0xFF171717);
const _paper = Color(0xFFF4F1EB);
const _purple = Color(0xFF252525);
const _lilac = Color(0xFF9B9B98);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AccountProfile? _profile;
  DashboardStats? _stats;
  List<MarketplaceProvider> _team = [];
  List<IntroductionRequest> _outgoingIntroductions = [];
  List<DealRoom> _deals = [];
  Map<String, dynamic>? _acquisition;
  bool _loading = true;
  bool _saving = false;
  Timer? _refreshTimer;
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
    _name.dispose();
    _job.dispose();
    _company.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _refreshActivity() async {
    if (BackendService.user == null) return;
    try {
      final values = await Future.wait([
        AccountService.loadStats(),
        AccountService.loadTeam(),
        AccountService.loadOutgoingIntroductions(),
        DealRoomService.loadRooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = values[0] as DashboardStats;
        _team = values[1] as List<MarketplaceProvider>;
        _outgoingIntroductions = values[2] as List<IntroductionRequest>;
        _deals = values[3] as List<DealRoom>;
      });
    } catch (_) {
      // Keep the existing dashboard visible and try again on the next refresh.
    }
  }

  Future<void> _load() async {
    if (BackendService.user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final values = await Future.wait([
        AccountService.loadProfile(),
        AccountService.loadStats(),
        AccountService.loadTeam(),
        AccountService.loadOutgoingIntroductions(),
        DealRoomService.loadRooms(),
      ]);
      final profile = values[0] as AccountProfile?;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = values[1] as DashboardStats;
        _team = values[2] as List<MarketplaceProvider>;
        _outgoingIntroductions = values[3] as List<IntroductionRequest>;
        _deals = values[4] as List<DealRoom>;
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _photo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      await AccountService.uploadProfilePhoto(
        await file.readAsBytes(),
        extension,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SiteText(
              templateValues: {'value1': '${error}'},
              contentKey: 'copy.profile_page.m3',
              literal: false,
              "Could not upload photo: {{value1}}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showIntroductionDialog(MarketplaceProvider provider) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionBriefPage(
          provider: provider,
          initialContext: _stats?.lastAddress.isNotEmpty == true
              ? 'I would like help with ${_stats!.lastAddress}.'
              : '',
        ),
      ),
    );
    await _refreshActivity();
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 78,
        backgroundColor: const Color(0xFFF7F5F0),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        title: const HomeBrandButton(size: 58, dark: false),
        actions: [
          toggle,
          const AppNavigationMenu(dark: false),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverToBoxAdapter(child: _header(profile, scroll)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 54),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 980
                              ? (constraints.maxWidth - 60) / 6
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
                                value: '${stats.introductionCount}',
                                label: 'Connections started',
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
                      _acquisitionPath(),
                      const SizedBox(height: 24),
                      _currentDeals(),
                      const SizedBox(height: 42),
                      _introductionCentre(),
                      const SizedBox(height: 42),
                      const SiteText(
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
                        'PropertyIQ and DealIQ professionals you select in the Network stay attached to your account.',
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
                            'Your team is empty. Open Local Network and add professionals you want to remember.',
                          ),
                        )
                      else
                        ..._team.map(_teamRow),
                      const SizedBox(height: 32),
                      _profileEditor(profile),
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
      ('3. Deal screen', deal.isNotEmpty, const BusinessAcquisitionPage()),
      (
        '4. Pipeline',
        _deals.any((room) => room.isBusiness),
        const DealRoomsPage(initialSide: PlatformSide.business),
      ),
    ];
    return TopoCard(
      width: double.infinity,
      opacity: .11,
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
              color: Colors.white,
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

  Widget _header(AccountProfile? profile, ScrollController scroll) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SiteParallaxImage(
        controller: scroll,
        asset: 'assets/images/affinity-reflection-facade.jpg',
        contentKey: 'image.profile_page.mbackground1',
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF036294C), Color(0xCC33485C), Color(0xC05A4950)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 54),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          ProfilePhoto(
                            size: 112,
                            photoUrl: profile?.photoUrl ?? '',
                            borderRadius: BorderRadius.circular(28),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: IconButton.filled(
                              onPressed: _photo,
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 17,
                              ),
                              tooltip: 'Upload profile photo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SiteText(
                              contentKey: 'copy.profile_page.m5',
                              literal: false,
                              profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : 'Complete your profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SiteText(
                              contentKey: 'copy.profile_page.m6',
                              literal: false,
                              _publicIdentity(profile),
                              style: const TextStyle(
                                color: Color(0xFFE5DAEA),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
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
                MaterialPageRoute<void>(builder: (_) => const DealRoomsPage()),
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
    if (profile == null) return 'Affinity member';
    final parts = [
      profile.jobTitle,
      profile.companyName,
    ].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? _roleLabel(profile.role) : parts.join(' · ');
  }

  Widget _introductionCentre() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SiteText(
        contentKey: 'copy.profile_page.8',
        literal: true,
        'Connections',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 8),
      const SiteText(
        contentKey: 'copy.profile_page.9',
        literal: true,
        'Keep track of the connection briefs you have sent to professionals.',
        style: TextStyle(color: Color(0xFF666674)),
      ),
      const SizedBox(height: 18),
      if (_outgoingIntroductions.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SiteText(
            contentKey: 'copy.profile_page.10',
            literal: true,
            'No connections yet. Open a professional profile and build a private brief with the context they need.',
          ),
        )
      else
        ..._outgoingIntroductions.map(
          (request) => _introductionRow(request, incoming: false),
        ),
    ],
  );

  Widget _introductionRow(
    IntroductionRequest request, {
    required bool incoming,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      title: SiteText(
        contentKey: 'copy.profile_page.m11',
        literal: false,
        incoming ? request.requesterName : request.providerName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: SiteText(
        contentKey: 'copy.profile_page.m12',
        literal: false,
        incoming
            ? 'Request for ${request.providerName}'
            : request.providerCompany,
        style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
      ),
      trailing: _statusBadge(request.status),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SiteText(
            contentKey: 'copy.profile_page.m13',
            literal: false,
            request.propertySummary.isEmpty
                ? 'No property details supplied.'
                : request.propertySummary,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        if (request.memberMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SiteText(
              templateValues: {'value1': '${request.memberMessage}'},
              contentKey: 'copy.profile_page.m14',
              literal: false,
              "Response: {{value1}}",
              style: const TextStyle(
                color: _purple,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (incoming) ...[
          if (request.nextFollowUpAt != null ||
              request.providerNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SiteText(
                contentKey: 'copy.profile_page.m15',
                literal: false,
                [
                  if (request.nextFollowUpAt != null)
                    'FOLLOW UP ${DateFormat.yMMMd().format(request.nextFollowUpAt!)}',
                  if (request.providerNotes.isNotEmpty)
                    'PRIVATE NOTE · ${request.providerNotes}',
                ].join('\n'),
                style: const TextStyle(
                  color: Color(0xFF5E45D7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              [
                request.requesterEmail,
                if (request.requesterPhone.isNotEmpty) request.requesterPhone,
              ].join(' · '),
              style: const TextStyle(
                color: Color(0xFF4D4D5A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              FilledButton.icon(
                onPressed: () => _respondToIntroduction(request),
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: const SiteText(
                  contentKey: 'copy.profile_page.11',
                  literal: true,
                  'UPDATE LEAD',
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'accepted' ||
      'qualified' ||
      'contacted' ||
      'consultation' ||
      'won' => const Color(0xFF16825D),
      'declined' || 'lost' => const Color(0xFFB42318),
      'closed' => const Color(0xFF666674),
      _ => _purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SiteText(
        contentKey: 'copy.profile_page.m16',
        literal: false,
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Future<void> _respondToIntroduction(IntroductionRequest request) async {
    final message = TextEditingController();
    final notes = TextEditingController(text: request.providerNotes);
    final reason = TextEditingController(text: request.closedReason);
    var status = request.status == 'new' ? 'accepted' : request.status;
    DateTime? followUp = request.nextFollowUpAt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const SiteText(
            contentKey: 'copy.profile_page.12',
            literal: true,
            'Update lead',
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      label: SiteText(
                        'Pipeline stage',
                        contentKey: 'copy.profile_page.field1',
                        literal: true,
                      ),
                    ),
                    items:
                        const [
                              'accepted',
                              'qualified',
                              'contacted',
                              'consultation',
                              'won',
                              'lost',
                              'declined',
                              'closed',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: SiteText(
                                  contentKey: 'copy.profile_page.m17',
                                  literal: false,
                                  value.toUpperCase(),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => value == null
                        ? null
                        : setModalState(() => status = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: message,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: SiteText(
                        'Message visible to client (optional)',
                        contentKey: 'copy.profile_page.field2',
                        literal: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: SiteText(
                        'Private pipeline notes',
                        contentKey: 'copy.profile_page.field3',
                        literal: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            followUp ??
                            DateTime.now().add(const Duration(days: 2)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setModalState(() => followUp = picked);
                      }
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: SiteText(
                      contentKey: 'copy.profile_page.m18',
                      literal: false,
                      followUp == null
                          ? 'SET FOLLOW-UP'
                          : 'FOLLOW UP ${DateFormat.yMMMd().format(followUp!)}',
                    ),
                  ),
                  if ({'lost', 'declined', 'closed'}.contains(status)) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: reason,
                      decoration: const InputDecoration(
                        label: SiteText(
                          'Close reason',
                          contentKey: 'copy.profile_page.field4',
                          literal: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const SiteText(
                contentKey: 'copy.profile_page.13',
                literal: true,
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const SiteText(
                contentKey: 'copy.profile_page.14',
                literal: true,
                'Save update',
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await AccountService.respondToIntroduction(
        introductionId: request.id,
        status: status,
        message: message.text,
        followUpAt: followUp,
        privateNotes: notes.text,
        closedReason: reason.text,
      );
      await _refreshActivity();
    }
    message.dispose();
    notes.dispose();
    reason.dispose();
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
                      MemberDealMarketplacePage(initialChatProvider: provider),
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
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showIntroductionDialog(provider),
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
                label: SiteText(
                  contentKey: 'copy.profile_page.m28',
                  literal: false,
                  provider.isExample
                      ? 'PREVIEW CONNECTION'
                      : 'BUILD CONNECTION BRIEF',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0EAF3)],
        ),
        border: Border.all(color: const Color(0xFFE0D7E7)),
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 24,
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
