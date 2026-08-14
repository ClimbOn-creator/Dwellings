import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/account_service.dart';
import '../services/backend_service.dart';
import '../services/marketplace_service.dart';
import '../services/deal_room_service.dart';
import '../widgets/home_brand_button.dart';
import '../widgets/profile_photo.dart';
import '../widgets/app_navigation_menu.dart';
import 'auth_page.dart';
import 'deal_rooms_page.dart';
import 'member_workspace_pages.dart';
import 'member_profile_page.dart';

const _ink = Color(0xFF050510);
const _paper = Color(0xFFF5F5F7);
const _purple = Color(0xFF7657FF);
const _lilac = Color(0xFFBCAEFF);

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
  List<IntroductionRequest> _incomingIntroductions = [];
  List<DealRoom> _deals = [];
  ProfessionalWorkspaceStats? _professionalStats;
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
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshActivity(),
    );
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
        AccountService.loadIncomingIntroductions(),
        AccountService.loadProfessionalStats(),
        DealRoomService.loadRooms(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = values[0] as DashboardStats;
        _team = values[1] as List<MarketplaceProvider>;
        _outgoingIntroductions = values[2] as List<IntroductionRequest>;
        _incomingIntroductions = values[3] as List<IntroductionRequest>;
        _professionalStats = values[4] as ProfessionalWorkspaceStats?;
        _deals = values[5] as List<DealRoom>;
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
        AccountService.loadIncomingIntroductions(),
        AccountService.loadProfessionalStats(),
        DealRoomService.loadRooms(),
      ]);
      final profile = values[0] as AccountProfile?;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = values[1] as DashboardStats;
        _team = values[2] as List<MarketplaceProvider>;
        _outgoingIntroductions = values[3] as List<IntroductionRequest>;
        _incomingIntroductions = values[4] as List<IntroductionRequest>;
        _professionalStats = values[5] as ProfessionalWorkspaceStats?;
        _deals = values[6] as List<DealRoom>;
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
          SnackBar(content: Text('Could not load profile: $error')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
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
          SnackBar(content: Text('Could not upload photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showIntroductionDialog(MarketplaceProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = TextEditingController();
    final property = TextEditingController(
      text: _stats?.lastAddress.isNotEmpty == true
          ? 'I would like help with ${_stats!.lastAddress}.'
          : '',
    );
    var sending = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Introduction to ${provider.name}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isExample
                      ? 'This is an example professional. You can preview the introduction flow, but no message will be sent.'
                      : 'We will securely share your account name, email and property note with ${provider.name}.',
                  style: const TextStyle(
                    color: Color(0xFF666674),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: property,
                  onChanged: (_) => setModalState(() {}),
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Property or financing details',
                    hintText:
                        'Tell them what you are buying and what help you need.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'By requesting the introduction, you consent to this professional contacting you about this request.',
                  style: TextStyle(color: Color(0xFF777785), fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: sending || property.text.trim().isEmpty
                  ? null
                  : () async {
                      setModalState(() => sending = true);
                      try {
                        await AccountService.requestIntroduction(
                          provider: provider,
                          propertySummary: property.text,
                          phone: phone.text,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _refreshActivity();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.isExample
                                  ? 'Introduction preview complete. Nothing was sent.'
                                  : 'Introduction requested. ${provider.name} can now contact you.',
                            ),
                          ),
                        );
                      } catch (error) {
                        setModalState(() => sending = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Could not send: $error')),
                          );
                        }
                      }
                    },
              child: Text(sending ? 'Sending…' : 'Request introduction'),
            ),
          ],
        ),
      ),
    );
    phone.dispose();
    property.dispose();
  }

  Future<void> _signOut() async {
    await BackendService.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _ink,
        body: Center(child: CircularProgressIndicator(color: _purple)),
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
      backgroundColor: _paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(profile)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 54),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_professionalStats != null) ...[
                        _professionalWorkspace(_professionalStats!),
                        const SizedBox(height: 24),
                      ],
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
                                label: 'Introductions requested',
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
                      _currentDeals(),
                      const SizedBox(height: 42),
                      _introductionCentre(),
                      const SizedBox(height: 42),
                      const Text(
                        'Your selected team',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
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
                          child: const Text(
                            'Your team is empty. Open Local Network and add professionals you want to remember.',
                          ),
                        )
                      else
                        ..._team.map(_teamRow),
                      const SizedBox(height: 32),
                      _profileEditor(profile),
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

  Widget _header(AccountProfile? profile) => Container(
    color: _ink,
    padding: const EdgeInsets.fromLTRB(28, 22, 28, 54),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HomeBrandButton(size: 46),
              const Spacer(),
              const AppNavigationMenu(),
            ],
          ),
          const SizedBox(height: 54),
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
                      icon: const Icon(Icons.camera_alt_outlined, size: 17),
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
                    Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : 'Complete your profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _publicIdentity(profile),
                      style: const TextStyle(
                        color: Color(0xFFBCAEFF),
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
              child: Text(
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
              child: const Text('VIEW ALL'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_deals.isEmpty)
          const Text(
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
                              child: Text(
                                deal.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
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
                        Text(
                          'CURRENT STEP · ${deal.currentStep.toUpperCase()}',
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
    if (profile == null) return 'DwellingsIQ member';
    final parts = [
      profile.jobTitle,
      profile.companyName,
    ].where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? _roleLabel(profile.role) : parts.join(' · ');
  }

  Widget _professionalWorkspace(ProfessionalWorkspaceStats stats) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Member performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stats.verified
                    ? 'VERIFIED · ${stats.membershipTier.toUpperCase()}'
                    : stats.onboardingStatus.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                  color: Color(0xFFD8D0FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          stats.verified
              ? 'Your verified marketplace listing and client opportunity pipeline.'
              : 'Your application is ${stats.onboardingStatus.replaceAll('_', ' ')}. Your listing stays private until DwellingsIQ verifies it.',
          style: const TextStyle(color: Color(0xFFB8B8C5), fontSize: 12),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _professionalMetric('${stats.teamSaves}', 'TEAM SAVES'),
            _professionalMetric('${stats.introductions}', 'INTRODUCTIONS'),
            _professionalMetric('${stats.dealRooms}', 'DEAL ROOMS'),
            _professionalMetric(
              '${stats.profileCompleteness}%',
              'PROFILE READY',
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Divider(color: Color(0xFF2A2A3A), height: 1),
        const SizedBox(height: 18),
        const Text(
          'WORKSPACE TOOLS',
          style: TextStyle(
            color: _lilac,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 20) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _workspaceLaunchButton(
                  width: width,
                  icon: Icons.inbox_outlined,
                  title: 'Lead inbox',
                  detail: 'Review and move introductions forward.',
                  page: const MemberLeadInboxPage(),
                ),
                _workspaceLaunchButton(
                  width: width,
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI email composer',
                  detail: 'Create a reviewable client email draft.',
                  page: MemberEmailComposerPage(
                    senderName: _profile?.fullName ?? '',
                  ),
                ),
                _workspaceLaunchButton(
                  width: width,
                  icon: Icons.newspaper_outlined,
                  title: 'Newsletter builder',
                  detail: 'Build your monthly client update.',
                  page: MemberNewsletterBuilderPage(
                    memberName: _profile?.fullName ?? '',
                  ),
                ),
              ],
            );
          },
        ),
        if (!stats.verified) ...[
          const SizedBox(height: 16),
          const Text(
            'Verification checklist · real name and company · direct contact details · service markets · specialties · licence details when applicable. Platform review is required before public placement.',
            style: TextStyle(
              color: Color(0xFFD5D5DE),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _workspaceLaunchButton({
    required double width,
    required IconData icon,
    required String title,
    required String detail,
    required Widget page,
  }) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => page)),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: _lilac, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFAAAAB8),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _professionalMetric(String value, String label) => Container(
    width: 150,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: _lilac, fontSize: 8)),
      ],
    ),
  );

  Widget _introductionCentre() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _incomingIntroductions.isEmpty ? 'Introductions' : 'Lead inbox',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Track consented introductions from first response through consultation and outcome.',
        style: TextStyle(color: Color(0xFF666674)),
      ),
      const SizedBox(height: 18),
      if (_incomingIntroductions.isNotEmpty) ...[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _leadCount('NEW', {'new'}),
            _leadCount('ACTIVE', {
              'accepted',
              'qualified',
              'contacted',
              'consultation',
            }),
            _leadCount('WON', {'won'}),
            _leadCount('CLOSED', {'lost', 'declined', 'closed'}),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionLabel('CLIENT LEADS'),
        const SizedBox(height: 8),
        ..._incomingIntroductions.map(
          (request) => _introductionRow(request, incoming: true),
        ),
        const SizedBox(height: 18),
      ],
      const _SectionLabel('YOUR REQUESTS'),
      const SizedBox(height: 8),
      if (_outgoingIntroductions.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'No introductions yet. Open a professional profile to request one with your property context attached.',
          ),
        )
      else
        ..._outgoingIntroductions.map(
          (request) => _introductionRow(request, incoming: false),
        ),
    ],
  );

  Widget _leadCount(String label, Set<String> statuses) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE3E3E9)),
    ),
    child: Text(
      '${_incomingIntroductions.where((lead) => statuses.contains(lead.status)).length}  $label',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
    ),
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
      title: Text(
        incoming ? request.requesterName : request.providerName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        incoming
            ? 'Request for ${request.providerName}'
            : request.providerCompany,
        style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
      ),
      trailing: _statusBadge(request.status),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
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
            child: Text(
              'Response: ${request.memberMessage}',
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
              child: Text(
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
                label: const Text('UPDATE LEAD'),
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
      child: Text(
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
          title: const Text('Update lead'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Pipeline stage',
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
                                child: Text(value.toUpperCase()),
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
                      labelText: 'Message visible to client (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Private pipeline notes',
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
                      if (picked != null)
                        setModalState(() => followUp = picked);
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
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
                        labelText: 'Close reason',
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save update'),
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
      title: const Text(
        'Profile details',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${_roleLabel(profile?.role ?? 'user')} account · Tap to edit',
        style: const TextStyle(
          color: _purple,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _job,
          decoration: const InputDecoration(
            labelText: 'Job title or specialty',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _company,
          decoration: const InputDecoration(
            labelText: 'Company, firm or practice',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _employment,
          decoration: const InputDecoration(labelText: 'Work arrangement'),
          items: const [
            DropdownMenuItem(
              value: 'company',
              child: Text('Part of a company or firm'),
            ),
            DropdownMenuItem(
              value: 'self_employed',
              child: Text('Self-employed'),
            ),
            DropdownMenuItem(
              value: 'own_practice',
              child: Text('Own practice or company'),
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
            labelText: 'Professional bio or property goals',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          ),
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 17),
          label: const Text('Sign out'),
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
      title: Text(
        provider.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${provider.jobTitle} · ${provider.company}',
        style: const TextStyle(color: Color(0xFF666674), fontSize: 12),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
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
          child: Text(
            '${provider.reviewScore.toStringAsFixed(1)} ★ · ${provider.reviewCount} ratings · ${provider.experience} years experience${provider.isExample ? ' · Example profile' : ''}',
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
                builder: (_) => MemberProfilePage(provider: provider),
              ),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('OPEN FULL PROFILE'),
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
                label: Text(
                  provider.isExample
                      ? 'PREVIEW INTRODUCTION'
                      : 'REQUEST INTRODUCTION',
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
              label: const Text('REMOVE'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _purple,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
    ),
  );
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
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 128),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
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
        Text(
          label,
          style: const TextStyle(color: Color(0xFF777785), fontSize: 10),
        ),
      ],
    ),
  );
}
